import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { initializeConfig } from "../src/config.js";
import { initializeContextSpace, verifyContextPacket } from "../src/context-space.js";
import { addKnowledgeEntry, importKnowledgeFile } from "../src/knowledge.js";
import { prepareSpawnPlan } from "../src/orchestrator.js";
import type { ContextPacket, FactoryTask } from "../src/types.js";
import { sha256 } from "../src/util.js";

function createProject(): string {
  const root = mkdtempSync(join(tmpdir(), "codex-factory-memory-orchestration-"));
  initializeConfig(root, { multiAgent: true, externalContext: true, maxThreads: 4 });
  initializeContextSpace(root);
  mkdirSync(join(root, "docs"), { recursive: true });
  return root;
}

function implementationTask(taskId: string, keyword: string): FactoryTask {
  return {
    task_id: taskId,
    title: "Implement " + keyword,
    description: "Apply the verified " + keyword + " project policy.",
    role: "implementation",
    status: "pending",
    dependencies: [],
    write_scope: ["src/" + taskId],
    acceptance_methods: ["exists:package.json"],
    required_artifacts: [],
  };
}

test("automatically binds relevant role-visible knowledge into an assignment packet", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  const source = join(root, "docs", "nebula-policy.md");
  writeFileSync(
    source,
    "NebulaTransaction requires a server-side authorization boundary and one database transaction.",
    "utf8",
  );
  const entry = importKnowledgeFile(root, "docs/nebula-policy.md", {
    roles: ["implementation"],
    tags: ["authorization", "transaction"],
  });

  const runId = "run-memory-auto-injection";
  const plan = prepareSpawnPlan(
    root,
    [implementationTask("memory-task", "NebulaTransaction")],
    runId,
  );
  assert.equal(plan.assignments.length, 1);
  const assignment = plan.assignments[0];
  const packet = JSON.parse(
    readFileSync(resolve(root, assignment.context_packet_path), "utf8"),
  ) as ContextPacket;
  const retrieval = packet.trusted_context.find(
    (item) => item.kind === "knowledge_retrieval",
  );
  assert.ok(retrieval, "knowledge retrieval must be present in trusted context");
  assert.equal(retrieval.admission.source?.kind, "knowledge_store_verified");
  const entries = retrieval.payload.entries as Array<Record<string, unknown>>;
  assert.equal(entries.length, 1);
  assert.equal(entries[0].entry_id, entry.entry_id);
  assert.equal(entries[0].source_sha256, entry.source_sha256);
  assert.equal(entries[0].content_digest, entry.content_digest);
  assert.ok(String(entries[0].excerpt).length <= 1_200);
  assert.equal(
    verifyContextPacket(root, packet, {
      runId,
      targetRole: "implementation",
      assignmentId: assignment.assignment_id,
    }).valid,
    true,
  );
});

test("does not inject knowledge that is private to another role", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  writeFileSync(
    join(root, "docs", "private-verifier.md"),
    "QuasarVerifierOnly must remain visible only to the independent verifier.",
    "utf8",
  );
  importKnowledgeFile(root, "docs/private-verifier.md", {
    roles: ["verifier"],
    tags: ["verification"],
  });

  const plan = prepareSpawnPlan(
    root,
    [implementationTask("private-memory-task", "QuasarVerifierOnly")],
    "run-memory-role-filter",
  );
  const packet = JSON.parse(
    readFileSync(resolve(root, plan.assignments[0].context_packet_path), "utf8"),
  ) as ContextPacket;
  assert.equal(
    packet.trusted_context.some((item) => item.kind === "knowledge_retrieval"),
    false,
  );
});

test("does not automatically inject a caller-asserted URI knowledge claim", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  const content = "PulsarManualClaim is an unbound note supplied by a caller.";
  addKnowledgeEntry(root, {
    title: "Unbound manual note",
    content,
    source_uri: "manual://operator-note",
    source_sha256: sha256(content),
    source_kind: "manual_note",
    roles: ["implementation"],
    tags: ["manual"],
  });

  const plan = prepareSpawnPlan(
    root,
    [implementationTask("manual-claim-task", "PulsarManualClaim")],
    "run-memory-unbound-claim",
  );
  const packet = JSON.parse(
    readFileSync(resolve(root, plan.assignments[0].context_packet_path), "utf8"),
  ) as ContextPacket;
  assert.equal(
    packet.trusted_context.some((item) => item.kind === "knowledge_retrieval"),
    false,
  );
});

test("fails assignment planning closed when a project knowledge source drifts", (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  const source = join(root, "docs", "drift-policy.md");
  writeFileSync(source, "OrionDriftPolicy original verified content.", "utf8");
  importKnowledgeFile(root, "docs/drift-policy.md", {
    roles: ["implementation"],
    tags: ["drift"],
  });
  writeFileSync(source, "OrionDriftPolicy changed after knowledge admission.", "utf8");

  assert.throws(
    () =>
      prepareSpawnPlan(
        root,
        [implementationTask("drift-memory-task", "OrionDriftPolicy")],
        "run-memory-source-drift",
      ),
    /knowledge|source|digest|drift/i,
  );
});
