import { DatabaseSync } from "node:sqlite";
import { existsSync } from "node:fs";
import { join, relative, resolve } from "node:path";
import { loadConfig } from "./config.js";
import type {
  ContextAdmissionSource,
  ContextEvent,
  ContextEventAdmission,
  ContextEventKind,
  ContextLedgerVerification,
  ContextPacket,
} from "./types.js";
import {
  assertWithinRoot,
  ensureDirectory,
  newId,
  nowIso,
  sha256,
  stableStringify,
  writeJsonAtomic,
} from "./util.js";

interface UnsignedContextEvent {
  event_id: string;
  sequence: number;
  kind: ContextEventKind;
  actor: string;
  created_at: string;
  payload: Record<string, unknown>;
  previous_hash: string;
}

interface EventRow {
  sequence: number;
  event_id: string;
  kind: ContextEventKind;
  actor: string;
  created_at: string;
  payload_json: string;
  previous_hash: string;
  hash: string;
  admission_status: "candidate" | "admitted" | null;
  admission_basis:
    | "legacy_unverified"
    | "untrusted_append"
    | "trusted_internal"
    | "independent_verification"
    | null;
  admission_authority:
    | "untrusted_input"
    | "legacy_migration"
    | "factory_control_plane"
    | "factory_independent_verifier"
    | null;
  admission_recorded_at: string | null;
  admission_verified_by: string | null;
  admission_source_json: string | null;
  admission_event_hash: string | null;
  admission_hash: string | null;
}

interface UnsignedAdmissionReceipt {
  event_id: string;
  event_hash: string;
  status: ContextEventAdmission["status"];
  basis: ContextEventAdmission["basis"];
  authority: ContextEventAdmission["authority"];
  recorded_at: string;
  verified_by?: string;
  source?: ContextAdmissionSource;
}

export type TrustedContextAdmissionInput =
  | {
      basis: "trusted_internal";
      authority: "factory_control_plane";
      source:
        | Extract<ContextAdmissionSource, { kind: "control_plane_receipt" }>
        | Extract<ContextAdmissionSource, { kind: "knowledge_store_verified" }>;
    }
  | {
      basis: "independent_verification";
      authority: "factory_independent_verifier";
      verifiedBy: string;
      source: Extract<ContextAdmissionSource, { kind: "verification_receipt" }>;
    };

export interface ContextQueryOptions {
  targetRole: string;
  limit?: number;
}

const CONTEXT_SCHEMA_VERSION = "1.2.0";
const CONTEXT_AUTHORITY = "sqlite_hash_chain_and_admission_receipts";
const LEGACY_AUTHORITY = "sqlite_hash_chain_and_verified_artifacts";
const SHA256_PATTERN = /^[a-f0-9]{64}$/;

function contextRoot(projectRoot: string): string {
  const config = loadConfig(projectRoot);
  return assertWithinRoot(
    projectRoot,
    resolve(projectRoot, config.features.external_context.directory),
  );
}

export function contextDatabasePath(projectRoot: string): string {
  return join(contextRoot(projectRoot), "state.db");
}

function packetDirectory(projectRoot: string): string {
  return join(contextRoot(projectRoot), "packets");
}

function openDatabase(projectRoot: string): DatabaseSync {
  const database = new DatabaseSync(contextDatabasePath(projectRoot));
  database.exec("PRAGMA foreign_keys = ON");
  database.exec("PRAGMA journal_mode = WAL");
  database.exec("PRAGMA busy_timeout = 5000");
  return database;
}

function installSchema(database: DatabaseSync): void {
  database.exec(
    [
      "CREATE TABLE IF NOT EXISTS metadata (",
      "  key TEXT PRIMARY KEY,",
      "  value TEXT NOT NULL",
      ");",
      "CREATE TABLE IF NOT EXISTS context_events (",
      "  sequence INTEGER PRIMARY KEY,",
      "  event_id TEXT NOT NULL UNIQUE,",
      "  kind TEXT NOT NULL,",
      "  actor TEXT NOT NULL,",
      "  created_at TEXT NOT NULL,",
      "  payload_json TEXT NOT NULL,",
      "  previous_hash TEXT NOT NULL,",
      "  hash TEXT NOT NULL UNIQUE",
      ");",
      "CREATE TABLE IF NOT EXISTS context_event_admissions (",
      "  event_id TEXT PRIMARY KEY REFERENCES context_events(event_id) ON DELETE RESTRICT,",
      "  event_hash TEXT NOT NULL,",
      "  status TEXT NOT NULL CHECK(status IN ('candidate', 'admitted')),",
      "  basis TEXT NOT NULL CHECK(basis IN ('legacy_unverified', 'untrusted_append', 'trusted_internal', 'independent_verification')),",
      "  authority TEXT NOT NULL CHECK(authority IN ('untrusted_input', 'legacy_migration', 'factory_control_plane', 'factory_independent_verifier')),",
      "  recorded_at TEXT NOT NULL,",
      "  verified_by TEXT,",
      "  source_json TEXT,",
      "  admission_hash TEXT NOT NULL UNIQUE",
      ");",
      "CREATE INDEX IF NOT EXISTS context_events_kind_idx ON context_events(kind);",
      "CREATE INDEX IF NOT EXISTS context_events_created_idx ON context_events(created_at);",
      "CREATE VIRTUAL TABLE IF NOT EXISTS context_events_fts USING fts5(",
      "  event_id UNINDEXED, kind, actor, searchable_text",
      ");",
    ].join("\n"),
  );
}

export function initializeContextSpace(projectRoot: string): void {
  const config = loadConfig(projectRoot);
  if (!config.features.external_context.enabled) return;
  ensureDirectory(contextRoot(projectRoot));
  ensureDirectory(packetDirectory(projectRoot));
  const database = openDatabase(projectRoot);
  try {
    installSchema(database);
    const schemaBefore = database
      .prepare("SELECT value FROM metadata WHERE key = 'schema_version'")
      .get() as { value?: string } | undefined;
    const insert = database.prepare(
      "INSERT OR IGNORE INTO metadata(key, value) VALUES (?, ?)",
    );
    const events = readEventsFromDatabase(database);
    const chain = verifyEvents(events);
    if (!chain.valid) {
      throw new Error(
        "Context ledger is invalid; cannot initialize integrity anchors: " +
          chain.issues.join("; "),
      );
    }
    if (!schemaBefore?.value) {
      if (events.length > 0) {
        throw new Error("Context schema metadata is missing for a non-empty ledger");
      }
      insert.run("schema_version", CONTEXT_SCHEMA_VERSION);
      insert.run("project_id", config.project_id);
      insert.run("created_at", nowIso());
      insert.run("trust_frontend_summary", "false");
      insert.run("authority", CONTEXT_AUTHORITY);
      insert.run("expected_event_count", "0");
      insert.run("expected_head_hash", "GENESIS");
      insert.run("expected_admission_count", "0");
      insert.run("expected_admission_root_hash", "GENESIS");
      return;
    }

    const metadata = readMetadata(database);
    if (metadata.schema_version === "1.0.0" || metadata.schema_version === "1.1.0") {
      validateLegacyMetadata(database, events, chain, config.project_id, metadata);
      migrateLegacyAdmissions(database, events);
      return;
    }
    if (metadata.schema_version !== CONTEXT_SCHEMA_VERSION) {
      throw new Error("Unsupported context schema version: " + String(metadata.schema_version));
    }
    verifyAnchorsAndFts(database, events, chain, config.project_id);
    verifyAdmissionReceipts(database, events, chain);
    if (!chain.valid) {
      throw new Error("Context integrity anchors are invalid: " + chain.issues.join("; "));
    }
  } finally {
    database.close();
  }
}

function eventFromRow(row: EventRow): ContextEvent {
  const source = row.admission_source_json
    ? (JSON.parse(row.admission_source_json) as ContextAdmissionSource)
    : undefined;
  const admission: ContextEventAdmission = row.admission_hash
    ? {
        status: row.admission_status!,
        basis: row.admission_basis!,
        authority: row.admission_authority!,
        recorded_at: row.admission_recorded_at!,
        ...(row.admission_verified_by ? { verified_by: row.admission_verified_by } : {}),
        ...(source ? { source } : {}),
        bound_event_hash: row.admission_event_hash!,
        admission_hash: row.admission_hash,
      }
    : {
        status: "candidate",
        basis: "legacy_unverified",
        authority: "legacy_migration",
        recorded_at: row.created_at,
        bound_event_hash: row.hash,
        admission_hash: "",
      };
  return {
    event_id: row.event_id,
    sequence: Number(row.sequence),
    kind: row.kind,
    actor: row.actor,
    created_at: row.created_at,
    payload: JSON.parse(row.payload_json) as Record<string, unknown>,
    previous_hash: row.previous_hash,
    hash: row.hash,
    admission,
  };
}

function readEventsFromDatabase(database: DatabaseSync): ContextEvent[] {
  const rows = database
    .prepare(
      [
        "SELECT e.sequence, e.event_id, e.kind, e.actor, e.created_at,",
        "e.payload_json, e.previous_hash, e.hash,",
        "a.status AS admission_status, a.basis AS admission_basis,",
        "a.authority AS admission_authority, a.recorded_at AS admission_recorded_at,",
        "a.verified_by AS admission_verified_by, a.source_json AS admission_source_json,",
        "a.event_hash AS admission_event_hash, a.admission_hash AS admission_hash",
        "FROM context_events e",
        "LEFT JOIN context_event_admissions a ON a.event_id = e.event_id",
        "ORDER BY e.sequence ASC",
      ].join(" "),
    )
    .all() as unknown as EventRow[];
  return rows.map(eventFromRow);
}

export function readAllContextEventsInternal(projectRoot: string): ContextEvent[] {
  if (!existsSync(contextDatabasePath(projectRoot))) return [];
  const database = openDatabase(projectRoot);
  try {
    installSchema(database);
    return readEventsFromDatabase(database);
  } finally {
    database.close();
  }
}

export function readContextEvents(projectRoot: string, targetRole: string): ContextEvent[] {
  if (!targetRole.trim()) throw new Error("Context target role is required");
  const verification = verifyContextLedger(projectRoot);
  if (!verification.valid) {
    throw new Error(
      "Context ledger is invalid; refusing role-scoped read: " + verification.issues.join("; "),
    );
  }
  return readAllContextEventsInternal(projectRoot).filter((event) =>
    eventVisibleToRole(event, targetRole),
  );
}

function unsignedEvent(event: ContextEvent): UnsignedContextEvent {
  return {
    event_id: event.event_id,
    sequence: event.sequence,
    kind: event.kind,
    actor: event.actor,
    created_at: event.created_at,
    payload: event.payload,
    previous_hash: event.previous_hash,
  };
}

function readMetadata(database: DatabaseSync): Record<string, string> {
  const rows = database
    .prepare("SELECT key, value FROM metadata")
    .all() as unknown as Array<{ key: string; value: string }>;
  return Object.fromEntries(rows.map((row) => [row.key, row.value]));
}

function unsignedAdmissionReceipt(
  event: ContextEvent,
  admission: Omit<ContextEventAdmission, "admission_hash">,
): UnsignedAdmissionReceipt {
  return {
    event_id: event.event_id,
    event_hash: admission.bound_event_hash,
    status: admission.status,
    basis: admission.basis,
    authority: admission.authority,
    recorded_at: admission.recorded_at,
    ...(admission.verified_by ? { verified_by: admission.verified_by } : {}),
    ...(admission.source ? { source: admission.source } : {}),
  };
}

function signAdmission(
  event: ContextEvent,
  admission: Omit<ContextEventAdmission, "admission_hash">,
): ContextEventAdmission {
  return {
    ...admission,
    admission_hash: sha256(stableStringify(unsignedAdmissionReceipt(event, admission))),
  };
}

function admissionRootHash(events: ContextEvent[]): string {
  if (events.length === 0) return "GENESIS";
  return sha256(
    stableStringify(
      events.map((event) => ({
        event_id: event.event_id,
        event_hash: event.hash,
        admission_hash: event.admission.admission_hash,
      })),
    ),
  );
}

function insertAdmission(
  database: DatabaseSync,
  event: ContextEvent,
  admission: ContextEventAdmission,
): void {
  database
    .prepare(
      [
        "INSERT INTO context_event_admissions(",
        "event_id, event_hash, status, basis, authority, recorded_at,",
        "verified_by, source_json, admission_hash",
        ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
      ].join(" "),
    )
    .run(
      event.event_id,
      admission.bound_event_hash,
      admission.status,
      admission.basis,
      admission.authority,
      admission.recorded_at,
      admission.verified_by ?? null,
      admission.source ? stableStringify(admission.source) : null,
      admission.admission_hash,
    );
}

function validateLegacyMetadata(
  database: DatabaseSync,
  events: ContextEvent[],
  chain: ContextLedgerVerification,
  expectedProjectId: string,
  metadata: Record<string, string>,
): void {
  if (metadata.project_id !== expectedProjectId) {
    throw new Error("Legacy context project_id metadata mismatch");
  }
  if (metadata.trust_frontend_summary !== "false") {
    throw new Error("Legacy context trust_frontend_summary must be false");
  }
  if (metadata.authority !== LEGACY_AUTHORITY) {
    throw new Error("Legacy context authority metadata mismatch");
  }
  const hasCount = metadata.expected_event_count !== undefined;
  const hasHead = metadata.expected_head_hash !== undefined;
  if (hasCount !== hasHead) throw new Error("Legacy context anchor metadata is incomplete");
  if (metadata.schema_version === "1.1.0" && (!hasCount || !hasHead)) {
    throw new Error("Legacy context integrity anchors are missing");
  }
  if (hasCount && metadata.expected_event_count !== String(chain.event_count)) {
    throw new Error("Legacy context expected_event_count anchor mismatch");
  }
  if (hasHead && metadata.expected_head_hash !== chain.head_hash) {
    throw new Error("Legacy context expected_head_hash anchor mismatch");
  }
  verifyFtsRows(database, events, chain);
  if (!chain.integrity_valid) {
    throw new Error("Legacy context FTS integrity failed: " + chain.issues.join("; "));
  }
}

function migrateLegacyAdmissions(database: DatabaseSync, events: ContextEvent[]): void {
  database.exec("BEGIN IMMEDIATE");
  try {
    for (const event of events) {
      const admission = signAdmission(event, {
        status: "candidate",
        basis: "legacy_unverified",
        authority: "legacy_migration",
        recorded_at: event.created_at,
        bound_event_hash: event.hash,
      });
      insertAdmission(database, event, admission);
      event.admission = admission;
    }
    const update = database.prepare("UPDATE metadata SET value = ? WHERE key = ?");
    const insert = database.prepare("INSERT OR IGNORE INTO metadata(key, value) VALUES (?, ?)");
    update.run(CONTEXT_SCHEMA_VERSION, "schema_version");
    update.run(CONTEXT_AUTHORITY, "authority");
    insert.run("expected_event_count", String(events.length));
    insert.run("expected_head_hash", events.at(-1)?.hash ?? "GENESIS");
    insert.run("expected_admission_count", String(events.length));
    insert.run("expected_admission_root_hash", admissionRootHash(events));
    update.run(String(events.length), "expected_event_count");
    update.run(events.at(-1)?.hash ?? "GENESIS", "expected_head_hash");
    update.run(String(events.length), "expected_admission_count");
    update.run(admissionRootHash(events), "expected_admission_root_hash");
    database.exec("COMMIT");
  } catch (error) {
    database.exec("ROLLBACK");
    throw error;
  }
}

function verifyEvents(events: ContextEvent[]): ContextLedgerVerification {
  const issues: string[] = [];
  let previousHash = "GENESIS";
  let expectedSequence = 1;
  const ids = new Set<string>();

  for (const event of events) {
    if (event.sequence !== expectedSequence) {
      issues.push(
        "Sequence mismatch for " +
          event.event_id +
          ": expected " +
          expectedSequence +
          ", got " +
          event.sequence,
      );
    }
    if (event.previous_hash !== previousHash) {
      issues.push("Previous hash mismatch for " + event.event_id);
    }
    if (event.hash !== sha256(stableStringify(unsignedEvent(event)))) {
      issues.push("Event hash mismatch for " + event.event_id);
    }
    if (ids.has(event.event_id)) issues.push("Duplicate event_id: " + event.event_id);
    ids.add(event.event_id);
    previousHash = event.hash;
    expectedSequence += 1;
  }

  return {
    valid: issues.length === 0,
    integrity_valid: issues.length === 0,
    admission_integrity_valid: true,
    event_count: events.length,
    admitted_event_count: 0,
    candidate_event_count: 0,
    head_hash: events.length > 0 ? previousHash : "GENESIS",
    admission_root_hash: "",
    issues,
  };
}

function verifyAnchorsAndFts(
  database: DatabaseSync,
  events: ContextEvent[],
  result: ContextLedgerVerification,
  expectedProjectId: string,
): void {
  const metadata = readMetadata(database);
  if (metadata.schema_version !== CONTEXT_SCHEMA_VERSION) {
    result.issues.push("Context schema_version must be " + CONTEXT_SCHEMA_VERSION);
  }
  if (metadata.project_id !== expectedProjectId) {
    result.issues.push("Context project_id metadata mismatch");
  }
  if (metadata.trust_frontend_summary !== "false") {
    result.issues.push("Context trust_frontend_summary metadata must be false");
  }
  if (metadata.authority !== CONTEXT_AUTHORITY) {
    result.issues.push("Context authority metadata mismatch");
  }
  if (metadata.expected_event_count !== String(result.event_count)) {
    result.issues.push("Context expected_event_count anchor mismatch");
  }
  if (metadata.expected_head_hash !== result.head_hash) {
    result.issues.push("Context expected_head_hash anchor mismatch");
  }
  verifyFtsRows(database, events, result);
  result.integrity_valid = result.issues.length === 0;
  result.valid = result.integrity_valid && result.admission_integrity_valid;
}

function verifyFtsRows(
  database: DatabaseSync,
  events: ContextEvent[],
  result: ContextLedgerVerification,
): void {
  const issuesBefore = result.issues.length;
  const ftsRows = database
    .prepare("SELECT event_id, kind, actor, searchable_text FROM context_events_fts")
    .all() as unknown as Array<{
      event_id: string;
      kind: string;
      actor: string;
      searchable_text: string;
    }>;
  const ftsById = new Map(ftsRows.map((row) => [row.event_id, row]));
  if (ftsRows.length !== events.length || ftsById.size !== events.length) {
    result.issues.push("Context FTS row count does not match the event ledger");
  }
  for (const event of events) {
    const row = ftsById.get(event.event_id);
    if (
      !row ||
      row.kind !== event.kind ||
      row.actor !== event.actor ||
      row.searchable_text !== stableStringify(event.payload)
    ) {
      result.issues.push("Context FTS row mismatch for " + event.event_id);
    }
  }
  if (result.issues.length > issuesBefore) result.integrity_valid = false;
  result.valid = result.integrity_valid && result.admission_integrity_valid;
}

function validDigest(value: unknown): value is string {
  return typeof value === "string" && SHA256_PATTERN.test(value);
}

function validateAdmissionSource(source: ContextAdmissionSource | undefined): string[] {
  if (!source) return ["admitted event is missing its bound source"];
  const issues: string[] = [];
  if (containsSecret(source)) issues.push("admission source appears to contain secret material");
  if (!source.reference.trim()) issues.push("admission source reference is empty");
  if (source.kind === "knowledge_store_verified") {
    if (!validDigest(source.store_digest)) issues.push("knowledge store digest is invalid");
    for (const [label, digests] of [
      ["entry", source.entry_digests],
      ["source", source.source_digests],
      ["content", source.content_digests],
    ] as const) {
      if (digests.length === 0) issues.push("knowledge " + label + " digests are empty");
      if (digests.some((digest) => !validDigest(digest))) {
        issues.push("knowledge " + label + " digest is invalid");
      }
    }
  } else if (!validDigest(source.sha256)) {
    issues.push("admission source sha256 is invalid");
  }
  return issues;
}

function verifyAdmissionReceipts(
  database: DatabaseSync,
  events: ContextEvent[],
  result: ContextLedgerVerification,
): void {
  const issuesBefore = result.issues.length;
  let admitted = 0;
  let candidates = 0;
  for (const event of events) {
    const admission = event.admission;
    if (!admission.admission_hash) {
      result.issues.push("Missing admission receipt for " + event.event_id);
      continue;
    }
    if (admission.bound_event_hash !== event.hash) {
      result.issues.push("Admission receipt is bound to a different event hash: " + event.event_id);
    }
    const { admission_hash: _admissionHash, ...unsigned } = admission;
    const expected = sha256(stableStringify(unsignedAdmissionReceipt(event, unsigned)));
    if (admission.admission_hash !== expected) {
      result.issues.push("Admission receipt hash mismatch for " + event.event_id);
    }
    if (!Number.isFinite(Date.parse(admission.recorded_at))) {
      result.issues.push("Admission receipt timestamp is invalid for " + event.event_id);
    }
    if (admission.status === "candidate") {
      candidates += 1;
      if (admission.basis !== "legacy_unverified" && admission.basis !== "untrusted_append") {
        result.issues.push("Candidate admission basis is invalid for " + event.event_id);
      }
      if (admission.authority !== "legacy_migration" && admission.authority !== "untrusted_input") {
        result.issues.push("Candidate admission authority is invalid for " + event.event_id);
      }
      if (admission.source || admission.verified_by) {
        result.issues.push("Candidate event must not claim verified source metadata: " + event.event_id);
      }
    } else {
      admitted += 1;
      if (admission.basis !== "trusted_internal" && admission.basis !== "independent_verification") {
        result.issues.push("Admitted event basis is invalid for " + event.event_id);
      }
      if (event.kind === "frontend_summary") {
        result.issues.push("Frontend summary cannot have admitted status: " + event.event_id);
      }
      const visibility = event.payload.visible_to_roles;
      if (
        !Array.isArray(visibility) ||
        visibility.length === 0 ||
        visibility.some((role) => typeof role !== "string" || !role.trim() || role === "*")
      ) {
        result.issues.push("Admitted event has unsafe or missing role visibility: " + event.event_id);
      }
      for (const issue of validateAdmissionSource(admission.source)) {
        result.issues.push(issue + " for " + event.event_id);
      }
      if (admission.basis === "trusted_internal") {
        if (admission.authority !== "factory_control_plane") {
          result.issues.push("Trusted internal admission authority is invalid for " + event.event_id);
        }
        if (
          admission.source?.kind !== "control_plane_receipt" &&
          admission.source?.kind !== "knowledge_store_verified"
        ) {
          result.issues.push("Trusted internal event has an invalid source kind: " + event.event_id);
        }
        if (admission.verified_by) {
          result.issues.push("Trusted internal event must not claim independent verification: " + event.event_id);
        }
      } else {
        if (admission.authority !== "factory_independent_verifier") {
          result.issues.push("Independent admission authority is invalid for " + event.event_id);
        }
        if (!admission.verified_by?.trim()) {
          result.issues.push("Independent admission is missing verifier identity: " + event.event_id);
        }
        if (admission.source?.kind !== "verification_receipt") {
          result.issues.push("Independent admission must bind a verification receipt: " + event.event_id);
        }
      }
    }
  }
  const metadata = readMetadata(database);
  const admissionCountRow = database
    .prepare("SELECT COUNT(*) AS count FROM context_event_admissions")
    .get() as { count: number | bigint };
  if (Number(admissionCountRow.count) !== events.length) {
    result.issues.push("Context admission receipt row count does not match the event ledger");
  }
  const root = admissionRootHash(events);
  result.admitted_event_count = admitted;
  result.candidate_event_count = candidates;
  result.admission_root_hash = root;
  if (metadata.expected_admission_count !== String(events.length)) {
    result.issues.push("Context expected_admission_count anchor mismatch");
  }
  if (metadata.expected_admission_root_hash !== root) {
    result.issues.push("Context expected_admission_root_hash anchor mismatch");
  }
  result.admission_integrity_valid = result.issues.length === issuesBefore;
  result.valid = result.integrity_valid && result.admission_integrity_valid;
}

export function verifyContextLedger(projectRoot: string): ContextLedgerVerification {
  if (!existsSync(contextDatabasePath(projectRoot))) {
    return {
      valid: false,
      integrity_valid: false,
      admission_integrity_valid: false,
      event_count: 0,
      admitted_event_count: 0,
      candidate_event_count: 0,
      head_hash: "",
      admission_root_hash: "",
      issues: ["Context database does not exist"],
    };
  }
  try {
    initializeContextSpace(projectRoot);
  } catch (error) {
    return {
      valid: false,
      integrity_valid: false,
      admission_integrity_valid: false,
      event_count: 0,
      admitted_event_count: 0,
      candidate_event_count: 0,
      head_hash: "",
      admission_root_hash: "",
      issues: [(error as Error).message],
    };
  }
  const database = openDatabase(projectRoot);
  try {
    const config = loadConfig(projectRoot);
    installSchema(database);
    const integrity = database.prepare("PRAGMA integrity_check").get() as
      | { integrity_check?: string }
      | undefined;
    const events = readEventsFromDatabase(database);
    const result = verifyEvents(events);
    verifyAnchorsAndFts(database, events, result, config.project_id);
    verifyAdmissionReceipts(database, events, result);
    if (integrity?.integrity_check !== "ok") {
      result.valid = false;
      result.integrity_valid = false;
      result.issues.unshift(
        "SQLite integrity check failed: " + String(integrity?.integrity_check),
      );
    }
    return result;
  } catch (error) {
    return {
      valid: false,
      integrity_valid: false,
      admission_integrity_valid: false,
      event_count: 0,
      admitted_event_count: 0,
      candidate_event_count: 0,
      head_hash: "",
      admission_root_hash: "",
      issues: [(error as Error).message],
    };
  } finally {
    database.close();
  }
}

const TRUSTED_INTERNAL_ACTORS = new Set(["main_controller", "factoryctl"]);
const SECRET_FIELD_PATTERN = /(?:^|_)(?:api_?key|secret|token|password|passwd|private_?key|credential|authorization)(?:$|_)/i;
const SECRET_VALUE_PATTERNS = [
  /-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----/,
  /\b(?:sk|gh[opusr])[-_][A-Za-z0-9_-]{16,}\b/,
  /\bAKIA[A-Z0-9]{16}\b/,
  /\b(?:api[_ -]?key|secret|token|password|credential)\s*[:=]\s*["']?[A-Za-z0-9_./+\-=]{8,}/i,
];

function safeSecretReference(value: string): boolean {
  const trimmed = value.trim();
  return (
    /^\$\{[A-Z][A-Z0-9_]*\}$/.test(trimmed) ||
    /^(?:env:)?[A-Z][A-Z0-9_]{2,}$/.test(trimmed) ||
    /^(?:<redacted>|\[redacted\]|redacted|\*+)$/i.test(trimmed)
  );
}

function containsSecret(value: unknown, key = ""): boolean {
  if (typeof value === "string") {
    if (SECRET_VALUE_PATTERNS.some((pattern) => pattern.test(value))) return true;
    return SECRET_FIELD_PATTERN.test(key) && value.trim().length > 0 && !safeSecretReference(value);
  }
  if (Array.isArray(value)) return value.some((item) => containsSecret(item, key));
  if (value && typeof value === "object") {
    return Object.entries(value as Record<string, unknown>).some(([childKey, childValue]) =>
      containsSecret(childValue, childKey),
    );
  }
  return false;
}

function assertPayloadContainsNoSecrets(payload: Record<string, unknown>): void {
  if (containsSecret(payload)) {
    throw new Error("Context payload rejected because it appears to contain secret material");
  }
}

function validateTrustedAdmissionInput(
  kind: ContextEventKind,
  actor: string,
  payload: Record<string, unknown>,
  input: TrustedContextAdmissionInput,
): void {
  if (kind === "frontend_summary") {
    throw new Error("Frontend summaries cannot use the trusted context append path");
  }
  const visibility = payload.visible_to_roles;
  if (
    !Array.isArray(visibility) ||
    visibility.length === 0 ||
    visibility.some((role) => typeof role !== "string" || !role.trim() || role === "*")
  ) {
    throw new Error("Trusted context requires an explicit non-wildcard visible_to_roles list");
  }
  for (const issue of validateAdmissionSource(input.source)) {
    throw new Error("Invalid trusted context admission source: " + issue);
  }
  if (kind === "knowledge_retrieval" && input.source.kind !== "knowledge_store_verified") {
    throw new Error("Knowledge retrieval events must bind a verified knowledge store source");
  }
  if (
    kind === "knowledge_retrieval" &&
    (typeof payload.run_id !== "string" ||
      !payload.run_id.trim() ||
      typeof payload.assignment_id !== "string" ||
      !payload.assignment_id.trim() ||
      typeof payload.target_role !== "string" ||
      !payload.target_role.trim() ||
      !visibility.includes(payload.target_role))
  ) {
    throw new Error(
      "Knowledge retrieval context must be bound to run_id, assignment_id, and a visible target_role",
    );
  }
  if (input.source.kind === "knowledge_store_verified" && kind !== "knowledge_retrieval") {
    throw new Error("Verified knowledge store sources are limited to knowledge_retrieval events");
  }
  if (input.basis === "trusted_internal") {
    if (!TRUSTED_INTERNAL_ACTORS.has(actor)) {
      throw new Error("Trusted internal context actor is not a control-plane identity");
    }
  } else {
    if (actor !== "factoryctl") {
      throw new Error("Independently verified context must be recorded by factoryctl");
    }
    if (!input.verifiedBy.trim() || input.verifiedBy === actor) {
      throw new Error("Independent context admission requires a distinct verifier identity");
    }
  }
}

function appendContextEventWithAdmission(
  projectRoot: string,
  kind: ContextEventKind,
  actor: string,
  payload: Record<string, unknown>,
  trustedAdmission?: TrustedContextAdmissionInput,
): ContextEvent {
  const config = loadConfig(projectRoot);
  if (!config.features.external_context.enabled) {
    throw new Error("External context space is disabled");
  }
  if (!actor.trim()) throw new Error("Context event actor is required");
  assertPayloadContainsNoSecrets(payload);
  if (trustedAdmission) validateTrustedAdmissionInput(kind, actor, payload, trustedAdmission);
  initializeContextSpace(projectRoot);

  const database = openDatabase(projectRoot);
  try {
    installSchema(database);
    database.exec("BEGIN IMMEDIATE");
    try {
      const currentEvents = readEventsFromDatabase(database);
      const verification = verifyEvents(currentEvents);
      verifyAnchorsAndFts(
        database,
        currentEvents,
        verification,
        config.project_id,
      );
      verifyAdmissionReceipts(database, currentEvents, verification);
      if (!verification.valid) {
        throw new Error(
          "Context ledger is invalid; refusing append: " +
            verification.issues.join("; "),
        );
      }
      const unsigned: UnsignedContextEvent = {
        event_id: newId("ctx"),
        sequence: verification.event_count + 1,
        kind,
        actor,
        created_at: nowIso(),
        payload,
        previous_hash: verification.head_hash,
      };
      const event: ContextEvent = {
        ...unsigned,
        hash: sha256(stableStringify(unsigned)),
        admission: undefined as never,
      };
      const admission = trustedAdmission
        ? signAdmission(event, {
            status: "admitted",
            basis: trustedAdmission.basis,
            authority: trustedAdmission.authority,
            recorded_at: event.created_at,
            ...(trustedAdmission.basis === "independent_verification"
              ? { verified_by: trustedAdmission.verifiedBy }
              : {}),
            source: trustedAdmission.source,
            bound_event_hash: event.hash,
          })
        : signAdmission(event, {
            status: "candidate",
            basis: "untrusted_append",
            authority: "untrusted_input",
            recorded_at: event.created_at,
            bound_event_hash: event.hash,
          });
      event.admission = admission;
      database
        .prepare(
          [
            "INSERT INTO context_events(",
            "sequence, event_id, kind, actor, created_at, payload_json, previous_hash, hash",
            ") VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
          ].join(" "),
        )
        .run(
          event.sequence,
          event.event_id,
          event.kind,
          event.actor,
          event.created_at,
          stableStringify(event.payload),
          event.previous_hash,
          event.hash,
        );
      database
        .prepare(
          "INSERT INTO context_events_fts(event_id, kind, actor, searchable_text) VALUES (?, ?, ?, ?)",
        )
        .run(
          event.event_id,
          event.kind,
          event.actor,
          stableStringify(event.payload),
        );
      insertAdmission(database, event, admission);
      database
        .prepare("UPDATE metadata SET value = ? WHERE key = 'expected_event_count'")
        .run(String(event.sequence));
      database
        .prepare("UPDATE metadata SET value = ? WHERE key = 'expected_head_hash'")
        .run(event.hash);
      database
        .prepare("UPDATE metadata SET value = ? WHERE key = 'expected_admission_count'")
        .run(String(event.sequence));
      database
        .prepare("UPDATE metadata SET value = ? WHERE key = 'expected_admission_root_hash'")
        .run(admissionRootHash([...currentEvents, event]));
      database.exec("COMMIT");
      return event;
    } catch (error) {
      database.exec("ROLLBACK");
      throw error;
    }
  } finally {
    database.close();
  }
}

/** Public/manual input is always recorded as a candidate, regardless of its actor string. */
export function appendContextEvent(
  projectRoot: string,
  kind: ContextEventKind,
  actor: string,
  payload: Record<string, unknown>,
): ContextEvent {
  return appendContextEventWithAdmission(projectRoot, kind, actor, payload);
}

/** Explicit control-plane path for source-bound operational or independently verified events. */
export function appendTrustedContextEvent(
  projectRoot: string,
  kind: ContextEventKind,
  actor: string,
  payload: Record<string, unknown>,
  admission: TrustedContextAdmissionInput,
): ContextEvent {
  return appendContextEventWithAdmission(projectRoot, kind, actor, payload, admission);
}

export function queryContextEvents(
  projectRoot: string,
  query: string,
  options: ContextQueryOptions,
): ContextEvent[] {
  if (!options.targetRole.trim()) throw new Error("Context query target role is required");
  const limit = Math.max(1, Math.min(100, options.limit ?? 20));
  return queryAllContextEventsInternal(projectRoot, query, 10_000)
    .filter((event) => eventVisibleToRole(event, options.targetRole))
    .slice(0, limit);
}

export function queryAllContextEventsInternal(
  projectRoot: string,
  query: string,
  limit = 100,
): ContextEvent[] {
  if (!query.trim()) return [];
  const verification = verifyContextLedger(projectRoot);
  if (!verification.valid) {
    throw new Error(
      "Context ledger is invalid; refusing query: " + verification.issues.join("; "),
    );
  }
  const database = openDatabase(projectRoot);
  try {
    installSchema(database);
    const rows = database
      .prepare(
        [
          "SELECT e.sequence, e.event_id, e.kind, e.actor, e.created_at,",
          "e.payload_json, e.previous_hash, e.hash,",
          "a.status AS admission_status, a.basis AS admission_basis,",
          "a.authority AS admission_authority, a.recorded_at AS admission_recorded_at,",
          "a.verified_by AS admission_verified_by, a.source_json AS admission_source_json,",
          "a.event_hash AS admission_event_hash, a.admission_hash AS admission_hash",
          "FROM context_events_fts f",
          "JOIN context_events e ON e.event_id = f.event_id",
          "LEFT JOIN context_event_admissions a ON a.event_id = e.event_id",
          "WHERE context_events_fts MATCH ?",
          "ORDER BY bm25(context_events_fts), e.sequence DESC LIMIT ?",
        ].join(" "),
      )
      .all(query, Math.max(1, Math.min(10_000, limit))) as unknown as EventRow[];
    return rows.map(eventFromRow);
  } finally {
    database.close();
  }
}

function packetWithoutHash(packet: ContextPacket): Omit<ContextPacket, "packet_hash"> {
  const { packet_hash: _packetHash, ...unsigned } = packet;
  return unsigned;
}

export interface CreateContextPacketOptions {
  /** Include only these ledger events. The ledger head still binds the packet to the full state. */
  sourceEventIds?: string[];
  /** Hard limit to keep a role packet bounded. Newest matching events win. */
  maxEvents?: number;
}

export function eventVisibleToRole(event: ContextEvent, targetRole: string): boolean {
  const declared = event.payload.visible_to_roles;
  if (declared === undefined) return true;
  if (!Array.isArray(declared)) return false;
  const roles = declared.filter((item): item is string => typeof item === "string");
  return roles.includes("*") || roles.includes(targetRole);
}

export function createContextPacket(
  projectRoot: string,
  runId: string,
  targetRole: string,
  options: CreateContextPacketOptions = {},
): { packet: ContextPacket; path: string } {
  const config = loadConfig(projectRoot);
  if (!config.features.external_context.enabled) {
    throw new Error("External context space is disabled");
  }
  const verification = verifyContextLedger(projectRoot);
  if (!verification.valid) {
    throw new Error(
      "Context ledger is invalid; refusing packet generation: " +
        verification.issues.join("; "),
    );
  }
  const requestedIds = options.sourceEventIds
    ? new Set(options.sourceEventIds)
    : undefined;
  const maxEvents = Math.max(1, Math.min(500, options.maxEvents ?? 100));
  const allEvents = readAllContextEventsInternal(projectRoot);
  const requestedEvents = allEvents.filter(
    (event) =>
      (!requestedIds || requestedIds.has(event.event_id)) &&
      (requestedIds || event.kind !== "knowledge_retrieval") &&
      eventVisibleToRole(event, targetRole),
  );
  if (requestedIds) {
    const found = new Set(requestedEvents.map((event) => event.event_id));
    const unavailable = [...requestedIds].filter((eventId) => !found.has(eventId));
    if (unavailable.length > 0) {
      throw new Error(
        "Requested context events are missing or not visible to role " +
          targetRole +
          ": " +
          unavailable.join(", "),
      );
    }
  }
  const events = requestedEvents.slice(-maxEvents);
  const trusted = events
    .filter(
      (event) => event.kind !== "frontend_summary" && event.admission.status === "admitted",
    )
    .map((event) => ({
      event_id: event.event_id,
      kind: event.kind as Exclude<ContextEventKind, "frontend_summary">,
      payload: event.payload,
      admission: event.admission,
    }));
  const candidates = events
    .filter(
      (event) => event.kind !== "frontend_summary" && event.admission.status === "candidate",
    )
    .map((event) => ({
      event_id: event.event_id,
      kind: event.kind as Exclude<ContextEventKind, "frontend_summary">,
      payload: event.payload,
      admission: event.admission,
    }));
  const frontendNotes = events
    .filter((event) => event.kind === "frontend_summary")
    .map((event) => ({ event_id: event.event_id, payload: event.payload }));
  const generatedAt = new Date();
  const expiresAt = new Date(
    generatedAt.getTime() +
      config.features.external_context.packet_max_age_minutes * 60_000,
  );

  const packet: ContextPacket = {
    packet_id: newId("packet"),
    packet_version: "1.1.0",
    project_id: config.project_id,
    run_id: runId,
    target_role: targetRole,
    generated_at: generatedAt.toISOString(),
    expires_at: expiresAt.toISOString(),
    ledger_head_hash: verification.head_hash,
    source_event_ids: events.map((event) => event.event_id),
    trusted_context: trusted,
    untrusted_context_candidates: candidates,
    untrusted_frontend_notes: frontendNotes,
    forbidden_assumptions: [
      "The frontend compressed summary is evidence.",
      "An agent self-report proves completion.",
      "A claimed artifact name proves that a file exists.",
      "Historical PASS evidence applies to the current commit.",
    ],
    packet_hash: "",
  };
  packet.packet_hash = sha256(stableStringify(packetWithoutHash(packet)));
  const path = join(packetDirectory(projectRoot), packet.packet_id + ".json");
  writeJsonAtomic(path, packet);
  return { packet, path };
}

export function verifyContextPacket(
  projectRoot: string,
  packet: ContextPacket,
  expected: { runId?: string; targetRole?: string; assignmentId?: string } = {},
): { valid: boolean; stale: boolean; issues: string[] } {
  const issues: string[] = [];
  const config = loadConfig(projectRoot);
  if (packet.packet_hash !== sha256(stableStringify(packetWithoutHash(packet)))) {
    issues.push("Packet hash mismatch");
  }
  if (packet.packet_version !== "1.1.0") issues.push("Unsupported packet version");
  if (
    !Array.isArray(packet.source_event_ids) ||
    !Array.isArray(packet.trusted_context) ||
    !Array.isArray(packet.untrusted_context_candidates) ||
    !Array.isArray(packet.untrusted_frontend_notes)
  ) {
    issues.push("Packet context sections are missing or malformed");
    return { valid: false, stale: false, issues };
  }
  if (packet.project_id !== config.project_id) issues.push("Packet project_id mismatch");
  if (!packet.run_id.trim()) issues.push("Packet run_id is required");
  if (!packet.target_role.trim()) issues.push("Packet target_role is required");
  if (expected.runId && packet.run_id !== expected.runId) {
    issues.push("Packet run_id does not match the assignment");
  }
  if (expected.targetRole && packet.target_role !== expected.targetRole) {
    issues.push("Packet target_role does not match the assignment");
  }
  if (
    expected.assignmentId &&
    !packet.trusted_context.some(
      (item) => item.payload.assignment_id === expected.assignmentId,
    )
  ) {
    issues.push("Packet does not contain the expected assignment contract");
  }
  const ledger = verifyContextLedger(projectRoot);
  if (!ledger.valid) issues.push("Context ledger is invalid");
  const events = readAllContextEventsInternal(projectRoot);
  if (
    packet.ledger_head_hash !== "GENESIS" &&
    !events.some((event) => event.hash === packet.ledger_head_hash)
  ) {
    issues.push("Packet ledger head is not an ancestor in the current verified chain");
  }
  const eventsById = new Map(events.map((event) => [event.event_id, event]));
  const sourceIds = new Set(packet.source_event_ids);
  if (sourceIds.size !== packet.source_event_ids.length) {
    issues.push("Packet source_event_ids contains duplicates");
  }
  const missingSourceIds = packet.source_event_ids.filter((eventId) => !eventsById.has(eventId));
  if (missingSourceIds.length > 0) {
    issues.push("Packet references missing source events: " + missingSourceIds.join(", "));
  }
  const materializedIds = [
    ...packet.trusted_context.map((item) => item.event_id),
    ...packet.untrusted_context_candidates.map((item) => item.event_id),
    ...packet.untrusted_frontend_notes.map((item) => item.event_id),
  ];
  if (new Set(materializedIds).size !== materializedIds.length) {
    issues.push("Packet materializes a source event more than once");
  }
  if (
    sourceIds.size !== materializedIds.length ||
    materializedIds.some((eventId) => !sourceIds.has(eventId))
  ) {
    issues.push("Packet source_event_ids does not exactly match its materialized context");
  }
  for (const item of packet.trusted_context) {
    const source = eventsById.get(item.event_id);
    if (!source) continue;
    if (source.kind === "frontend_summary") {
      issues.push("Frontend summary was promoted into trusted context");
    }
    if (source.admission.status !== "admitted") {
      issues.push("Non-admitted event was promoted into trusted context: " + item.event_id);
    }
    if (
      source.kind !== item.kind ||
      stableStringify(source.payload) !== stableStringify(item.payload) ||
      stableStringify(source.admission) !== stableStringify(item.admission)
    ) {
      issues.push("Trusted context does not match ledger source: " + item.event_id);
    }
    if (!eventVisibleToRole(source, packet.target_role)) {
      issues.push("Trusted context is not visible to target role: " + item.event_id);
    }
    if (
      source.kind === "knowledge_retrieval" &&
      (source.payload.run_id !== packet.run_id ||
        source.payload.target_role !== packet.target_role ||
        (expected.assignmentId && source.payload.assignment_id !== expected.assignmentId))
    ) {
      issues.push("Knowledge retrieval context is not bound to this packet assignment: " + item.event_id);
    }
  }
  for (const item of packet.untrusted_context_candidates) {
    const source = eventsById.get(item.event_id);
    if (!source) continue;
    if (source.kind === "frontend_summary") {
      issues.push("Frontend summary was placed in untrusted context candidates: " + item.event_id);
    }
    if (source.admission.status !== "candidate") {
      issues.push("Admitted event was demoted into untrusted context candidates: " + item.event_id);
    }
    if (
      source.kind !== item.kind ||
      stableStringify(source.payload) !== stableStringify(item.payload) ||
      stableStringify(source.admission) !== stableStringify(item.admission)
    ) {
      issues.push("Untrusted context candidate does not match ledger source: " + item.event_id);
    }
    if (!eventVisibleToRole(source, packet.target_role)) {
      issues.push("Untrusted context candidate is not visible to target role: " + item.event_id);
    }
  }
  for (const item of packet.untrusted_frontend_notes) {
    const source = eventsById.get(item.event_id);
    if (!source) continue;
    if (source.kind !== "frontend_summary") {
      issues.push("Non-frontend event was placed in untrusted_frontend_notes: " + item.event_id);
    }
    if (source.admission.status !== "candidate") {
      issues.push("Frontend note has an invalid admitted status: " + item.event_id);
    }
    if (stableStringify(source.payload) !== stableStringify(item.payload)) {
      issues.push("Untrusted frontend note does not match ledger source: " + item.event_id);
    }
    if (!eventVisibleToRole(source, packet.target_role)) {
      issues.push("Frontend note is not visible to target role: " + item.event_id);
    }
  }
  const generatedAt = Date.parse(packet.generated_at);
  const expiresAt = Date.parse(packet.expires_at);
  const invalidDates = !Number.isFinite(generatedAt) || !Number.isFinite(expiresAt);
  if (invalidDates) issues.push("Packet timestamps are invalid");
  if (!invalidDates && expiresAt <= generatedAt) issues.push("Packet expiry must follow generation");
  const allowedMaxAge = config.features.external_context.packet_max_age_minutes * 60_000;
  if (!invalidDates && expiresAt - generatedAt > allowedMaxAge + 1_000) {
    issues.push("Packet expiry exceeds configured maximum age");
  }
  const stale = invalidDates || Date.now() >= expiresAt;
  if (stale) issues.push("Packet is stale");
  return { valid: issues.length === 0, stale, issues };
}

export function relativePacketPath(projectRoot: string, packetPath: string): string {
  return relative(resolve(projectRoot), resolve(packetPath)).replaceAll("\\", "/");
}
