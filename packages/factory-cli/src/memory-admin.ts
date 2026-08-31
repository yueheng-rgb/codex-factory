import {
  existsSync,
  lstatSync,
  readFileSync,
  readdirSync,
  statSync,
  type Stats,
} from "node:fs";
import { dirname, extname, isAbsolute, join, relative, resolve } from "node:path";
import { DatabaseSync } from "node:sqlite";
import { loadConfig, loadSecrets } from "./config.js";
import {
  contextDatabasePath,
  readAllContextEventsInternal,
  verifyContextLedger,
} from "./context-space.js";
import { verifyKnowledgeStore } from "./knowledge.js";
import type { ContextEvent } from "./types.js";
import {
  assertWithinRoot,
  sha256,
  stableStringify,
  writeJsonAtomic,
} from "./util.js";

const MEMORY_EXPORT_VERSION = "1.0.0";
const MAX_PACKET_INSPECTION_BYTES = 8 * 1024 * 1024;

type StoreIntegrityStatus = "VERIFIED" | "FAILED" | "NOT_INITIALIZED" | "DISABLED";

export interface MemoryStoreStatus {
  integrity_status: StoreIntegrityStatus;
  record_count: number;
  issues: string[];
}

export interface MemoryStatus {
  format_version: "1.0.0";
  project_id: string;
  generated_at: string;
  status: "READY" | "DISABLED" | "NOT_INITIALIZED" | "INTEGRITY_FAILED";
  trust_boundary: {
    integrity: {
      status: "VERIFIED" | "FAILED" | "NOT_AVAILABLE";
      meaning: string;
    };
    content_verification: {
      status: "NOT_ASSERTED";
      meaning: string;
    };
  };
  context: MemoryStoreStatus & {
    enabled: boolean;
    database_present: boolean;
    head_hash: string | null;
    admission_root_hash: string | null;
    admission_integrity_status: "VERIFIED" | "FAILED" | "NOT_AVAILABLE";
    admitted_record_count: number;
    candidate_record_count: number;
  };
  knowledge: MemoryStoreStatus & {
    database_present: boolean;
    fts_record_count: number;
    search_record_count: number;
    store_root_hash: string | null;
    schema_version: string | null;
  };
  storage: {
    database_bytes: number;
    wal_bytes: number;
    shm_bytes: number;
    packet_files: number;
    packet_bytes: number;
    total_bytes: number;
  };
}

export interface MemoryCleanupCandidate {
  candidate_type:
    | "aged_frontend_summary"
    | "superseded_knowledge"
    | "expired_context_packet";
  reference: string;
  reason: string;
  size_bytes: number;
  safe_action: "archive_rewrite_required" | "knowledge_rewrite_required" | "remove_expired_packet";
}

export interface MemoryCleanupPlan {
  format_version: "1.0.0";
  generated_at: string;
  dry_run: true;
  executed: false;
  older_than_days: number;
  candidate_count: number;
  candidate_bytes: number;
  candidates: MemoryCleanupCandidate[];
  warnings: string[];
  statement: string;
}

interface KnowledgeRow {
  entry_id: string;
  title: string;
  content: string;
  source_uri: string;
  source_sha256: string;
  source_kind: string;
  tags: string;
  roles: string;
  created_at: string;
  supersedes_id: string | null;
  status?: string;
  source_binding?: string;
  content_digest?: string;
  content_hash: string;
}

interface StoredKnowledgeRecord {
  entry_id: string;
  title: string;
  content: string;
  source_uri: string;
  source_sha256: string;
  source_kind: string;
  tags: string[];
  roles: string[];
  created_at: string;
  supersedes_id: string | null;
  status?: string;
  source_binding?: string;
  content_digest?: string;
  content_hash: string;
}

interface ExportedContextRecord {
  event_id: string;
  sequence: number;
  kind: string;
  actor: string;
  created_at: string;
  payload: Record<string, unknown>;
  admission?: unknown;
  source_event_hash: string;
}

interface ExportedKnowledgeRecord {
  entry_id: string;
  title: string;
  content: string;
  source_uri: string;
  source_sha256: string;
  source_kind: string;
  tags: string[];
  roles: string[];
  created_at: string;
  supersedes_id: string | null;
  status?: string;
  source_binding?: string;
  content_digest?: string;
  source_content_hash: string;
}

export interface MemoryExportReceipt {
  status: "EXPORTED";
  output_path: string;
  context_records: number;
  knowledge_records: number;
  redaction_count: number;
  bytes: number;
  export_hash: string;
  content_verification: "NOT_ASSERTED";
  note: string;
}

interface ClockOptions {
  now?: () => Date;
}

function safeStatSize(path: string): number {
  if (!existsSync(path)) return 0;
  const entry = lstatSync(path);
  if (!entry.isFile() || entry.isSymbolicLink()) return 0;
  return entry.size;
}

function databaseIsRegularFile(databasePath: string): boolean {
  if (!existsSync(databasePath)) return false;
  const entry = lstatSync(databasePath);
  return entry.isFile() && !entry.isSymbolicLink();
}

function openReadOnlyDatabase(databasePath: string): DatabaseSync {
  if (!databaseIsRegularFile(databasePath)) {
    throw new Error("Memory database must be a regular, non-symlink file");
  }
  return new DatabaseSync(databasePath, { readOnly: true });
}

function tableExists(databasePath: string, tableName: string): boolean {
  if (!databaseIsRegularFile(databasePath)) return false;
  const database = openReadOnlyDatabase(databasePath);
  try {
    return Boolean(
      database
        .prepare("SELECT 1 AS present FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1")
        .get(tableName),
    );
  } finally {
    database.close();
  }
}

function packetStorage(databasePath: string): { files: number; bytes: number } {
  const directory = join(dirname(databasePath), "packets");
  if (!existsSync(directory)) return { files: 0, bytes: 0 };
  const directoryEntry = lstatSync(directory);
  if (!directoryEntry.isDirectory() || directoryEntry.isSymbolicLink()) {
    return { files: 0, bytes: 0 };
  }
  let files = 0;
  let bytes = 0;
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if (!entry.isFile() || entry.isSymbolicLink()) continue;
    files += 1;
    bytes += safeStatSize(join(directory, entry.name));
  }
  return { files, bytes };
}

function buildStorageStatus(databasePath: string): MemoryStatus["storage"] {
  const databaseBytes = safeStatSize(databasePath);
  const walBytes = safeStatSize(databasePath + "-wal");
  const shmBytes = safeStatSize(databasePath + "-shm");
  const packets = packetStorage(databasePath);
  return {
    database_bytes: databaseBytes,
    wal_bytes: walBytes,
    shm_bytes: shmBytes,
    packet_files: packets.files,
    packet_bytes: packets.bytes,
    total_bytes: databaseBytes + walBytes + shmBytes + packets.bytes,
  };
}

export function getMemoryStatus(
  projectRoot: string,
  options: ClockOptions = {},
): MemoryStatus {
  const root = resolve(projectRoot);
  const config = loadConfig(root);
  const databasePath = contextDatabasePath(root);
  const databasePresent = existsSync(databasePath);
  const regularDatabase = databaseIsRegularFile(databasePath);
  let contextTablePresent = false;
  let knowledgeTablePresent = false;
  const databaseIssues: string[] = [];

  if (databasePresent && !regularDatabase) {
    databaseIssues.push("Memory database is not a regular, non-symlink file");
  } else if (regularDatabase) {
    try {
      contextTablePresent = tableExists(databasePath, "context_events");
      knowledgeTablePresent = tableExists(databasePath, "knowledge_entries");
    } catch (error) {
      databaseIssues.push("Memory database could not be inspected: " + (error as Error).message);
    }
  }

  let context: MemoryStatus["context"];
  if (!config.features.external_context.enabled && !contextTablePresent) {
    context = {
      enabled: false,
      database_present: databasePresent,
      integrity_status: "DISABLED",
      record_count: 0,
      head_hash: null,
      admission_root_hash: null,
      admission_integrity_status: "NOT_AVAILABLE",
      admitted_record_count: 0,
      candidate_record_count: 0,
      issues: databaseIssues,
    };
  } else if (!contextTablePresent) {
    context = {
      enabled: config.features.external_context.enabled,
      database_present: databasePresent,
      integrity_status: databaseIssues.length > 0 ? "FAILED" : "NOT_INITIALIZED",
      record_count: 0,
      head_hash: null,
      admission_root_hash: null,
      admission_integrity_status: "NOT_AVAILABLE",
      admitted_record_count: 0,
      candidate_record_count: 0,
      issues: databaseIssues.length > 0 ? databaseIssues : ["Context ledger is not initialized"],
    };
  } else if (databaseIssues.length > 0) {
    context = {
      enabled: config.features.external_context.enabled,
      database_present: databasePresent,
      integrity_status: "FAILED",
      record_count: 0,
      head_hash: null,
      admission_root_hash: null,
      admission_integrity_status: "FAILED",
      admitted_record_count: 0,
      candidate_record_count: 0,
      issues: databaseIssues,
    };
  } else {
    const verification = verifyContextLedger(root);
    context = {
      enabled: config.features.external_context.enabled,
      database_present: true,
      integrity_status: verification.valid ? "VERIFIED" : "FAILED",
      record_count: verification.event_count,
      head_hash: verification.head_hash || null,
      admission_root_hash: verification.admission_root_hash || null,
      admission_integrity_status: verification.admission_integrity_valid ? "VERIFIED" : "FAILED",
      admitted_record_count: verification.admitted_event_count,
      candidate_record_count: verification.candidate_event_count,
      issues: verification.issues,
    };
  }

  let knowledge: MemoryStatus["knowledge"];
  if (!knowledgeTablePresent) {
    knowledge = {
      database_present: databasePresent,
      integrity_status: databaseIssues.length > 0 ? "FAILED" : "NOT_INITIALIZED",
      record_count: 0,
      fts_record_count: 0,
      search_record_count: 0,
      store_root_hash: null,
      schema_version: null,
      issues: databaseIssues.length > 0 ? databaseIssues : ["Knowledge store is not initialized"],
    };
  } else if (databaseIssues.length > 0) {
    knowledge = {
      database_present: databasePresent,
      integrity_status: "FAILED",
      record_count: 0,
      fts_record_count: 0,
      search_record_count: 0,
      store_root_hash: null,
      schema_version: null,
      issues: databaseIssues,
    };
  } else {
    const verification = verifyKnowledgeStore(root);
    knowledge = {
      database_present: true,
      integrity_status: verification.valid ? "VERIFIED" : "FAILED",
      record_count: verification.entry_count,
      fts_record_count: verification.fts_entry_count,
      search_record_count: verification.search_entry_count,
      store_root_hash: verification.store_root_hash ?? null,
      schema_version: verification.schema_version ?? null,
      issues: verification.issues,
    };
  }

  const failed = context.integrity_status === "FAILED" || knowledge.integrity_status === "FAILED";
  const initialized = contextTablePresent || knowledgeTablePresent;
  const status: MemoryStatus["status"] = failed
    ? "INTEGRITY_FAILED"
    : !initialized && !config.features.external_context.enabled
      ? "DISABLED"
      : !initialized
        ? "NOT_INITIALIZED"
        : "READY";
  const verifiedStores = [context.integrity_status, knowledge.integrity_status]
    .filter((value) => value !== "NOT_INITIALIZED" && value !== "DISABLED");
  const integrityStatus = failed
    ? "FAILED"
    : verifiedStores.length > 0 && verifiedStores.every((value) => value === "VERIFIED")
      ? "VERIFIED"
      : "NOT_AVAILABLE";

  return {
    format_version: "1.0.0",
    project_id: config.project_id,
    generated_at: (options.now?.() ?? new Date()).toISOString(),
    status,
    trust_boundary: {
      integrity: {
        status: integrityStatus,
        meaning:
          "Integrity verifies SQLite structure, indexes, anchors, stored hashes, admission receipts, and project-source bindings; it does not prove that remembered claims are factually correct.",
      },
      content_verification: {
        status: "NOT_ASSERTED",
        meaning:
          "This command does not independently validate claim truth, source authority, or acceptance evidence.",
      },
    },
    context,
    knowledge,
    storage: buildStorageStatus(databasePath),
  };
}

function parseKnowledgeRows(databasePath: string): StoredKnowledgeRecord[] {
  if (!tableExists(databasePath, "knowledge_entries")) return [];
  const database = openReadOnlyDatabase(databasePath);
  try {
    const rows = database
      .prepare(
        [
          "SELECT *",
          "FROM knowledge_entries ORDER BY created_at ASC, entry_id ASC",
        ].join(" "),
      )
      .all() as unknown as KnowledgeRow[];
    return rows.map((row) => ({
      entry_id: row.entry_id,
      title: row.title,
      content: row.content,
      source_uri: row.source_uri,
      source_sha256: row.source_sha256,
      source_kind: row.source_kind,
      tags: JSON.parse(row.tags) as string[],
      roles: JSON.parse(row.roles) as string[],
      created_at: row.created_at,
      supersedes_id: row.supersedes_id,
      status: row.status,
      source_binding: row.source_binding,
      content_digest: row.content_digest,
      content_hash: row.content_hash,
    }));
  } finally {
    database.close();
  }
}

function pathInsideRoot(root: string, candidate: string): boolean {
  const rel = relative(resolve(root), resolve(candidate));
  return rel === "" || (rel !== ".." && !rel.startsWith("..\\") && !rel.startsWith("../") && !isAbsolute(rel));
}

function sameFilesystemEntry(
  left: Stats,
  right: Stats,
): boolean {
  return left.dev === right.dev && left.ino === right.ino;
}

function isSymlinkOrJunction(path: string, entry: Stats): boolean {
  if (entry.isSymbolicLink()) return true;
  if (process.platform !== "win32" || !entry.isDirectory()) return false;
  const followed = statSync(path);
  return followed.isDirectory() && !sameFilesystemEntry(entry, followed);
}

function assertNoSymlinkOrJunctionAncestor(path: string): void {
  let current = resolve(path);
  while (true) {
    const entry = lstatSync(current);
    if (isSymlinkOrJunction(current, entry)) {
      throw new Error("External export parent resolves through a symlink or junction");
    }
    const parent = dirname(current);
    if (parent === current) return;
    current = parent;
  }
}

export function resolveMemoryExportPath(projectRoot: string, requestedPath: string): string {
  const root = resolve(projectRoot);
  const trimmed = requestedPath.normalize("NFKC").trim();
  if (!trimmed || trimmed.includes("\u0000")) {
    throw new Error("--out must be a non-empty path without NUL characters");
  }
  if (/^\\\\[.?]\\/u.test(trimmed)) {
    throw new Error("Windows device paths are not allowed for memory export");
  }
  const candidate = resolve(root, trimmed);
  if (extname(candidate).toLowerCase() !== ".json") {
    throw new Error("Memory export output must use a .json extension");
  }
  if (existsSync(candidate)) {
    throw new Error("Refusing to overwrite existing export: " + candidate);
  }

  if (pathInsideRoot(root, candidate)) {
    return assertWithinRoot(root, candidate);
  }
  if (!isAbsolute(trimmed)) {
    throw new Error("Relative memory export paths must stay inside the project");
  }

  const parent = dirname(candidate);
  if (!existsSync(parent)) {
    throw new Error("An external export parent directory must already exist: " + parent);
  }
  const parentEntry = lstatSync(parent);
  if (!parentEntry.isDirectory() || parentEntry.isSymbolicLink()) {
    throw new Error("External export parent must be a real directory, not a symlink or junction");
  }
  assertNoSymlinkOrJunctionAncestor(parent);
  return candidate;
}

const SENSITIVE_KEY = /(?:api[-_]?key|authorization|bearer|credential|cookie|password|passwd|private[-_]?key|secret|session[-_]?id|access[-_]?token|refresh[-_]?token|client[-_]?secret|token)$/iu;

function regexEscape(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function knownSecretValues(projectRoot: string): string[] {
  const secrets = new Set<string>();
  for (const value of Object.values(loadSecrets(projectRoot))) {
    if (value.length >= 4) secrets.add(value);
  }
  for (const [name, value] of Object.entries(process.env)) {
    if (value && value.length >= 4 && SENSITIVE_KEY.test(name)) secrets.add(value);
  }
  return [...secrets].sort((left, right) => right.length - left.length);
}

interface RedactionState {
  count: number;
  knownSecrets: string[];
}

function redactText(value: string, state: RedactionState): string {
  let result = value;
  const replace = (pattern: RegExp, replacement: string): void => {
    result = result.replace(pattern, (match) => {
      state.count += 1;
      return replacement || (match ? "[REDACTED]" : match);
    });
  };
  for (const secret of state.knownSecrets) {
    replace(new RegExp(regexEscape(secret), "g"), "[REDACTED]");
  }
  replace(
    /-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----/gu,
    "[REDACTED_PRIVATE_KEY]",
  );
  replace(/\bBearer\s+[A-Za-z0-9._~+/=-]+/giu, "Bearer [REDACTED]");
  replace(/\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b/gu, "[REDACTED_JWT]");
  replace(/\b(?:sk|pk|api)[-_][A-Za-z0-9_-]{8,}\b/giu, "[REDACTED_TOKEN]");
  replace(
    /\b(api[-_ ]?key|access[-_ ]?token|refresh[-_ ]?token|client[-_ ]?secret|password|passwd|secret)\s*[:=]\s*[^\s,;]+/giu,
    "[REDACTED_CREDENTIAL]",
  );
  return result;
}

function redactValue(value: unknown, state: RedactionState, key = ""): unknown {
  if (key && SENSITIVE_KEY.test(key)) {
    state.count += 1;
    return "[REDACTED]";
  }
  if (typeof value === "string") return redactText(value, state);
  if (Array.isArray(value)) return value.map((item) => redactValue(item, state));
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>).map(([childKey, childValue]) => [
        childKey,
        redactValue(childValue, state, childKey),
      ]),
    );
  }
  return value;
}

function assertExportable(status: MemoryStatus): void {
  if (status.status === "INTEGRITY_FAILED") {
    throw new Error("Memory integrity verification failed; refusing export");
  }
  const initialized =
    status.context.integrity_status === "VERIFIED" ||
    status.knowledge.integrity_status === "VERIFIED";
  if (!initialized) {
    throw new Error("Memory stores are not initialized; nothing can be exported");
  }
}

function assertExportSnapshotUnchanged(
  projectRoot: string,
  before: MemoryStatus,
): void {
  if (before.context.integrity_status === "VERIFIED") {
    const after = verifyContextLedger(projectRoot);
    if (
      !after.valid ||
      after.event_count !== before.context.record_count ||
      after.head_hash !== before.context.head_hash ||
      after.admission_root_hash !== before.context.admission_root_hash
    ) {
      throw new Error("Context memory changed during export; no export was written");
    }
  }
  if (before.knowledge.integrity_status === "VERIFIED") {
    const after = verifyKnowledgeStore(projectRoot);
    if (
      !after.valid ||
      after.entry_count !== before.knowledge.record_count ||
      (after.store_root_hash ?? null) !== before.knowledge.store_root_hash
    ) {
      throw new Error("Knowledge memory changed during export; no export was written");
    }
  }
}

export function exportMemory(
  projectRoot: string,
  requestedPath: string,
  options: ClockOptions = {},
): MemoryExportReceipt {
  const root = resolve(projectRoot);
  const status = getMemoryStatus(root, options);
  assertExportable(status);
  const databasePath = contextDatabasePath(root);
  const events = status.context.integrity_status === "VERIFIED"
    ? readAllContextEventsInternal(root)
    : [];
  const knowledge = status.knowledge.integrity_status === "VERIFIED"
    ? parseKnowledgeRows(databasePath)
    : [];
  const redaction: RedactionState = {
    count: 0,
    knownSecrets: knownSecretValues(root),
  };

  const exportedContext = events.map((event): ExportedContextRecord => redactValue({
    event_id: event.event_id,
    sequence: event.sequence,
    kind: event.kind,
    actor: event.actor,
    created_at: event.created_at,
    payload: event.payload,
    admission: "admission" in event ? event.admission : undefined,
    source_event_hash: event.hash,
  }, redaction) as ExportedContextRecord);
  const exportedKnowledge = knowledge.map((entry): ExportedKnowledgeRecord => redactValue({
    entry_id: entry.entry_id,
    title: entry.title,
    content: entry.content,
    source_uri: entry.source_uri,
    source_sha256: entry.source_sha256,
    source_kind: entry.source_kind,
    tags: entry.tags,
    roles: entry.roles,
    created_at: entry.created_at,
    supersedes_id: entry.supersedes_id,
    status: entry.status,
    source_binding: entry.source_binding,
    content_digest: entry.content_digest,
    source_content_hash: entry.content_hash,
  }, redaction) as ExportedKnowledgeRecord);

  // Bind the materialized records to the same verified source snapshot. The output
  // path is not resolved or created until this second verification succeeds.
  assertExportSnapshotUnchanged(root, status);

  const generatedAt = (options.now?.() ?? new Date()).toISOString();
  const body = {
    format: "codex-app-factory-memory-export",
    format_version: MEMORY_EXPORT_VERSION,
    project_id: status.project_id,
    generated_at: generatedAt,
    source_integrity: {
      context: status.context.integrity_status,
      knowledge: status.knowledge.integrity_status,
      context_head_hash: status.context.head_hash,
      context_admission_root_hash: status.context.admission_root_hash,
      knowledge_store_root_hash: status.knowledge.store_root_hash,
      meaning:
        "VERIFIED means the source store passed structural, index, anchor, and hash checks at export time.",
    },
    content_verification: {
      status: "NOT_ASSERTED",
      meaning:
        "The export does not claim that remembered content is true or independently evidence-verified.",
    },
    redaction: {
      applied: true,
      replacement_count: redaction.count,
      note:
        "Sensitive-key fields, configured secret values, and common credential patterns are redacted. This is a portable audit export, not a byte-for-byte database backup.",
    },
    context_records: exportedContext,
    knowledge_records: exportedKnowledge,
  };
  const exportHash = sha256(stableStringify(body));
  const payload = { ...body, export_hash: exportHash };
  const outputPath = resolveMemoryExportPath(root, requestedPath);
  writeJsonAtomic(outputPath, payload);
  const bytes = statSync(outputPath).size;
  return {
    status: "EXPORTED",
    output_path: outputPath,
    context_records: exportedContext.length,
    knowledge_records: exportedKnowledge.length,
    redaction_count: redaction.count,
    bytes,
    export_hash: exportHash,
    content_verification: "NOT_ASSERTED",
    note: "Sanitized portable export created without changing the source memory stores.",
  };
}

function recordSize(value: unknown): number {
  return Buffer.byteLength(stableStringify(value), "utf8");
}

function validOlderThanDays(value: number): number {
  if (!Number.isSafeInteger(value) || value < 1 || value > 36_500) {
    throw new Error("olderThanDays must be an integer from 1 to 36500");
  }
  return value;
}

function daysOld(createdAt: string, now: Date): number | undefined {
  const timestamp = Date.parse(createdAt);
  if (!Number.isFinite(timestamp)) return undefined;
  return (now.getTime() - timestamp) / 86_400_000;
}

function cleanupContextCandidates(
  events: ContextEvent[],
  olderThanDays: number,
  now: Date,
): MemoryCleanupCandidate[] {
  return events
    .filter((event) => event.kind === "frontend_summary")
    .filter((event) => (daysOld(event.created_at, now) ?? -1) >= olderThanDays)
    .map((event) => ({
      candidate_type: "aged_frontend_summary" as const,
      reference: "context:" + sha256(event.event_id).slice(0, 16),
      reason:
        "Untrusted frontend summary is older than the selected threshold; removing it requires an audited ledger archive/rewrite.",
      size_bytes: recordSize(event),
      safe_action: "archive_rewrite_required" as const,
    }));
}

function cleanupKnowledgeCandidates(entries: StoredKnowledgeRecord[]): MemoryCleanupCandidate[] {
  const replacementByOldId = new Map<string, string>();
  for (const entry of entries) {
    if (entry.supersedes_id && entry.status === "active") {
      replacementByOldId.set(entry.supersedes_id, entry.entry_id);
    }
  }
  return entries
    .filter((entry) => replacementByOldId.has(entry.entry_id))
    .map((entry) => {
      const replacementId = replacementByOldId.get(entry.entry_id)!;
      return {
        candidate_type: "superseded_knowledge" as const,
        reference: "knowledge:" + sha256(entry.entry_id).slice(0, 16),
        reason:
          "Knowledge entry has active successor " + sha256(replacementId).slice(0, 16) +
            "; removal requires rebuilding integrity anchors and search indexes.",
        size_bytes: recordSize(entry),
        safe_action: "knowledge_rewrite_required" as const,
      };
    });
}

function cleanupPacketCandidates(
  databasePath: string,
  now: Date,
  warnings: string[],
): MemoryCleanupCandidate[] {
  const packetDirectory = join(dirname(databasePath), "packets");
  if (!existsSync(packetDirectory)) return [];
  const directoryEntry = lstatSync(packetDirectory);
  if (!directoryEntry.isDirectory() || directoryEntry.isSymbolicLink()) {
    warnings.push("Packet directory is not a regular directory; packet inspection was skipped");
    return [];
  }
  const candidates: MemoryCleanupCandidate[] = [];
  for (const entry of readdirSync(packetDirectory, { withFileTypes: true })) {
    if (!entry.isFile() || entry.isSymbolicLink() || extname(entry.name).toLowerCase() !== ".json") {
      continue;
    }
    const path = join(packetDirectory, entry.name);
    const size = safeStatSize(path);
    const fileReference = "packet:" + sha256(entry.name).slice(0, 16);
    if (size > MAX_PACKET_INSPECTION_BYTES) {
      warnings.push("Skipped oversized packet file " + fileReference);
      continue;
    }
    let packet: Record<string, unknown>;
    try {
      packet = JSON.parse(readFileSync(path, "utf8")) as Record<string, unknown>;
    } catch {
      warnings.push("Skipped unreadable packet file " + fileReference);
      continue;
    }
    if (typeof packet.expires_at !== "string") {
      warnings.push("Skipped packet without a valid expires_at field " + fileReference);
      continue;
    }
    const expiresAt = Date.parse(packet.expires_at);
    if (!Number.isFinite(expiresAt)) {
      warnings.push("Skipped packet with malformed expires_at " + fileReference);
      continue;
    }
    if (expiresAt >= now.getTime()) continue;
    candidates.push({
      candidate_type: "expired_context_packet",
      reference: fileReference,
      reason: "Context Packet expired at " + new Date(expiresAt).toISOString() + ".",
      size_bytes: size,
      safe_action: "remove_expired_packet",
    });
  }
  return candidates;
}

export function createMemoryCleanupPlan(
  projectRoot: string,
  options: ClockOptions & { olderThanDays?: number } = {},
): MemoryCleanupPlan {
  const root = resolve(projectRoot);
  const olderThanDays = validOlderThanDays(options.olderThanDays ?? 30);
  const now = options.now?.() ?? new Date();
  const status = getMemoryStatus(root, { now: () => now });
  if (status.status === "INTEGRITY_FAILED") {
    throw new Error("Memory integrity verification failed; refusing to propose cleanup candidates");
  }
  const databasePath = contextDatabasePath(root);
  const events = status.context.integrity_status === "VERIFIED"
    ? readAllContextEventsInternal(root)
    : [];
  const knowledge = status.knowledge.integrity_status === "VERIFIED"
    ? parseKnowledgeRows(databasePath)
    : [];
  const warnings: string[] = [];
  const candidates = [
    ...cleanupContextCandidates(events, olderThanDays, now),
    ...cleanupKnowledgeCandidates(knowledge),
    ...cleanupPacketCandidates(databasePath, now, warnings),
  ].sort((left, right) =>
    left.candidate_type.localeCompare(right.candidate_type) ||
    left.reference.localeCompare(right.reference));
  return {
    format_version: "1.0.0",
    generated_at: now.toISOString(),
    dry_run: true,
    executed: false,
    older_than_days: olderThanDays,
    candidate_count: candidates.length,
    candidate_bytes: candidates.reduce((total, item) => total + item.size_bytes, 0),
    candidates,
    warnings,
    statement:
      "No files or records were changed. Ledger and knowledge candidates require an audited rewrite; this command never deletes them.",
  };
}
