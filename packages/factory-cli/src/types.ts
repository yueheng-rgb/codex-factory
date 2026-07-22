export type AgentExecutionMode = "codex_native" | "manual";
export type AgentIsolationMode = "scope_guard" | "worktree" | "directory";
export type SearchProviderType = "none" | "glm_zhipu";
export type AgentCapability =
  | "routing"
  | "architecture"
  | "product-design"
  | "app-classification"
  | "anti-overengineering"
  | "knowledge-retrieval"
  | "skill-curation"
  | "source-verification"
  | "independent-verification"
  | "security-review"
  | "drift-audit"
  | "scope-audit"
  | "contract-audit"
  | "web-research"
  | "documentation-research"
  | "evidence-pack"
  | "implementation"
  | "frontend"
  | "backend"
  | "database"
  | "auth-security"
  | "mobile"
  | "testing"
  | "e2e-testing"
  | "smoke-testing"
  | "negative-testing"
  | "integration"
  | "conflict-resolution"
  | "release";

export interface MultiAgentFeatureConfig {
  enabled: boolean;
  execution_mode: AgentExecutionMode;
  policy: "adaptive_single_layer";
  max_threads: number;
  max_depth: 1;
  resident_profiles: string[];
  allow_temporary_agents: boolean;
  isolation: AgentIsolationMode;
  context_inheritance: "verified_packet_only";
}

export interface ContextSpaceFeatureConfig {
  enabled: boolean;
  directory: string;
  trust_frontend_summary: false;
  packet_max_age_minutes: number;
  hash_chain: true;
}

export interface SearchFeatureConfig {
  enabled: boolean;
  provider: SearchProviderType;
  api_key_env: string;
  endpoint: string;
  require_explicit_user_opt_in: true;
}

export interface FactoryConfig {
  version: "5.0.0-preview.1";
  project_id: string;
  created_at: string;
  updated_at: string;
  model_runtime: {
    provider: "inherit_from_codex" | "deepseek" | "openai" | "custom";
    model?: string;
    note: string;
  };
  features: {
    multi_agent: MultiAgentFeatureConfig;
    external_context: ContextSpaceFeatureConfig;
    external_search: SearchFeatureConfig;
  };
}

export type ContextEventKind =
  | "requirement"
  | "decision"
  | "task_state"
  | "risk"
  | "evidence"
  | "knowledge_retrieval"
  | "rejected_claim"
  | "agent_event"
  | "frontend_summary";

export type ContextAdmissionStatus = "candidate" | "admitted";

export type ContextAdmissionBasis =
  | "legacy_unverified"
  | "untrusted_append"
  | "trusted_internal"
  | "independent_verification";

export type ContextAdmissionSource =
  | {
      kind: "control_plane_receipt";
      reference: string;
      sha256: string;
    }
  | {
      kind: "verification_receipt";
      reference: string;
      sha256: string;
    }
  | {
      kind: "knowledge_store_verified";
      reference: string;
      store_digest: string;
      entry_digests: string[];
      source_digests: string[];
      content_digests: string[];
    };

export interface ContextEventAdmission {
  status: ContextAdmissionStatus;
  basis: ContextAdmissionBasis;
  authority:
    | "untrusted_input"
    | "legacy_migration"
    | "factory_control_plane"
    | "factory_independent_verifier";
  recorded_at: string;
  verified_by?: string;
  source?: ContextAdmissionSource;
  bound_event_hash: string;
  admission_hash: string;
}

export interface ContextEvent {
  event_id: string;
  sequence: number;
  kind: ContextEventKind;
  actor: string;
  created_at: string;
  payload: Record<string, unknown>;
  previous_hash: string;
  hash: string;
  /** Admission is separately hash-bound to this event; event-chain integrity alone is not trust. */
  admission: ContextEventAdmission;
}

export interface ContextLedgerVerification {
  valid: boolean;
  integrity_valid: boolean;
  admission_integrity_valid: boolean;
  event_count: number;
  admitted_event_count: number;
  candidate_event_count: number;
  head_hash: string;
  admission_root_hash: string;
  issues: string[];
}

export interface ContextPacket {
  packet_id: string;
  packet_version: "1.1.0";
  project_id: string;
  run_id: string;
  target_role: string;
  generated_at: string;
  expires_at: string;
  ledger_head_hash: string;
  source_event_ids: string[];
  trusted_context: Array<{
    event_id: string;
    kind: Exclude<ContextEventKind, "frontend_summary">;
    payload: Record<string, unknown>;
    admission: ContextEventAdmission;
  }>;
  untrusted_context_candidates: Array<{
    event_id: string;
    kind: Exclude<ContextEventKind, "frontend_summary">;
    payload: Record<string, unknown>;
    admission: ContextEventAdmission;
  }>;
  untrusted_frontend_notes: Array<{
    event_id: string;
    payload: Record<string, unknown>;
  }>;
  forbidden_assumptions: string[];
  packet_hash: string;
}

export type AgentProfileKind = "resident" | "temporary";

export interface AgentProfile {
  profile_id: string;
  codex_agent_name: string;
  display_name: string;
  icon: string;
  kind: AgentProfileKind;
  role: string;
  read_only: boolean;
  nickname_candidates: string[];
  skill_ids: string[];
  capabilities: AgentCapability[];
  developer_instructions: string;
}

export interface FactoryTask {
  task_id: string;
  title: string;
  description: string;
  role: string;
  profile_id?: string;
  required_capabilities?: AgentCapability[];
  status:
    | "pending"
    | "ready"
    | "assigned"
    | "in_progress"
    | "handoff"
    | "verified"
    | "blocked"
    | "failed";
  dependencies: string[];
  write_scope: string[];
  acceptance_methods: string[];
  required_artifacts: string[];
}

export interface SpawnPlanEntry {
  assignment_id: string;
  task_id: string;
  profile_id: string;
  codex_agent_name: string;
  profile_kind: AgentProfileKind;
  isolation: AgentIsolationMode;
  fork_turns: "none";
  context_packet_path: string;
  write_scope: string[];
  prompt: string;
  status: "planned";
}

export interface SpawnPlan {
  version: "1.0.0";
  run_id: string;
  project_id: string;
  generated_at: string;
  native_spawn_required: true;
  max_parallel: number;
  max_depth: 1;
  assignments: SpawnPlanEntry[];
  blocked_tasks: Array<{ task_id: string; blocked_by: string[] }>;
  instructions_for_main_agent: string[];
}

export interface SearchResultItem {
  title: string;
  url: string;
  snippet: string;
  content: string;
  source_origin: "provider_search_result";
}

export interface SearchEvidenceCheck {
  check_id: string;
  passed: boolean;
  detail: string;
}

export interface SearchEvidenceVerification {
  verifier_id: "factory_search_evidence_verifier";
  verifier_version: "1.0.0";
  independent_from_provider_acceptance: true;
  verdict: "PASS" | "FAIL";
  checked_at: string;
  checks: SearchEvidenceCheck[];
}

export interface SearchEvidenceBundle {
  bundle_version: "1.0.0";
  invocation_id: string;
  provider: "glm_zhipu";
  mode: "live_api";
  endpoint: string;
  request_id: string;
  response_id: string;
  query_hash: string;
  raw_response_hash: string;
  normalized_results_hash: string;
  retrieved_at: string;
  result_count: number;
  results: SearchResultItem[];
}

export interface SearchResponse {
  accepted: boolean;
  provider: "glm_zhipu";
  mode: "live_api";
  invocation_id: string;
  request_id: string;
  response_id: string;
  query_hash: string;
  retrieved_at: string;
  endpoint: string;
  result_count: number;
  results: SearchResultItem[];
  raw_response_hash?: string;
  evidence_bundle?: SearchEvidenceBundle;
  independent_verification?: SearchEvidenceVerification;
  evidence_bundle_path?: string;
  ledger_entry_hash?: string;
  error_code?: string;
  error_message?: string;
}

export interface DoctorCheck {
  id: string;
  status: "PASS" | "WARN" | "FAIL";
  detail: string;
}

export interface DoctorResult {
  status: "READY" | "READY_WITH_LIMITATIONS" | "NOT_READY";
  checks: DoctorCheck[];
}
