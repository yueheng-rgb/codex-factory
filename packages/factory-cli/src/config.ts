import { existsSync, readFileSync } from "node:fs";
import { basename, join, resolve } from "node:path";
import type { FactoryConfig, SearchProviderType } from "./types.js";
import { ensureDirectory, nowIso, readJson, slugifyProjectId, writeJsonAtomic } from "./util.js";

export const FACTORY_DIRECTORY = ".codex-factory";
export const CONFIG_FILE = "config.json";

export interface CreateConfigOptions {
  projectId?: string;
  multiAgent?: boolean;
  externalContext?: boolean;
  searchProvider?: SearchProviderType;
  maxThreads?: number;
  modelProvider?: FactoryConfig["model_runtime"]["provider"];
  model?: string;
}

export function factoryDirectory(projectRoot: string): string {
  return join(resolve(projectRoot), FACTORY_DIRECTORY);
}

export function configPath(projectRoot: string): string {
  return join(factoryDirectory(projectRoot), CONFIG_FILE);
}

export function createDefaultConfig(
  projectRoot: string,
  options: CreateConfigOptions = {},
): FactoryConfig {
  const timestamp = nowIso();
  const searchProvider = options.searchProvider ?? "none";
  const maxThreads = Math.max(2, Math.min(8, options.maxThreads ?? 4));

  return {
    version: "5.0.0-preview.1",
    project_id: slugifyProjectId(options.projectId ?? basename(resolve(projectRoot))),
    created_at: timestamp,
    updated_at: timestamp,
    model_runtime: {
      provider: options.modelProvider ?? "inherit_from_codex",
      model: options.model,
      note:
        "The Factory orchestrates the current Codex runtime. Provider labels do not prove API compatibility.",
    },
    features: {
      multi_agent: {
        enabled: options.multiAgent ?? false,
        execution_mode: "codex_native",
        policy: "adaptive_single_layer",
        max_threads: maxThreads,
        max_depth: 1,
        resident_profiles: [
          "factory_router",
          "factory_librarian",
          "factory_verifier",
          "factory_drift_auditor",
        ],
        allow_temporary_agents: true,
        isolation: "scope_guard",
        context_inheritance: "verified_packet_only",
      },
      external_context: {
        enabled: options.externalContext ?? true,
        directory: ".codex-factory/context",
        trust_frontend_summary: false,
        packet_max_age_minutes: 60,
        hash_chain: true,
      },
      external_search: {
        enabled: searchProvider !== "none",
        provider: searchProvider,
        api_key_env: searchProvider === "glm_zhipu" ? "ZHIPUAI_API_KEY" : "",
        endpoint:
          searchProvider === "glm_zhipu"
            ? "https://open.bigmodel.cn/api/paas/v4/web_search"
            : "",
        require_explicit_user_opt_in: true,
      },
    },
  };
}

export function validateConfig(config: FactoryConfig): string[] {
  const issues: string[] = [];
  if (config.version !== "5.0.0-preview.1") {
    issues.push("Unsupported config version: " + String(config.version));
  }
  if (!config.project_id) issues.push("project_id is required");
  if (config.features.multi_agent.max_depth !== 1) {
    issues.push("multi_agent.max_depth must remain 1 for the single-layer policy");
  }
  const maxThreads = config.features.multi_agent.max_threads;
  if (!Number.isInteger(maxThreads) || maxThreads < 2 || maxThreads > 8) {
    issues.push("multi_agent.max_threads must be an integer from 2 to 8");
  }
  if (config.features.multi_agent.isolation !== "scope_guard") {
    issues.push("multi_agent.isolation must be scope_guard; worktree/directory are not implemented");
  }
  if (config.features.external_context.trust_frontend_summary !== false) {
    issues.push("external_context.trust_frontend_summary must be false");
  }
  const search = config.features.external_search;
  if (search.enabled && search.provider === "none") {
    issues.push("external_search cannot be enabled with provider=none");
  }
  if (search.enabled && !search.api_key_env) {
    issues.push("external_search.api_key_env is required when search is enabled");
  }
  return issues;
}

export function saveConfig(projectRoot: string, config: FactoryConfig): void {
  const issues = validateConfig(config);
  if (issues.length > 0) {
    throw new Error("Invalid Factory config: " + issues.join("; "));
  }
  config.updated_at = nowIso();
  ensureDirectory(factoryDirectory(projectRoot));
  writeJsonAtomic(configPath(projectRoot), config);
}

export function initializeConfig(
  projectRoot: string,
  options: CreateConfigOptions = {},
): FactoryConfig {
  const target = configPath(projectRoot);
  if (existsSync(target)) {
    const current = loadConfig(projectRoot);
    const updated: FactoryConfig = {
      ...current,
      model_runtime: {
        ...current.model_runtime,
        provider: options.modelProvider ?? current.model_runtime.provider,
        model: options.model ?? current.model_runtime.model,
      },
      features: {
        ...current.features,
        multi_agent: {
          ...current.features.multi_agent,
          enabled: options.multiAgent ?? current.features.multi_agent.enabled,
          max_threads: options.maxThreads ?? current.features.multi_agent.max_threads,
        },
        external_context: {
          ...current.features.external_context,
          enabled: options.externalContext ?? current.features.external_context.enabled,
        },
        external_search:
          options.searchProvider === undefined
            ? current.features.external_search
            : {
                ...current.features.external_search,
                enabled: options.searchProvider !== "none",
                provider: options.searchProvider,
                api_key_env:
                  options.searchProvider === "glm_zhipu" ? "ZHIPUAI_API_KEY" : "",
                endpoint:
                  options.searchProvider === "glm_zhipu"
                    ? "https://open.bigmodel.cn/api/paas/v4/web_search"
                    : "",
              },
      },
    };
    saveConfig(projectRoot, updated);
    return updated;
  }
  const config = createDefaultConfig(projectRoot, options);
  saveConfig(projectRoot, config);
  return config;
}

export function loadConfig(projectRoot: string): FactoryConfig {
  const target = configPath(projectRoot);
  if (!existsSync(target)) {
    throw new Error("Factory config not found: " + target + ". Run factory init first.");
  }
  const config = readJson<FactoryConfig>(target);
  const issues = validateConfig(config);
  if (issues.length > 0) {
    throw new Error("Invalid Factory config: " + issues.join("; "));
  }
  return config;
}

export function loadSecrets(projectRoot: string): Record<string, string> {
  const secretsPath = join(factoryDirectory(projectRoot), "secrets.env");
  const result: Record<string, string> = {};
  if (!existsSync(secretsPath)) return result;

  const lines = readFileSync(secretsPath, "utf8").split(/\r?\n/);
  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) continue;
    const equalsAt = line.indexOf("=");
    if (equalsAt <= 0) continue;
    const key = line.slice(0, equalsAt).trim();
    let value = line.slice(equalsAt + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (/^[A-Z][A-Z0-9_]*$/.test(key) && value) {
      result[key] = value;
    }
  }
  return result;
}

export function resolveSecret(projectRoot: string, name: string): string | undefined {
  if (!name) return undefined;
  return process.env[name] || loadSecrets(projectRoot)[name];
}
