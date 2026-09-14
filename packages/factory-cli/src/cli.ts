#!/usr/bin/env node

import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { initializeConfig, loadConfig, type CreateConfigOptions } from "./config.js";
import { chooseClarification, clarificationTemplate, createClarification, formatClarification, inspectClarification, readConfirmedClarificationTasks } from "./clarification.js";
import { applyTeachingToTasks, captureTeachingSource, createTeachingDraft, formatTeachingCatalog, formatTeachingDraft, formatTeachingSuggestions, inspectTeachingDraft, listTeachingLessons, publishTeachingSkill, suggestTeachingLessons, teachingTemplate } from "./teaching.js";
import {
  appendContextEvent,
  queryContextEvents,
  verifyContextPacket,
  verifyContextLedger,
} from "./context-space.js";
import { runDoctor } from "./doctor.js";
import {
  recordAgentHandoff,
  verifyTaskCompletion,
  type WorkerHandoffInput,
} from "./evidence.js";
import { initializeFactoryProject } from "./installer.js";
import { runFactoryHook, type FactoryHookEvent } from "./hooks.js";
import {
  addKnowledgeEntry,
  bindKnowledgeEntryToProjectFile,
  importKnowledgeFile,
  queryKnowledge,
  setKnowledgeEntryStatus,
  verifyKnowledgeStore,
  type AddKnowledgeEntryInput,
} from "./knowledge.js";
import {
  createMemoryCleanupPlan,
  exportMemory,
  getMemoryStatus,
} from "./memory-admin.js";
import {
  prepareSpawnPlan,
  readAgentRegistry,
  readTaskGraphSnapshot,
  registerNativeDispatch,
  updateNativeAgentLifecycle,
  validateNewTasks,
  verifyAssignmentInput,
  type NativeAgentLifecycle,
} from "./orchestrator.js";
import { executeSearch } from "./search.js";
import { continueRun, createRepairRun, inspectRun, listRuns, prepareRepair } from "./run-management.js";
import { RunManagementError } from "./repair-store.js";
import { createProbeDraft, inspectProbe, observeProbe, prepareProbeRepair, probeTemplate } from "./probes.js";
import type {
  ContextEventKind,
  ContextPacket,
  FactoryTask,
  SearchProviderType,
} from "./types.js";
import { assertWithinRoot, readJson } from "./util.js";

const VERSION = "5.0.0-preview.1";

interface ParsedArguments {
  positionals: string[];
  flags: Map<string, string | boolean>;
}

function parseArguments(argv: string[]): ParsedArguments {
  const positionals: string[] = [];
  const flags = new Map<string, string | boolean>();
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("--")) {
      positionals.push(token);
      continue;
    }
    const equalsAt = token.indexOf("=");
    if (equalsAt > 2) {
      const key = token.slice(2, equalsAt);
      if (flags.has(key)) throw new Error("Duplicate flag: --" + key);
      flags.set(key, token.slice(equalsAt + 1));
      continue;
    }
    const key = token.slice(2);
    if (flags.has(key)) throw new Error("Duplicate flag: --" + key);
    const following = argv[index + 1];
    if (following !== undefined && !following.startsWith("--")) {
      flags.set(key, following);
      index += 1;
    } else {
      flags.set(key, true);
    }
  }
  return { positionals, flags };
}

function assertAllowedFlags(args: ParsedArguments, allowed: string[]): void {
  const expected = new Set(allowed);
  const unknown = [...args.flags.keys()].filter((flag) => !expected.has(flag));
  if (unknown.length > 0) {
    throw new Error("Unknown flag(s): " + unknown.map((flag) => "--" + flag).join(", "));
  }
}

function flagString(args: ParsedArguments, name: string): string | undefined {
  const value = args.flags.get(name);
  return typeof value === "string" ? value : undefined;
}

function requiredFlag(args: ParsedArguments, name: string): string {
  const value = flagString(args, name);
  if (!value) throw new Error("Missing required --" + name);
  return value;
}

function projectRoot(args: ParsedArguments): string {
  return resolve(flagString(args, "project") ?? process.cwd());
}

function featureBoolean(
  args: ParsedArguments,
  positive: string,
  negative: string,
): boolean | undefined {
  const enabled = args.flags.has(positive);
  const disabled = args.flags.has(negative);
  if (enabled && disabled) throw new Error("Cannot combine --" + positive + " and --" + negative);
  return enabled ? true : disabled ? false : undefined;
}

function searchProvider(args: ParsedArguments): SearchProviderType | undefined {
  const value = flagString(args, "search");
  if (value === undefined) return undefined;
  if (value === "none") return "none";
  if (["glm", "glm_zhipu", "zhipu"].includes(value)) return "glm_zhipu";
  throw new Error("--search must be glm or none");
}

function initOptions(args: ParsedArguments): CreateConfigOptions {
  const threads = flagString(args, "max-threads");
  const provider = flagString(args, "model-provider");
  if (provider && !["inherit_from_codex", "deepseek", "openai", "custom"].includes(provider)) {
    throw new Error("Invalid --model-provider");
  }
  return {
    projectId: flagString(args, "project-id"),
    multiAgent: featureBoolean(args, "multi-agent", "no-multi-agent"),
    externalContext: featureBoolean(args, "external-context", "no-external-context"),
    searchProvider: searchProvider(args),
    maxThreads: threads === undefined ? undefined : Number(threads),
    modelProvider: provider as CreateConfigOptions["modelProvider"],
    model: flagString(args, "model"),
  };
}

function jsonMode(args: ParsedArguments): boolean {
  return args.flags.has("json");
}

function output(value: unknown, asJson = true): void {
  if (asJson || typeof value !== "string") {
    process.stdout.write(JSON.stringify(value, null, 2) + "\n");
  } else {
    process.stdout.write(value + "\n");
  }
}

function readProjectJson<T>(root: string, inputPath: string): T {
  const path = assertWithinRoot(root, resolve(root, inputPath));
  if (!existsSync(path)) throw new Error("Input file not found: " + path);
  return readJson<T>(path);
}

function readTasks(root: string, inputPath: string): FactoryTask[] {
  const value = readProjectJson<FactoryTask[] | { tasks: FactoryTask[] }>(root, inputPath);
  const confirmed = readConfirmedClarificationTasks(root, value);
  if (confirmed) return confirmed;
  const tasks = Array.isArray(value) ? value : value?.tasks;
  if (!Array.isArray(tasks)) throw new Error("Task input must be an array or an object with tasks[]");
  return tasks;
}

function contextKind(value: string): ContextEventKind {
  const allowed: ContextEventKind[] = [
    "requirement",
    "decision",
    "task_state",
    "risk",
    "evidence",
    "rejected_claim",
    "agent_event",
    "frontend_summary",
  ];
  if (!allowed.includes(value as ContextEventKind)) {
    throw new Error("Invalid context event kind: " + value);
  }
  return value as ContextEventKind;
}

function helpText(): string {
  return [
    "Codex App Factory control plane " + VERSION,
    "",
    "核心命令 / Core commands:",
    "  factoryctl init [--project <path>] [--multi-agent] [--external-context] [--search glm|none]",
    "  factoryctl configure [same feature flags as init]",
    "  factoryctl doctor [--project <path>] [--json]",
    "  factoryctl hook handle --event <CodexHookEvent> (reads hook JSON from stdin)",
    "  factoryctl context append --kind <kind> --actor <name> --payload-json <json>",
    "  factoryctl context verify | query --query <text> --role <role>",
    "  factoryctl context packet-verify --file <packet.json> --run <id> --role <role> --assignment <id>",
    "  factoryctl context assignment-verify --file <input.json> --run <id> --role <role> --assignment <id>",
    "  factoryctl plan --tasks <tasks.json> [--run <id>] [--json] (new run)",
    "  factoryctl tasks validate --tasks <tasks.json> [--json] (read-only preflight)",
    "  factoryctl clarify template [--json] (read-only example proposal; no model call)",
    "  factoryctl clarify create --file <contrast.json> [--json] (record two concrete alternatives)",
    "  factoryctl clarify show --id <id> [--json] (read-only comparison)",
    "  factoryctl clarify choose --id <id> --option <id> --draft-hash <hash> --reply <user-reply> [--json]",
    "  factoryctl teach template [--json] (example candidate schema)",
    "  factoryctl teach capture --path <tracked-file> [--base HEAD] --note <user-explanation> [--json]",
    "  factoryctl teach draft --source <source-id> --file <lesson.json> [--json]",
    "  factoryctl teach show --id <lesson-id> [--json] (read-only preview and status)",
    "  factoryctl teach list [--limit <1-100>] [--offset <n>] [--json] (discover lessons and applicability boundaries)",
    "  factoryctl teach suggest --tasks <file> --task <id> [--limit <1-5>] [--json] (reviewable lexical shortlist)",
    "  factoryctl teach publish --id <lesson-id> --draft-hash <hash> --reply <user-approval> [--json]",
    "  factoryctl teach apply --id <lesson-id> --tasks <file> --task <id> --reason <applicability> [--json]",
    "  factoryctl run continue --run <id> [--json] (execute ready acceptance, then plan next wave)",
    "  factoryctl plan --run <id> --json (resume authoritative run)",
    "  factoryctl run inspect --run <id> [--json] (read-only; does not dispatch)",
    "  factoryctl run list [--limit <1-50>] [--json] (newest created first; default 10)",
    "  factoryctl repair create --from-run <id> --task <id> (--reuse-task | --tasks <file> | --probe <id>) --request-id <id> [--json]",
    "  factoryctl repair prepare --from-run <id> --task <id> [--json] (read-only failure context and recovery guidance)",
    "  factoryctl probe template [--json] (two hypotheses and one JSON observation)",
    "  factoryctl probe draft --from-run <id> --task <id> --file <probe.json> [--json]",
    "  factoryctl probe show --id <probe-id> [--json]",
    "  factoryctl probe observe --id <probe-id> --draft-hash <hash> --reply <user-approval> [--json]",
    "  factoryctl probe repair-plan --id <probe-id> [--json] (read-only repair task preview)",
    "  factoryctl agent register-spawn --run <id> --assignment <id> --native-id <id> --receipt-json <json>",
    "  factoryctl agent status --run <id>",
    "  factoryctl agent lifecycle --run <id> --native-id <id> --status <state>",
    "  factoryctl handoff record --run <id> --assignment <id> --file <handoff.json>",
    "  factoryctl verify --run <id> --task <id> --verifier-assignment <id>",
    "  factoryctl search --query <text>",
    "  factoryctl knowledge import --file <path> --roles <role,...> [--tags <tag,...>]",
    "  factoryctl knowledge add --file <entry.json> | query --query <text> --role <role> | verify",
    "  factoryctl knowledge retire --id <entry> | revoke --id <entry>",
    "  factoryctl knowledge bind --id <entry> (verify and bind an exact project file)",
    "  factoryctl memory status",
    "  factoryctl memory export --out <new-file.json>",
    "  factoryctl memory cleanup-plan [--older-than-days <days>] (dry-run only)",
    "",
    "启用多 Agent 后，Codex 主 Agent 会自动执行 plan；用户无需打开额外窗口或复制提示词。",
    "API Key 只放在 ZHIPUAI_API_KEY 或 .codex-factory/secrets.env 中，绝不写入 config。",
  ].join("\n");
}

async function run(argv: string[]): Promise<void> {
  const args = parseArguments(argv);
  const [command, subcommand] = args.positionals;
  if (!command || ["help", "-h"].includes(command) || args.flags.has("help")) {
    output(helpText(), false);
    return;
  }
  if (command === "version" || command === "-v") {
    output(VERSION, false);
    return;
  }

  const root = projectRoot(args);
  if (command === "init") {
    assertAllowedFlags(args, [
      "project", "project-id", "multi-agent", "no-multi-agent", "external-context",
      "no-external-context", "search", "max-threads", "model-provider", "model", "json",
    ]);
    const result = initializeFactoryProject(root, initOptions(args));
    output(result, true);
    return;
  }
  if (command === "configure") {
    assertAllowedFlags(args, [
      "project", "project-id", "multi-agent", "no-multi-agent", "external-context",
      "no-external-context", "search", "max-threads", "model-provider", "model", "json",
    ]);
    loadConfig(root);
    const config = initializeConfig(root, initOptions(args));
    const install = initializeFactoryProject(root, {});
    output({ config, written: install.written, warnings: install.warnings }, true);
    return;
  }
  if (command === "doctor") {
    assertAllowedFlags(args, ["project", "json"]);
    const result = runDoctor(root);
    output(result, true);
    if (result.status === "NOT_READY") process.exitCode = 1;
    return;
  }
  if (command === "hook" && subcommand === "handle") {
    assertAllowedFlags(args, ["project", "event", "json"]);
    const event = requiredFlag(args, "event") as FactoryHookEvent;
    const allowedEvents = new Set<FactoryHookEvent>([
      "SessionStart", "PreToolUse", "PostToolUse", "SubagentStart",
      "SubagentStop", "PreCompact", "PostCompact", "Stop",
    ]);
    if (!allowedEvents.has(event)) throw new Error("Unsupported Factory hook event: " + event);
    const inputText = readFileSync(0, "utf8");
    const input = JSON.parse(inputText || "{}") as Record<string, unknown>;
    output(runFactoryHook(root, event, input), true);
    return;
  }
  if (command === "context") {
    if (subcommand === "append") {
      assertAllowedFlags(args, ["project", "kind", "actor", "payload-json", "json"]);
      const payloadText = requiredFlag(args, "payload-json");
      const payload = JSON.parse(payloadText) as unknown;
      if (payload === null || typeof payload !== "object" || Array.isArray(payload)) {
        throw new Error("--payload-json must be a JSON object");
      }
      output(
        appendContextEvent(
          root,
          contextKind(requiredFlag(args, "kind")),
          requiredFlag(args, "actor"),
          payload as Record<string, unknown>,
        ),
      );
      return;
    }
    if (subcommand === "verify") {
      assertAllowedFlags(args, ["project", "json"]);
      const result = verifyContextLedger(root);
      output(result);
      if (!result.valid) process.exitCode = 1;
      return;
    }
    if (subcommand === "query") {
      assertAllowedFlags(args, ["project", "query", "role", "limit", "json"]);
      output(queryContextEvents(root, requiredFlag(args, "query"), {
        targetRole: requiredFlag(args, "role"),
        limit: Number(flagString(args, "limit") ?? 20),
      }));
      return;
    }
    if (subcommand === "assignment-verify") {
      assertAllowedFlags(args, ["project", "file", "run", "role", "assignment", "json"]);
      const result = verifyAssignmentInput(root, requiredFlag(args, "file"), {
        runId: requiredFlag(args, "run"),
        targetRole: requiredFlag(args, "role"),
        assignmentId: requiredFlag(args, "assignment"),
      });
      output(result);
      if (!result.valid) process.exitCode = 1;
      return;
    }
    if (subcommand === "packet-verify") {
      assertAllowedFlags(args, [
        "project", "file", "run", "role", "assignment", "json",
      ]);
      const packet = readProjectJson<ContextPacket>(root, requiredFlag(args, "file"));
      const result = verifyContextPacket(root, packet, {
        runId: requiredFlag(args, "run"),
        targetRole: requiredFlag(args, "role"),
        assignmentId: requiredFlag(args, "assignment"),
      });
      output(result);
      if (!result.valid) process.exitCode = 1;
      return;
    }
    throw new Error("context requires append, verify, query, assignment-verify, or packet-verify");
  }
  if (command === "memory") {
    if (subcommand === "status") {
      assertAllowedFlags(args, ["project", "json"]);
      const result = getMemoryStatus(root);
      output(result);
      if (["NOT_INITIALIZED", "INTEGRITY_FAILED"].includes(result.status)) {
        process.exitCode = 1;
      }
      return;
    }
    if (subcommand === "export") {
      assertAllowedFlags(args, ["project", "out", "json"]);
      output(exportMemory(root, requiredFlag(args, "out")));
      return;
    }
    if (subcommand === "cleanup-plan") {
      assertAllowedFlags(args, ["project", "older-than-days", "json"]);
      const rawDays = flagString(args, "older-than-days");
      output(createMemoryCleanupPlan(root, {
        olderThanDays: rawDays === undefined ? undefined : Number(rawDays),
      }));
      return;
    }
    throw new Error("memory requires status, export, or cleanup-plan");
  }
  if (command === "probe") {
    if (args.positionals.length !== 2) throw new Error("Unexpected probe arguments");
    if (subcommand === "repair-plan") {
      assertAllowedFlags(args, ["project", "id", "json"]);
      output(prepareProbeRepair(root, requiredFlag(args, "id")));
      return;
    }
    if (subcommand === "template") {
      assertAllowedFlags(args, ["project", "json"]);
      output(probeTemplate());
      return;
    }
    let result: ReturnType<typeof inspectProbe>;
    if (subcommand === "draft") {
      assertAllowedFlags(args, ["project", "from-run", "task", "file", "json"]);
      result = createProbeDraft(root, requiredFlag(args, "from-run"), requiredFlag(args, "task"),
        readProjectJson<unknown>(root, requiredFlag(args, "file")));
    } else if (subcommand === "show") {
      assertAllowedFlags(args, ["project", "id", "json"]);
      result = inspectProbe(root, requiredFlag(args, "id"));
    } else if (subcommand === "observe") {
      assertAllowedFlags(args, ["project", "id", "draft-hash", "reply", "json"]);
      result = observeProbe(root, requiredFlag(args, "id"), { draftHash: requiredFlag(args, "draft-hash"),
        userReply: requiredFlag(args, "reply") });
    } else throw new Error("probe requires template, draft, show, observe, or repair-plan");
    output(jsonMode(args) ? result : [result.status + " " + result.draft.probe_id,
      "Draft hash: " + result.draft.draft_hash, result.draft.data.proposal.question,
      ...result.draft.data.proposal.hypotheses.map((item) => item.id + ": " + item.cause + " Expected: " + JSON.stringify(item.expected) +
        "\n  Evidence: " + item.evidence_refs.join(", ") + "; follow-up: " + item.next_step),
      "Observation: " + JSON.stringify(result.draft.data.proposal.observation),
      "Saved result: " + JSON.stringify(result.observation?.data ?? null), result.next_step, ...result.limitations].join("\n"), jsonMode(args));
    return;
  }
  if (command === "teach") {
    if (args.positionals.length !== 2) throw new Error("Unexpected teach arguments");
    if (subcommand === "suggest") {
      assertAllowedFlags(args, ["project", "tasks", "task", "limit", "json"]);
      const result = suggestTeachingLessons(root, readTasks(root, requiredFlag(args, "tasks")), requiredFlag(args, "task"),
        args.flags.has("limit") ? Number(requiredFlag(args, "limit")) : undefined);
      output(jsonMode(args) ? result : formatTeachingSuggestions(result), jsonMode(args));
      return;
    }
    if (subcommand === "list") {
      assertAllowedFlags(args, ["project", "limit", "offset", "json"]);
      const result = listTeachingLessons(root, {
        limit: args.flags.has("limit") ? Number(requiredFlag(args, "limit")) : undefined,
        offset: args.flags.has("offset") ? Number(requiredFlag(args, "offset")) : undefined,
      });
      output(jsonMode(args) ? result : formatTeachingCatalog(result), jsonMode(args));
      return;
    }
    if (subcommand === "apply") {
      assertAllowedFlags(args, ["project", "id", "tasks", "task", "reason", "json"]);
      output(applyTeachingToTasks(root, requiredFlag(args, "id"), readTasks(root, requiredFlag(args, "tasks")),
        requiredFlag(args, "task"), requiredFlag(args, "reason")));
      return;
    }
    if (subcommand === "template") {
      assertAllowedFlags(args, ["project", "json"]);
      output(teachingTemplate());
      return;
    }
    if (subcommand === "capture") {
      assertAllowedFlags(args, ["project", "path", "base", "note", "json"]);
      const result = captureTeachingSource(root, { path: requiredFlag(args, "path"),
        base: args.flags.has("base") ? requiredFlag(args, "base") : undefined, note: requiredFlag(args, "note") });
      output(jsonMode(args) ? result : [result.status + " " + result.source_id, "Path: " + result.data.path,
        "Base: " + result.data.base_commit, "Source file: " + result.source_file, "", result.data.diff,
        result.next_action, result.limitation].join("\n"), jsonMode(args));
      return;
    }
    let result: ReturnType<typeof inspectTeachingDraft>;
    if (subcommand === "draft") {
      assertAllowedFlags(args, ["project", "source", "file", "json"]);
      result = createTeachingDraft(root, requiredFlag(args, "source"), readProjectJson<unknown>(root, requiredFlag(args, "file")));
    } else if (subcommand === "show") {
      assertAllowedFlags(args, ["project", "id", "json"]);
      result = inspectTeachingDraft(root, requiredFlag(args, "id"));
    } else if (subcommand === "publish") {
      assertAllowedFlags(args, ["project", "id", "draft-hash", "reply", "json"]);
      result = publishTeachingSkill(root, requiredFlag(args, "id"), { draftHash: requiredFlag(args, "draft-hash"),
        userReply: requiredFlag(args, "reply") });
    } else throw new Error("teach requires template, capture, draft, list, suggest, show, publish, or apply");
    output(jsonMode(args) ? result : formatTeachingDraft(result), jsonMode(args));
    return;
  }
  if (command === "clarify") {
    if (args.positionals.length !== 2) throw new Error("Unexpected clarify arguments");
    if (subcommand === "template") {
      assertAllowedFlags(args, ["project", "json"]);
      output(clarificationTemplate());
      return;
    }
    let result: ReturnType<typeof inspectClarification>;
    if (subcommand === "create") {
      assertAllowedFlags(args, ["project", "file", "json"]);
      result = createClarification(root, readProjectJson<unknown>(root, requiredFlag(args, "file")));
    } else if (subcommand === "show") {
      assertAllowedFlags(args, ["project", "id", "json"]);
      result = inspectClarification(root, requiredFlag(args, "id"));
    } else if (subcommand === "choose") {
      assertAllowedFlags(args, ["project", "id", "option", "draft-hash", "reply", "json"]);
      result = chooseClarification(root, requiredFlag(args, "id"), {
        optionId: requiredFlag(args, "option"), draftHash: requiredFlag(args, "draft-hash"),
        userReply: requiredFlag(args, "reply"),
      });
    } else throw new Error("clarify requires template, create, show, or choose");
    output(jsonMode(args) ? result : formatClarification(result), jsonMode(args));
    return;
  }
  if (command === "tasks" && subcommand === "validate") {
    assertAllowedFlags(args, ["project", "tasks", "json"]);
    if (args.positionals.length !== 2) throw new Error("Unexpected tasks validate arguments");
    const result = validateNewTasks(readTasks(root, requiredFlag(args, "tasks")));
    output(jsonMode(args) ? result : [
      "VALID: " + result.worker_count + " workers + " + result.verifier_count + " independent verifiers",
      "Initially ready: " + result.ready_task_ids.join(", "),
      ...result.tasks.map((task) => "  " + task.task_id + " [" + task.profile_id + "] depends on: " +
        (task.dependencies.join(", ") || "none") + "; writes: " + (task.write_scope.join(", ") || "read-only")),
      ...result.limitations,
    ].join("\n"), jsonMode(args));
    return;
  }
  if (command === "run" && subcommand === "continue") {
    assertAllowedFlags(args, ["project", "run", "json"]);
    if (args.positionals.length !== 2) throw new Error("Unexpected run continue arguments");
    const result = continueRun(root, requiredFlag(args, "run"));
    output(jsonMode(args) ? result : [
      result.run_id + ": " + result.status,
      ...result.verifications.map((receipt) => "Acceptance " + receipt.task_id + ": " + receipt.verdict),
      ...(result.plan?.assignments ?? []).map((item) => "Dispatch " + item.task_id + ": " + item.assignment_id),
      ...result.waiting_for.map((item) => "Await " + item.task_id + ": " + item.native_agent_id),
      "Verified deliveries: " + result.delivery.tasks.length + (result.delivery.complete ? " (complete)" : " (partial)"),
      ...result.delivery.tasks.flatMap((task) => ["  " + task.task_id + ": " + task.title,
        ...task.artifacts.map((artifact) => "    " + artifact.path), "    Receipt: " + task.receipt_path]),
      ...result.inspection.tasks.flatMap((task) => task.failure_reasons.map((reason) => task.task_id + ": " + reason)),
      ...result.next_actions, ...result.inspection.limitations,
    ].join("\n"), jsonMode(args));
    if (result.status === "FAILED") process.exitCode = 1;
    return;
  }
  if (command === "run" && subcommand === "list") {
    assertAllowedFlags(args, ["project", "limit", "json"]);
    if (args.positionals.length !== 2) throw new Error("Unexpected run list arguments");
    const limit = args.flags.has("limit") ? Number(requiredFlag(args, "limit")) : 10;
    const result = listRuns(root, limit);
    output(jsonMode(args) ? result : result.total === 0 ? "No Factory runs found in this project." : [
      "Recent runs (newest created first): " + result.runs.length + "/" + result.total,
      "Created (UTC)             Status             Verified/Total  Run",
      ...result.runs.map((run) => [
        (run.created_at ?? "unknown").padEnd(24), run.status.padEnd(18),
        (run.total_tasks === null ? "?/?" : run.verified_tasks + "/" + run.total_tasks).padEnd(15),
        run.run_id + (run.parent_run_id ? " (repair " + run.repair_index + "/2 from " + run.parent_run_id + ")" : ""),
        ...(run.error ? ["- " + run.error] : []),
      ].join(" ")),
      ...(result.has_more ? ["More runs exist; increase --limit (maximum 50)."] : []),
      "Recorded status only; host liveness is unknown. Task counts include independent verifiers.",
      "Next: factoryctl run inspect --project " + JSON.stringify(root.replaceAll("\\", "/")) + " --run <id>",
    ].join("\n"), jsonMode(args));
    return;
  }
  if (command === "run" && subcommand === "inspect") {
    assertAllowedFlags(args, ["project", "run", "json"]);
    if (args.positionals.length !== 2) throw new Error("Unexpected run inspect arguments");
    const result = inspectRun(root, requiredFlag(args, "run"));
    output(jsonMode(args) ? result : [
      result.run_id + ": " + result.status + " (evidence " + result.integrity + ")",
      ...result.tasks.map((task) => "  " + task.task_id + ": " + task.status +
        (task.blocked_by.length ? " (blocked by: " + task.blocked_by.join(", ") + ")" : task.status === "blocked" ? " (explicitly blocked)" : "") +
        (task.failure_reasons.length ? " - " + task.failure_reasons.join("; ") : "")),
      ...result.next_actions, ...result.limitations,
    ].join("\n"), jsonMode(args));
    return;
  }

  if (command === "repair" && subcommand === "prepare") {
    assertAllowedFlags(args, ["project", "from-run", "task", "json"]);
    if (args.positionals.length !== 2) throw new Error("Unexpected repair prepare arguments");
    const result = prepareRepair(root, requiredFlag(args, "from-run"), requiredFlag(args, "task"));
    output(jsonMode(args) ? result : [
      result.from_run + "/" + result.task_id + ": " + result.status + " (read-only; original verdict " + result.source_verdict + ")",
      "Acceptance: " + result.observations.acceptance.passed + "/" + result.observations.acceptance.total + " passed",
      ...result.observations.acceptance.items.map((check) => "  Check " + check.index + ": " + check.method + " - " + check.detail),
      ...result.observations.artifacts.items.map((check) => "  Artifact: " + check.method + " - " + check.detail),
      "Reported command failures: " + result.observations.reported_command_failures.total,
      ...result.observations.reported_command_failures.items.map((item) => "  " + item.source + ": " + item.command + " (exit " + item.exit_code + ")"),
      "Independent verifier proposal: " + result.observations.verifier_proposal,
      "Scope: " + (result.task_contract.write_scope.join(", ") || "read-only"),
      "Required artifacts: " + result.task_contract.required_artifacts.join(", "),
      "Original acceptance: " + result.task_contract.acceptance_methods.join(" | "),
      ...result.upstream_inputs.map((item) => "Upstream " + item.run_id + "/" + item.task_id + ": " + item.artifacts.map((artifact) => artifact.path).join(", ")),
      "Repair attempts remaining: " + result.repair.remaining_attempts + "/2",
      ...(result.repair.existing_child ? ["Existing repair: " + result.repair.existing_child.run_id + " (" +
        (result.repair.existing_child.status ?? result.repair.existing_child.state) + ")"] : []),
      "Evidence: " + result.evidence.receipt_path,
      ...result.next_actions, ...result.limitations,
    ].join("\n"), jsonMode(args));
    return;
  }
  if (command === "repair" && subcommand === "create") {
    assertAllowedFlags(args, ["project", "from-run", "task", "tasks", "reuse-task", "probe", "request-id", "json"]);
    if (args.positionals.length !== 2) throw new Error("Unexpected repair create arguments");
    const fromRun = requiredFlag(args, "from-run");
    const taskId = requiredFlag(args, "task");
    const requestId = requiredFlag(args, "request-id");
    if (args.flags.has("reuse-task") && args.flags.has("tasks")) throw new Error("Choose --reuse-task or --tasks, not both");
    if (args.flags.has("probe") && (args.flags.has("tasks") || args.flags.has("reuse-task"))) {
      throw new Error("Choose --probe, --reuse-task or --tasks, not a combination");
    }
    if (args.flags.has("reuse-task") && args.flags.get("reuse-task") !== true) throw new Error("--reuse-task takes no value");
    let tasks: FactoryTask[];
    if (args.flags.has("probe")) {
      const prepared = prepareProbeRepair(root, requiredFlag(args, "probe"));
      if (prepared.from_run !== fromRun || prepared.task_id !== taskId) throw new Error("Probe belongs to a different failed run/task");
      if (!prepared.tasks || prepared.status === "BLOCKED") throw new Error("Probe repair is blocked; inspect repair prepare before proceeding");
      tasks = prepared.tasks;
    } else if (args.flags.has("reuse-task")) {
      const graph = readTaskGraphSnapshot(root, fromRun);
      const original = graph.tasks.find((task) => task.task_id === taskId);
      if (!original) throw new RunManagementError("TASK_NOT_FOUND", "Failed task not found");
      if (original.dependencies.some((id) => graph.tasks.find((task) => task.task_id === id)?.status !== "verified")) {
        throw new Error("--reuse-task requires verified upstream tasks; use --tasks for an explicit repair plan");
      }
      // Upstream outputs are reused; only this task receives a new execution.
      tasks = [{ ...original, status: "pending", dependencies: [] }];
    } else {
      tasks = readTasks(root, requiredFlag(args, "tasks"));
    }
    const result = createRepairRun(root, {
      fromRun, taskId, tasks, requestId,
    });
    output(jsonMode(args) ? result : result.run_id + " (repair " + result.repair.repair_index + "/2)\n" + result.next_action, jsonMode(args));
    return;
  }

  if (command === "plan") {
    assertAllowedFlags(args, ["project", "tasks", "run", "json"]);
    const runId = flagString(args, "run");
    const taskInput = flagString(args, "tasks") ??
      (runId ? ".codex-factory/runs/" + runId + "/task-graph.json" : undefined);
    if (!taskInput) throw new Error("A new run requires --tasks; an existing run can resume with --run");
    const plan = prepareSpawnPlan(
      root,
      readTasks(root, taskInput),
      runId,
    );
    output(plan, true);
    return;
  }
  if (command === "agent") {
    if (subcommand === "status") {
      assertAllowedFlags(args, ["project", "run", "json"]);
      output(readAgentRegistry(root, requiredFlag(args, "run")));
      return;
    }
    if (subcommand === "register-spawn") {
      assertAllowedFlags(args, [
        "project", "run", "assignment", "native-id", "nickname", "receipt-json",
        "receipt-file", "tool", "json",
      ]);
      const receiptJson = flagString(args, "receipt-json");
      const receiptFile = flagString(args, "receipt-file");
      if (Boolean(receiptJson) === Boolean(receiptFile)) {
        throw new Error("Provide exactly one of --receipt-json or --receipt-file");
      }
      const rawReceipt = receiptFile
        ? readProjectJson<unknown>(root, receiptFile)
        : JSON.parse(receiptJson as string);
      const tool = flagString(args, "tool") ?? "spawn_agent";
      if (!["spawn_agent", "followup_task"].includes(tool)) {
        throw new Error("--tool must be spawn_agent or followup_task");
      }
      output(
        registerNativeDispatch(root, requiredFlag(args, "run"), requiredFlag(args, "assignment"), {
          nativeAgentId: requiredFlag(args, "native-id"),
          nativeNickname: flagString(args, "nickname"),
          rawToolReceipt: rawReceipt,
          toolName: tool as "spawn_agent" | "followup_task",
        }),
      );
      return;
    }
    if (subcommand === "lifecycle") {
      assertAllowedFlags(args, ["project", "run", "native-id", "status", "json"]);
      output(
        updateNativeAgentLifecycle(
          root,
          requiredFlag(args, "run"),
          requiredFlag(args, "native-id"),
          requiredFlag(args, "status") as NativeAgentLifecycle,
        ),
      );
      return;
    }
    throw new Error("agent requires register-spawn, status, or lifecycle");
  }
  if (command === "handoff") {
    assertAllowedFlags(args, ["project", "run", "assignment", "file", "json"]);
    if (subcommand !== "record") throw new Error("handoff requires record");
    const handoff = readProjectJson<WorkerHandoffInput>(root, requiredFlag(args, "file"));
    output(
      recordAgentHandoff(
        root,
        requiredFlag(args, "run"),
        requiredFlag(args, "assignment"),
        handoff,
      ),
    );
    return;
  }
  if (command === "verify") {
    assertAllowedFlags(args, ["project", "run", "task", "verifier-assignment", "json"]);
    const receipt = verifyTaskCompletion(
      root,
      requiredFlag(args, "run"),
      requiredFlag(args, "task"),
      requiredFlag(args, "verifier-assignment"),
    );
    output(receipt);
    if (receipt.verdict !== "PASS") process.exitCode = 1;
    return;
  }
  if (command === "search") {
    assertAllowedFlags(args, ["project", "query", "json"]);
    const response = await executeSearch(root, requiredFlag(args, "query"));
    output(response);
    if (!response.accepted) process.exitCode = 1;
    return;
  }
  if (command === "knowledge") {
    if (subcommand === "import") {
      assertAllowedFlags(args, [
        "project", "file", "roles", "tags", "title", "source-kind", "supersedes", "entry-id", "json",
      ]);
      const roles = requiredFlag(args, "roles").split(",").map((item) => item.trim()).filter(Boolean);
      const tags = (flagString(args, "tags") ?? "").split(",").map((item) => item.trim()).filter(Boolean);
      output(importKnowledgeFile(root, requiredFlag(args, "file"), {
        title: flagString(args, "title"),
        sourceKind: flagString(args, "source-kind"),
        tags,
        roles,
        supersedesId: flagString(args, "supersedes"),
        entryId: flagString(args, "entry-id"),
      }));
      return;
    }
    if (subcommand === "add") {
      assertAllowedFlags(args, ["project", "file", "json"]);
      output(addKnowledgeEntry(root, readProjectJson<AddKnowledgeEntryInput>(root, requiredFlag(args, "file"))));
      return;
    }
    if (subcommand === "query") {
      assertAllowedFlags(args, ["project", "query", "role", "limit", "json"]);
      output(queryKnowledge(root, requiredFlag(args, "query"), {
        requestingRole: requiredFlag(args, "role"),
        limit: Number(flagString(args, "limit") ?? 20),
      }));
      return;
    }
    if (subcommand === "verify") {
      assertAllowedFlags(args, ["project", "json"]);
      const result = verifyKnowledgeStore(root);
      output(result);
      if (!result.valid) process.exitCode = 1;
      return;
    }
    if (subcommand === "retire" || subcommand === "revoke") {
      assertAllowedFlags(args, ["project", "id", "json"]);
      output(setKnowledgeEntryStatus(
        root,
        requiredFlag(args, "id"),
        subcommand === "retire" ? "retired" : "revoked",
      ));
      return;
    }
    if (subcommand === "bind") {
      assertAllowedFlags(args, ["project", "id", "json"]);
      output(bindKnowledgeEntryToProjectFile(root, requiredFlag(args, "id")));
      return;
    }
    throw new Error("knowledge requires import, add, query, verify, retire, revoke, or bind");
  }
  throw new Error("Unknown command: " + command);
}

run(process.argv.slice(2)).catch((error: unknown) => {
  const message = error instanceof Error ? error.message : String(error);
  process.stderr.write(JSON.stringify({ status: "ERROR", message,
    ...(error instanceof RunManagementError ? { code: error.code } : {}),
  }, null, 2) + "\n");
  process.exitCode = 1;
});
