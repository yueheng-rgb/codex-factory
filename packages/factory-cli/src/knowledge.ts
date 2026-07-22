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
  status: KnowledgeEntryStatus;
  source_binding: KnowledgeSourceBinding;
  content_digest: string;
  content_hash: string;
}

export type KnowledgeEntryStatus = "active" | "retired" | "revoked";
export type KnowledgeSourceBinding = "project_file" | "uri_claim";

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
  status?: KnowledgeEntryStatus;
}

export interface AddKnowledgeEntryOptions {
  idFactory?: () => string;
  now?: () => Date;
}

export interface QueryKnowledgeOptions {
  requestingRole: string;
  limit?: number;
  sourceBoundOnly?: boolean;
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
  search_entry_count: number;
  schema_version?: string;
  store_root_hash?: string;
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
  status: string;
  source_binding: string;
  content_digest: string;
  content_hash: string;
}

interface KnowledgeFtsRow {
  entry_id: string;
  title: string;
  content: string;
  tags: string;
}

interface KnowledgeSearchRow {
  entry_id: string;
  normalized_text: string;
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
  "status",
  "source_binding",
  "content_digest",
  "content_hash",
] as const;

const LEGACY_REQUIRED_COLUMNS = REQUIRED_COLUMNS.filter(
  (column) => !["status", "source_binding", "content_digest"].includes(column),
);
const KNOWLEDGE_SCHEMA_VERSION = "1.1.0";
const LEGACY_KNOWLEDGE_SCHEMA_VERSION = "1.0.0";
const KNOWLEDGE_STATUSES = new Set<KnowledgeEntryStatus>([
  "active",
  "retired",
  "revoked",
]);
const SOURCE_BINDINGS = new Set<KnowledgeSourceBinding>(["project_file", "uri_claim"]);

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

function installSchema(database: DatabaseSync, projectRoot: string): void {
  if (tableExists(database, "knowledge_entries")) {
    migrateLegacySchema(database, projectRoot);
    return;
  }
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
      "  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'retired', 'revoked')),",
      "  source_binding TEXT NOT NULL DEFAULT 'uri_claim' CHECK(source_binding IN ('project_file', 'uri_claim')),",
      "  content_digest TEXT NOT NULL CHECK(length(content_digest) = 64),",
      "  content_hash TEXT NOT NULL UNIQUE,",
      "  UNIQUE(source_uri, source_sha256),",
      "  UNIQUE(content_digest),",
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
      "CREATE TABLE IF NOT EXISTS knowledge_search (",
      "  entry_id TEXT PRIMARY KEY REFERENCES knowledge_entries(entry_id),",
      "  normalized_text TEXT NOT NULL",
      ") STRICT;",
      "INSERT OR IGNORE INTO knowledge_metadata(key, value)",
      "  VALUES ('schema_version', '" + KNOWLEDGE_SCHEMA_VERSION + "');",
      "INSERT OR IGNORE INTO knowledge_metadata(key, value)",
      "  VALUES ('entry_count', '0');",
      "INSERT OR IGNORE INTO knowledge_metadata(key, value)",
      "  VALUES ('store_root_hash', '4f53cda18c2baa0c0354bb5f9a3ecbe5ed12ab4d8e11ba873c2f11161202b945');",
    ].join("\n"),
  );
  database.exec(
    [
      "CREATE INDEX IF NOT EXISTS knowledge_entries_status_idx",
      "  ON knowledge_entries(status, created_at);",
      "CREATE UNIQUE INDEX IF NOT EXISTS knowledge_entries_content_digest_idx",
      "  ON knowledge_entries(content_digest);",
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

function normalizeContent(value: string): string {
  return value
    .normalize("NFKC")
    .replaceAll("\r\n", "\n")
    .replaceAll("\r", "\n")
    .split("\n")
    .map((line) => line.replace(/[\t ]+$/u, ""))
    .join("\n")
    .trim();
}

function calculateContentDigest(value: string): string {
  return sha256(normalizeContent(value));
}

function normalizeSearchText(...values: string[]): string {
  return values
    .join("\n")
    .normalize("NFKC")
    .toLocaleLowerCase("und")
    .replace(/\s+/gu, " ")
    .trim();
}

function searchTextForEntry(entry: KnowledgeEntry): string {
  return normalizeSearchText(entry.title, entry.content, entry.tags.join(" "));
}

const SECRET_PATTERNS: Array<{ label: string; pattern: RegExp }> = [
  { label: "private key material", pattern: /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/u },
  { label: "OpenAI-style API key", pattern: /\bsk-[A-Za-z0-9_-]{20,}\b/u },
  { label: "GitHub token", pattern: /\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{20,}\b/u },
  { label: "GitHub fine-grained token", pattern: /\bgithub_pat_[A-Za-z0-9_]{20,}\b/u },
  { label: "AWS access key", pattern: /\bAKIA[A-Z0-9]{16}\b/u },
  { label: "Google API key", pattern: /\bAIza[A-Za-z0-9_-]{30,}\b/u },
  { label: "Slack token", pattern: /\bxox[baprs]-[A-Za-z0-9-]{10,}\b/u },
  {
    label: "bearer credential",
    pattern: /\bauthorization\b\s*[:=]\s*["']?Bearer\s+[A-Za-z0-9._~+/-]{16,}/iu,
  },
  {
    label: "JSON web token",
    pattern: /\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b/u,
  },
  {
    label: "credential assignment",
    pattern:
      /\b(?:api[_-]?key|access[_-]?token|auth[_-]?token|client[_-]?secret|password|passwd|private[_-]?key)\b\s*[:=]\s*["']?(?!<|\$\{|example|placeholder|redacted|your[-_ ])[A-Za-z0-9+/_=-]{16,}["']?/iu,
  },
];

function assertNoSecrets(value: string, location: string): void {
  const match = SECRET_PATTERNS.find(({ pattern }) => pattern.test(value));
  if (match) {
    throw new Error(
      "Potential secret detected (" + match.label + ") in " + location + "; refusing knowledge admission",
    );
  }
}

function assertSafeKnowledgeSourcePath(sourceUri: string): void {
  const normalized = sourceUri.replaceAll("\\", "/").toLowerCase();
  const leaf = normalized.split("/").at(-1) ?? "";
  if (
    normalized === ".env" ||
    leaf === ".env" ||
    leaf.startsWith(".env.") ||
    leaf.endsWith(".env") ||
    leaf.endsWith(".pem") ||
    leaf.endsWith(".key") ||
    leaf.endsWith(".p12") ||
    leaf.endsWith(".pfx") ||
    /^(?:id_rsa|id_ed25519|id_ecdsa)(?:\.|$)/u.test(leaf) ||
    /^(?:secrets?|credentials?)(?:\.|$)/u.test(leaf) ||
    normalized.includes("/.codex-factory/secrets.") ||
    normalized.startsWith(".codex-factory/secrets.")
  ) {
    throw new Error("Sensitive credential file cannot be imported as knowledge: " + sourceUri);
  }
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

function validateStatus(value: string): KnowledgeEntryStatus {
  const normalized = normalizeScalar(value, "status").toLowerCase() as KnowledgeEntryStatus;
  if (!KNOWLEDGE_STATUSES.has(normalized)) {
    throw new Error("Invalid knowledge status: " + value);
  }
  return normalized;
}

function validateSourceBinding(value: string): KnowledgeSourceBinding {
  const normalized = normalizeScalar(
    value,
    "source_binding",
  ).toLowerCase() as KnowledgeSourceBinding;
  if (!SOURCE_BINDINGS.has(normalized)) {
    throw new Error("Invalid knowledge source_binding: " + value);
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

function calculateLegacyEntryHash(entry: KnowledgeEntry): string {
  return sha256(
    stableStringify({
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
    }),
  );
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
    status: validateStatus(row.status),
    source_binding: validateSourceBinding(row.source_binding),
    content_digest: validateDigest(row.content_digest, "content_digest"),
    content_hash: row.content_hash,
  };
}

function readRows(database: DatabaseSync, legacy = false): KnowledgeRow[] {
  return database
    .prepare(
      [
        "SELECT entry_id, title, content, source_uri, source_sha256, source_kind,",
        "tags, roles, created_at, supersedes_id,",
        legacy
          ? "'active' AS status, 'uri_claim' AS source_binding, lower(hex(zeroblob(32))) AS content_digest,"
          : "status, source_binding, content_digest,",
        "content_hash",
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

function assertEntryMatchesProjectFile(
  projectRoot: string,
  entry: KnowledgeEntry,
): void {
  assertSafeKnowledgeSourcePath(entry.source_uri);
  const filePath = safeProjectFile(projectRoot, entry.source_uri);
  const bytes = readFileSync(filePath);
  if (bytes.includes(0)) throw new Error("Knowledge source appears to be binary");
  let decoded: string;
  try {
    decoded = new TextDecoder("utf-8", { fatal: true }).decode(bytes);
  } catch {
    throw new Error("Knowledge source must be valid UTF-8 text");
  }
  assertNoSecrets(decoded, "knowledge source file");
  const currentDigest = createHash("sha256").update(bytes).digest("hex");
  if (currentDigest !== entry.source_sha256) {
    throw new Error("Project source digest mismatch");
  }
  if (decoded !== entry.content) {
    throw new Error("Project source content does not match the stored knowledge content");
  }
}

function migratedSourceBinding(
  projectRoot: string,
  entry: KnowledgeEntry,
): KnowledgeSourceBinding {
  try {
    assertEntryMatchesProjectFile(projectRoot, entry);
    return "project_file";
  } catch {
    return "uri_claim";
  }
}

function migrateLegacySchema(database: DatabaseSync, projectRoot: string): void {
  const columns = database.prepare("PRAGMA table_info(knowledge_entries)").all() as unknown as Array<{
    name: string;
  }>;
  const columnNames = new Set(columns.map((column) => column.name));
  const lifecycleColumns = ["status", "source_binding", "content_digest"];
  const presentLifecycleColumns = lifecycleColumns.filter((column) => columnNames.has(column));
  if (presentLifecycleColumns.length === lifecycleColumns.length) return;
  if (presentLifecycleColumns.length !== 0) {
    throw new Error(
      "Partial knowledge lifecycle migration detected; refusing to modify the store",
    );
  }
  if (tableExists(database, "knowledge_search")) {
    throw new Error("Unexpected knowledge_search table in legacy schema; refusing migration");
  }

  const verification = verifyDatabase(database, projectRoot, true);
  if (!verification.valid) {
    throw new Error(
      "Legacy knowledge store is invalid; refusing migration: " +
        verification.issues.join("; "),
    );
  }
  const legacyRows = readRows(database, true);
  const migratedEntries = legacyRows.map((row) => {
    const legacyEntry = entryFromRow(row);
    const migrated: KnowledgeEntry = {
      ...legacyEntry,
      status: "active",
      source_binding: migratedSourceBinding(projectRoot, legacyEntry),
      content_digest: calculateContentDigest(legacyEntry.content),
      content_hash: "",
    };
    migrated.content_hash = calculateEntryHash(migrated);
    return migrated;
  });
  const digestOwners = new Map<string, string>();
  for (const entry of migratedEntries) {
    const owner = digestOwners.get(entry.content_digest);
    if (owner) {
      throw new Error(
        "Legacy knowledge store contains normalized duplicate content in " +
          owner +
          " and " +
          entry.entry_id,
      );
    }
    digestOwners.set(entry.content_digest, entry.entry_id);
  }

  database.exec("BEGIN IMMEDIATE");
  try {
    database.exec(
      [
        "ALTER TABLE knowledge_entries ADD COLUMN status TEXT NOT NULL DEFAULT 'active'",
        "  CHECK(status IN ('active', 'retired', 'revoked'));",
        "ALTER TABLE knowledge_entries ADD COLUMN source_binding TEXT NOT NULL DEFAULT 'uri_claim'",
        "  CHECK(source_binding IN ('project_file', 'uri_claim'));",
        "ALTER TABLE knowledge_entries ADD COLUMN content_digest TEXT NOT NULL",
        "  DEFAULT '0000000000000000000000000000000000000000000000000000000000000000';",
      ].join("\n"),
    );
    const update = database.prepare(
      "UPDATE knowledge_entries SET status = ?, source_binding = ?, content_digest = ?, content_hash = ? WHERE entry_id = ?",
    );
    const temporaryHash = database.prepare(
      "UPDATE knowledge_entries SET content_hash = ? WHERE entry_id = ?",
    );
    for (const entry of migratedEntries) {
      temporaryHash.run(
        sha256("knowledge-v1.1-migration\u0000" + entry.entry_id + "\u0000" + entry.content_hash),
        entry.entry_id,
      );
    }
    for (const entry of migratedEntries) {
      update.run(
        entry.status,
        entry.source_binding,
        entry.content_digest,
        entry.content_hash,
        entry.entry_id,
      );
    }
    database.exec(
      [
        "CREATE TABLE knowledge_search (",
        "  entry_id TEXT PRIMARY KEY REFERENCES knowledge_entries(entry_id),",
        "  normalized_text TEXT NOT NULL",
        ") STRICT;",
        "CREATE INDEX knowledge_entries_status_idx",
        "  ON knowledge_entries(status, created_at);",
        "CREATE UNIQUE INDEX knowledge_entries_content_digest_idx",
        "  ON knowledge_entries(content_digest);",
      ].join("\n"),
    );
    const insertSearch = database.prepare(
      "INSERT INTO knowledge_search(entry_id, normalized_text) VALUES (?, ?)",
    );
    for (const entry of migratedEntries) {
      insertSearch.run(entry.entry_id, searchTextForEntry(entry));
    }
    const versionUpdate = database
      .prepare("UPDATE knowledge_metadata SET value = ? WHERE key = 'schema_version'")
      .run(KNOWLEDGE_SCHEMA_VERSION);
    if (Number(versionUpdate.changes) !== 1) {
      throw new Error("Knowledge schema_version anchor is missing");
    }
    updateStoreAnchor(database);
    const migratedVerification = verifyDatabase(database, projectRoot);
    if (!migratedVerification.valid) {
      throw new Error(
        "Migrated knowledge store failed verification: " +
          migratedVerification.issues.join("; "),
      );
    }
    database.exec("COMMIT");
  } catch (error) {
    database.exec("ROLLBACK");
    throw error;
  }
}

function verifyDatabase(
  database: DatabaseSync,
  projectRoot: string,
  allowLegacy = false,
  skipActiveSourceValidation = false,
): KnowledgeStoreVerification {
  const issues: string[] = [];
  const emptyResult = (): KnowledgeStoreVerification => ({
    valid: false,
    entry_count: 0,
    fts_entry_count: 0,
    search_entry_count: 0,
    issues,
  });
  const integrity = database.prepare("PRAGMA integrity_check").get() as
    | { integrity_check?: string }
    | undefined;
  if (integrity?.integrity_check !== "ok") {
    issues.push("SQLite integrity check failed: " + String(integrity?.integrity_check));
  }

  if (!tableExists(database, "knowledge_entries")) {
    issues.push("knowledge_entries table is missing");
    return emptyResult();
  }
  if (!tableExists(database, "knowledge_entries_fts")) {
    issues.push("knowledge_entries_fts table is missing");
    return emptyResult();
  }
  if (!tableExists(database, "knowledge_metadata")) {
    issues.push("knowledge_metadata table is missing");
    return emptyResult();
  }

  const columns = database.prepare("PRAGMA table_info(knowledge_entries)").all() as unknown as Array<{
    name: string;
  }>;
  const columnNames = new Set(columns.map((column) => column.name));
  const missingLegacyColumns = LEGACY_REQUIRED_COLUMNS.filter(
    (column) => !columnNames.has(column),
  );
  if (missingLegacyColumns.length > 0) {
    issues.push("Missing knowledge columns: " + missingLegacyColumns.join(", "));
    return emptyResult();
  }
  const legacy = ["status", "source_binding", "content_digest"].some(
    (column) => !columnNames.has(column),
  );
  if (legacy && !allowLegacy) {
    issues.push("Legacy knowledge schema requires verified migration");
    return emptyResult();
  }
  if (!legacy && !tableExists(database, "knowledge_search")) {
    issues.push("knowledge_search table is missing");
    return emptyResult();
  }

  let rows: KnowledgeRow[] = [];
  let ftsRows: KnowledgeFtsRow[] = [];
  let searchRows: KnowledgeSearchRow[] = [];
  try {
    rows = readRows(database, legacy);
    ftsRows = database
      .prepare("SELECT entry_id, title, content, tags FROM knowledge_entries_fts")
      .all() as unknown as KnowledgeFtsRow[];
    if (!legacy) {
      searchRows = database
        .prepare("SELECT entry_id, normalized_text FROM knowledge_search")
        .all() as unknown as KnowledgeSearchRow[];
    }
  } catch (error) {
    issues.push("Knowledge rows cannot be read: " + (error as Error).message);
    return {
      valid: false,
      entry_count: rows.length,
      fts_entry_count: ftsRows.length,
      search_entry_count: searchRows.length,
      issues,
    };
  }

  const metadataRows = database
    .prepare("SELECT key, value FROM knowledge_metadata WHERE key IN (?, ?, ?)")
    .all("schema_version", "entry_count", "store_root_hash") as unknown as Array<{
      key: string;
      value: string;
    }>;
  const metadata = new Map(metadataRows.map((row) => [row.key, row.value]));
  const schemaVersion = metadata.get("schema_version");
  const anchoredRootHash = metadata.get("store_root_hash");
  const expectedVersion = legacy
    ? LEGACY_KNOWLEDGE_SCHEMA_VERSION
    : KNOWLEDGE_SCHEMA_VERSION;
  if (schemaVersion !== expectedVersion) {
    issues.push("Unsupported or missing knowledge schema_version");
  }
  if (metadata.get("entry_count") !== String(rows.length)) {
    issues.push("Knowledge entry_count anchor mismatch");
  }
  if (anchoredRootHash !== storeRootHash(rows)) {
    issues.push("Knowledge store_root_hash anchor mismatch");
  }

  const ids = new Set<string>();
  const hashes = new Set<string>();
  const contentDigests = new Set<string>();
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
      if (!legacy) {
        if (contentDigests.has(entry.content_digest)) {
          issues.push("Duplicate normalized content digest: " + entry.content_digest);
        }
        contentDigests.add(entry.content_digest);
      }
      const sourceIdentity = entry.source_uri + "\u0000" + entry.source_sha256;
      if (sourceIdentities.has(sourceIdentity)) {
        issues.push("Duplicate source identity: " + entry.source_uri);
      }
      sourceIdentities.add(sourceIdentity);

      normalizeScalar(entry.entry_id, "entry_id");
      normalizeScalar(entry.title, "title");
      validateContent(entry.content);
      assertNoSecrets(entry.content, "knowledge entry " + entry.entry_id);
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
      if (!legacy && entry.content_digest !== calculateContentDigest(entry.content)) {
        issues.push("Normalized content digest mismatch for " + entry.entry_id);
      }
      const expectedHash = legacy
        ? calculateLegacyEntryHash(entry)
        : calculateEntryHash(entry);
      if (entry.content_hash !== expectedHash) {
        issues.push("Content hash mismatch for " + entry.entry_id);
      }
      if (
        !legacy &&
        !skipActiveSourceValidation &&
        entry.status === "active" &&
        entry.source_binding === "project_file"
      ) {
        try {
          assertEntryMatchesProjectFile(projectRoot, entry);
        } catch (error) {
          const message = (error as Error).message;
          if (message === "Project source digest mismatch") {
            issues.push("Project source digest mismatch for " + entry.entry_id);
          } else {
            issues.push(
              "Project source is unavailable for " + entry.entry_id + ": " + message,
            );
          }
        }
      }
    } catch (error) {
      issues.push("Invalid knowledge entry " + row.entry_id + ": " + (error as Error).message);
    }
  }

  const activeSuccessors = new Map<string, string[]>();
  for (const entry of parsedEntries.values()) {
    if (entry.supersedes_id === entry.entry_id) {
      issues.push("Entry cannot supersede itself: " + entry.entry_id);
    } else if (entry.supersedes_id && !parsedEntries.has(entry.supersedes_id)) {
      issues.push(
        "Missing superseded entry for " + entry.entry_id + ": " + entry.supersedes_id,
      );
    } else if (entry.supersedes_id) {
      const superseded = parsedEntries.get(entry.supersedes_id)!;
      if (Date.parse(entry.created_at) < Date.parse(superseded.created_at)) {
        issues.push("Superseding entry is older than its target: " + entry.entry_id);
      }
      if (entry.status === "active") {
        const current = activeSuccessors.get(entry.supersedes_id) ?? [];
        current.push(entry.entry_id);
        activeSuccessors.set(entry.supersedes_id, current);
      }
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
  for (const [entryId, successors] of activeSuccessors) {
    if (successors.length > 1) {
      issues.push("Multiple active successors for " + entryId + ": " + successors.join(", "));
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

  if (!legacy) {
    const searchById = new Map<string, KnowledgeSearchRow[]>();
    for (const searchRow of searchRows) {
      const current = searchById.get(searchRow.entry_id) ?? [];
      current.push(searchRow);
      searchById.set(searchRow.entry_id, current);
    }
    for (const entry of parsedEntries.values()) {
      const matches = searchById.get(entry.entry_id) ?? [];
      if (matches.length !== 1) {
        issues.push(
          "Expected exactly one search row for " + entry.entry_id + ", found " + matches.length,
        );
      } else if (matches[0].normalized_text !== searchTextForEntry(entry)) {
        issues.push("Normalized search row mismatch for " + entry.entry_id);
      }
    }
    for (const entryId of searchById.keys()) {
      if (!parsedEntries.has(entryId)) issues.push("Orphan search row: " + entryId);
    }
  }

  return {
    valid: issues.length === 0,
    entry_count: rows.length,
    fts_entry_count: ftsRows.length,
    search_entry_count: searchRows.length,
    schema_version: schemaVersion,
    store_root_hash: anchoredRootHash,
    issues,
  };
}

function assertValidStore(
  database: DatabaseSync,
  projectRoot: string,
  action: string,
): void {
  const verification = verifyDatabase(database, projectRoot);
  if (!verification.valid) {
    throw new Error(
      "Knowledge store is invalid; refusing " + action + ": " + verification.issues.join("; "),
    );
  }
}

function createEntry(
  input: AddKnowledgeEntryInput,
  options: AddKnowledgeEntryOptions,
  sourceBinding: KnowledgeSourceBinding,
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
  const content = validateContent(input.content);
  assertNoSecrets(content, "knowledge content");
  const createdAt = (options.now?.() ?? new Date()).toISOString();
  const entry: KnowledgeEntry = {
    entry_id: normalizeScalar(
      input.entry_id ?? options.idFactory?.() ?? newId("knowledge"),
      "entry_id",
    ),
    title: normalizeScalar(input.title, "title"),
    content,
    source_uri: sourceUri,
    source_sha256: validateDigest(input.source_sha256, "source_sha256"),
    source_kind: sourceKind,
    tags: normalizeList(input.tags ?? [], "tags"),
    roles: normalizeList(input.roles, "roles", true),
    created_at: createdAt,
    supersedes_id: input.supersedes_id
      ? normalizeScalar(input.supersedes_id, "supersedes_id")
      : null,
    status: validateStatus(input.status ?? "active"),
    source_binding: validateSourceBinding(sourceBinding),
    content_digest: calculateContentDigest(content),
    content_hash: "",
  };
  entry.content_hash = calculateEntryHash(entry);
  return entry;
}

function persistKnowledgeEntry(
  projectRoot: string,
  input: AddKnowledgeEntryInput,
  options: AddKnowledgeEntryOptions,
  sourceBinding: KnowledgeSourceBinding,
): KnowledgeEntry {
  const database = openDatabase(projectRoot);
  try {
    installSchema(database, projectRoot);
    database.exec("BEGIN IMMEDIATE");
    try {
      assertValidStore(database, projectRoot, "knowledge write");
      const entry = createEntry(input, options, sourceBinding);
      if (entry.supersedes_id) {
        const superseded = database
          .prepare("SELECT entry_id, created_at FROM knowledge_entries WHERE entry_id = ?")
          .get(entry.supersedes_id) as { entry_id?: string; created_at?: string } | undefined;
        if (!superseded) {
          throw new Error("supersedes_id does not exist: " + entry.supersedes_id);
        }
        if (Date.parse(entry.created_at) < Date.parse(String(superseded.created_at))) {
          throw new Error("Superseding entry cannot be older than its target");
        }
        if (entry.status === "active") {
          const activeSuccessor = database
            .prepare(
              "SELECT entry_id FROM knowledge_entries WHERE supersedes_id = ? AND status = 'active' LIMIT 1",
            )
            .get(entry.supersedes_id) as { entry_id?: string } | undefined;
          if (activeSuccessor?.entry_id) {
            throw new Error(
              "Knowledge entry already has active successor " + activeSuccessor.entry_id,
            );
          }
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
      const duplicateContent = database
        .prepare("SELECT entry_id FROM knowledge_entries WHERE content_digest = ?")
        .get(entry.content_digest) as { entry_id?: string } | undefined;
      if (duplicateContent?.entry_id) {
        throw new Error(
          "Duplicate normalized knowledge content already stored as " +
            duplicateContent.entry_id,
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
            "tags, roles, created_at, supersedes_id, status, source_binding,",
            "content_digest, content_hash",
            ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
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
          entry.status,
          entry.source_binding,
          entry.content_digest,
          entry.content_hash,
        );
      database
        .prepare(
          "INSERT INTO knowledge_entries_fts(entry_id, title, content, tags) VALUES (?, ?, ?, ?)",
        )
        .run(entry.entry_id, entry.title, entry.content, entry.tags.join(" "));
      database
        .prepare("INSERT INTO knowledge_search(entry_id, normalized_text) VALUES (?, ?)")
        .run(entry.entry_id, searchTextForEntry(entry));
      updateStoreAnchor(database);
      assertValidStore(database, projectRoot, "knowledge commit");
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

export function addKnowledgeEntry(
  projectRoot: string,
  input: AddKnowledgeEntryInput,
  options: AddKnowledgeEntryOptions = {},
): KnowledgeEntry {
  return persistKnowledgeEntry(projectRoot, input, options, "uri_claim");
}

export function setKnowledgeEntryStatus(
  projectRoot: string,
  entryId: string,
  status: Exclude<KnowledgeEntryStatus, "active">,
): KnowledgeEntry {
  if (!existsSync(contextDatabasePath(projectRoot))) {
    throw new Error("Knowledge store does not exist");
  }
  const normalizedId = normalizeScalar(entryId, "entry_id");
  const normalizedStatus = validateStatus(status);
  if (normalizedStatus === "active") {
    throw new Error("Knowledge entries cannot be reactivated through lifecycle status updates");
  }
  const database = openDatabase(projectRoot);
  try {
    installSchema(database, projectRoot);
    database.exec("BEGIN IMMEDIATE");
    try {
      const preflight = verifyDatabase(database, projectRoot, false, true);
      if (!preflight.valid) {
        throw new Error(
          "Knowledge store is invalid; refusing lifecycle update: " +
            preflight.issues.join("; "),
        );
      }
      const row = database
        .prepare(
          [
            "SELECT entry_id, title, content, source_uri, source_sha256, source_kind,",
            "tags, roles, created_at, supersedes_id, status, source_binding,",
            "content_digest, content_hash FROM knowledge_entries WHERE entry_id = ?",
          ].join(" "),
        )
        .get(normalizedId) as unknown as KnowledgeRow | undefined;
      if (!row) throw new Error("Knowledge entry does not exist: " + normalizedId);
      const current = entryFromRow(row);
      if (current.status === "revoked" && normalizedStatus !== "revoked") {
        throw new Error("Revoked knowledge entries cannot transition to another status");
      }
      if (current.status === normalizedStatus) {
        assertValidStore(database, projectRoot, "lifecycle no-op");
        database.exec("COMMIT");
        return current;
      }
      if (current.status === "active" && current.supersedes_id) {
        const predecessor = database
          .prepare("SELECT status FROM knowledge_entries WHERE entry_id = ?")
          .get(current.supersedes_id) as { status?: string } | undefined;
        if (predecessor?.status === "active") {
          throw new Error(
            "Cannot deactivate the sole active successor while its superseded entry remains active; retire or revoke the predecessor first",
          );
        }
      }
      const updated: KnowledgeEntry = {
        ...current,
        status: normalizedStatus,
        content_hash: "",
      };
      updated.content_hash = calculateEntryHash(updated);
      const result = database
        .prepare(
          "UPDATE knowledge_entries SET status = ?, content_hash = ? WHERE entry_id = ?",
        )
        .run(updated.status, updated.content_hash, updated.entry_id);
      if (Number(result.changes) !== 1) {
        throw new Error("Knowledge lifecycle update did not affect exactly one entry");
      }
      updateStoreAnchor(database);
      assertValidStore(database, projectRoot, "knowledge lifecycle commit");
      database.exec("COMMIT");
      return updated;
    } catch (error) {
      database.exec("ROLLBACK");
      throw error;
    }
  } finally {
    database.close();
  }
}

export function bindKnowledgeEntryToProjectFile(
  projectRoot: string,
  entryId: string,
): KnowledgeEntry {
  if (!existsSync(contextDatabasePath(projectRoot))) {
    throw new Error("Knowledge store does not exist");
  }
  const normalizedId = normalizeScalar(entryId, "entry_id");
  const database = openDatabase(projectRoot);
  try {
    installSchema(database, projectRoot);
    database.exec("BEGIN IMMEDIATE");
    try {
      assertValidStore(database, projectRoot, "knowledge source binding");
      const row = database
        .prepare(
          [
            "SELECT entry_id, title, content, source_uri, source_sha256, source_kind,",
            "tags, roles, created_at, supersedes_id, status, source_binding,",
            "content_digest, content_hash FROM knowledge_entries WHERE entry_id = ?",
          ].join(" "),
        )
        .get(normalizedId) as unknown as KnowledgeRow | undefined;
      if (!row) throw new Error("Knowledge entry does not exist: " + normalizedId);
      const current = entryFromRow(row);
      assertEntryMatchesProjectFile(projectRoot, current);
      if (current.source_binding === "project_file") {
        database.exec("COMMIT");
        return current;
      }
      const updated: KnowledgeEntry = {
        ...current,
        source_binding: "project_file",
        content_hash: "",
      };
      updated.content_hash = calculateEntryHash(updated);
      const result = database
        .prepare(
          "UPDATE knowledge_entries SET source_binding = ?, content_hash = ? WHERE entry_id = ?",
        )
        .run(updated.source_binding, updated.content_hash, updated.entry_id);
      if (Number(result.changes) !== 1) {
        throw new Error("Knowledge source binding did not affect exactly one entry");
      }
      updateStoreAnchor(database);
      assertValidStore(database, projectRoot, "knowledge source binding commit");
      database.exec("COMMIT");
      return updated;
    } catch (error) {
      database.exec("ROLLBACK");
      throw error;
    }
  } finally {
    database.close();
  }
}

const ROLE_ALIAS_GROUPS = [
  ["router", "factory_router"],
  ["librarian", "factory_librarian"],
  ["verifier", "factory_verifier"],
  ["drift_auditor", "factory_drift_auditor"],
  ["research", "researcher", "factory_researcher"],
  ["implementation", "implementer", "factory_implementer"],
  ["test", "tester", "factory_tester"],
  ["integration", "integrator", "factory_integrator"],
] as const;

function roleAliases(value: string): string[] {
  const role = normalizeList([value], "roles", true)[0];
  const group = ROLE_ALIAS_GROUPS.find((aliases) =>
    aliases.some((alias) => alias === role),
  );
  return group ? [...group] : [role];
}

function queryTerms(query: string): string[] {
  if (typeof query !== "string") throw new Error("query must be a string");
  const terms = query
    .normalize("NFKC")
    .toLowerCase()
    .match(/[\p{Letter}\p{Number}_:/.-]+/gu) ?? [];
  return [...new Set(terms.map((term) => term.trim()).filter(Boolean))]
    .slice(0, 32)
    .map((term) => term.slice(0, 128));
}

function ftsExpression(terms: string[]): string {
  return terms
    .map((term) => '"' + term.replaceAll('"', '""') + '"')
    .join(" OR ");
}

export function queryKnowledge(
  projectRoot: string,
  query: string,
  options: QueryKnowledgeOptions,
): KnowledgeEntry[] {
  const aliases = roleAliases(options.requestingRole);
  const terms = queryTerms(query);
  if (terms.length === 0) return [];
  const expression = ftsExpression(terms);
  const limit = Math.max(1, Math.min(100, options.limit ?? 20));
  if (!existsSync(contextDatabasePath(projectRoot))) return [];

  const database = openDatabase(projectRoot);
  try {
    if (!tableExists(database, "knowledge_entries")) return [];
    installSchema(database, projectRoot);
    assertValidStore(database, projectRoot, "knowledge query");
    const audiencePlaceholders = aliases.map(() => "?").join(", ");
    const selectedColumns = [
      "e.entry_id, e.title, e.content, e.source_uri, e.source_sha256,",
      "e.source_kind, e.tags, e.roles, e.created_at, e.supersedes_id,",
      "e.status, e.source_binding, e.content_digest, e.content_hash",
    ].join(" ");
    const eligibleClauses = [
      "e.status = 'active'",
      options.sourceBoundOnly ? "AND e.source_binding = 'project_file'" : "",
      "AND NOT EXISTS (",
      "  SELECT 1 FROM knowledge_entries successor",
      "  WHERE successor.supersedes_id = e.entry_id AND successor.status = 'active'",
      ")",
      "AND EXISTS (",
      "  SELECT 1 FROM json_each(e.roles) audience",
      "  WHERE audience.value IN (" + audiencePlaceholders + ") OR audience.value = '*'",
      ")",
    ].filter(Boolean).join(" ");
    const candidateLimit = Math.min(500, Math.max(limit * 10, 50));
    type FtsCandidate = KnowledgeRow & { fts_rank: number };
    type LexicalCandidate = KnowledgeRow & {
      normalized_text: string;
      lexical_hits: number;
      phrase_hit: number;
    };
    const ftsRows = database
      .prepare(
        [
          "SELECT " + selectedColumns + ", bm25(knowledge_entries_fts) AS fts_rank",
          "FROM knowledge_entries_fts f",
          "JOIN knowledge_entries e ON e.entry_id = f.entry_id",
          "WHERE knowledge_entries_fts MATCH ?",
          "AND " + eligibleClauses,
          "ORDER BY bm25(knowledge_entries_fts), e.created_at DESC, e.entry_id ASC",
          "LIMIT ?",
        ].join(" "),
      )
      .all(expression, ...aliases, candidateLimit) as unknown as FtsCandidate[];

    const lexicalHitExpression = terms
      .map(() => "CASE WHEN instr(s.normalized_text, ?) > 0 THEN 1 ELSE 0 END")
      .join(" + ");
    const lexicalWhere = terms.map(() => "instr(s.normalized_text, ?) > 0").join(" OR ");
    const normalizedPhrase = normalizeSearchText(query);
    const lexicalRows = database
      .prepare(
        [
          "SELECT " + selectedColumns + ", s.normalized_text,",
          "(" + lexicalHitExpression + ") AS lexical_hits,",
          "CASE WHEN instr(s.normalized_text, ?) > 0 THEN 1 ELSE 0 END AS phrase_hit",
          "FROM knowledge_entries e",
          "JOIN knowledge_search s ON s.entry_id = e.entry_id",
          "WHERE (" + lexicalWhere + ")",
          "AND " + eligibleClauses,
          "ORDER BY lexical_hits DESC, phrase_hit DESC, e.created_at DESC, e.entry_id ASC",
          "LIMIT ?",
        ].join(" "),
      )
      .all(
        ...terms,
        normalizedPhrase,
        ...terms,
        ...aliases,
        candidateLimit,
      ) as unknown as LexicalCandidate[];

    const candidates = new Map<
      string,
      {
        entry: KnowledgeEntry;
        ftsRank: number;
        lexicalHits: number;
        phraseHit: number;
      }
    >();
    for (const row of ftsRows) {
      candidates.set(row.entry_id, {
        entry: entryFromRow(row),
        ftsRank: row.fts_rank,
        lexicalHits: 0,
        phraseHit: 0,
      });
    }
    for (const row of lexicalRows) {
      const current = candidates.get(row.entry_id);
      candidates.set(row.entry_id, {
        entry: current?.entry ?? entryFromRow(row),
        ftsRank: current?.ftsRank ?? Number.POSITIVE_INFINITY,
        lexicalHits: row.lexical_hits,
        phraseHit: row.phrase_hit,
      });
    }
    return [...candidates.values()]
      .sort((left, right) => {
        if (right.lexicalHits !== left.lexicalHits) {
          return right.lexicalHits - left.lexicalHits;
        }
        if (right.phraseHit !== left.phraseHit) return right.phraseHit - left.phraseHit;
        if (left.ftsRank !== right.ftsRank) return left.ftsRank - right.ftsRank;
        const created = Date.parse(right.entry.created_at) - Date.parse(left.entry.created_at);
        return created || left.entry.entry_id.localeCompare(right.entry.entry_id);
      })
      .slice(0, limit)
      .map((candidate) => candidate.entry);
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
      search_entry_count: 0,
      issues: ["Context database does not exist"],
    };
  }
  const database = openDatabase(projectRoot);
  try {
    return verifyDatabase(database, projectRoot);
  } catch (error) {
    return {
      valid: false,
      entry_count: 0,
      fts_entry_count: 0,
      search_entry_count: 0,
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
  assertSafeKnowledgeSourcePath(inputPath);
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
  assertNoSecrets(decoded, "knowledge source file");
  const realRoot = realpathSync(resolve(projectRoot));
  const sourceUri = relative(realRoot, filePath).replaceAll("\\", "/");
  assertSafeKnowledgeSourcePath(sourceUri);
  const inferredKind = extname(filePath).slice(1).toLowerCase();
  const sourceSha256 = createHash("sha256").update(bytes).digest("hex");
  return persistKnowledgeEntry(
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
    "project_file",
  );
}

// Kept local to this module so CLI integrations can initialize through a write/import,
// while verification remains a read-only signal when no knowledge schema exists yet.
export function initializeKnowledgeStore(projectRoot: string): void {
  const database = openDatabase(projectRoot);
  try {
    installSchema(database, projectRoot);
  } finally {
    database.close();
  }
}
