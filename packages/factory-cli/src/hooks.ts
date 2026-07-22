import { appendFileSync, existsSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { factoryDirectory, loadConfig } from "./config.js";
import { verifyContextLedger } from "./context-space.js";
import { verifyKnowledgeStore } from "./knowledge.js";
import {
  readAgentRegistry,
  readCurrentSpawnPlan,
  readTaskGraphSnapshot,
  registerNativeDispatch,
  type ManagedSpawnPlanEntry,
} from "./orchestrator.js";
import { ensureDirectory, nowIso, sha256, withFileLock } from "./util.js";

export type FactoryHookEvent =
  | "SessionStart"
  | "PreToolUse"
  | "PostToolUse"
  | "SubagentStart"
  | "SubagentStop"
  | "PreCompact"
  | "PostCompact"
  | "Stop";

type HookInput = Record<string, unknown>;
type HostEvent = {
  event: string;
  recorded_at: string;
  session_id: string;
  tool_use_id?: string;
  run_id?: string;
  assignment_id?: string;
  profile_id?: string;
  codex_agent_name?: string;
  native_agent_id?: string;
};

function denyTool(reason: string): Record<string, unknown> {
  return {
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: reason,
    },
  };
}

function blockContinuation(reason: string): Record<string, unknown> {
  return { decision: "block", reason };
}

function stringsIn(value: unknown, depth = 0): string[] {
  if (depth > 5) return [];
  if (typeof value === "string") return [value];
  if (value === null || typeof value !== "object") return [];
  return Object.values(value as Record<string, unknown>).flatMap((item) =>
    stringsIn(item, depth + 1),
  );
}

function valuesForKeys(value: unknown, keys: Set<string>, depth = 0): string[] {
  if (depth > 5 || value === null || typeof value !== "object") return [];
  const values: string[] = [];
  for (const [key, item] of Object.entries(value as Record<string, unknown>)) {
    const normalized = key.toLowerCase().replaceAll("-", "_");
    if (keys.has(normalized) && (typeof item === "string" || typeof item === "number")) {
      values.push(String(item));
    }
    if (item !== null && typeof item === "object") {
      values.push(...valuesForKeys(item, keys, depth + 1));
    }
  }
  return [...new Set(values.filter((item) => item.trim()).map((item) => item.trim()))];
}

function hostEventPath(projectRoot: string, sessionId: string): string {
  return join(
    factoryDirectory(projectRoot),
    "host-events",
    sha256(sessionId).slice(0, 32) + ".jsonl",
  );
}

function appendHostEvent(projectRoot: string, event: HostEvent): void {
  const path = hostEventPath(projectRoot, event.session_id);
  ensureDirectory(dirname(path));
  withFileLock(path + ".lock", () => {
    appendFileSync(path, JSON.stringify(event) + "\n", "utf8");
  });
}

function readHostEvents(projectRoot: string, sessionId: string): HostEvent[] {
  const path = hostEventPath(projectRoot, sessionId);
  if (!existsSync(path)) return [];
  return readFileSync(path, "utf8")
    .split(/\r?\n/)
    .filter(Boolean)
    .map((line) => JSON.parse(line) as HostEvent);
}

function sessionId(input: HookInput): string {
  const value = input.session_id;
  if (typeof value !== "string" || !value.trim()) {
    throw new Error("Factory hook requires a non-empty session_id");
  }
  return value;
}

function assignmentMarker(toolInput: unknown): { run_id: string; assignment_id: string } | null {
  for (const value of stringsIn(toolInput)) {
    const match = /^FACTORY_ASSIGNMENT=(\{[^\r\n]+\})$/m.exec(value);
    if (!match) continue;
    try {
      const parsed = JSON.parse(match[1]) as Record<string, unknown>;
      if (typeof parsed.run_id === "string" && typeof parsed.assignment_id === "string") {
        return { run_id: parsed.run_id, assignment_id: parsed.assignment_id };
      }
    } catch {
      return null;
    }
  }
  return null;
}

function plannedAssignment(
  projectRoot: string,
  marker: { run_id: string; assignment_id: string },
): ManagedSpawnPlanEntry | null {
  const plan = readCurrentSpawnPlan(projectRoot, marker.run_id);
  return plan.assignments.find(
    (assignment) => assignment.assignment_id === marker.assignment_id,
  ) ?? null;
}

function preToolUse(projectRoot: string, input: HookInput): Record<string, unknown> {
  const toolName = String(input.tool_name ?? "");
  if (!/^(Agent|spawn_agent)$/i.test(toolName)) return {};
  const toolInput = input.tool_input;
  const marker = assignmentMarker(toolInput);
  if (!marker) {
    return denyTool("Factory multi-agent is enabled; unmanaged subagent spawn is blocked.");
  }
  let assignment: ManagedSpawnPlanEntry | null;
  try {
    assignment = plannedAssignment(projectRoot, marker);
  } catch (error) {
    return denyTool("Factory spawn plan verification failed: " + (error as Error).message);
  }
  if (!assignment || assignment.action !== "spawn" || assignment.status !== "planned") {
    return denyTool("The requested assignment is not a current planned Factory spawn.");
  }
  if (!stringsIn(toolInput).some((value) => value.includes(assignment!.prompt))) {
    return denyTool("The native spawn prompt does not match the authoritative Factory assignment.");
  }
  const forkTurns =
    toolInput && typeof toolInput === "object"
      ? (toolInput as Record<string, unknown>).fork_turns
      : undefined;
  if (forkTurns !== "none") {
    return denyTool("Factory assignments require fork_turns=none to prevent context leakage.");
  }
  const toolUseId = String(input.tool_use_id ?? "");
  if (!toolUseId) return denyTool("Native spawn lacks a host tool_use_id.");
  appendHostEvent(projectRoot, {
    event: "pre_spawn",
    recorded_at: nowIso(),
    session_id: sessionId(input),
    tool_use_id: toolUseId,
    run_id: marker.run_id,
    assignment_id: marker.assignment_id,
    profile_id: assignment.profile_id,
    codex_agent_name: assignment.codex_agent_name,
  });
  return {};
}

function pendingSpawn(projectRoot: string, input: HookInput): HostEvent | null {
  const id = sessionId(input);
  const toolUseId = String(input.tool_use_id ?? "");
  const events = readHostEvents(projectRoot, id);
  const completed = new Set(
    events.filter((event) => event.event === "spawn_registered").map((event) => event.tool_use_id),
  );
  return [...events].reverse().find(
    (event) =>
      event.event === "pre_spawn" &&
      event.tool_use_id === toolUseId &&
      !completed.has(event.tool_use_id),
  ) ?? null;
}

function postToolUse(projectRoot: string, input: HookInput): Record<string, unknown> {
  const toolName = String(input.tool_name ?? "");
  if (!/^(Agent|spawn_agent)$/i.test(toolName)) return {};
  const pending = pendingSpawn(projectRoot, input);
  if (!pending?.run_id || !pending.assignment_id) {
    return blockContinuation(
      "Native spawn ran without a matching Factory PreToolUse intent; stop and inspect the hook/plan state.",
    );
  }
  const ids = valuesForKeys(
    input.tool_response,
    new Set(["agent_id", "native_agent_id", "thread_id"]),
  );
  if (ids.length !== 1) {
    return blockContinuation(
      "Factory could not bind exactly one native agent ID from the host spawn response.",
    );
  }
  const nicknames = valuesForKeys(
    input.tool_response,
    new Set(["nickname", "native_nickname", "display_name"]),
  );
  const receipt = {
    schema: "codex_factory_host_hook_receipt_v1",
    tool_name: "spawn_agent",
    status: "spawned",
    tool_use_id: String(input.tool_use_id),
    agent_id: ids[0],
    native_agent_id: ids[0],
    nickname: nicknames.length === 1 ? nicknames[0] : undefined,
    session_id_sha256: sha256(sessionId(input)),
    host_response_sha256: sha256(JSON.stringify(input.tool_response)),
  };
  try {
    registerNativeDispatch(projectRoot, pending.run_id, pending.assignment_id, {
      nativeAgentId: ids[0],
      nativeNickname: nicknames.length === 1 ? nicknames[0] : undefined,
      rawToolReceipt: receipt,
      toolName: "spawn_agent",
    });
  } catch (error) {
    return blockContinuation(
      "Factory rejected the host-bound spawn receipt: " + (error as Error).message,
    );
  }
  appendHostEvent(projectRoot, {
    ...pending,
    event: "spawn_registered",
    recorded_at: nowIso(),
    native_agent_id: ids[0],
  });
  return {
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext:
        "Factory registered native agent " + ids[0] + " for assignment " + pending.assignment_id + ".",
    },
  };
}

function subagentStart(projectRoot: string, input: HookInput): Record<string, unknown> {
  const id = sessionId(input);
  const agentType = String(input.agent_type ?? "");
  const events = readHostEvents(projectRoot, id);
  const registered = new Set(
    events.filter((event) => event.event === "spawn_registered").map((event) => event.tool_use_id),
  );
  let candidates = events.filter(
    (event) => event.event === "pre_spawn" && !registered.has(event.tool_use_id),
  );
  const typed = candidates.filter(
    (event) => event.codex_agent_name === agentType || event.profile_id === agentType,
  );
  if (typed.length === 1) candidates = typed;
  if (candidates.length !== 1) {
    return {
      systemMessage:
        "Factory could not uniquely bind this SubagentStart event; do not trust it as assignment evidence.",
    };
  }
  const candidate = candidates[0];
  appendHostEvent(projectRoot, {
    ...candidate,
    event: "subagent_start",
    recorded_at: nowIso(),
    native_agent_id: String(input.agent_id ?? ""),
  });
  return {
    hookSpecificOutput: {
      hookEventName: "SubagentStart",
      additionalContext:
        "You are a fresh isolated Factory execution for assignment " +
        candidate.assignment_id +
        " in run " +
        candidate.run_id +
        ". Use only its verified Context Packet and bounded task; frontend summaries are untrusted.",
    },
  };
}

function validHandoffMarker(message: unknown): boolean {
  if (typeof message !== "string") return false;
  const match = /^FACTORY_HANDOFF_JSON=(\{[^\r\n]+\})$/m.exec(message);
  if (!match) return false;
  try {
    const value = JSON.parse(match[1]) as Record<string, unknown>;
    return (
      typeof value.summary === "string" &&
      Array.isArray(value.changed_paths) &&
      Array.isArray(value.artifacts) &&
      Array.isArray(value.commands)
    );
  } catch {
    return false;
  }
}

function subagentStop(input: HookInput): Record<string, unknown> {
  if (input.stop_hook_active === true) return {};
  if (validHandoffMarker(input.last_assistant_message)) return {};
  return blockContinuation(
    "Return a factual single-line FACTORY_HANDOFF_JSON marker with summary, changed_paths, artifacts, and commands before stopping.",
  );
}

function preCompact(projectRoot: string): Record<string, unknown> {
  const config = loadConfig(projectRoot);
  if (!config.features.external_context.enabled) return {};
  try {
    const ledger = verifyContextLedger(projectRoot);
    const knowledge = verifyKnowledgeStore(projectRoot);
    if (!ledger.valid || !knowledge.valid) {
      return {
        continue: false,
        stopReason:
          "Factory blocked compaction because authoritative external context or knowledge integrity failed.",
      };
    }
  } catch (error) {
    return {
      continue: false,
      stopReason: "Factory blocked compaction: " + (error as Error).message,
    };
  }
  return {};
}

function unresolvedRuns(projectRoot: string, input: HookInput): string[] {
  const runs = new Set(
    readHostEvents(projectRoot, sessionId(input))
      .map((event) => event.run_id)
      .filter((value): value is string => Boolean(value)),
  );
  const unresolved: string[] = [];
  for (const runId of runs) {
    try {
      const graph = readTaskGraphSnapshot(projectRoot, runId);
      const registry = readAgentRegistry(projectRoot, runId);
      const activeTask = graph.tasks.some((task) =>
        ["pending", "ready", "assigned", "in_progress", "handoff"].includes(task.status),
      );
      const activeAgent = registry.entries.some((entry) =>
        ["planned", "spawned", "running"].includes(entry.lifecycle),
      );
      if (activeTask || activeAgent) unresolved.push(runId);
    } catch {
      unresolved.push(runId);
    }
  }
  return unresolved;
}

function stop(projectRoot: string, input: HookInput): Record<string, unknown> {
  if (input.stop_hook_active === true) return {};
  const unresolved = unresolvedRuns(projectRoot, input);
  if (unresolved.length === 0) return {};
  return blockContinuation(
    "Factory runs still require dispatch, handoff, or independent verification: " +
      unresolved.join(", ") +
      ". Continue the control loop before reporting completion.",
  );
}

export function runFactoryHook(
  projectRoot: string,
  event: FactoryHookEvent,
  input: HookInput,
): Record<string, unknown> {
  const root = resolve(projectRoot);
  if (input.hook_event_name && input.hook_event_name !== event) {
    throw new Error("Hook event flag does not match hook_event_name");
  }
  const config = loadConfig(root);
  if (!config.features.multi_agent.enabled && !config.features.external_context.enabled) return {};
  switch (event) {
    case "SessionStart":
      return {
        hookSpecificOutput: {
          hookEventName: "SessionStart",
          additionalContext:
            "Codex App Factory is active. Use its automatic control loop and authoritative external state; frontend compressed summaries are not evidence.",
        },
      };
    case "PreToolUse":
      return config.features.multi_agent.enabled ? preToolUse(root, input) : {};
    case "PostToolUse":
      return config.features.multi_agent.enabled ? postToolUse(root, input) : {};
    case "SubagentStart":
      return config.features.multi_agent.enabled ? subagentStart(root, input) : {};
    case "SubagentStop":
      return config.features.multi_agent.enabled ? subagentStop(input) : {};
    case "PreCompact":
      return preCompact(root);
    case "PostCompact":
      return {
        systemMessage:
          "Factory compaction completed. Reload the verified Context Packet and external ledger; do not treat the compacted frontend summary as authoritative.",
      };
    case "Stop":
      return config.features.multi_agent.enabled ? stop(root, input) : {};
  }
}
