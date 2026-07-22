import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import {
  mkdtempSync,
  mkdirSync,
  readFileSync,
  rmSync,
  unlinkSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { DatabaseSync } from "node:sqlite";
import test from "node:test";
import { initializeConfig } from "../src/config.js";
import { contextDatabasePath } from "../src/context-space.js";
import {
  addKnowledgeEntry,
  bindKnowledgeEntryToProjectFile,
  importKnowledgeFile,
  initializeKnowledgeStore,
  queryKnowledge,
  setKnowledgeEntryStatus,
  verifyKnowledgeStore,
} from "../src/knowledge.js";
import { sha256, stableStringify } from "../src/util.js";

const FIXED_TIME = new Date("2026-07-18T12:00:00.000Z");

function createProject(): string {
  const root = mkdtempSync(join(tmpdir(), "codex-factory-knowledge-"));
  initializeConfig(root, { externalContext: true });
  return root;
}

function digest(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}

function entryInput(overrides: Record<string, unknown> = {}) {
  const content = String(overrides.content ?? "Use a transaction for related writes.");
  return {
    entry_id: String(overrides.entry_id ?? "knowledge-transaction-boundary"),
    title: String(overrides.title ?? "Transaction boundary"),
    content,
    source_uri: String(overrides.source_uri ?? "docs/transactions.md"),
    source_sha256: String(overrides.source_sha256 ?? digest(content)),
    source_kind: String(overrides.source_kind ?? "project_markdown"),
    tags: (overrides.tags as string[] | undefined) ?? ["database", "transaction"],
    roles: (overrides.roles as string[] | undefined) ?? ["factory_implementer"],
    supersedes_id: (overrides.supersedes_id as string | null | undefined) ?? null,
    status: (overrides.status as "active" | "retired" | "revoked" | undefined) ??
      "active",
  };
}

interface LegacyEntryFixture {
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
}

function installLegacyStore(root: string, entries: LegacyEntryFixture[]): void {
  mkdirSync(dirname(contextDatabasePath(root)), { recursive: true });
  const database = new DatabaseSync(contextDatabasePath(root));
  try {
    database.exec(
      [
        "CREATE TABLE knowledge_entries (",
        "entry_id TEXT PRIMARY KEY, title TEXT NOT NULL, content TEXT NOT NULL,",
        "source_uri TEXT NOT NULL, source_sha256 TEXT NOT NULL, source_kind TEXT NOT NULL,",
        "tags TEXT NOT NULL, roles TEXT NOT NULL, created_at TEXT NOT NULL,",
        "supersedes_id TEXT REFERENCES knowledge_entries(entry_id), content_hash TEXT NOT NULL UNIQUE,",
        "UNIQUE(source_uri, source_sha256)) STRICT;",
        "CREATE TABLE knowledge_metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL) STRICT;",
        "CREATE VIRTUAL TABLE knowledge_entries_fts USING fts5(entry_id UNINDEXED, title, content, tags);",
      ].join("\n"),
    );
    const insertEntry = database.prepare(
      "INSERT INTO knowledge_entries VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    );
    const insertFts = database.prepare(
      "INSERT INTO knowledge_entries_fts VALUES (?, ?, ?, ?)",
    );
    const anchors: Array<{ entry_id: string; content_hash: string }> = [];
    for (const entry of entries) {
      const contentHash = sha256(stableStringify(entry));
      anchors.push({ entry_id: entry.entry_id, content_hash: contentHash });
      insertEntry.run(
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
        contentHash,
      );
      insertFts.run(entry.entry_id, entry.title, entry.content, entry.tags.join(" "));
    }
    const insertMetadata = database.prepare(
      "INSERT INTO knowledge_metadata(key, value) VALUES (?, ?)",
    );
    insertMetadata.run("schema_version", "1.0.0");
    insertMetadata.run("entry_count", String(entries.length));
    insertMetadata.run(
      "store_root_hash",
      sha256(
        stableStringify(
          anchors.sort((left, right) => left.entry_id.localeCompare(right.entry_id)),
        ),
      ),
    );
  } finally {
    database.close();
  }
}

test("stores canonical entries in the shared context database and enforces role visibility", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));

  const privateEntry = addKnowledgeEntry(root, entryInput(), {
    now: () => FIXED_TIME,
  });
  const publicContent = "Every form needs loading, empty, error, and success states.";
  const publicEntry = addKnowledgeEntry(
    root,
    entryInput({
      entry_id: "knowledge-ui-states",
      title: "UI states",
      content: publicContent,
      source_uri: "docs/ui-states.md",
      source_sha256: digest(publicContent),
      roles: ["*"],
      tags: ["ui"],
    }),
    { now: () => new Date(FIXED_TIME.getTime() + 1_000) },
  );

  assert.match(privateEntry.content_hash, /^[a-f0-9]{64}$/);
  assert.equal(contextDatabasePath(root).endsWith("state.db"), true);
  assert.deepEqual(
    queryKnowledge(root, "transaction", {
      requestingRole: "factory_implementer",
      sourceBoundOnly: true,
    }),
    [],
  );
  assert.deepEqual(
    queryKnowledge(root, "transaction", {
      requestingRole: "factory_implementer",
    }).map((entry) => entry.entry_id),
    [privateEntry.entry_id],
  );
  assert.deepEqual(
    queryKnowledge(root, "transaction", {
      requestingRole: "factory_researcher",
    }),
    [],
  );
  assert.deepEqual(
    queryKnowledge(root, "loading empty error success", {
      requestingRole: "factory_researcher",
    }).map((entry) => entry.entry_id),
    [publicEntry.entry_id],
  );
  assert.throws(
    () => queryKnowledge(root, "transaction", { requestingRole: "" }),
    /roles is required/,
  );

  const verification = verifyKnowledgeStore(root);
  assert.equal(verification.valid, true);
  assert.equal(verification.entry_count, 2);
  assert.equal(verification.fts_entry_count, 2);
});

test("rejects duplicate identity and duplicate source revisions without partial writes", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  addKnowledgeEntry(root, entryInput(), { now: () => FIXED_TIME });

  assert.throws(
    () =>
      addKnowledgeEntry(root, entryInput(), {
        now: () => new Date(FIXED_TIME.getTime() + 1_000),
      }),
    /Duplicate knowledge entry_id/,
  );
  assert.throws(
    () =>
      addKnowledgeEntry(
        root,
        entryInput({ entry_id: "knowledge-different-id" }),
        { now: () => new Date(FIXED_TIME.getTime() + 2_000) },
      ),
    /Duplicate knowledge source revision/,
  );

  const verification = verifyKnowledgeStore(root);
  assert.equal(verification.valid, true);
  assert.equal(verification.entry_count, 1);
  assert.equal(verification.fts_entry_count, 1);
});

test("detects database or index tampering and refuses reads and writes", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  addKnowledgeEntry(root, entryInput(), { now: () => FIXED_TIME });

  const database = new DatabaseSync(contextDatabasePath(root));
  try {
    database
      .prepare("UPDATE knowledge_entries SET content = ? WHERE entry_id = ?")
      .run("Tampered content", "knowledge-transaction-boundary");
  } finally {
    database.close();
  }

  const verification = verifyKnowledgeStore(root);
  assert.equal(verification.valid, false);
  assert.equal(
    verification.issues.some((issue) => issue.includes("Content hash mismatch")),
    true,
  );
  assert.throws(
    () =>
      queryKnowledge(root, "tampered", {
        requestingRole: "factory_implementer",
      }),
    /refusing knowledge query/,
  );
  assert.throws(
    () =>
      addKnowledgeEntry(
        root,
        entryInput({
          entry_id: "knowledge-second",
          source_uri: "docs/second.md",
          content: "Second entry",
          source_sha256: digest("Second entry"),
        }),
      ),
    /refusing knowledge write/,
  );
});

test("detects deletion even when both the entry and its FTS row are removed", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  addKnowledgeEntry(root, entryInput(), { now: () => FIXED_TIME });

  const database = new DatabaseSync(contextDatabasePath(root));
  try {
    database
      .prepare("DELETE FROM knowledge_entries_fts WHERE entry_id = ?")
      .run("knowledge-transaction-boundary");
    database
      .prepare("DELETE FROM knowledge_search WHERE entry_id = ?")
      .run("knowledge-transaction-boundary");
    database
      .prepare("DELETE FROM knowledge_entries WHERE entry_id = ?")
      .run("knowledge-transaction-boundary");
  } finally {
    database.close();
  }

  const verification = verifyKnowledgeStore(root);
  assert.equal(verification.valid, false);
  assert.equal(
    verification.issues.some((issue) => issue.includes("anchor mismatch")),
    true,
  );
  assert.throws(
    () =>
      queryKnowledge(root, "transaction", {
        requestingRole: "factory_implementer",
      }),
    /refusing knowledge query/,
  );
});

test("imports only project-contained text files and records the exact source digest", (context) => {
  const root = createProject();
  const outsideRoot = mkdtempSync(join(tmpdir(), "codex-factory-outside-"));
  context.after(() => {
    rmSync(root, { recursive: true, force: true });
    rmSync(outsideRoot, { recursive: true, force: true });
  });
  mkdirSync(join(root, "knowledge"), { recursive: true });
  const sourcePath = join(root, "knowledge", "postgres.md");
  const sourceText = "Use a unique constraint for business identity.\n";
  writeFileSync(sourcePath, sourceText, "utf8");

  const entry = importKnowledgeFile(root, "knowledge/postgres.md", {
    roles: ["factory_librarian", "factory_implementer"],
    tags: ["postgres"],
    entryId: "knowledge-postgres",
    now: () => FIXED_TIME,
  });

  assert.equal(entry.source_uri, "knowledge/postgres.md");
  assert.equal(
    entry.source_sha256,
    createHash("sha256").update(readFileSync(sourcePath)).digest("hex"),
  );
  assert.equal(entry.source_kind, "project_md");
  assert.equal(verifyKnowledgeStore(root).valid, true);

  const outsideFile = join(outsideRoot, "outside.md");
  writeFileSync(outsideFile, "outside", "utf8");
  assert.throws(
    () => importKnowledgeFile(root, outsideFile, { roles: ["factory_librarian"] }),
    /Path escapes project root/,
  );
});

test("never promotes a frontend compressed summary and validates supersession", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));

  assert.throws(
    () =>
      addKnowledgeEntry(
        root,
        entryInput({ source_kind: "frontend_summary" }),
        { now: () => FIXED_TIME },
      ),
    /cannot be promoted/,
  );
  assert.equal(verifyKnowledgeStore(root).entry_count, 0);

  const first = addKnowledgeEntry(root, entryInput(), { now: () => FIXED_TIME });
  const revisedContent = "Use one transaction and document its rollback boundary.";
  const revised = addKnowledgeEntry(
    root,
    entryInput({
      entry_id: "knowledge-transaction-boundary-v2",
      content: revisedContent,
      source_sha256: digest(revisedContent),
      supersedes_id: first.entry_id,
    }),
    { now: () => new Date(FIXED_TIME.getTime() + 1_000) },
  );
  assert.equal(revised.supersedes_id, first.entry_id);
  assert.equal(verifyKnowledgeStore(root).valid, true);

  assert.throws(
    () =>
      addKnowledgeEntry(
        root,
        entryInput({
          entry_id: "knowledge-orphan-revision",
          source_uri: "docs/orphan.md",
          supersedes_id: "missing-entry",
        }),
      ),
    /supersedes_id does not exist/,
  );
});

test("returns only active leaf revisions and accepts role/profile aliases", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));

  const original = addKnowledgeEntry(
    root,
    entryInput({
      content: "Legacy transaction rollback guidance.",
      source_sha256: digest("Legacy transaction rollback guidance."),
    }),
    { now: () => FIXED_TIME },
  );
  const replacementContent = "Current transaction rollback guidance with savepoints.";
  const replacement = addKnowledgeEntry(
    root,
    entryInput({
      entry_id: "knowledge-transaction-boundary-v2",
      content: replacementContent,
      source_sha256: digest(replacementContent),
      supersedes_id: original.entry_id,
    }),
    { now: () => new Date(FIXED_TIME.getTime() + 1_000) },
  );
  const retiredContent = "Retired transaction rollback experiment.";
  addKnowledgeEntry(
    root,
    entryInput({
      entry_id: "knowledge-retired-experiment",
      content: retiredContent,
      source_uri: "docs/retired.md",
      source_sha256: digest(retiredContent),
      status: "retired",
    }),
    { now: () => new Date(FIXED_TIME.getTime() + 2_000) },
  );

  const results = queryKnowledge(root, "rollback", {
    requestingRole: "implementation",
  });
  assert.deepEqual(results.map((entry) => entry.entry_id), [replacement.entry_id]);
  assert.equal(results[0].status, "active");
  assert.equal(results[0].source_binding, "uri_claim");
  assert.match(results[0].content_digest, /^[a-f0-9]{64}$/);
  assert.throws(
    () =>
      addKnowledgeEntry(
        root,
        entryInput({
          entry_id: "knowledge-transaction-boundary-branch",
          content: "Conflicting active transaction rollback branch.",
          source_sha256: digest("Conflicting active transaction rollback branch."),
          supersedes_id: original.entry_id,
        }),
        { now: () => new Date(FIXED_TIME.getTime() + 3_000) },
      ),
    /already has active successor/,
  );
  const verification = verifyKnowledgeStore(root);
  assert.equal(verification.schema_version, "1.1.0");
  assert.match(verification.store_root_hash ?? "", /^[a-f0-9]{64}$/);
});

test("applies one-way lifecycle transitions without resurrecting superseded knowledge", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  const original = addKnowledgeEntry(root, entryInput(), { now: () => FIXED_TIME });
  const replacementContent = "Use an explicit transaction rollback boundary.";
  const replacement = addKnowledgeEntry(
    root,
    entryInput({
      entry_id: "knowledge-transaction-replacement",
      content: replacementContent,
      source_sha256: digest(replacementContent),
      supersedes_id: original.entry_id,
    }),
    { now: () => new Date(FIXED_TIME.getTime() + 1_000) },
  );

  assert.throws(
    () => setKnowledgeEntryStatus(root, replacement.entry_id, "retired"),
    /retire or revoke the predecessor first/,
  );
  const retiredOriginal = setKnowledgeEntryStatus(root, original.entry_id, "retired");
  assert.equal(retiredOriginal.status, "retired");
  assert.notEqual(retiredOriginal.content_hash, original.content_hash);
  const retiredReplacement = setKnowledgeEntryStatus(
    root,
    replacement.entry_id,
    "retired",
  );
  assert.equal(retiredReplacement.status, "retired");
  assert.deepEqual(
    queryKnowledge(root, "transaction", {
      requestingRole: "implementation",
    }),
    [],
  );
  const revoked = setKnowledgeEntryStatus(root, replacement.entry_id, "revoked");
  assert.equal(revoked.status, "revoked");
  assert.throws(
    () => setKnowledgeEntryStatus(root, replacement.entry_id, "retired"),
    /cannot transition/,
  );
  assert.equal(verifyKnowledgeStore(root).valid, true);
});

test("can revoke a source-drifted active entry while preserving fail-closed retrieval", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  mkdirSync(join(root, "knowledge"), { recursive: true });
  const sourcePath = join(root, "knowledge", "revocable.md");
  writeFileSync(sourcePath, "Source-bound policy before drift.\n", "utf8");
  const entry = importKnowledgeFile(root, "knowledge/revocable.md", {
    entryId: "knowledge-revocable",
    roles: ["implementation"],
    now: () => FIXED_TIME,
  });
  writeFileSync(sourcePath, "Source-bound policy after drift.\n", "utf8");
  assert.equal(verifyKnowledgeStore(root).valid, false);

  const revoked = setKnowledgeEntryStatus(root, entry.entry_id, "revoked");
  assert.equal(revoked.status, "revoked");
  assert.equal(verifyKnowledgeStore(root).valid, true);
  assert.deepEqual(
    queryKnowledge(root, "policy", {
      requestingRole: "implementation",
      sourceBoundOnly: true,
    }),
    [],
  );
});

test("rejects normalized duplicate content independent of identity and source metadata", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));

  const firstContent = "Ｃｏｄｅ review\r\n";
  addKnowledgeEntry(
    root,
    entryInput({
      content: firstContent,
      source_sha256: digest(firstContent),
    }),
    { now: () => FIXED_TIME },
  );
  const duplicateContent = "Code review\n";
  assert.throws(
    () =>
      addKnowledgeEntry(
        root,
        entryInput({
          entry_id: "knowledge-normalized-duplicate",
          content: duplicateContent,
          source_uri: "docs/other.md",
          source_sha256: digest(duplicateContent),
        }),
        { now: () => new Date(FIXED_TIME.getTime() + 1_000) },
      ),
    /Duplicate normalized knowledge content/,
  );
  assert.equal(verifyKnowledgeStore(root).entry_count, 1);
});

test("detects imported project source drift and deletion while leaving URI claims valid", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  mkdirSync(join(root, "knowledge"), { recursive: true });
  const sourcePath = join(root, "knowledge", "transactions.md");
  writeFileSync(sourcePath, "事务必须在服务端校验。\n", "utf8");

  const imported = importKnowledgeFile(root, "knowledge/transactions.md", {
    entryId: "knowledge-source-bound",
    roles: ["factory_implementer"],
    now: () => FIXED_TIME,
  });
  assert.equal(imported.source_binding, "project_file");
  assert.equal(verifyKnowledgeStore(root).valid, true);

  writeFileSync(sourcePath, "事务边界已经发生变化。\n", "utf8");
  const changed = verifyKnowledgeStore(root);
  assert.equal(changed.valid, false);
  assert.equal(
    changed.issues.some((issue) => issue.includes("Project source digest mismatch")),
    true,
  );
  assert.throws(
    () => queryKnowledge(root, "事务", { requestingRole: "implementation" }),
    /refusing knowledge query/,
  );

  writeFileSync(sourcePath, "事务必须在服务端校验。\n", "utf8");
  assert.equal(verifyKnowledgeStore(root).valid, true);
  unlinkSync(sourcePath);
  const deleted = verifyKnowledgeStore(root);
  assert.equal(deleted.valid, false);
  assert.equal(
    deleted.issues.some((issue) => issue.includes("Project source is unavailable")),
    true,
  );
});

test("retrieves short CJK substrings with OR semantics and deterministic role aliases", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  const chineseContent = "数据库事务边界必须覆盖提交与回滚。";
  const entry = addKnowledgeEntry(
    root,
    entryInput({
      entry_id: "knowledge-cjk-transaction",
      title: "数据库事务规范",
      content: chineseContent,
      source_uri: "manual://database-transaction",
      source_sha256: digest(chineseContent),
      tags: ["数据库", "事务"],
    }),
    { now: () => FIXED_TIME },
  );

  assert.deepEqual(
    queryKnowledge(root, "完全不存在的词 事务", {
      requestingRole: "implementation",
    }).map((item) => item.entry_id),
    [entry.entry_id],
  );
  assert.deepEqual(
    queryKnowledge(root, "数据", {
      requestingRole: "factory_implementer",
    }).map((item) => item.entry_id),
    [entry.entry_id],
  );
});

test("rejects credential files and secret-bearing direct claims", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  const secretsPath = join(root, ".codex-factory", "secrets.env");
  writeFileSync(secretsPath, "GLM_API_KEY=0123456789abcdef0123456789abcdef\n", "utf8");

  assert.throws(
    () =>
      importKnowledgeFile(root, ".codex-factory/secrets.env", {
        roles: ["factory_librarian"],
      }),
    /Sensitive credential file/,
  );
  assert.throws(
    () =>
      addKnowledgeEntry(
        root,
        entryInput({
          content: "api_key=0123456789abcdef0123456789abcdef",
          source_sha256: digest("api_key=0123456789abcdef0123456789abcdef"),
        }),
      ),
    /Potential secret detected/,
  );
  assert.equal(verifyKnowledgeStore(root).entry_count, 0);
});

test("detects normalized search index and lifecycle tampering", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  addKnowledgeEntry(root, entryInput(), { now: () => FIXED_TIME });

  const database = new DatabaseSync(contextDatabasePath(root));
  try {
    database
      .prepare("UPDATE knowledge_search SET normalized_text = ? WHERE entry_id = ?")
      .run("forged searchable text", "knowledge-transaction-boundary");
    database
      .prepare("UPDATE knowledge_entries SET status = 'retired' WHERE entry_id = ?")
      .run("knowledge-transaction-boundary");
  } finally {
    database.close();
  }
  const verification = verifyKnowledgeStore(root);
  assert.equal(verification.valid, false);
  assert.equal(
    verification.issues.some((issue) => issue.includes("Normalized search row mismatch")),
    true,
  );
  assert.equal(
    verification.issues.some((issue) => issue.includes("Content hash mismatch")),
    true,
  );
});

test("migrates an intact v1 knowledge store without blessing corrupted data", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  const content = "Legacy verified migration knowledge.";
  const legacyEntry = {
    entry_id: "knowledge-legacy",
    title: "Legacy knowledge",
    content,
    source_uri: "docs/missing-legacy.md",
    source_sha256: digest(content),
    source_kind: "manual_uri",
    tags: ["migration"],
    roles: ["factory_implementer"],
    created_at: FIXED_TIME.toISOString(),
    supersedes_id: null,
  };
  const contentHash = sha256(stableStringify(legacyEntry));
  const rootHash = sha256(
    stableStringify([{ entry_id: legacyEntry.entry_id, content_hash: contentHash }]),
  );
  mkdirSync(dirname(contextDatabasePath(root)), { recursive: true });
  const database = new DatabaseSync(contextDatabasePath(root));
  try {
    database.exec(
      [
        "CREATE TABLE knowledge_entries (",
        "entry_id TEXT PRIMARY KEY, title TEXT NOT NULL, content TEXT NOT NULL,",
        "source_uri TEXT NOT NULL, source_sha256 TEXT NOT NULL, source_kind TEXT NOT NULL,",
        "tags TEXT NOT NULL, roles TEXT NOT NULL, created_at TEXT NOT NULL,",
        "supersedes_id TEXT REFERENCES knowledge_entries(entry_id), content_hash TEXT NOT NULL UNIQUE,",
        "UNIQUE(source_uri, source_sha256)) STRICT;",
        "CREATE TABLE knowledge_metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL) STRICT;",
        "CREATE VIRTUAL TABLE knowledge_entries_fts USING fts5(entry_id UNINDEXED, title, content, tags);",
      ].join("\n"),
    );
    database
      .prepare(
        "INSERT INTO knowledge_entries VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
      )
      .run(
        legacyEntry.entry_id,
        legacyEntry.title,
        legacyEntry.content,
        legacyEntry.source_uri,
        legacyEntry.source_sha256,
        legacyEntry.source_kind,
        stableStringify(legacyEntry.tags),
        stableStringify(legacyEntry.roles),
        legacyEntry.created_at,
        null,
        contentHash,
      );
    database
      .prepare("INSERT INTO knowledge_entries_fts VALUES (?, ?, ?, ?)")
      .run(legacyEntry.entry_id, legacyEntry.title, legacyEntry.content, "migration");
    const insertMetadata = database.prepare(
      "INSERT INTO knowledge_metadata(key, value) VALUES (?, ?)",
    );
    insertMetadata.run("schema_version", "1.0.0");
    insertMetadata.run("entry_count", "1");
    insertMetadata.run("store_root_hash", rootHash);
  } finally {
    database.close();
  }

  initializeKnowledgeStore(root);
  const verification = verifyKnowledgeStore(root);
  assert.equal(verification.valid, true);
  assert.equal(verification.schema_version, "1.1.0");
  const migrated = queryKnowledge(root, "migration", {
    requestingRole: "implementation",
  });
  assert.deepEqual(migrated.map((entry) => entry.entry_id), [legacyEntry.entry_id]);
  assert.equal(migrated[0].source_binding, "uri_claim");
});

test("upgrades a legacy entry to project_file only when the current file exactly matches", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  mkdirSync(join(root, "docs"), { recursive: true });
  const content = "Legacy source-bound migration policy.\n";
  writeFileSync(join(root, "docs", "legacy-bound.md"), content, "utf8");
  const fixture: LegacyEntryFixture = {
    entry_id: "knowledge-legacy-bound",
    title: "Legacy bound knowledge",
    content,
    source_uri: "docs/legacy-bound.md",
    source_sha256: digest(content),
    source_kind: "project_md",
    tags: ["migration"],
    roles: ["factory_implementer"],
    created_at: FIXED_TIME.toISOString(),
    supersedes_id: null,
  };
  installLegacyStore(root, [fixture]);

  initializeKnowledgeStore(root);
  const result = queryKnowledge(root, "migration", {
    requestingRole: "implementation",
    sourceBoundOnly: true,
  });
  assert.deepEqual(result.map((entry) => entry.entry_id), [fixture.entry_id]);
  assert.equal(result[0].source_binding, "project_file");
  assert.equal(verifyKnowledgeStore(root).valid, true);
});

test("can explicitly bind a migrated URI claim after its exact project source is restored", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  const content = "Restorable legacy knowledge.\n";
  const fixture: LegacyEntryFixture = {
    entry_id: "knowledge-legacy-restored",
    title: "Restored legacy knowledge",
    content,
    source_uri: "docs/restored.md",
    source_sha256: digest(content),
    source_kind: "project_md",
    tags: ["restore"],
    roles: ["implementation"],
    created_at: FIXED_TIME.toISOString(),
    supersedes_id: null,
  };
  installLegacyStore(root, [fixture]);
  initializeKnowledgeStore(root);
  assert.deepEqual(
    queryKnowledge(root, "restorable", {
      requestingRole: "implementation",
      sourceBoundOnly: true,
    }),
    [],
  );

  mkdirSync(join(root, "docs"), { recursive: true });
  writeFileSync(join(root, "docs", "restored.md"), content, "utf8");
  const rebound = bindKnowledgeEntryToProjectFile(root, fixture.entry_id);
  assert.equal(rebound.source_binding, "project_file");
  assert.deepEqual(
    queryKnowledge(root, "restorable", {
      requestingRole: "implementation",
      sourceBoundOnly: true,
    }).map((entry) => entry.entry_id),
    [fixture.entry_id],
  );
});

test("refuses lifecycle migration when legacy anchors are inconsistent", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  mkdirSync(dirname(contextDatabasePath(root)), { recursive: true });
  const database = new DatabaseSync(contextDatabasePath(root));
  try {
    database.exec(
      [
        "CREATE TABLE knowledge_entries (",
        "entry_id TEXT PRIMARY KEY, title TEXT NOT NULL, content TEXT NOT NULL,",
        "source_uri TEXT NOT NULL, source_sha256 TEXT NOT NULL, source_kind TEXT NOT NULL,",
        "tags TEXT NOT NULL, roles TEXT NOT NULL, created_at TEXT NOT NULL,",
        "supersedes_id TEXT REFERENCES knowledge_entries(entry_id), content_hash TEXT NOT NULL UNIQUE,",
        "UNIQUE(source_uri, source_sha256)) STRICT;",
        "CREATE TABLE knowledge_metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL) STRICT;",
        "CREATE VIRTUAL TABLE knowledge_entries_fts USING fts5(entry_id UNINDEXED, title, content, tags);",
        "INSERT INTO knowledge_metadata VALUES ('schema_version', '1.0.0');",
        "INSERT INTO knowledge_metadata VALUES ('entry_count', '1');",
        "INSERT INTO knowledge_metadata VALUES ('store_root_hash',",
        "'4f53cda18c2baa0c0354bb5f9a3ecbe5ed12ab4d8e11ba873c2f11161202b945');",
      ].join("\n"),
    );
  } finally {
    database.close();
  }

  assert.throws(
    () => initializeKnowledgeStore(root),
    /Legacy knowledge store is invalid; refusing migration/,
  );
  const inspection = new DatabaseSync(contextDatabasePath(root), { readOnly: true });
  try {
    const columns = inspection
      .prepare("PRAGMA table_info(knowledge_entries)")
      .all() as unknown as Array<{ name: string }>;
    assert.equal(columns.some((column) => column.name === "status"), false);
  } finally {
    inspection.close();
  }
});
