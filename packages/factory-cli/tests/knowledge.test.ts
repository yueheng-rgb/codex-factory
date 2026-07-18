import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import {
  mkdtempSync,
  mkdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { DatabaseSync } from "node:sqlite";
import test from "node:test";
import { initializeConfig } from "../src/config.js";
import { contextDatabasePath } from "../src/context-space.js";
import {
  addKnowledgeEntry,
  importKnowledgeFile,
  queryKnowledge,
  verifyKnowledgeStore,
} from "../src/knowledge.js";

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
  };
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
