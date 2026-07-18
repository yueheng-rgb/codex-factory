import { DatabaseSync } from "node:sqlite";
import { existsSync } from "node:fs";
import { join, relative, resolve } from "node:path";
import { loadConfig } from "./config.js";
import type {
  ContextEvent,
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
}

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
    insert.run("schema_version", "1.1.0");
    insert.run("project_id", config.project_id);
    insert.run("created_at", nowIso());
    insert.run("trust_frontend_summary", "false");
    insert.run("authority", "sqlite_hash_chain_and_verified_artifacts");
    const metadataRows = database
      .prepare("SELECT key, value FROM metadata")
      .all() as unknown as Array<{ key: string; value: string }>;
    const metadata = Object.fromEntries(metadataRows.map((row) => [row.key, row.value]));
    const events = readEventsFromDatabase(database);
    const chain = verifyEvents(events);
    if (!chain.valid) {
      throw new Error(
        "Context ledger is invalid; cannot initialize integrity anchors: " +
          chain.issues.join("; "),
      );
    }
    const hasCount = metadata.expected_event_count !== undefined;
    const hasHead = metadata.expected_head_hash !== undefined;
    if (metadata.schema_version === "1.0.0") {
      if (hasCount !== hasHead) throw new Error("Legacy context anchor metadata is incomplete");
      database.prepare("UPDATE metadata SET value = ? WHERE key = 'schema_version'").run("1.1.0");
      if (!hasCount) {
        insert.run("expected_event_count", String(chain.event_count));
        insert.run("expected_head_hash", chain.head_hash);
      }
    } else if (metadata.schema_version === "1.1.0") {
      if (!schemaBefore && !hasCount && !hasHead && events.length === 0) {
        insert.run("expected_event_count", "0");
        insert.run("expected_head_hash", "GENESIS");
      } else if (!hasCount || !hasHead) {
        throw new Error("Context integrity anchors are missing");
      }
    } else {
      throw new Error("Unsupported context schema version: " + String(metadata.schema_version));
    }
  } finally {
    database.close();
  }
}

function eventFromRow(row: EventRow): ContextEvent {
  return {
    event_id: row.event_id,
    sequence: Number(row.sequence),
    kind: row.kind,
    actor: row.actor,
    created_at: row.created_at,
    payload: JSON.parse(row.payload_json) as Record<string, unknown>,
    previous_hash: row.previous_hash,
    hash: row.hash,
  };
}

function readEventsFromDatabase(database: DatabaseSync): ContextEvent[] {
  const rows = database
    .prepare(
      [
        "SELECT sequence, event_id, kind, actor, created_at,",
        "payload_json, previous_hash, hash",
        "FROM context_events ORDER BY sequence ASC",
      ].join(" "),
    )
    .all() as unknown as EventRow[];
  return rows.map(eventFromRow);
}

export function readContextEvents(projectRoot: string): ContextEvent[] {
  if (!existsSync(contextDatabasePath(projectRoot))) return [];
  const database = openDatabase(projectRoot);
  try {
    installSchema(database);
    return readEventsFromDatabase(database);
  } finally {
    database.close();
  }
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
    event_count: events.length,
    head_hash: events.length > 0 ? previousHash : "GENESIS",
    issues,
  };
}

function verifyAnchorsAndFts(
  database: DatabaseSync,
  events: ContextEvent[],
  result: ContextLedgerVerification,
  expectedProjectId: string,
): void {
  const metadataRows = database
    .prepare("SELECT key, value FROM metadata")
    .all() as unknown as Array<{ key: string; value: string }>;
  const metadata = Object.fromEntries(metadataRows.map((row) => [row.key, row.value]));
  if (metadata.schema_version !== "1.1.0") {
    result.issues.push("Context schema_version must be 1.1.0");
  }
  if (metadata.project_id !== expectedProjectId) {
    result.issues.push("Context project_id metadata mismatch");
  }
  if (metadata.trust_frontend_summary !== "false") {
    result.issues.push("Context trust_frontend_summary metadata must be false");
  }
  if (metadata.authority !== "sqlite_hash_chain_and_verified_artifacts") {
    result.issues.push("Context authority metadata mismatch");
  }
  if (metadata.expected_event_count !== String(result.event_count)) {
    result.issues.push("Context expected_event_count anchor mismatch");
  }
  if (metadata.expected_head_hash !== result.head_hash) {
    result.issues.push("Context expected_head_hash anchor mismatch");
  }
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
  result.valid = result.issues.length === 0;
}

export function verifyContextLedger(projectRoot: string): ContextLedgerVerification {
  if (!existsSync(contextDatabasePath(projectRoot))) {
    return {
      valid: false,
      event_count: 0,
      head_hash: "",
      issues: ["Context database does not exist"],
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
    if (integrity?.integrity_check !== "ok") {
      result.valid = false;
      result.issues.unshift(
        "SQLite integrity check failed: " + String(integrity?.integrity_check),
      );
    }
    return result;
  } catch (error) {
    return {
      valid: false,
      event_count: 0,
      head_hash: "",
      issues: [(error as Error).message],
    };
  } finally {
    database.close();
  }
}

export function appendContextEvent(
  projectRoot: string,
  kind: ContextEventKind,
  actor: string,
  payload: Record<string, unknown>,
): ContextEvent {
  const config = loadConfig(projectRoot);
  if (!config.features.external_context.enabled) {
    throw new Error("External context space is disabled");
  }
  if (!actor.trim()) throw new Error("Context event actor is required");
  initializeContextSpace(projectRoot);

  const database = openDatabase(projectRoot);
  try {
    installSchema(database);
    database.exec("BEGIN IMMEDIATE");
    try {
      const verification = verifyEvents(readEventsFromDatabase(database));
      verifyAnchorsAndFts(
        database,
        readEventsFromDatabase(database),
        verification,
        config.project_id,
      );
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
      };
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
      database
        .prepare("UPDATE metadata SET value = ? WHERE key = 'expected_event_count'")
        .run(String(event.sequence));
      database
        .prepare("UPDATE metadata SET value = ? WHERE key = 'expected_head_hash'")
        .run(event.hash);
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

export function queryContextEvents(
  projectRoot: string,
  query: string,
  limit = 20,
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
          "e.payload_json, e.previous_hash, e.hash",
          "FROM context_events_fts f",
          "JOIN context_events e ON e.event_id = f.event_id",
          "WHERE context_events_fts MATCH ?",
          "ORDER BY bm25(context_events_fts), e.sequence DESC LIMIT ?",
        ].join(" "),
      )
      .all(query, Math.max(1, Math.min(100, limit))) as unknown as EventRow[];
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
  const allEvents = readContextEvents(projectRoot);
  const requestedEvents = allEvents.filter(
    (event) =>
      (!requestedIds || requestedIds.has(event.event_id)) &&
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
    .filter((event) => event.kind !== "frontend_summary")
    .map((event) => ({
      event_id: event.event_id,
      kind: event.kind as Exclude<ContextEventKind, "frontend_summary">,
      payload: event.payload,
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
    packet_version: "1.0.0",
    project_id: config.project_id,
    run_id: runId,
    target_role: targetRole,
    generated_at: generatedAt.toISOString(),
    expires_at: expiresAt.toISOString(),
    ledger_head_hash: verification.head_hash,
    source_event_ids: events.map((event) => event.event_id),
    trusted_context: trusted,
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
  if (packet.packet_version !== "1.0.0") issues.push("Unsupported packet version");
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
  const events = readContextEvents(projectRoot);
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
    if (source.kind !== item.kind || stableStringify(source.payload) !== stableStringify(item.payload)) {
      issues.push("Trusted context does not match ledger source: " + item.event_id);
    }
    if (!eventVisibleToRole(source, packet.target_role)) {
      issues.push("Trusted context is not visible to target role: " + item.event_id);
    }
  }
  for (const item of packet.untrusted_frontend_notes) {
    const source = eventsById.get(item.event_id);
    if (!source) continue;
    if (source.kind !== "frontend_summary") {
      issues.push("Non-frontend event was placed in untrusted_frontend_notes: " + item.event_id);
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
