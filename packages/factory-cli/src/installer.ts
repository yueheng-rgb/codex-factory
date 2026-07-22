import { randomUUID } from "node:crypto";
import {
  existsSync,
  readFileSync,
  renameSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { AGENT_PROFILES, renderAgentToml } from "./agents.js";
import { DOMAIN_SKILL_IDS } from "./capabilities.js";
import {
  configPath,
  initializeConfig,
  type CreateConfigOptions,
} from "./config.js";
import { contextDatabasePath, initializeContextSpace } from "./context-space.js";
import { initializeKnowledgeStore } from "./knowledge.js";
import type { AgentProfile, FactoryConfig } from "./types.js";
import { ensureDirectory } from "./util.js";

export const AGENTS_BLOCK_START = "<!-- >>> CODEX_APP_FACTORY:CONTROL_PLANE >>> -->";
export const AGENTS_BLOCK_END = "<!-- <<< CODEX_APP_FACTORY:CONTROL_PLANE <<< -->";
export const SKILL_BLOCK_START = "<!-- >>> CODEX_APP_FACTORY:SKILL >>> -->";
export const SKILL_BLOCK_END = "<!-- <<< CODEX_APP_FACTORY:SKILL <<< -->";
export const AGENT_FILE_BLOCK_START = "# >>> CODEX_APP_FACTORY:AGENT >>>";
export const AGENT_FILE_BLOCK_END = "# <<< CODEX_APP_FACTORY:AGENT <<<";
export const CODEX_CONFIG_BLOCK_START = "# >>> CODEX_APP_FACTORY:THREAD_LIMITS >>>";
export const CODEX_CONFIG_BLOCK_END = "# <<< CODEX_APP_FACTORY:THREAD_LIMITS <<<";
export const GITIGNORE_BLOCK_START = "# >>> CODEX_APP_FACTORY:RUNTIME_STATE >>>";
export const GITIGNORE_BLOCK_END = "# <<< CODEX_APP_FACTORY:RUNTIME_STATE <<<";
export const FACTORY_HOOKS_DESCRIPTION = "Codex App Factory managed lifecycle hooks v1";

export interface InitializeFactoryProjectResult {
  config: FactoryConfig;
  written: string[];
  warnings: string[];
}

export interface CodexAgentsConfigInspection {
  section_count: number;
  max_threads?: number;
  max_depth?: number;
  duplicate_keys: string[];
  issues: string[];
}

interface ManagedWriteResult {
  changed: boolean;
  warning?: string;
}

const FACTORY_HOOK_EVENTS = [
  "SessionStart",
  "PreToolUse",
  "PostToolUse",
  "SubagentStart",
  "SubagentStop",
  "PreCompact",
  "PostCompact",
  "Stop",
] as const;

export function managedHooksContent(projectRoot: string): string {
  const root = resolve(projectRoot);
  const hooks = Object.fromEntries(
    FACTORY_HOOK_EVENTS.map((event) => {
      const matcher = event === "PreToolUse" || event === "PostToolUse"
        ? "Agent|spawn_agent"
        : event === "PreCompact" || event === "PostCompact"
          ? "manual|auto"
          : event === "SessionStart"
            ? "startup|resume|clear|compact"
            : "*";
      const command =
        "factoryctl hook handle --project " + JSON.stringify(root) + " --event " + event;
      return [
        event,
        [
          {
            matcher,
            hooks: [
              {
                type: "command",
                command,
                commandWindows: command,
                timeout: 30,
                statusMessage: "Codex App Factory: " + event,
              },
            ],
          },
        ],
      ];
    }),
  );
  return JSON.stringify({ description: FACTORY_HOOKS_DESCRIPTION, hooks }, null, 2) + "\n";
}

function writeOwnedHooksFile(path: string, content: string): ManagedWriteResult {
  if (!existsSync(path)) {
    writeTextAtomic(path, content);
    return { changed: true };
  }
  const current = readText(path);
  try {
    const parsed = JSON.parse(current) as Record<string, unknown>;
    if (parsed.description !== FACTORY_HOOKS_DESCRIPTION) {
      return { changed: false, warning: "Existing unowned hooks file was preserved: " + path };
    }
  } catch {
    return { changed: false, warning: "Invalid existing hooks file was preserved: " + path };
  }
  if (current === content) return { changed: false };
  writeTextAtomic(path, content);
  return { changed: true };
}

const FACTORY_SKILL_BODY = [
  "# Codex Factory automatic control plane",
  "",
  "Operate the Factory without asking the user to open extra windows or copy prompts.",
  "",
  "1. Read `.codex-factory/config.json` before substantial project work. Run `factoryctl doctor --project <root> --json`; stop on `NOT_READY` for any enabled feature.",
  "2. When `features.multi_agent.enabled` is true, decompose work into a dependency DAG and write the task input expected by `factoryctl plan --project <root> --tasks <tasks.json> [--run <id>] --json`.",
  "3. Before dispatching each assignment, run `factoryctl context packet-verify --project <root> --file <packet> --run <id> --role <role> --assignment <assignment-id>`. Stop that assignment if verification fails. Then execute it automatically with native `spawn_agent`, selecting the assignment's `.codex/agents/<codex_agent_name>.toml` profile, `fork_turns=none`, and only its verified Context Packet plus bounded task, acceptance methods, and write scope.",
  "4. Dispatch routing, knowledge, verification, and drift work to resident profiles. Spawn a fresh isolated execution for every assignment; resident means a durable specialist profile, not a reusable conversation or always-running daemon. Spawn temporary researchers, implementers, testers, or integrators only for bounded work.",
  "5. Keep a single worker layer. Workers must not spawn children. Treat `max_threads` as the native worker/subagent limit (the main controller is not subtracted), and never run overlapping write scopes concurrently.",
  "6. Immediately record the native ID and returned nickname with `factoryctl agent register-spawn --project <root> --run <id> --assignment <id> --native-id <id> [--nickname <name>] (--receipt-json <json> | --receipt-file <path>)`. Supply exactly one receipt option; never register a spawn without native evidence.",
  "7. Treat only `trusted_context` items with a verified admission receipt, physical repository files, command exit codes, and independent verifier receipts as authority. Treat `untrusted_context_candidates`, frontend summaries, and agent self-reports as leads that require verification; hash-chain integrity alone does not prove content truth.",
  "8. Wait for or steer active workers from the main controller. Record each structured handoff with `factoryctl handoff record --project <root> --run <id> --assignment <id> --file <handoff.json>`. After every handoff wave, run `factoryctl plan --project <root> --run <id> --json` without replacing the task graph; dispatch any returned original or verifier assignments and repeat until no pending assignment remains.",
  "9. A worker completion is not PASS. Require an independent verifier to re-run acceptance checks and decide with `factoryctl verify --project <root> --run <id> --task <id> --verifier-assignment <id>`, then let the integrator consume only verified outputs. On FAIL, preserve that immutable run and its evidence, automatically create a new bounded repair DAG under a new run ID, and verify again; this preview must not pretend it can append repair tasks to the failed run.",
  "10. Managed assignment planning automatically retrieves active, role-visible, source-current knowledge and binds bounded excerpts into a `knowledge_retrieval` admission receipt. Preserve and cite entry IDs, source URIs, and source hashes. For manual research, run `factoryctl knowledge verify` before `knowledge query`; never import frontend summaries or credential material as knowledge.",
  "11. When external search is enabled, use only the configured live provider and fail closed on a missing credential, HTTP error, malformed response, or absent evidence receipt. Never substitute invented or cached results.",
  "12. If multi-agent is disabled, continue in one Agent while still honoring external-context, professional-knowledge, and external-search controls.",
].join("\n");

export const FACTORY_SKILL_CONTENT = [
  "---",
  "name: codex-factory",
  "description: Automatically operate the project-local Codex App Factory control plane. Use for substantial project work whenever .codex-factory/config.json exists, especially when managed multi-agent dispatch, verified external context, anti-drift verification, scope-bounded workers, or optional live search is enabled.",
  "---",
  "",
  SKILL_BLOCK_START,
  FACTORY_SKILL_BODY,
  SKILL_BLOCK_END,
  "",
].join("\n");

export const FACTORY_SPECIALIST_SKILLS: Record<
  string,
  { description: string; instructions: string[] }
> = {
  "factory-router": {
    description: "Route substantial projects through architecture analysis and a bounded dependency DAG before implementation.",
    instructions: [
      "Classify the application with APP_TYPE_ROUTER-style rules and choose the smallest suitable architecture.",
      "Define roles, user journeys, page tree, API/data/permission sketches, completeness checks, failure risks, the first closed slice, and real paths that must work.",
      "Produce tasks with explicit dependencies, disjoint write scopes, executable acceptance methods, and required artifacts.",
      "Do not implement product code or declare tasks verified.",
    ],
  },
  "factory-librarian": {
    description: "Retrieve and maintain source-bound professional knowledge for a specific role without trusting frontend summaries.",
    instructions: [
      "Run `factoryctl knowledge verify` before retrieval and fail closed if integrity is invalid.",
      "Use source-bound `knowledge_retrieval` entries already attached to the assignment, or query with `factoryctl knowledge query --query <terms> --role librarian`; respect role visibility.",
      "Return entry IDs, source URIs, source hashes, staleness concerns, and contradictions.",
      "Never import a frontend compressed summary or an uncited agent self-report as knowledge.",
    ],
  },
  "factory-verifier": {
    description: "Independently verify physical artifacts and executable acceptance evidence without repairing the work under review.",
    instructions: [
      "Be a different native Agent from the worker and remain read-only.",
      "Inspect the physical diff, artifact hashes, exact commands, outputs, and exit codes.",
      "Return proposed_verdict PASS only when every declared method passes; otherwise use FAIL or BLOCKED.",
      "Never turn a worker handoff or a zero-test result into PASS.",
    ],
  },
  "factory-drift-auditor": {
    description: "Detect requirement, architecture, scope, context, and evidence drift against approved contracts.",
    instructions: [
      "Compare the current verified Context Packet, config, task graph, physical diff, and verification receipts.",
      "Report exact paths and contract clauses for every drift finding.",
      "Treat historical PASS files and frontend summaries as non-authoritative.",
      "Do not fix findings in the same assignment.",
    ],
  },
  "factory-researcher": {
    description: "Perform opt-in live research and return source-bound evidence rather than model recollection.",
    instructions: [
      "Use `factoryctl search --query <query>` only when external search is enabled.",
      "Require accepted=true, provider IDs, response hash, evidence bundle, and independent search verification.",
      "Prefer primary sources and clearly separate source facts from inference.",
      "Never fall back to invented or mock results in a live run.",
    ],
  },
  "factory-implementer": {
    description: "Implement one bounded task inside its declared write scope and provide a factual handoff.",
    instructions: [
      "Read the verified assignment packet before editing and stay inside write_scope.",
      "Make the smallest contract-compatible change and preserve unrelated user work.",
      "Record changed paths, artifact SHA-256 values, commands, exit codes, caveats, and unresolved risks.",
      "Do not edit controller state, expand scope, integrate other workers, or mark your own work PASS.",
    ],
  },
  "factory-tester": {
    description: "Create and run focused positive and negative tests for one bounded task.",
    instructions: [
      "Cover the requested behavior, important failure paths, and regression boundaries.",
      "Use executable acceptance methods and preserve exact exit evidence.",
      "Do not confuse writing tests with independent verification.",
    ],
  },
  "factory-integrator": {
    description: "Integrate only independently verified outputs while preserving provenance and user changes.",
    instructions: [
      "Require a current PASS receipt for every worker output before integration.",
      "Reject stale packets, changed artifact hashes, unresolved scope conflicts, or missing provenance.",
      "Run the integrated acceptance path and record the final physical diff.",
      "Do not silently reinterpret requirements or bypass a failed verifier.",
    ],
  },
};

export function specialistSkillContent(skillId: string): string {
  const skill = FACTORY_SPECIALIST_SKILLS[skillId];
  if (!skill) throw new Error("Unknown Factory specialist Skill: " + skillId);
  return [
    "---",
    "name: " + skillId,
    "description: " + skill.description,
    "---",
    "",
    SKILL_BLOCK_START,
    "# " + skillId,
    "",
    ...skill.instructions.map((instruction, index) => String(index + 1) + ". " + instruction),
    SKILL_BLOCK_END,
    "",
  ].join("\n");
}

export function domainSkillContent(skillId: string): string {
  if (!(DOMAIN_SKILL_IDS as readonly string[]).includes(skillId)) {
    throw new Error("Unknown Factory domain Skill: " + skillId);
  }
  const assetPath = join(
    dirname(fileURLToPath(import.meta.url)),
    "..",
    "domain-skills",
    skillId,
    "SKILL.md",
  );
  if (!existsSync(assetPath)) throw new Error("Factory domain Skill asset is missing: " + skillId);
  return readText(assetPath);
}

export const FACTORY_AGENTS_BLOCK = [
  AGENTS_BLOCK_START,
  "## Codex App Factory control plane (managed)",
  "",
  "- Before substantial project work, read `.codex-factory/config.json` and use the project skill at `.agents/skills/codex-factory/SKILL.md`.",
  "- If managed multi-agent work is enabled, the main Agent must plan, spawn, register, steer, wait for, verify, and integrate native subagents automatically. Never ask the user to open Agent windows or copy prompts.",
  "- Never trust frontend context compression or a worker self-report as completion evidence. Use the verified external Context Packet and physical artifacts.",
  "- Keep native delegation to one worker layer (`max_depth = 1`); workers may not spawn children.",
  "- External search is opt-in and requires the configured credential. Fail closed when it is unavailable.",
  AGENTS_BLOCK_END,
].join("\n");

export const FACTORY_GITIGNORE_BLOCK = [
  GITIGNORE_BLOCK_START,
  ".codex-factory/secrets.env",
  ".codex-factory/context/state.db",
  ".codex-factory/context/state.db-wal",
  ".codex-factory/context/state.db-shm",
  ".codex-factory/context/packets/",
  ".codex-factory/search/",
  ".codex-factory/runs/",
  ".codex-factory/*.lock",
  ".codex-factory/**/*.lock",
  GITIGNORE_BLOCK_END,
].join("\n");

function readText(path: string): string {
  return readFileSync(path, "utf8");
}

function writeTextAtomic(path: string, content: string): void {
  ensureDirectory(dirname(path));
  const temporaryPath = path + ".tmp-" + process.pid + "-" + randomUUID();
  writeFileSync(temporaryPath, content, "utf8");
  renameSync(temporaryPath, path);
}

function newlineFor(content: string): "\n" | "\r\n" {
  return content.includes("\r\n") ? "\r\n" : "\n";
}

function convertNewlines(content: string, newline: "\n" | "\r\n"): string {
  return content.replace(/\r?\n/g, newline);
}

function relativeProjectPath(projectRoot: string, path: string): string {
  return relative(resolve(projectRoot), resolve(path)).replaceAll("\\", "/");
}

function appendOrReplaceManagedBlock(
  path: string,
  startMarker: string,
  endMarker: string,
  managedBlock: string,
): ManagedWriteResult {
  if (!existsSync(path)) {
    writeTextAtomic(path, managedBlock.replace(/\r?\n/g, "\n") + "\n");
    return { changed: true };
  }

  const current = readText(path);
  const start = current.indexOf(startMarker);
  const end = current.indexOf(endMarker);
  if ((start >= 0) !== (end >= 0) || (start >= 0 && end < start)) {
    return {
      changed: false,
      warning: "Malformed Factory marker block; preserved file: " + path,
    };
  }

  const newline = newlineFor(current);
  const normalizedBlock = convertNewlines(managedBlock, newline);
  let next: string;
  if (start >= 0) {
    const blockEnd = end + endMarker.length;
    next = current.slice(0, start) + normalizedBlock + current.slice(blockEnd);
  } else {
    const separator = current.length === 0
      ? ""
      : current.endsWith(newline + newline)
        ? ""
        : current.endsWith(newline)
          ? newline
          : newline + newline;
    next = current + separator + normalizedBlock + newline;
  }
  if (next === current) return { changed: false };
  writeTextAtomic(path, next);
  return { changed: true };
}

function writeOwnedFile(
  path: string,
  startMarker: string,
  endMarker: string,
  content: string,
): ManagedWriteResult {
  if (!existsSync(path)) {
    writeTextAtomic(path, content);
    return { changed: true };
  }
  const current = readText(path);
  const start = current.indexOf(startMarker);
  const end = current.indexOf(endMarker);
  if (start < 0 || end < start) {
    return {
      changed: false,
      warning: "Existing unowned file was preserved: " + path,
    };
  }
  if (current === content) return { changed: false };
  writeTextAtomic(path, content);
  return { changed: true };
}

export function managedAgentContent(profile: AgentProfile, projectRoot: string): string {
  const skillPaths = profile.skill_ids.map((skillId) =>
    resolve(projectRoot, ".agents", "skills", skillId, "SKILL.md"),
  );
  return [
    AGENT_FILE_BLOCK_START,
    "# Logical icon (Factory dashboard): " + profile.icon,
    renderAgentToml(profile, skillPaths).trimEnd(),
    AGENT_FILE_BLOCK_END,
    "",
  ].join("\n");
}

function stripTomlComment(value: string): string {
  let quoted = false;
  let quote = "";
  for (let index = 0; index < value.length; index += 1) {
    const character = value[index];
    if ((character === '"' || character === "'") && value[index - 1] !== "\\") {
      if (!quoted) {
        quoted = true;
        quote = character;
      } else if (quote === character) {
        quoted = false;
      }
    }
    if (character === "#" && !quoted) return value.slice(0, index).trim();
  }
  return value.trim();
}

function findAgentsSection(lines: string[]): { start: number; end: number; count: number } {
  const starts: number[] = [];
  for (let index = 0; index < lines.length; index += 1) {
    if (/^\s*\[agents\]\s*(?:#.*)?$/.test(lines[index])) starts.push(index);
  }
  if (starts.length !== 1) {
    return { start: starts[0] ?? -1, end: -1, count: starts.length };
  }
  let end = lines.length;
  for (let index = starts[0] + 1; index < lines.length; index += 1) {
    if (/^\s*\[/.test(lines[index]) && !/^\s*#/.test(lines[index])) {
      end = index;
      break;
    }
  }
  return { start: starts[0], end, count: 1 };
}

export function inspectCodexAgentsConfig(content: string): CodexAgentsConfigInspection {
  const lines = content.replace(/^\uFEFF/, "").split(/\r?\n/);
  const section = findAgentsSection(lines);
  const result: CodexAgentsConfigInspection = {
    section_count: section.count,
    duplicate_keys: [],
    issues: [],
  };
  if (section.count === 0) {
    result.issues.push("Missing [agents] section");
    return result;
  }
  if (section.count > 1) {
    result.issues.push("Duplicate [agents] sections");
    return result;
  }

  const seen = new Set<string>();
  for (let index = section.start + 1; index < section.end; index += 1) {
    const match = /^\s*(max_threads|max_depth)\s*=\s*(.*?)\s*$/.exec(lines[index]);
    if (!match) continue;
    const key = match[1] as "max_threads" | "max_depth";
    if (seen.has(key)) result.duplicate_keys.push(key);
    seen.add(key);
    const rawValue = stripTomlComment(match[2]);
    if (!/^\d+$/.test(rawValue)) {
      result.issues.push(key + " must be an unquoted non-negative integer");
      continue;
    }
    result[key] = Number(rawValue);
  }
  if (result.duplicate_keys.length > 0) {
    result.issues.push("Duplicate keys: " + result.duplicate_keys.join(", "));
  }
  if (result.max_threads === undefined) result.issues.push("Missing agents.max_threads");
  if (result.max_depth === undefined) result.issues.push("Missing agents.max_depth");
  return result;
}

function renderCodexConfigBlock(maxThreads: number, keys = ["max_threads", "max_depth"]): string {
  const values: Record<string, number> = { max_threads: maxThreads, max_depth: 1 };
  return [
    CODEX_CONFIG_BLOCK_START,
    ...keys.map((key) => key + " = " + values[key]),
    CODEX_CONFIG_BLOCK_END,
  ].join("\n");
}

function updateCodexConfig(path: string, maxThreads: number): ManagedWriteResult {
  if (!existsSync(path)) {
    writeTextAtomic(
      path,
      ["[agents]", renderCodexConfigBlock(maxThreads), ""].join("\n"),
    );
    return { changed: true };
  }

  const current = readText(path);
  const bom = current.startsWith("\uFEFF") ? "\uFEFF" : "";
  const newline = newlineFor(current);
  const lines = current.replace(/^\uFEFF/, "").split(/\r?\n/);
  const section = findAgentsSection(lines);
  const managedStart = current.indexOf(CODEX_CONFIG_BLOCK_START);
  const managedEnd = current.indexOf(CODEX_CONFIG_BLOCK_END);
  if ((managedStart >= 0) !== (managedEnd >= 0) || managedEnd < managedStart) {
    return {
      changed: false,
      warning: "Malformed Factory thread-limit marker; preserved file: " + path,
    };
  }
  if (managedStart >= 0) {
    if (section.count !== 1) {
      return {
        changed: false,
        warning: "Factory thread limits exist without one valid [agents] section; preserved file: " + path,
      };
    }
    const beforeMarkerLine = current.slice(0, managedStart).split(/\r?\n/).length - 1;
    if (beforeMarkerLine <= section.start || beforeMarkerLine >= section.end) {
      return {
        changed: false,
        warning: "Factory thread-limit marker is outside [agents]; preserved file: " + path,
      };
    }
    const endOffset = managedEnd + CODEX_CONFIG_BLOCK_END.length;
    const next =
      current.slice(0, managedStart) +
      convertNewlines(renderCodexConfigBlock(maxThreads), newline) +
      current.slice(endOffset);
    if (next === current) return { changed: false };
    writeTextAtomic(path, next);
    return { changed: true };
  }

  if (section.count > 1) {
    return {
      changed: false,
      warning: "Duplicate [agents] sections; preserved Codex config: " + path,
    };
  }

  if (section.count === 0) {
    const firstAgentSubtable = lines.findIndex((line) => /^\s*\[agents\./.test(line));
    const addition = ["[agents]", renderCodexConfigBlock(maxThreads), ""].join(newline);
    let next: string;
    if (firstAgentSubtable >= 0) {
      lines.splice(firstAgentSubtable, 0, addition);
      next = bom + lines.join(newline);
    } else {
      const separator = current.length === 0 || current.endsWith(newline)
        ? newline
        : newline + newline;
      next = current + separator + addition;
    }
    writeTextAtomic(path, next);
    return { changed: true };
  }

  const keys = new Map<string, number>();
  for (let index = section.start + 1; index < section.end; index += 1) {
    const match = /^\s*(max_threads|max_depth)\s*=\s*(.*?)\s*$/.exec(lines[index]);
    if (!match) continue;
    const value = stripTomlComment(match[2]);
    if (!/^\d+$/.test(value) || keys.has(match[1])) {
      return {
        changed: false,
        warning: "Conflicting or invalid user-owned agents limits were preserved: " + path,
      };
    }
    keys.set(match[1], Number(value));
  }
  if (
    (keys.has("max_threads") && keys.get("max_threads") !== maxThreads) ||
    (keys.has("max_depth") && keys.get("max_depth") !== 1)
  ) {
    return {
      changed: false,
      warning: "User-owned agents limits conflict with Factory settings and were preserved: " + path,
    };
  }
  const missing = ["max_threads", "max_depth"].filter((key) => !keys.has(key));
  if (missing.length === 0) return { changed: false };
  lines.splice(section.start + 1, 0, renderCodexConfigBlock(maxThreads, missing));
  writeTextAtomic(path, bom + lines.join(newline));
  return { changed: true };
}

function recordWrite(
  result: ManagedWriteResult,
  projectRoot: string,
  path: string,
  written: Set<string>,
  warnings: string[],
): void {
  if (result.changed) written.add(relativeProjectPath(projectRoot, path));
  if (result.warning) warnings.push(result.warning);
}

export function initializeFactoryProject(
  projectRoot: string,
  options: CreateConfigOptions = {},
): InitializeFactoryProjectResult {
  const root = resolve(projectRoot);
  if (!existsSync(root) || !statSync(root).isDirectory()) {
    throw new Error("Project root must be an existing directory: " + root);
  }

  const written = new Set<string>();
  const warnings: string[] = [];
  const oldConfig = existsSync(configPath(root)) ? readText(configPath(root)) : undefined;
  const config = initializeConfig(root, options);
  const newConfig = readText(configPath(root));
  if (oldConfig !== newConfig) written.add(relativeProjectPath(root, configPath(root)));

  const gitignorePath = join(root, ".gitignore");
  recordWrite(
    appendOrReplaceManagedBlock(
      gitignorePath,
      GITIGNORE_BLOCK_START,
      GITIGNORE_BLOCK_END,
      FACTORY_GITIGNORE_BLOCK,
    ),
    root,
    gitignorePath,
    written,
    warnings,
  );

  const agentsPath = join(root, "AGENTS.md");
  recordWrite(
    appendOrReplaceManagedBlock(
      agentsPath,
      AGENTS_BLOCK_START,
      AGENTS_BLOCK_END,
      FACTORY_AGENTS_BLOCK,
    ),
    root,
    agentsPath,
    written,
    warnings,
  );

  const skillPath = join(root, ".agents", "skills", "codex-factory", "SKILL.md");
  recordWrite(
    writeOwnedFile(
      skillPath,
      SKILL_BLOCK_START,
      SKILL_BLOCK_END,
      FACTORY_SKILL_CONTENT,
    ),
    root,
    skillPath,
    written,
    warnings,
  );

  for (const skillId of Object.keys(FACTORY_SPECIALIST_SKILLS)) {
    const specialistPath = join(root, ".agents", "skills", skillId, "SKILL.md");
    recordWrite(
      writeOwnedFile(
        specialistPath,
        SKILL_BLOCK_START,
        SKILL_BLOCK_END,
        specialistSkillContent(skillId),
      ),
      root,
      specialistPath,
      written,
      warnings,
    );
  }

  for (const skillId of DOMAIN_SKILL_IDS) {
    const domainPath = join(root, ".agents", "skills", skillId, "SKILL.md");
    recordWrite(
      writeOwnedFile(
        domainPath,
        SKILL_BLOCK_START,
        SKILL_BLOCK_END,
        domainSkillContent(skillId),
      ),
      root,
      domainPath,
      written,
      warnings,
    );
  }

  for (const profile of AGENT_PROFILES) {
    const path = join(root, ".codex", "agents", profile.codex_agent_name + ".toml");
    recordWrite(
      writeOwnedFile(
        path,
        AGENT_FILE_BLOCK_START,
        AGENT_FILE_BLOCK_END,
        managedAgentContent(profile, root),
      ),
      root,
      path,
      written,
      warnings,
    );
  }

  const codexConfigPath = join(root, ".codex", "config.toml");
  recordWrite(
    updateCodexConfig(codexConfigPath, config.features.multi_agent.max_threads),
    root,
    codexConfigPath,
    written,
    warnings,
  );

  const hooksPath = join(root, ".codex", "hooks.json");
  recordWrite(
    writeOwnedHooksFile(hooksPath, managedHooksContent(root)),
    root,
    hooksPath,
    written,
    warnings,
  );

  if (config.features.external_context.enabled) {
    const databaseExisted = existsSync(contextDatabasePath(root));
    initializeContextSpace(root);
    if (!databaseExisted) {
      written.add(relativeProjectPath(root, contextDatabasePath(root)));
    }
  }
  initializeKnowledgeStore(root);

  return { config, written: [...written].sort(), warnings };
}
