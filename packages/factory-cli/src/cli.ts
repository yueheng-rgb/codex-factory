#!/usr/bin/env node

import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { initializeConfig, loadConfig, type CreateConfigOptions } from "./config.js";
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
  registerNativeDispatch,
  updateNativeAgentLifecycle,
  type NativeAgentLifecycle,
} from "./orchestrator.js";
import { executeSearch } from "./search.js";
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
  const tasks = Array.isArray(value) ? value : value.tasks;
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
    "  factoryctl context append --kind <kind> --actor <name> --payload-json <json>",
    "  factoryctl context verify | query --query <text> --role <role>",
    "  factoryctl context packet-verify --file <packet.json> --run <id> --role <role> --assignment <id>",
    "  factoryctl plan --tasks <tasks.json> [--run <id>] [--json] (new run)",
    "  factoryctl plan --run <id> --json (resume authoritative run)",
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
    throw new Error("context requires append, verify, query, or packet-verify");
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
  process.stderr.write(JSON.stringify({ status: "ERROR", message }, null, 2) + "\n");
  process.exitCode = 1;
});
