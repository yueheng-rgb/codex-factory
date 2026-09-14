import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import fs, { existsSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { syncBuiltinESMExports } from "node:module";
import { DatabaseSync } from "node:sqlite";
import { dirname, join } from "node:path";
import { afterEach, describe, it } from "node:test";
import { fileURLToPath } from "node:url";
import { prepareSpawnPlan, readAgentRegistry, readTaskGraphSnapshot, registerNativeDispatch, setRunTaskStatus } from "../src/orchestrator.js";
import { recordAgentHandoff, verifyTaskCompletion } from "../src/evidence.js";
import { contextDatabasePath } from "../src/context-space.js";
import { createRepairRun, inspectRun, listRuns } from "../src/run-management.js";
import { managedRunDirectory, repairJournalPath, RunManagementError, runFileSnapshot } from "../src/repair-store.js";
import { sha256, stableStringify, writeJsonAtomic } from "../src/util.js";
import { completeFixtureRun, failedFixture, fixtureProject, repairTask } from "./helpers/repair-fixture.js";

const roots: string[] = [];
function project(context = false): string { const root = fixtureProject(context); roots.push(root); return root; }
afterEach(() => { for (const root of roots.splice(0)) rmSync(root, { recursive: true, force: true }); });
const code = (expected: string) => (error: unknown) => error instanceof RunManagementError && error.code === expected;
const request = (fromRun = "original", requestId = "repair-one") => ({ fromRun, taskId: "worker", tasks: [repairTask()], requestId });
const cliPath = join(dirname(fileURLToPath(import.meta.url)), "../src/cli.ts");
function cli(root: string, args: string[]) {
  return spawnSync(process.execPath, ["--import", "tsx", cliPath, "--project", root, ...args], { encoding: "utf8", windowsHide: true });
}
function asyncCli(root: string, args: string[]): Promise<{ code: number | null; stdout: string; stderr: string }> {
  return new Promise((resolve, reject) => {
    const child = spawn(process.execPath, ["--import", "tsx", cliPath, "--project", root, ...args], { windowsHide: true });
    let stdout = "", stderr = "";
    child.stdout.on("data", (chunk) => { stdout += chunk; });
    child.stderr.on("data", (chunk) => { stderr += chunk; });
    child.once("error", reject);
    child.once("close", (code) => resolve({ code, stdout, stderr }));
  });
}

describe("run listing", () => {
  it("lists an empty project without creating files and validates CLI arguments", () => {
    const root = project();
    const before = runFileSnapshot(root, root);
    assert.deepEqual(listRuns(root).runs, []);
    const empty = cli(root, ["run", "list", "--json"]);
    assert.equal(empty.status, 0, empty.stderr);
    assert.equal(JSON.parse(empty.stdout).total, 0);
    assert.match(cli(root, ["run", "list"]).stdout, /No Factory runs/);
    for (const flags of [["--limit"], ["--limit", "0"], ["--limit", "51"], ["--limit", "1.5"], ["--limit", "no"], ["--unknown"]]) {
      assert.equal(cli(root, ["run", "list", ...flags]).status, 1, flags.join(" "));
    }
    assert.equal(runFileSnapshot(root, root), before);
  });

  it("lists recent runs with saved status, progress and repair parent", () => {
    const root = project();
    failedFixture(root);
    const repair = createRepairRun(root, request());
    prepareSpawnPlan(root, [repairTask()], "queued");
    for (const [id, created_at] of [["original", "2026-01-01T00:00:00Z"], [repair.run_id, "2026-01-02T00:00:00Z"], ["queued", "2026-01-03T00:00:00Z"]]) {
      const path = join(managedRunDirectory(root, id), "run.json");
      writeJsonAtomic(path, { ...JSON.parse(readFileSync(path, "utf8")), created_at });
    }
    const before = runFileSnapshot(root, root);
    const result = listRuns(root, 2);
    assert.equal(result.total, 3);
    assert.equal(result.has_more, true);
    assert.equal(result.host_liveness, "UNKNOWN");
    assert.deepEqual(result.runs.map((run) => [run.run_id, run.status]), [["queued", "AWAITING_DISPATCH"], [repair.run_id, "READY"]]);
    assert.equal(result.runs[1].parent_run_id, "original");
    assert.equal(result.runs[1].repair_index, 1);
    assert.equal(result.runs[1].verified_tasks, 0);
    assert.equal(result.runs[1].total_tasks, 2);
    assert.equal(listRuns(root).runs[2].status, "FAILED");
    const command = cli(root, ["run", "list", "--limit", "2", "--json"]);
    assert.equal(command.status, 0, command.stderr);
    assert.deepEqual(JSON.parse(command.stdout), result);
    assert.match(cli(root, ["run", "list"]).stdout, /repair 1\/2 from original/);
    assert.equal(runFileSnapshot(root, root), before);
  });

  it("keeps unreadable runs visible without hiding readable records", () => {
    const root = project();
    prepareSpawnPlan(root, [repairTask()], "readable");
    fs.mkdirSync(managedRunDirectory(root, "partial"));
    const before = runFileSnapshot(root, root);
    const result = listRuns(root);
    assert.equal(result.runs[0].status, "AWAITING_DISPATCH");
    assert.equal(result.runs[1].run_id, "partial");
    assert.equal(result.runs[1].created_at, null);
    assert.equal(result.runs[1].status, "UNAVAILABLE");
    assert.equal(result.runs[1].total_tasks, null);
    assert.match(result.runs[1].error ?? "", /missing run.json/);
    assert.equal(runFileSnapshot(root, root), before);
  });
});

describe("read-only run inspection", () => {
  it("guides dispatch, waiting, verifier planning and acceptance without executing them", () => {
    const root = project();
    const runId = "guided-run";
    const initial = prepareSpawnPlan(root, [repairTask()], runId);
    const worker = initial.assignments[0];
    const inspect = () => {
      const before = runFileSnapshot(root, root);
      const result = inspectRun(root, runId);
      assert.equal(runFileSnapshot(root, root), before);
      return result.next_actions.join("\n");
    };
    const register = (assignmentId: string, nativeAgentId: string) => registerNativeDispatch(root, runId, assignmentId, {
      nativeAgentId, rawToolReceipt: { tool_name: "spawn_agent", agent_id: nativeAgentId, status: "spawned" },
    });
    assert.match(inspect(), /Unregistered dispatches: worker/);
    assert.match(inspect(), /Do not blindly spawn again/);
    assert.match(inspect(), new RegExp(worker.assignment_id));
    register(worker.assignment_id, "fixture-guided-worker");
    assert.match(inspect(), /Await or recover handoffs from worker \(fixture-guided-worker\)/);
    assert.doesNotMatch(inspect(), /execute acceptance/);
    writeFileSync(join(root, "artifact.txt"), "fixture artifact");
    recordAgentHandoff(root, runId, worker.assignment_id, {
      summary: "Offline worker fixture", changed_paths: ["artifact.txt"],
      artifacts: [{ path: "artifact.txt", sha256: sha256(readFileSync(join(root, "artifact.txt"))) }],
      commands: [], proposed_verdict: "PASS",
    });
    assert.match(inspect(), /Dependencies ready for verify-worker/);
    assert.doesNotMatch(inspect(), /factoryctl verify/);
    const plan = prepareSpawnPlan(root, readTaskGraphSnapshot(root, runId).tasks, runId);
    const verifier = plan.assignments[0];
    assert.match(inspect(), /Unregistered dispatches: verify-worker/);
    register(verifier.assignment_id, "fixture-guided-verifier");
    assert.match(inspect(), /fixture-guided-verifier/);
    recordAgentHandoff(root, runId, verifier.assignment_id, {
      summary: "Offline verifier fixture", changed_paths: [], artifacts: [], commands: [], proposed_verdict: "PASS",
    });
    const ready = inspect();
    assert.match(ready, /factoryctl verify/);
    assert.match(ready, new RegExp("--task worker --verifier-assignment " + verifier.assignment_id));
    assert.doesNotMatch(ready, /Await or recover|factoryctl plan/);
    const output = cli(root, ["run", "inspect", "--run", runId]);
    assert.equal(output.status, 0, output.stderr);
    assert.match(output.stdout, new RegExp(verifier.assignment_id));
    verifyTaskCompletion(root, runId, "worker", verifier.assignment_id);
    assert.match(inspect(), /Run complete/);
    assert.doesNotMatch(inspect(), /factoryctl plan|factoryctl verify/);
  });

  for (const context of [false, true]) {
    it("inspects FAIL without changing files, including context=" + context, () => {
      const root = project(context);
      const runId = failedFixture(root);
      const before = runFileSnapshot(root, root);
      const result = inspectRun(root, runId);
      assert.equal(result.status, "FAILED");
      assert.equal(result.host_liveness, "UNKNOWN");
      assert.match(result.tasks[0].failure_reasons.join(" "), /verifier/);
      assert.equal(result.tasks[0].evidence.length, 3);
      assert.equal(runFileSnapshot(root, root), before);
      const command = cli(root, ["run", "inspect", "--run", runId, "--json"]);
      assert.equal(command.status, 0, command.stderr);
      assert.equal(JSON.parse(command.stdout).status, "FAILED");
      assert.equal(runFileSnapshot(root, root), before);
    });
  }

  it("reports PASS and preserves historical evidence after artifacts change", () => {
    const root = project();
    prepareSpawnPlan(root, [repairTask()], "success");
    completeFixtureRun(root, "success", "PASS");
    writeFileSync(join(root, "artifact.txt"), "new working tree content");
    assert.equal(inspectRun(root, "success").status, "PASSED");
  });

  it("distinguishes queued and blocked states", () => {
    const root = project();
    prepareSpawnPlan(root, [repairTask()], "queued");
    assert.equal(inspectRun(root, "queued").status, "AWAITING_DISPATCH");
    setRunTaskStatus(root, "queued", "worker", "blocked");
    assert.equal(inspectRun(root, "queued").status, "BLOCKED");
    assert.match(inspectRun(root, "queued").next_actions.join(" "), /Resolve blocked tasks/);
    assert.doesNotMatch(inspectRun(root, "queued").next_actions.join(" "), /factoryctl plan/);
    const output = cli(root, ["run", "inspect", "--run", "queued"]);
    assert.match(output.stdout, /worker: blocked \(explicitly blocked\)/);
    assert.match(output.stdout, /verify-worker: pending \(blocked by: worker\)/);
  });

  it("does not create an unknown run and rejects traversal", () => {
    const root = project();
    const before = runFileSnapshot(root, root);
    assert.throws(() => inspectRun(root, "missing"), code("RUN_NOT_FOUND"));
    assert.throws(() => inspectRun(root, "../outside"), code("INVALID_ID"));
    assert.equal(runFileSnapshot(root, root), before);
    assert.equal(cli(root, ["run", "inspect", "--run", "missing", "--json"]).status, 1);
  });

  it("rejects missing and tampered failed receipts", () => {
    const root = project();
    failedFixture(root);
    const path = join(managedRunDirectory(root, "original"), "verification/worker/receipt.json");
    const saved = readFileSync(path, "utf8");
    const receipt = JSON.parse(saved);
    receipt.failure_reasons = [];
    writeJsonAtomic(path, receipt);
    assert.throws(() => inspectRun(root, "original"), /receipt.*invalid/);
    rmSync(path);
    assert.throws(() => inspectRun(root, "original"), /verification receipt/);
    assert.throws(() => createRepairRun(root, request()), /verification receipt/);
  });

  it("rejects forged terminal states and malformed registry identity", () => {
    const root = project();
    failedFixture(root);
    const path = join(managedRunDirectory(root, "original"), "agent-registry.json");
    const registry = readAgentRegistry(root, "original");
    writeJsonAtomic(path, { ...registry, project_id: "wrong-project" });
    assert.throws(() => inspectRun(root, "original"), code("RUN_INTEGRITY"));
    writeJsonAtomic(path, registry);
    const graph = readTaskGraphSnapshot(root, "original");
    graph.tasks[0].status = "verified";
    graph.graph_sha256 = sha256(stableStringify(graph.tasks));
    writeJsonAtomic(join(managedRunDirectory(root, "original"), "task-graph.json"), graph);
    assert.throws(() => inspectRun(root, "original"), /receipt.*invalid/);
  });

  it("does not rewrite a failed task on a same-state retry", () => {
    const root = project(); failedFixture(root);
    const before = runFileSnapshot(root, root);
    assert.equal(setRunTaskStatus(root, "original", "worker", "failed").status, "failed");
    assert.equal(runFileSnapshot(root, root), before);
  });

  it("rejects acceptance drift even when the task graph is rehashed", () => {
    const root = project(); failedFixture(root);
    const graph = readTaskGraphSnapshot(root, "original");
    graph.tasks[0].acceptance_methods = ["exists:unrelated.txt"];
    graph.graph_sha256 = sha256(stableStringify(graph.tasks));
    writeJsonAtomic(join(managedRunDirectory(root, "original"), "task-graph.json"), graph);
    assert.throws(() => inspectRun(root, "original"), code("RUN_INTEGRITY"));
    assert.throws(() => createRepairRun(root, request()), code("RUN_INTEGRITY"));
  });

  it("rejects mixed snapshots when another writer changes run metadata", (t) => {
    const root = project(); failedFixture(root);
    const path = join(managedRunDirectory(root, "original"), "run.json");
    const read = fs.readFileSync;
    let reads = 0;
    const replacement = t.mock.method(fs, "readFileSync", (file, options) => {
      if (String(file) === path && ++reads === 2) {
        const metadata = JSON.parse(read(path, "utf8"));
        writeJsonAtomic(path, { ...metadata, created_at: "2026-01-01T00:00:00.000Z" });
      }
      return read(file, options);
    });
    syncBuiltinESMExports();
    try { assert.throws(() => inspectRun(root, "original"), code("RUN_CHANGED")); }
    finally { replacement.mock.restore(); syncBuiltinESMExports(); }
  });

  it("reads committed WAL content without modifying an open source database", () => {
    const root = project(true); failedFixture(root);
    const db = new DatabaseSync(contextDatabasePath(root));
    try {
      db.exec("PRAGMA wal_autocheckpoint=0; CREATE TABLE inspection_probe (value TEXT); INSERT INTO inspection_probe VALUES ('committed')");
      const before = runFileSnapshot(root, root);
      assert.equal(inspectRun(root, "original").status, "FAILED");
      assert.equal(runFileSnapshot(root, root), before);
      db.exec("UPDATE context_events SET hash = 'tampered' WHERE sequence = 1");
      assert.throws(() => inspectRun(root, "original"), /ledger|hash/i);
    } finally { db.close(); }
  });
});

describe("bounded repair runs", () => {
  it("reuses the original task through the CLI without a task file and preserves retries", () => {
    const root = project();
    const task = repairTask({ title: "Keep original requirements", required_capabilities: ["implementation"] });
    prepareSpawnPlan(root, [task], "original");
    completeFixtureRun(root, "original", "FAIL");
    const before = runFileSnapshot(root, managedRunDirectory(root, "original"));
    const args = ["repair", "create", "--from-run", "original", "--task", "worker", "--reuse-task", "--request-id", "reuse-one", "--json"];
    const result = cli(root, args);
    assert.equal(result.status, 0, result.stderr);
    const created = JSON.parse(result.stdout);
    const graph = readTaskGraphSnapshot(root, created.run_id);
    assert.deepEqual(graph.tasks.find((item) => item.task_id === "worker"), task);
    assert.equal(graph.tasks.filter((item) => item.role === "verifier").length, 1);
    const plan = prepareSpawnPlan(root, graph.tasks, created.run_id);
    const metadataPath = join(managedRunDirectory(root, created.run_id), "run.json");
    assert.equal(JSON.parse(readFileSync(metadataPath, "utf8")).created_at, created.repair.created_at);
    const source = plan.assignments[0].prompt.split("\n").find((line) => line.startsWith("Repair source: "))!;
    assert.deepEqual(JSON.parse(source.slice("Repair source: ".length)), {
      parent_run_id: "original", failed_task_id: "worker", attempt: 1,
      receipt_path: ".codex-factory/runs/original/verification/worker/receipt.json",
      task_graph_path: ".codex-factory/runs/original/task-graph.json",
    });
    assert.match(plan.assignments[0].prompt, /historical observations, not current command results/);
    completeFixtureRun(root, created.run_id, "PASS");
    const retry = cli(root, args);
    assert.equal(JSON.parse(readFileSync(metadataPath, "utf8")).created_at, created.repair.created_at);
    assert.equal(retry.status, 0, retry.stderr);
    assert.equal(JSON.parse(retry.stdout).run_id, created.run_id);
    assert.equal(inspectRun(root, created.run_id).status, "PASSED");
    assert.equal(runFileSnapshot(root, managedRunDirectory(root, "original")), before);
  });

  it("rejects ambiguous reuse flags and reuse of unverified upstream tasks", () => {
    const root = project();
    const base = ["repair", "create", "--from-run", "original", "--task", "worker", "--request-id", "reuse-bad"];
    assert.match(cli(root, [...base, "--reuse-task", "--tasks", "missing.json"]).stderr, /not both/);
    assert.match(cli(root, [...base, "--reuse-task=false"]).stderr, /takes no value/);
    prepareSpawnPlan(root, [repairTask({ task_id: "upstream", write_scope: ["input.txt"] }), repairTask({ dependencies: ["upstream"] })], "original");
    const before = runFileSnapshot(root, root);
    const result = cli(root, [...base, "--reuse-task"]);
    assert.equal(result.status, 1);
    assert.match(result.stderr, /verified upstream tasks/);
    assert.equal(runFileSnapshot(root, root), before);
  });

  it("completes FAIL -> linked repair -> PASS, with immutable old run and idempotent retries", () => {
    const root = project(true);
    failedFixture(root);
    const before = runFileSnapshot(root, managedRunDirectory(root, "original"));
    const created = createRepairRun(root, request());
    assert.equal(created.repair.repair_index, 1);
    assert.equal(created.repair.parent_run_id, "original");
    assert.equal(inspectRun(root, created.run_id).status, "READY");
    assert.deepEqual(createRepairRun(root, request()), created);
    const plan = prepareSpawnPlan(root, readTaskGraphSnapshot(root, created.run_id).tasks, created.run_id);
    assert.match(plan.assignments[0].prompt, /Repair source: /);
    completeFixtureRun(root, created.run_id, "PASS");
    assert.equal(inspectRun(root, created.run_id).status, "PASSED");
    assert.equal(inspectRun(root, "original").status, "FAILED");
    assert.equal(runFileSnapshot(root, managedRunDirectory(root, "original")), before);
    assert.deepEqual(createRepairRun(root, request()), created);
  });

  it("rejects reused request IDs with changed inputs and sibling repairs", () => {
    const root = project(); failedFixture(root); createRepairRun(root, request());
    assert.throws(() => createRepairRun(root, { ...request(), tasks: [repairTask({ title: "changed" })] }), code("REQUEST_CONFLICT"));
    assert.throws(() => createRepairRun(root, request("original", "another")), code("REPAIR_CONFLICT"));
  });

  it("enforces two repairs across a chain of new run IDs", () => {
    const root = project(); failedFixture(root);
    const first = createRepairRun(root, request());
    completeFixtureRun(root, first.run_id, "FAIL");
    const second = createRepairRun(root, request(first.run_id, "repair-two"));
    assert.equal(second.repair.repair_index, 2);
    completeFixtureRun(root, second.run_id, "FAIL");
    assert.throws(() => createRepairRun(root, request(second.run_id, "repair-three")), code("REPAIR_LIMIT"));
  });

  it("rejects expanded scope, weaker acceptance and omitted target artifacts", () => {
    const root = project(); failedFixture(root);
    for (const scope of ["other.txt", "artifact.txt-other", "../outside", "C:/outside", "artifact.txt/*"]) {
      assert.throws(() => createRepairRun(root, { ...request(), tasks: [repairTask({ write_scope: [scope] })] }));
    }
    for (const task of [repairTask({ acceptance_methods: ["exists:other.txt"] }), repairTask({ required_artifacts: [] })]) {
      assert.throws(() => createRepairRun(root, { ...request(), tasks: [task] }), code("ACCEPTANCE_WEAKENED"));
    }
    assert.equal(existsSync(join(root, ".codex-factory", "runs", "repair-one")), false);
  });

  it("rejects active or unknown host lifecycle and non-failed source", () => {
    const root = project(); failedFixture(root);
    const registry = readAgentRegistry(root, "original");
    for (const lifecycle of ["running", "idle", "failed", "planned"] as const) {
      registry.entries[0].lifecycle = lifecycle;
      writeJsonAtomic(join(managedRunDirectory(root, "original"), "agent-registry.json"), registry);
      assert.throws(() => createRepairRun(root, request()), code("ACTIVE_EXECUTION"));
    }
    prepareSpawnPlan(root, [repairTask()], "queued");
    assert.throws(() => createRepairRun(root, request("queued")), code("NOT_REPAIRABLE"));
  });

  it("blocks partial creation from read, plan, status and repeated create", () => {
    const root = project(); failedFixture(root);
    const created = createRepairRun(root, request());
    const path = repairJournalPath(root, created.run_id);
    const journal = JSON.parse(readFileSync(path, "utf8"));
    writeJsonAtomic(path, { ...journal, state: "PREPARING" });
    assert.throws(() => inspectRun(root, created.run_id), code("REPAIR_INCOMPLETE"));
    assert.throws(() => prepareSpawnPlan(root, [repairTask()], created.run_id), code("REPAIR_INCOMPLETE"));
    assert.throws(() => setRunTaskStatus(root, created.run_id, "worker", "ready"), code("REPAIR_INCOMPLETE"));
    assert.throws(() => createRepairRun(root, request()), code("REPAIR_INCOMPLETE"));
    rmSync(join(managedRunDirectory(root, created.run_id), "repair-origin.json"));
    rmSync(path);
    assert.throws(() => prepareSpawnPlan(root, [repairTask()], created.run_id), code("REPAIR_INCOMPLETE"));
  });

  it("rejects repair contract edits even with a recomputed graph hash", () => {
    const root = project(); failedFixture(root);
    const created = createRepairRun(root, request());
    const graph = readTaskGraphSnapshot(root, created.run_id);
    graph.tasks[0].write_scope = ["outside.txt"];
    graph.graph_sha256 = sha256(stableStringify(graph.tasks));
    writeJsonAtomic(join(managedRunDirectory(root, created.run_id), "task-graph.json"), graph);
    assert.throws(() => prepareSpawnPlan(root, graph.tasks, created.run_id), code("REPAIR_INTEGRITY"));
  });

  it("refuses a child whose parent failure evidence was replaced", () => {
    const root = project(); failedFixture(root);
    const created = createRepairRun(root, request());
    const path = join(managedRunDirectory(root, "original"), "verification/worker/receipt.json");
    const receipt = JSON.parse(readFileSync(path, "utf8"));
    receipt.verified_at = "2099-01-01T00:00:00.000Z";
    const { receipt_hash: _old, ...unsigned } = receipt;
    writeJsonAtomic(path, { ...unsigned, receipt_hash: sha256(stableStringify(unsigned)) });
    assert.throws(() => inspectRun(root, created.run_id), code("REPAIR_INTEGRITY"));
    assert.throws(() => prepareSpawnPlan(root, [repairTask()], created.run_id), code("REPAIR_INTEGRITY"));
  });

  for (const stopAt of ["repair-origin.json", "task-graph.json", "agent-registry.json", "spawn-plan.json", "run.json", "commit"]) {
    it("fails closed on an interrupted write at " + stopAt, (t) => {
      const root = project(); failedFixture(root);
      const rename = fs.renameSync;
      let reservedRun = "";
      const replacement = t.mock.method(fs, "renameSync", (from, to) => {
        const destination = String(to);
        if (destination.includes("repair-r1-")) {
          reservedRun = destination.match(/repair-r1-[a-f0-9]{32}/)![0];
          const isCommit = destination.endsWith(reservedRun + ".json") && existsSync(destination);
          if ((stopAt === "commit" && isCommit) || destination.endsWith(stopAt)) throw new Error("Injected interrupted write");
        }
        rename(from, to);
      });
      syncBuiltinESMExports();
      try { assert.throws(() => createRepairRun(root, request()), /Injected interrupted write/); }
      finally { replacement.mock.restore(); syncBuiltinESMExports(); }
      assert.ok(reservedRun);
      assert.throws(() => createRepairRun(root, request()), code("REPAIR_INCOMPLETE"));
      assert.throws(() => prepareSpawnPlan(root, [repairTask()], reservedRun), code("REPAIR_INCOMPLETE"));
      assert.equal(inspectRun(root, "original").status, "FAILED");
    });
  }

  it("requires helper tasks to precede the original acceptance target", () => {
    const root = project(); failedFixture(root);
    const helper = repairTask({ task_id: "helper" });
    assert.throws(() => createRepairRun(root, { ...request(), tasks: [repairTask(), helper] }), code("INVALID_REPAIR"));
    const created = createRepairRun(root, { ...request(), tasks: [repairTask({ dependencies: ["helper"] }), helper] });
    const graph = readTaskGraphSnapshot(root, created.run_id);
    assert.equal(graph.tasks.filter((task) => task.profile_id === "factory_verifier").length, 2);
    assert.equal(prepareSpawnPlan(root, graph.tasks, created.run_id).assignments[0].task_id, "helper");
  });

  it("serializes simultaneous CLI retries to one committed child", async () => {
    const root = project(); failedFixture(root);
    writeJsonAtomic(join(root, "repair-tasks.json"), [repairTask()]);
    const args = ["repair", "create", "--from-run", "original", "--task", "worker", "--tasks", "repair-tasks.json", "--request-id", "cli-one", "--json"];
    const results = await Promise.all([asyncCli(root, args), asyncCli(root, args)]);
    for (const result of results) assert.equal(result.code, 0, result.stderr);
    assert.deepEqual(JSON.parse(results[0].stdout), JSON.parse(results[1].stdout));
  });

  it("does not admit two concurrent requests for the same failed parent", async () => {
    const root = project(); failedFixture(root);
    writeJsonAtomic(join(root, "repair-tasks.json"), [repairTask()]);
    const args = ["repair", "create", "--from-run", "original", "--task", "worker", "--tasks", "repair-tasks.json", "--json"];
    const results = await Promise.all([asyncCli(root, [...args, "--request-id", "first"]), asyncCli(root, [...args, "--request-id", "second"])]);
    assert.deepEqual(results.map((result) => result.code).sort(), [0, 1]);
    assert.match(results.find((result) => result.code === 1)!.stderr, /REPAIR_CONFLICT/);
  });
});
