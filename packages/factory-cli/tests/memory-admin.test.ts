import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { spawnSync } from "node:child_process";
import {
  existsSync,
  mkdtempSync,
  mkdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { DatabaseSync } from "node:sqlite";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { initializeConfig } from "../src/config.js";
import {
  appendContextEvent,
  contextDatabasePath,
  initializeContextSpace,
  readAllContextEventsInternal,
} from "../src/context-space.js";
import {
  addKnowledgeEntry,
  setKnowledgeEntryStatus,
  verifyKnowledgeStore,
} from "../src/knowledge.js";
import {
  createMemoryCleanupPlan,
  exportMemory,
  getMemoryStatus,
  resolveMemoryExportPath,
} from "../src/memory-admin.js";

function digest(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}

function createProject(): string {
  const root = mkdtempSync(join(tmpdir(), "codex-factory-memory-admin-"));
  initializeConfig(root, { externalContext: true });
  initializeContextSpace(root);
  return root;
}

function populateMemory(root: string, secret: string): void {
  appendContextEvent(root, "requirement", "user", {
    summary: "Server authorization is required.",
    reference_note: secret,
  });
  appendContextEvent(root, "frontend_summary", "codex_frontend", {
    summary: "Compressed note with reference " + secret,
  });

  const oldContent = "Use the legacy authorization boundary.";
  addKnowledgeEntry(root, {
    entry_id: "knowledge-auth-v1",
    title: "Authorization v1",
    content: oldContent,
    source_uri: "docs/auth-v1.md",
    source_sha256: digest(oldContent),
    source_kind: "project_markdown",
    tags: ["auth"],
    roles: ["factory_librarian"],
  });
  const newContent = "Use server-side authorization for every protected operation.";
  addKnowledgeEntry(root, {
    entry_id: "knowledge-auth-v2",
    title: "Authorization v2",
    content: newContent,
    source_uri: "docs/auth-v2.md",
    source_sha256: digest(newContent),
    source_kind: "project_markdown",
    tags: ["auth", "approved"],
    roles: ["factory_librarian"],
    supersedes_id: "knowledge-auth-v1",
  });
}

test("memory status separates store integrity from factual content verification", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  populateMemory(root, "status-test-secret-value");

  const status = getMemoryStatus(root, {
    now: () => new Date("2030-01-02T03:04:05.000Z"),
  });

  assert.equal(status.status, "READY");
  assert.equal(status.context.integrity_status, "VERIFIED");
  assert.equal(status.knowledge.integrity_status, "VERIFIED");
  assert.equal(status.context.record_count, 2);
  assert.equal(status.context.admitted_record_count, 0);
  assert.equal(status.context.candidate_record_count, 2);
  assert.equal(status.context.admission_integrity_status, "VERIFIED");
  assert.equal(status.knowledge.record_count, 2);
  assert.equal(status.trust_boundary.integrity.status, "VERIFIED");
  assert.equal(status.trust_boundary.content_verification.status, "NOT_ASSERTED");
  assert.match(status.trust_boundary.integrity.meaning, /does not prove/i);
  assert.ok(status.storage.total_bytes > 0);
});

test("memory administration fails closed when the source ledger is tampered", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  populateMemory(root, "tamper-test-reference-value");
  const database = new DatabaseSync(contextDatabasePath(root));
  try {
    database
      .prepare("UPDATE context_events SET payload_json = ? WHERE sequence = 1")
      .run('{"summary":"tampered"}');
  } finally {
    database.close();
  }

  const status = getMemoryStatus(root);
  assert.equal(status.status, "INTEGRITY_FAILED");
  assert.equal(status.context.integrity_status, "FAILED");
  assert.throws(
    () => exportMemory(root, "exports/tampered.json"),
    /integrity verification failed/,
  );
  assert.throws(
    () => createMemoryCleanupPlan(root),
    /integrity verification failed/,
  );
  assert.equal(existsSync(join(root, "exports", "tampered.json")), false);
});

test("memory export is sanitized, atomic, project-safe, and never overwrites", (context) => {
  const root = createProject();
  const externalDirectory = mkdtempSync(join(tmpdir(), "codex-factory-memory-export-"));
  const secret = "memory-admin-export-secret-987654";
  context.after(() => rmSync(root, { recursive: true, force: true }));
  context.after(() => rmSync(externalDirectory, { recursive: true, force: true }));
  populateMemory(root, secret);
  process.env.MEMORY_ADMIN_TEST_TOKEN = secret;
  context.after(() => {
    delete process.env.MEMORY_ADMIN_TEST_TOKEN;
  });

  const receipt = exportMemory(root, "exports/memory.json", {
    now: () => new Date("2030-01-02T03:04:05.000Z"),
  });
  const serialized = readFileSync(receipt.output_path, "utf8");
  const exported = JSON.parse(serialized) as Record<string, unknown>;

  assert.equal(receipt.status, "EXPORTED");
  assert.equal(receipt.context_records, 2);
  assert.equal(receipt.knowledge_records, 2);
  assert.ok(receipt.redaction_count >= 2);
  assert.equal(serialized.includes(secret), false);
  assert.match(serialized, /\[REDACTED/);
  assert.equal(
    (exported.content_verification as Record<string, unknown>).status,
    "NOT_ASSERTED",
  );
  assert.match(String(exported.export_hash), /^[a-f0-9]{64}$/);
  assert.throws(
    () => exportMemory(root, "exports/memory.json"),
    /Refusing to overwrite/,
  );
  assert.throws(
    () => resolveMemoryExportPath(root, "../memory-escape.json"),
    /must stay inside the project/,
  );
  assert.throws(
    () => resolveMemoryExportPath(root, "exports/memory.txt"),
    /\.json extension/,
  );
  const explicitExternalPath = join(externalDirectory, "memory-audit.json");
  assert.equal(resolveMemoryExportPath(root, explicitExternalPath), explicitExternalPath);
});

test("cleanup-plan reports candidates and bytes without deleting or rewriting memory", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  populateMemory(root, "cleanup-test-secret-value");
  const packetDirectory = join(dirname(contextDatabasePath(root)), "packets");
  mkdirSync(packetDirectory, { recursive: true });
  const packetPath = join(packetDirectory, "expired-packet.json");
  writeFileSync(packetPath, JSON.stringify({
    packet_id: "packet-expired-001",
    expires_at: "2029-01-01T00:00:00.000Z",
  }), "utf8");
  const eventIdsBefore = readAllContextEventsInternal(root).map((event) => event.event_id);
  const knowledgeBefore = verifyKnowledgeStore(root);

  const plan = createMemoryCleanupPlan(root, {
    olderThanDays: 30,
    now: () => new Date("2030-01-02T03:04:05.000Z"),
  });

  assert.equal(plan.dry_run, true);
  assert.equal(plan.executed, false);
  assert.ok(plan.candidate_count >= 3);
  assert.ok(plan.candidate_bytes > 0);
  assert.deepEqual(
    new Set(plan.candidates.map((candidate) => candidate.candidate_type)),
    new Set([
      "aged_frontend_summary",
      "superseded_knowledge",
      "expired_context_packet",
    ]),
  );
  assert.equal(existsSync(packetPath), true);
  assert.deepEqual(
    readAllContextEventsInternal(root).map((event) => event.event_id),
    eventIdsBefore,
  );
  assert.deepEqual(verifyKnowledgeStore(root), knowledgeBefore);
  assert.match(plan.statement, /No files or records were changed/);

  setKnowledgeEntryStatus(root, "knowledge-auth-v1", "retired");
  setKnowledgeEntryStatus(root, "knowledge-auth-v2", "retired");
  const noActiveSuccessorPlan = createMemoryCleanupPlan(root, {
    olderThanDays: 30,
    now: () => new Date("2030-01-02T03:04:05.000Z"),
  });
  assert.equal(
    noActiveSuccessorPlan.candidates.some(
      (candidate) => candidate.candidate_type === "superseded_knowledge",
    ),
    false,
  );
});

test("factoryctl exposes memory commands and requires a role for context queries", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  populateMemory(root, "cli-test-secret-value");
  const bindableContent = "This exact project file can be source bound.";
  mkdirSync(join(root, "docs"), { recursive: true });
  writeFileSync(join(root, "docs", "bindable.md"), bindableContent, "utf8");
  addKnowledgeEntry(root, {
    entry_id: "knowledge-bindable",
    title: "Bindable project source",
    content: bindableContent,
    source_uri: "docs/bindable.md",
    source_sha256: digest(bindableContent),
    source_kind: "project_markdown",
    tags: ["migration"],
    roles: ["factory_librarian"],
  });
  const cliPath = join(dirname(fileURLToPath(import.meta.url)), "..", "src", "cli.ts");
  const runCli = (args: string[]) => spawnSync(
    process.execPath,
    ["--import", "tsx", cliPath, ...args],
    {
      cwd: dirname(dirname(cliPath)),
      encoding: "utf8",
      windowsHide: true,
      env: { ...process.env, MEMORY_ADMIN_CLI_TOKEN: "cli-test-secret-value" },
    },
  );

  const helpResult = runCli(["--help"]);
  assert.equal(helpResult.status, 0, helpResult.stderr);
  assert.match(helpResult.stdout, /factoryctl memory status/);
  assert.match(helpResult.stdout, /factoryctl knowledge bind --id/);
  assert.match(helpResult.stdout, /核心命令 \/ Core commands/);
  assert.doesNotMatch(helpResult.stdout, /�|鏍稿績|鍛戒护|澶.Agent|銆/);

  const statusResult = runCli(["memory", "status", "--project", root, "--json"]);
  assert.equal(statusResult.status, 0, statusResult.stderr);
  assert.equal(JSON.parse(statusResult.stdout).status, "READY");

  const cleanupResult = runCli([
    "memory", "cleanup-plan", "--project", root, "--older-than-days", "30", "--json",
  ]);
  assert.equal(cleanupResult.status, 0, cleanupResult.stderr);
  assert.equal(JSON.parse(cleanupResult.stdout).dry_run, true);

  const exportResult = runCli([
    "memory", "export", "--project", root, "--out", "exports/cli-memory.json", "--json",
  ]);
  assert.equal(exportResult.status, 0, exportResult.stderr);
  const exportReceipt = JSON.parse(exportResult.stdout) as Record<string, unknown>;
  assert.equal(exportReceipt.status, "EXPORTED");
  assert.equal(readFileSync(String(exportReceipt.output_path), "utf8").includes("cli-test-secret-value"), false);

  const contextResult = runCli([
    "context", "query", "--project", root, "--query", "authorization", "--json",
  ]);
  assert.equal(contextResult.status, 1);
  assert.match(contextResult.stderr, /Missing required --role/);

  const bindResult = runCli([
    "knowledge", "bind", "--project", root, "--id", "knowledge-bindable", "--json",
  ]);
  assert.equal(bindResult.status, 0, bindResult.stderr);
  assert.equal(JSON.parse(bindResult.stdout).source_binding, "project_file");

  const retireResult = runCli([
    "knowledge", "retire", "--project", root, "--id", "knowledge-auth-v1", "--json",
  ]);
  assert.equal(retireResult.status, 0, retireResult.stderr);
  assert.equal(JSON.parse(retireResult.stdout).status, "retired");

  const revokeResult = runCli([
    "knowledge", "revoke", "--project", root, "--id", "knowledge-auth-v2", "--json",
  ]);
  assert.equal(revokeResult.status, 0, revokeResult.stderr);
  assert.equal(JSON.parse(revokeResult.stdout).status, "revoked");
});
