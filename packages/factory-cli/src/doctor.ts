import { DatabaseSync } from "node:sqlite";
import { spawnSync } from "node:child_process";
import { existsSync, readFileSync, statSync } from "node:fs";
import { join, resolve } from "node:path";
import { AGENT_PROFILES } from "./agents.js";
import { DOMAIN_SKILL_IDS } from "./capabilities.js";
import { loadConfig, resolveSecret } from "./config.js";
import { contextDatabasePath, verifyContextLedger } from "./context-space.js";
import {
  FACTORY_AGENTS_BLOCK,
  FACTORY_GITIGNORE_BLOCK,
  FACTORY_SPECIALIST_SKILLS,
  FACTORY_SKILL_CONTENT,
  inspectCodexAgentsConfig,
  managedAgentContent,
  managedHooksContent,
  domainSkillContent,
  specialistSkillContent,
} from "./installer.js";
import { verifyKnowledgeStore } from "./knowledge.js";
import type { DoctorCheck, DoctorResult, FactoryConfig } from "./types.js";

export interface CodexCapabilityProbe {
  available: boolean;
  version: string | null;
  multi_agent: boolean;
  multi_agent_v2: boolean;
  hooks: boolean;
  error?: "not_found" | "timeout" | "version_failed" | "features_failed";
}

export interface DoctorOptions {
  codexCapabilityProbe?: () => CodexCapabilityProbe;
}

export function parseCodexFeatureList(output: string): Map<string, boolean> {
  const features = new Map<string, boolean>();
  for (const line of output.split(/\r?\n/)) {
    const columns = line.trim().split(/\s+/);
    if (columns.length < 2) continue;
    const state = columns.at(-1);
    if (state !== "true" && state !== "false") continue;
    features.set(columns[0], state === "true");
  }
  return features;
}

export function probeCodexCapabilities(): CodexCapabilityProbe {
  const command = process.env.CODEX_FACTORY_CODEX_BIN?.trim() || "codex";
  const options = {
    encoding: "utf8" as const,
    timeout: 5_000,
    windowsHide: true,
  };
  const versionResult = spawnSync(command, ["--version"], options);
  if (versionResult.error) {
    const code = (versionResult.error as NodeJS.ErrnoException).code;
    return {
      available: false,
      version: null,
      multi_agent: false,
      multi_agent_v2: false,
      hooks: false,
      error: code === "ETIMEDOUT" ? "timeout" : "not_found",
    };
  }
  if (versionResult.status !== 0) {
    return {
      available: false,
      version: null,
      multi_agent: false,
      multi_agent_v2: false,
      hooks: false,
      error: "version_failed",
    };
  }
  const version = /\b(\d+\.\d+\.\d+(?:[-+][\w.-]+)?)\b/.exec(
    String(versionResult.stdout),
  )?.[1] ?? null;
  const featureResult = spawnSync(command, ["features", "list"], options);
  if (featureResult.error || featureResult.status !== 0) {
    return {
      available: true,
      version,
      multi_agent: false,
      multi_agent_v2: false,
      hooks: false,
      error:
        (featureResult.error as NodeJS.ErrnoException | undefined)?.code === "ETIMEDOUT"
          ? "timeout"
          : "features_failed",
    };
  }
  const features = parseCodexFeatureList(String(featureResult.stdout));
  return {
    available: true,
    version,
    multi_agent: features.get("multi_agent") === true,
    multi_agent_v2: features.get("multi_agent_v2") === true,
    hooks: features.get("hooks") === true,
  };
}

function normalizeNewlines(value: string): string {
  return value.replace(/\r\n/g, "\n");
}

function readText(path: string): string {
  return readFileSync(path, "utf8");
}

function resultFromChecks(checks: DoctorCheck[]): DoctorResult {
  if (checks.some((check) => check.status === "FAIL")) {
    return { status: "NOT_READY", checks };
  }
  if (checks.some((check) => check.status === "WARN")) {
    return { status: "READY_WITH_LIMITATIONS", checks };
  }
  return { status: "READY", checks };
}

function checkManagedText(
  id: string,
  path: string,
  expected: string,
  label: string,
): DoctorCheck {
  if (!existsSync(path)) {
    return { id, status: "FAIL", detail: label + " is missing" };
  }
  if (!normalizeNewlines(readText(path)).includes(normalizeNewlines(expected).trimEnd())) {
    return {
      id,
      status: "FAIL",
      detail: label + " is stale, incomplete, or no longer contains the managed contract",
    };
  }
  return { id, status: "PASS", detail: label + " is installed" };
}

function checkAgentFiles(root: string, config: FactoryConfig): DoctorCheck {
  const configuredResidents = new Set(config.features.multi_agent.resident_profiles);
  const knownResidents = new Set(
    AGENT_PROFILES.filter((profile) => profile.kind === "resident").map(
      (profile) => profile.profile_id,
    ),
  );
  const unknownResidents = [...configuredResidents].filter(
    (profileId) => !knownResidents.has(profileId),
  );
  const missingResidents = [...knownResidents].filter(
    (profileId) => !configuredResidents.has(profileId),
  );
  if (unknownResidents.length > 0 || missingResidents.length > 0) {
    const details: string[] = [];
    if (unknownResidents.length > 0) {
      details.push("unknown resident profiles: " + unknownResidents.join(", "));
    }
    if (missingResidents.length > 0) {
      details.push("mandatory resident profiles omitted: " + missingResidents.join(", "));
    }
    return {
      id: "multi_agent.agent_profiles",
      status: config.features.multi_agent.enabled ? "FAIL" : "WARN",
      detail: details.join("; "),
    };
  }

  const required = AGENT_PROFILES.filter(
    (profile) =>
      configuredResidents.has(profile.profile_id) ||
      (config.features.multi_agent.allow_temporary_agents && profile.kind === "temporary"),
  );
  const issues: string[] = [];
  for (const profile of required) {
    const path = join(root, ".codex", "agents", profile.codex_agent_name + ".toml");
    if (!existsSync(path)) {
      issues.push(profile.codex_agent_name + " is missing");
      continue;
    }
    if (
      normalizeNewlines(readText(path)) !==
      normalizeNewlines(managedAgentContent(profile, root))
    ) {
      issues.push(profile.codex_agent_name + " is stale or unowned");
    }
  }

  if (issues.length > 0) {
    return {
      id: "multi_agent.agent_profiles",
      status: config.features.multi_agent.enabled ? "FAIL" : "WARN",
      detail: issues.join("; "),
    };
  }
  return {
    id: "multi_agent.agent_profiles",
    status: "PASS",
    detail:
      String(required.length) +
      " required native Agent profiles are installed with Factory boundaries",
  };
}

function checkSpecialistSkills(root: string): DoctorCheck {
  const issues: string[] = [];
  for (const skillId of Object.keys(FACTORY_SPECIALIST_SKILLS)) {
    const path = join(root, ".agents", "skills", skillId, "SKILL.md");
    if (!existsSync(path)) {
      issues.push(skillId + " is missing");
      continue;
    }
    if (normalizeNewlines(readText(path)) !== normalizeNewlines(specialistSkillContent(skillId))) {
      issues.push(skillId + " is stale or unowned");
    }
  }
  for (const skillId of DOMAIN_SKILL_IDS) {
    const path = join(root, ".agents", "skills", skillId, "SKILL.md");
    if (!existsSync(path)) {
      issues.push(skillId + " is missing");
      continue;
    }
    if (normalizeNewlines(readText(path)) !== normalizeNewlines(domainSkillContent(skillId))) {
      issues.push(skillId + " is stale or unowned");
    }
  }
  return issues.length > 0
    ? { id: "skills.specialists", status: "FAIL", detail: issues.join("; ") }
    : {
        id: "skills.specialists",
        status: "PASS",
        detail:
          String(Object.keys(FACTORY_SPECIALIST_SKILLS).length) +
          " role Skills and " +
          String(DOMAIN_SKILL_IDS.length) +
          " task-routed professional Skills are installed",
      };
}

function checkKnowledgeStore(root: string): DoctorCheck {
  try {
    const verification = verifyKnowledgeStore(root);
    return verification.valid
      ? {
          id: "knowledge.integrity",
          status: "PASS",
          detail: "Professional knowledge store verified (entries=" + verification.entry_count + ")",
        }
      : {
          id: "knowledge.integrity",
          status: "FAIL",
          detail: verification.issues.join("; "),
        };
  } catch (error) {
    return {
      id: "knowledge.integrity",
      status: "FAIL",
      detail: "Professional knowledge store could not be verified: " + (error as Error).message,
    };
  }
}

function checkCodexLimits(root: string, config: FactoryConfig): DoctorCheck {
  const path = join(root, ".codex", "config.toml");
  const active = config.features.multi_agent.enabled;
  if (!existsSync(path)) {
    return {
      id: "multi_agent.codex_limits",
      status: active ? "FAIL" : "WARN",
      detail: "Project .codex/config.toml is missing",
    };
  }
  const inspection = inspectCodexAgentsConfig(readText(path));
  const issues = [...inspection.issues];
  if (
    inspection.max_threads !== undefined &&
    inspection.max_threads !== config.features.multi_agent.max_threads
  ) {
    issues.push(
      "agents.max_threads does not match Factory config (expected " +
        config.features.multi_agent.max_threads +
        ")",
    );
  }
  if (inspection.max_depth !== undefined && inspection.max_depth !== 1) {
    issues.push("agents.max_depth must equal 1");
  }
  if (issues.length > 0) {
    return {
      id: "multi_agent.codex_limits",
      status: active ? "FAIL" : "WARN",
      detail: issues.join("; "),
    };
  }
  return {
    id: "multi_agent.codex_limits",
    status: "PASS",
    detail:
      "Codex native limits are max_threads=" +
      inspection.max_threads +
      ", max_depth=1",
  };
}

function checkCodexCapabilities(
  config: FactoryConfig,
  probe: () => CodexCapabilityProbe,
): DoctorCheck {
  if (!config.features.multi_agent.enabled) {
    return {
      id: "multi_agent.codex_capabilities",
      status: "PASS",
      detail: "Native Codex multi-agent capability is not required while Factory multi-agent is disabled",
    };
  }
  const capability = probe();
  if (!capability.available) {
    return {
      id: "multi_agent.codex_capabilities",
      status: "FAIL",
      detail: "Codex CLI capability probe failed (" + (capability.error ?? "unavailable") + ")",
    };
  }
  if (!capability.multi_agent && !capability.multi_agent_v2) {
    return {
      id: "multi_agent.codex_capabilities",
      status: "FAIL",
      detail:
        "Installed Codex " +
        (capability.version ?? "unknown") +
        " does not report an enabled multi_agent or multi_agent_v2 feature",
    };
  }
  if (!capability.hooks) {
    return {
      id: "multi_agent.codex_capabilities",
      status: "FAIL",
      detail:
        "Installed Codex " +
        (capability.version ?? "unknown") +
        " does not report the Hooks feature enabled",
    };
  }
  return {
    id: "multi_agent.codex_capabilities",
    status: "PASS",
    detail:
      "Codex " +
      (capability.version ?? "unknown") +
      " native multi-agent is enabled (" +
      (capability.multi_agent_v2 ? "multi_agent_v2" : "multi_agent") +
      ")",
  };
}

function readContextMetadata(databasePath: string): Record<string, string> {
  const database = new DatabaseSync(databasePath, { readOnly: true });
  try {
    const rows = database
      .prepare("SELECT key, value FROM metadata")
      .all() as unknown as Array<{ key: string; value: string }>;
    return Object.fromEntries(rows.map((row) => [row.key, row.value]));
  } finally {
    database.close();
  }
}

function checkContextSpace(root: string, config: FactoryConfig): DoctorCheck {
  if (!config.features.external_context.enabled) {
    return {
      id: "external_context.ledger",
      status: "PASS",
      detail: "External context is disabled by project configuration",
    };
  }
  const path = contextDatabasePath(root);
  if (!existsSync(path)) {
    return {
      id: "external_context.ledger",
      status: "FAIL",
      detail: "Authoritative context database is missing",
    };
  }
  try {
    const metadata = readContextMetadata(path);
    const metadataIssues: string[] = [];
    if (metadata.schema_version !== "1.2.0") {
      metadataIssues.push("unexpected or missing schema_version");
    }
    if (metadata.project_id !== config.project_id) {
      metadataIssues.push("project_id does not match Factory config");
    }
    if (metadata.trust_frontend_summary !== "false") {
      metadataIssues.push("trust_frontend_summary must be false");
    }
    if (metadata.authority !== "sqlite_hash_chain_and_admission_receipts") {
      metadataIssues.push("context authority metadata is missing or invalid");
    }
    const ledger = verifyContextLedger(root);
    const issues = [...metadataIssues, ...ledger.issues];
    if (!ledger.valid || issues.length > 0) {
      return {
        id: "external_context.ledger",
        status: "FAIL",
        detail: "Context verification failed: " + issues.join("; "),
      };
    }
    return {
      id: "external_context.ledger",
      status: "PASS",
      detail:
        "SQLite event chain and admission receipts verified (events=" +
        ledger.event_count +
        ", admitted=" +
        ledger.admitted_event_count +
        ", candidates=" +
        ledger.candidate_event_count +
        ", head=" +
        ledger.head_hash.slice(0, 12) +
        ")",
    };
  } catch (error) {
    return {
      id: "external_context.ledger",
      status: "FAIL",
      detail: "Context database could not be verified: " + (error as Error).message,
    };
  }
}

function checkSearch(root: string, config: FactoryConfig): DoctorCheck[] {
  const search = config.features.external_search;
  if (!search.enabled) {
    return [
      {
        id: "external_search.provider",
        status: "PASS",
        detail: "External search is disabled by project configuration",
      },
      {
        id: "external_search.credential",
        status: "PASS",
        detail: "Credential presence is not required while search is disabled",
      },
    ];
  }

  const providerIssues: string[] = [];
  if (search.provider !== "glm_zhipu") providerIssues.push("provider must be glm_zhipu");
  if (search.endpoint !== "https://open.bigmodel.cn/api/paas/v4/web_search") {
    providerIssues.push("endpoint is not the canonical HTTPS GLM web-search endpoint");
  }
  if (!search.require_explicit_user_opt_in) {
    providerIssues.push("explicit user opt-in must remain required");
  }
  const providerCheck: DoctorCheck = providerIssues.length > 0
    ? {
        id: "external_search.provider",
        status: "FAIL",
        detail: providerIssues.join("; "),
      }
    : {
        id: "external_search.provider",
        status: "PASS",
        detail: "Live GLM structured search is explicitly enabled",
      };

  let present = false;
  try {
    present = Boolean(resolveSecret(root, search.api_key_env)?.trim());
  } catch {
    return [
      providerCheck,
      {
        id: "external_search.credential",
        status: "FAIL",
        detail: "Credential presence could not be checked safely; no value was displayed",
      },
    ];
  }
  return [
    providerCheck,
    {
      id: "external_search.credential",
      status: present ? "PASS" : "FAIL",
      detail:
        "Configured credential present: " +
        String(present) +
        " (secret value is never displayed)",
    },
  ];
}

export function runDoctor(projectRoot: string, options: DoctorOptions = {}): DoctorResult {
  const root = resolve(projectRoot);
  const checks: DoctorCheck[] = [];
  if (!existsSync(root) || !statSync(root).isDirectory()) {
    checks.push({
      id: "project.root",
      status: "FAIL",
      detail: "Project root is not an existing directory: " + root,
    });
    return resultFromChecks(checks);
  }
  checks.push({ id: "project.root", status: "PASS", detail: "Project root exists" });

  let config: FactoryConfig;
  try {
    config = loadConfig(root);
    checks.push({
      id: "factory.config",
      status: "PASS",
      detail: "Factory config is valid (" + config.version + ")",
    });
  } catch (error) {
    checks.push({
      id: "factory.config",
      status: "FAIL",
      detail: (error as Error).message,
    });
    return resultFromChecks(checks);
  }

  checks.push(
    checkManagedText(
      "control_plane.agents_instructions",
      join(root, "AGENTS.md"),
      FACTORY_AGENTS_BLOCK,
      "AGENTS.md automatic-dispatch contract",
    ),
  );
  checks.push(
    checkManagedText(
      "control_plane.hooks",
      join(root, ".codex", "hooks.json"),
      managedHooksContent(root),
      "Codex lifecycle Hooks",
    ),
  );
  checks.push({
    id: "control_plane.hook_trust",
    status:
      config.features.multi_agent.enabled || config.features.external_context.enabled
        ? "WARN"
        : "PASS",
    detail:
      config.features.multi_agent.enabled || config.features.external_context.enabled
        ? "Codex requires one-time review of new or changed project hooks in /hooks; Factory does not bypass this host security boundary"
        : "Factory lifecycle hooks are dormant while multi-agent and external context are disabled",
  });
  checks.push(
    checkManagedText(
      "control_plane.skill",
      join(root, ".agents", "skills", "codex-factory", "SKILL.md"),
      FACTORY_SKILL_CONTENT,
      "Project-local codex-factory Skill",
    ),
  );
  checks.push(
    checkManagedText(
      "security.runtime_gitignore",
      join(root, ".gitignore"),
      FACTORY_GITIGNORE_BLOCK,
      "Runtime secret and state ignore rules",
    ),
  );
  checks.push(checkAgentFiles(root, config));
  checks.push(checkSpecialistSkills(root));
  checks.push(
    checkCodexCapabilities(config, options.codexCapabilityProbe ?? probeCodexCapabilities),
  );
  checks.push(checkCodexLimits(root, config));
  checks.push(checkContextSpace(root, config));
  checks.push(checkKnowledgeStore(root));
  checks.push(...checkSearch(root, config));

  if (config.features.multi_agent.enabled) {
    const policy = config.features.multi_agent;
    const issues: string[] = [];
    if (policy.execution_mode !== "codex_native") issues.push("execution_mode is not codex_native");
    if (policy.policy !== "adaptive_single_layer") issues.push("policy is not adaptive_single_layer");
    if (policy.max_depth !== 1) issues.push("max_depth must equal 1");
    if (policy.context_inheritance !== "verified_packet_only") {
      issues.push("context inheritance is not verified_packet_only");
    }
    if (policy.isolation !== "scope_guard") {
      issues.push(
        "only scope_guard is implemented in this preview; worktree/directory labels are not accepted as proof",
      );
    }
    if (!policy.allow_temporary_agents) {
      issues.push("temporary specialist Agents are disabled");
    }
    checks.push({
      id: "multi_agent.control_policy",
      status: issues.length > 0 ? "FAIL" : "PASS",
      detail:
        issues.length > 0
          ? issues.join("; ")
          : "Native automatic dispatch, one-layer scheduling, physical scope-diff guards, and verified-packet context are active",
    });
    if (issues.length === 0) {
      checks.push({
        id: "multi_agent.isolation_strength",
        status: "WARN",
        detail:
          "scope_guard detects unreported changes and wave-level out-of-scope physical changes, but cannot attribute an in-wave scope change to a specific Agent; it is not an OS ACL or separately sandboxed worktree, and controller state is tamper-evident rather than protected from a malicious same-user worker",
      });
    }
  } else {
    checks.push({
      id: "multi_agent.control_policy",
      status: "PASS",
      detail: "Managed multi-agent dispatch is disabled by project configuration",
    });
  }

  return resultFromChecks(checks);
}
