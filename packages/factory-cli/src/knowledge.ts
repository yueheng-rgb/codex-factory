import { createHash } from "node:crypto";
import {
  existsSync,
  lstatSync,
  readFileSync,
  realpathSync,
  statSync,
} from "node:fs";
import { basename, dirname, extname, relative, resolve } from "node:path";
import { DatabaseSync } from "node:sqlite";
import { contextDatabasePath } from "./context-space.js";
import {
  assertWithinRoot,
  ensureDirectory,
  newId,
  sha256,
  stableStringify,
} from "./util.js";

export interface KnowledgeEntry {
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
  content_hash: string;
}

export interface AddKnowledgeEntryInput {
  entry_id?: string;
  title: string;
  content: string;
  source_uri: string;
  source_sha256: string;
  source_kind: string;
  tags?: string[];
  roles: string[];
  supersedes_id?: string | null;
}

export interface AddKnowledgeEntryOptions {
  idFactory?: () => string;
  now?: () => Date;
}

export interface QueryKnowledgeOptions {
  requestingRole: string;
  limit?: number;
}

export interface ImportKnowledgeFileOptions {
  title?: string;
  sourceKind?: string;
  tags?: string[];
  roles: string[];
  supersedesId?: string | null;
  entryId?: string;
  idFactory?: () => string;
  now?: () => Date;
  maxBytes?: number;
}

export interface KnowledgeStoreVerification {
  valid: boolean;
  entry_count: number;
  fts_entry_count: number;
  issues: string[];
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
  content_hash: string;
}

interface KnowledgeFtsRow {
  entry_id: string;
  title: string;
  content: string;
  tags: string;
}

const REQUIRED_COLUMNS = [
  "entry_id",
  "title",
  "content",
  "source_uri",
  "source_sha256",
  "source_kind",
  "tags",
  "roles",
  "created_at",
  "supersedes_id",
  "content_hash",
] as const;

const FRONTEND_SUMMARY_KINDS = new Set([
  "frontend_summary",
  "frontend-summary",
  "frontend summary",
  "compressed_frontend_summary",
]);

function openDatabase(projectRoot: string): DatabaseSync {
  const path = contextDatabasePath(projectRoot);
  ensureDirectory(dirname(path));
  const database = new DatabaseSync(path);
  database.exec("PRAGMA foreign_keys = ON");
  database.exec("PRAGMA journal_mode = WAL");
  database.exec("PRAGMA busy_timeout = 5000");
  return database;
}

function installSchema(database: DatabaseSync): void {
  database.exec(
    [
      "CREATE TABLE IF NOT EXISTS knowledge_entries (",
      "  entry_id TEXT PRIMARY KEY,",
      "  title TEXT NOT NULL,",
      "  content TEXT NOT NULL,",
      "  source_uri TEXT NOT NULL,",
      "  source_sha256 TEXT NOT NULL,",
      "  source_kind TEXT NOT NULL,",
      "  tags TEXT NOT NULL,",
      "  roles TEXT NOT NULL,",
      "  created_at TEXT NOT NULL,",
      "  supersedes_id TEXT REFERENCES knowledge_entries(entry_id),",
      "  content_hash TEXT NOT NULL UNIQUE,",
      "  UNIQUE(source_uri, source_sha256),",
      "  CHECK(length(source_sha256) = 64),",
      "  CHECK(length(content_hash) = 64),",
      "  CHECK(json_valid(tags) AND json_type(tags) = 'array'),",
      "  CHECK(json_valid(roles) AND json_type(roles) = 'array')",
      ") STRICT;",
      "CREATE TABLE IF NOT EXISTS knowledge_metadata (",
      "  key TEXT PRIMARY KEY,",
      "  value TEXT NOT NULL",
      ") STRICT;",
      "CREATE INDEX IF NOT EXISTS knowledge_entries_created_idx",
      "  ON knowledge_entries(created_at);",
      "CREATE INDEX IF NOT EXISTS knowledge_entries_source_idx",
      "  ON knowledge_entries(source_uri, source_sha256);",
      "CREATE INDEX IF NOT EXISTS knowledge_entries_supersedes_idx",
      "  ON knowledge_entries(supersedes_id);",
      "CREATE VIRTUAL TABLE IF NOT EXISTS knowledge_entries_fts USING fts5(",
      "  entry_id UNINDEXED, title, content, tags",
      ");",
      "INSERT OR IGNORE INTO knowledge_metadata(key, value)",
      "  VALUES ('schema_version', '1.0.0');",
      "INSERT OR IGNORE INTO knowledge_metadata(key, value)",
      "  VALUES ('entry_count', '0');",
      "INSERT OR IGNORE INTO knowledge_metadata(key, value)",
      "  VALUES ('store_root_hash', '4f53cda18c2baa0c0354bb5f9a3ecbe5ed12ab4d8e11ba873c2f11161202b945');",
    ].join("\n"),
  );
}

function normalizeScalar(value: string, field: string): string {
  if (typeof value !== "string") throw new Error(field + " must be a string");
  const normalized = value.normalize("NFKC").trim();
  if (!normalized) throw new Error(field + " is required");
  if (normalized.includes("\u0000")) throw new Error(field + " contains NUL");
  return normalized;
}

function validateContent(value: string): string {
  if (typeof value !== "string") throw new Error("content must be a string");
  if (!value.trim()) throw new Error("content is required");
  if (value.includes("\u0000")) throw new Error("content contains NUL");
  return value;
}

function normalizeList(values: string[], field: string, allowWildcard = false): string[] {
  if (!Array.isArray(values)) throw new Error(field + " must be an array");
  const result = new Set<string>();
  for (const value of values) {
    if (typeof value !== "string") throw new Error(field + " must contain only strings");
    const normalized = normalizeScalar(value, field).toLowerCase();
    if (normalized === "*" && allowWildcard) {
      result.add(normalized);
      continue;
    }
    if (!/^[\p{Letter}\p{Number}][\p{Letter}\p{Number}._:/-]*$/u.test(normalized)) {
      throw new Error("Invalid " + field + " value: " + value);
    }
    result.add(normalized);
  }
  const sorted = [...result].sort((left, right) => left.localeCompare(right));
  if (field === "roles" && sorted.length === 0) {
    throw new Error("roles must contain at least one visible role");
  }
  return sorted;
}

function validateDigest(value: string, field: string): string {
  if (typeof value !== "string") throw new Error(field + " must be a string");
  const normalized = value.trim().toLowerCase();
  if (!/^[a-f0-9]{64}$/.test(normalized)) {
    throw new Error(field + " must be a lowercase SHA-256 digest");
  }
  return normalized;
}

function entryWithoutHash(entry: KnowledgeEntry): Omit<KnowledgeEntry, "content_hash"> {
  const { content_hash: _contentHash, ...unsigned } = entry;
  return unsigned;
}

function calculateEntryHash(entry: KnowledgeEntry): string {
  return sha256(stableStringify(entryWithoutHash(entry)));
}

function parseJsonList(raw: string, field: string): string[] {
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new Error(field + " is not valid JSON");
  }
  if (!Array.isArray(parsed) || parsed.some((item) => typeof item !== "string")) {
    throw new Error(field + " must be a JSON string array");
  }
  return parsed as string[];
}

function entryFromRow(row: KnowledgeRow): KnowledgeEntry {
  return {
    entry_id: row.entry_id,
    title: row.title,
    content: row.content,
    source_uri: row.source_uri,
    source_sha256: row.source_sha256,
    source_kind: row.source_kind,
    tags: parseJsonList(row.tags, "tags"),
    roles: parseJsonList(row.roles, "roles"),
    created_at: row.created_at,
    supersedes_id: row.supersedes_id,
    content_hash: row.content_hash,
  };
}

function readRows(database: DatabaseSync): KnowledgeRow[] {
  return database
    .prepare(
      [
        "SELECT entry_id, title, content, source_uri, source_sha256, source_kind,",
        "tags, roles, created_at, supersedes_id, content_hash",
        "FROM knowledge_entries ORDER BY created_at ASC, entry_id ASC",
      ].join(" "),
    )
    .all() as unknown as KnowledgeRow[];
}

function storeRootHash(rows: KnowledgeRow[]): string {
  return sha256(
    stableStringify(
      rows
        .map((row) => ({ entry_id: row.entry_id, content_hash: row.content_hash }))
        .sort((left, right) => left.entry_id.localeCompare(right.entry_id)),
    ),
  );
}

function updateStoreAnchor(database: DatabaseSync): void {
  const rows = readRows(database);
  const update = database.prepare("UPDATE knowledge_metadata SET value = ? WHERE key = ?");
  const countResult = update.run(String(rows.length), "entry_count");
  const rootResult = update.run(storeRootHash(rows), "store_root_hash");
  if (Number(countResult.changes) !== 1 || Number(rootResult.changes) !== 1) {
    throw new Error("Knowledge metadata anchor is missing");
  }
}

function tableExists(database: DatabaseSync, name: string): boolean {
  return Boolean(
    database
      .prepare("SELECT 1 AS present FROM sqlite_master WHERE name = ? LIMIT 1")
      .get(name),
  );
}

function verifyDatabase(database: DatabaseSync): KnowledgeStoreVerification {
  const issues: string[] = [];
  const integrity = database.prepare("PRAGMA integrity_check").get() as
    | { integrity_check?: string }
    | undefined;
  if (integrity?.integrity_check !== "ok") {
    issues.push("SQLite integrity check failed: " + String(integrity?.integrity_check));
  }

  if (!tableExists(database, "knowledge_entries")) {
    issues.push("knowledge_entries table is missing");
    return { valid: false, entry_count: 0, fts_entry_count: 0, issues };
  }
  if (!tableExists(database, "knowledge_entries_fts")) {
    issues.push("knowledge_entries_fts table is missing");
    return { valid: false, entry_count: 0, fts_entry_count: 0, issues };
  }
  if (!tableExists(database, "knowledge_metadata")) {
    issues.push("knowledge_metadata table is missing");
    return { valid: false, entry_count: 0, fts_entry_count: 0, issues };
  }

  const columns = database.prepare("PRAGMA table_info(knowledge_entries)").all() as unknown as Array<{
    name: string;
  }>;
  const columnNames = new Set(columns.map((column) => column.name));
  const missingColumns = REQUIRED_COLUMNS.filter((column) => !columnNames.has(column));
  if (missingColumns.length > 0) {
    issues.push("Missing knowledge columns: " + missingColumns.join(", "));
    return { valid: false, entry_count: 0, fts_entry_count: 0, issues };
  }

  let rows: KnowledgeRow[] = [];
  let ftsRows: KnowledgeFtsRow[] = [];
  try {
    rows = readRows(database);
    ftsRows = database
      .prepare("SELECT entry_id, title, content, tags FROM knowledge_entries_fts")
      .all() as unknown as KnowledgeFtsRow[];
  } catch (error) {
    issues.push("Knowledge rows cannot be read: " + (error as Error).message);
    return {
      valid: false,
      entry_count: rows.length,
      fts_entry_count: ftsRows.length,
      issues,
    };
  }

  const metadataRows = database
    .prepare(
      "SELECT key, value FROM knowledge_metadata WHERE key IN (?, ?, ?)",
    )
    .all("schema_version", "entry_count", "store_root_hash") as unknown as Array<{
      key: string;
      value: string;
    }>;
  const metadata = new Map(metadataRows.map((row) => [row.key, row.value]));
  if (metadata.get("schema_version") !== "1.0.0") {
    issues.push("Unsupported or missing knowledge schema_version");
  }
  if (metadata.get("entry_count") !== String(rows.length)) {
    issues.push("Knowledge entry_count anchor mismatch");
  }
  if (metadata.get("store_root_hash") !== storeRootHash(rows)) {
    issues.push("Knowledge store_root_hash anchor mismatch");
  }

  const ids = new Set<string>();
  const hashes = new Set<string>();
  const sourceIdentities = new Set<string>();
  const parsedEntries = new Map<string, KnowledgeEntry>();
  for (const row of rows) {
    try {
      const entry = entryFromRow(row);
      parsedEntries.set(entry.entry_id, entry);
      if (ids.has(entry.entry_id)) issues.push("Duplicate entry_id: " + entry.entry_id);
      ids.add(entry.entry_id);
      if (hashes.has(entry.content_hash)) {
        issues.push("Duplicate content_hash: " + entry.content_hash);
      }
      hashes.add(entry.content_hash);
      const sourceIdentity = entry.source_uri + "\u0000" + entry.source_sha256;
      if (sourceIdentities.has(sourceIdentity)) {
        issues.push("Duplicate source identity: " + entry.source_uri);
      }
      sourceIdentities.add(sourceIdentity);

      normalizeScalar(entry.entry_id, "entry_id");
      normalizeScalar(entry.title, "title");
      validateContent(entry.content);
      const normalizedSourceUri = normalizeScalar(entry.source_uri, "source_uri");
      if (/^frontend[-_ ]summary:/i.test(normalizedSourceUri)) {
        issues.push("Frontend summary source URI is forbidden: " + entry.entry_id);
      }
      validateDigest(entry.source_sha256, "source_sha256");
      validateDigest(entry.content_hash, "content_hash");
      const normalizedTags = normalizeList(entry.tags, "tags");
      const normalizedRoles = normalizeList(entry.roles, "roles", true);
      if (stableStringify(normalizedTags) !== stableStringify(entry.tags)) {
        issues.push("Non-canonical tags for " + entry.entry_id);
      }
      if (stableStringify(normalizedRoles) !== stableStringify(entry.roles)) {
        issues.push("Non-canonical roles for " + entry.entry_id);
      }
      if (FRONTEND_SUMMARY_KINDS.has(entry.source_kind.trim().toLowerCase())) {
        issues.push("Frontend summary source is forbidden: " + entry.entry_id);
      }
      if (!/^[a-z0-9][a-z0-9._-]*$/.test(entry.source_kind)) {
        issues.push("Invalid source_kind for " + entry.entry_id);
      }
      if (!Number.isFinite(Date.parse(entry.created_at))) {
        issues.push("Invalid created_at for " + entry.entry_id);
      }
      if (entry.content_hash !== calculateEntryHash(entry)) {
        issues.push("Content hash mismatch for " + entry.entry_id);
      }
    } catch (error) {
      issues.push("Invalid knowledge entry " + row.entry_id + ": " + (error as Error).message);
    }
  }

  for (const entry of parsedEntries.values()) {
    if (entry.supersedes_id === entry.entry_id) {
      issues.push("Entry cannot supersede itself: " + entry.entry_id);
    } else if (entry.supersedes_id && !parsedEntries.has(entry.supersedes_id)) {
      issues.push(
        "Missing superseded entry for " + entry.entry_id + ": " + entry.supersedes_id,
      );
    }
    const visited = new Set<string>([entry.entry_id]);
    let cursor = entry.supersedes_id;
    while (cursor) {
      if (visited.has(cursor)) {
        issues.push("Supersedes cycle detected at " + entry.entry_id);
        break;
      }
      visited.add(cursor);
      cursor = parsedEntries.get(cursor)?.supersedes_id ?? null;
    }
  }

  const ftsById = new Map<string, KnowledgeFtsRow[]>();
  for (const ftsRow of ftsRows) {
    const current = ftsById.get(ftsRow.entry_id) ?? [];
    current.push(ftsRow);
    ftsById.set(ftsRow.entry_id, current);
  }
  for (const entry of parsedEntries.values()) {
    const matches = ftsById.get(entry.entry_id) ?? [];
    if (matches.length !== 1) {
      issues.push(
        "Expected exactly one FTS row for " + entry.entry_id + ", found " + matches.length,
      );
      continue;
    }
    const fts = matches[0];
    if (
      fts.title !== entry.title ||
      fts.content !== entry.content ||
      fts.tags !== entry.tags.join(" ")
    ) {
      issues.push("FTS row mismatch for " + entry.entry_id);
    }
  }
  for (const entryId of ftsById.keys()) {
    if (!parsedEntries.has(entryId)) issues.push("Orphan FTS row: " + entryId);
  }

  return {
    valid: issues.length === 0,
    entry_count: rows.length,
    fts_entry_count: ftsRows.length,
    issues,
  };
}

function assertValidStore(database: DatabaseSync, action: string): void {
  const verification = verifyDatabase(database);
  if (!verification.valid) {
    throw new Error(
      "Knowledge store is invalid; refusing " + action + ": " + verification.issues.join("; "),
    );
  }
}

function createEntry(
  input: AddKnowledgeEntryInput,
  options: AddKnowledgeEntryOptions,
): KnowledgeEntry {
  const sourceKind = normalizeScalar(input.source_kind, "source_kind").toLowerCase();
  if (FRONTEND_SUMMARY_KINDS.has(sourceKind)) {
    throw new Error("Frontend summaries cannot be promoted into the knowledge store");
  }
  if (!/^[a-z0-9][a-z0-9._-]*$/.test(sourceKind)) {
    throw new Error("Invalid source_kind: " + input.source_kind);
  }
  const sourceUri = normalizeScalar(input.source_uri, "source_uri");
  if (/^frontend[-_ ]summary:/i.test(sourceUri)) {
    throw new Error("Frontend summaries cannot be promoted into the knowledge store");
  }
  const createdAt = (options.now?.() ?? new Date()).toISOString();
  const entry: KnowledgeEntry = {
    entry_id: normalizeScalar(
      input.entry_id ?? options.idFactory?.() ?? newId("knowledge"),
      "entry_id",
    ),
    title: normalizeScalar(input.title, "title"),
    content: validateContent(input.content),
    source_uri: sourceUri,
    source_sha256: validateDigest(input.source_sha256, "source_sha256"),
    source_kind: sourceKind,
    tags: normalizeList(input.tags ?? [], "tags"),
    roles: normalizeList(input.roles, "roles", true),
    created_at: createdAt,
    supersedes_id: input.supersedes_id
      ? normalizeScalar(input.supersedes_id, "supersedes_id")
      : null,
    content_hash: "",
  };
  entry.content_hash = calculateEntryHash(entry);
  return entry;
}

export function addKnowledgeEntry(
  projectRoot: string,
  input: AddKnowledgeEntryInput,
  options: AddKnowledgeEntryOptions = {},
): KnowledgeEntry {
  const database = openDatabase(projectRoot);
  try {
    installSchema(database);
    database.exec("BEGIN IMMEDIATE");
    try {
      assertValidStore(database, "knowledge write");
      const entry = createEntry(input, options);
      if (entry.supersedes_id) {
        const superseded = database
          .prepare("SELECT entry_id FROM knowledge_entries WHERE entry_id = ?")
          .get(entry.supersedes_id);
        if (!superseded) {
          throw new Error("supersedes_id does not exist: " + entry.supersedes_id);
        }
      }
      const duplicateId = database
        .prepare("SELECT entry_id FROM knowledge_entries WHERE entry_id = ?")
        .get(entry.entry_id);
      if (duplicateId) throw new Error("Duplicate knowledge entry_id: " + entry.entry_id);
      const duplicateSource = database
        .prepare(
          "SELECT entry_id FROM knowledge_entries WHERE source_uri = ? AND source_sha256 = ?",
        )
        .get(entry.source_uri, entry.source_sha256) as { entry_id?: string } | undefined;
      if (duplicateSource?.entry_id) {
        throw new Error(
          "Duplicate knowledge source revision already stored as " + duplicateSource.entry_id,
        );
      }
      const duplicateHash = database
        .prepare("SELECT entry_id FROM knowledge_entries WHERE content_hash = ?")
        .get(entry.content_hash) as { entry_id?: string } | undefined;
      if (duplicateHash?.entry_id) {
        throw new Error("Duplicate knowledge entry already stored as " + duplicateHash.entry_id);
      }

      database
        .prepare(
          [
            "INSERT INTO knowledge_entries(",
            "entry_id, title, content, source_uri, source_sha256, source_kind,",
            "tags, roles, created_at, supersedes_id, content_hash",
            ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
          ].join(" "),
        )
        .run(
          entry.entry_id,
          entry.title,
          entry.content,
          entry.source_uri,
          entry.source_sha256,
          entry.source_kind,
          stableStringify(entry.tags),
          stableStringify(entry.roles),
          entry.created_at,
          entry.supersedes_id,
          entry.content_hash,
        );
      database
        .prepare(
          "INSERT INTO knowledge_entries_fts(entry_id, title, content, tags) VALUES (?, ?, ?, ?)",
        )
        .run(entry.entry_id, entry.title, entry.content, entry.tags.join(" "));
      updateStoreAnchor(database);
      assertValidStore(database, "knowledge commit");
      database.exec("COMMIT");
      return entry;
    } catch (error) {
      database.exec("ROLLBACK");
      throw error;
    }
  } finally {
    database.close();
  }
}

function ftsExpression(query: string): string | undefined {
  const terms = query.normalize("NFKC").match(/[\p{Letter}\p{Number}_:/.-]+/gu) ?? [];
  const normalized = [...new Set(terms.map((term) => term.trim()).filter(Boolean))];
  if (normalized.length === 0) return undefined;
  return normalized
    .map((term) => '"' + term.replaceAll('"', '""') + '"')
    .join(" AND ");
}

export function queryKnowledge(
  projectRoot: string,
  query: string,
  options: QueryKnowledgeOptions,
): KnowledgeEntry[] {
  const role = normalizeList([options.requestingRole], "roles", true)[0];
  const expression = ftsExpression(query);
  if (!expression) return [];
  const limit = Math.max(1, Math.min(100, options.limit ?? 20));
  if (!existsSync(contextDatabasePath(projectRoot))) return [];

  const database = openDatabase(projectRoot);
  try {
    if (!tableExists(database, "knowledge_entries")) return [];
    assertValidStore(database, "knowledge query");
    const rows = database
      .prepare(
        [
          "SELECT e.entry_id, e.title, e.content, e.source_uri, e.source_sha256,",
          "e.source_kind, e.tags, e.roles, e.created_at, e.supersedes_id, e.content_hash",
          "FROM knowledge_entries_fts f",
          "JOIN knowledge_entries e ON e.entry_id = f.entry_id",
          "WHERE knowledge_entries_fts MATCH ?",
          "AND EXISTS (",
          "  SELECT 1 FROM json_each(e.roles) audience",
          "  WHERE audience.value = ? OR audience.value = '*'",
          ")",
          "ORDER BY bm25(knowledge_entries_fts), e.created_at DESC, e.entry_id ASC",
          "LIMIT ?",
        ].join(" "),
      )
      .all(expression, role, limit) as unknown as KnowledgeRow[];
    return rows.map(entryFromRow);
  } finally {
    database.close();
  }
}

export function verifyKnowledgeStore(projectRoot: string): KnowledgeStoreVerification {
  if (!existsSync(contextDatabasePath(projectRoot))) {
    return {
      valid: false,
      entry_count: 0,
      fts_entry_count: 0,
      issues: ["Context database does not exist"],
    };
  }
  const database = openDatabase(projectRoot);
  try {
    return verifyDatabase(database);
  } catch (error) {
    return {
      valid: false,
      entry_count: 0,
      fts_entry_count: 0,
      issues: [(error as Error).message],
    };
  } finally {
    database.close();
  }
}

function safeProjectFile(projectRoot: string, inputPath: string): string {
  const lexicalPath = assertWithinRoot(projectRoot, resolve(projectRoot, inputPath));
  if (!existsSync(lexicalPath)) throw new Error("Knowledge source file does not exist: " + inputPath);
  if (!lstatSync(lexicalPath).isFile() && !lstatSync(lexicalPath).isSymbolicLink()) {
    throw new Error("Knowledge source must be a file: " + inputPath);
  }
  const realRoot = realpathSync(resolve(projectRoot));
  const realFile = realpathSync(lexicalPath);
  assertWithinRoot(realRoot, realFile);
  if (!lstatSync(realFile).isFile()) {
    throw new Error("Knowledge source must resolve to a regular file: " + inputPath);
  }
  return realFile;
}

export function importKnowledgeFile(
  projectRoot: string,
  inputPath: string,
  options: ImportKnowledgeFileOptions,
): KnowledgeEntry {
  const filePath = safeProjectFile(projectRoot, inputPath);
  const configuredMaxBytes = options.maxBytes ?? 5 * 1024 * 1024;
  if (!Number.isSafeInteger(configuredMaxBytes) || configuredMaxBytes < 1) {
    throw new Error("maxBytes must be a positive safe integer");
  }
  const maxBytes = configuredMaxBytes;
  const sourceSize = statSync(filePath).size;
  if (sourceSize > maxBytes) {
    throw new Error(
      "Knowledge source exceeds maxBytes (" + sourceSize + " > " + maxBytes + ")",
    );
  }
  const bytes = readFileSync(filePath);
  if (bytes.includes(0)) throw new Error("Knowledge source appears to be binary");
  let decoded: string;
  try {
    decoded = new TextDecoder("utf-8", { fatal: true }).decode(bytes);
  } catch {
    throw new Error("Knowledge source must be valid UTF-8 text");
  }
  const realRoot = realpathSync(resolve(projectRoot));
  const sourceUri = relative(realRoot, filePath).replaceAll("\\", "/");
  const inferredKind = extname(filePath).slice(1).toLowerCase();
  const sourceSha256 = createHash("sha256").update(bytes).digest("hex");
  return addKnowledgeEntry(
    projectRoot,
    {
      entry_id: options.entryId,
      title: options.title ?? basename(filePath),
      content: decoded,
      source_uri: sourceUri,
      source_sha256: sourceSha256,
      source_kind: options.sourceKind ?? (inferredKind ? "project_" + inferredKind : "project_file"),
      tags: options.tags,
      roles: options.roles,
      supersedes_id: options.supersedesId,
    },
    { idFactory: options.idFactory, now: options.now },
  );
}

// Kept local to this module so CLI integrations can initialize through a write/import,
// while verification remains a read-only signal when no knowledge schema exists yet.
export function initializeKnowledgeStore(projectRoot: string): void {
  const database = openDatabase(projectRoot);
  try {
    installSchema(database);
  } finally {
    database.close();
  }
}
