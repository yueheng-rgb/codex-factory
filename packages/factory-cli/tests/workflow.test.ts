import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { afterEach, describe, it } from "node:test";
import { fileURLToPath } from "node:url";
import { recordAgentHandoff } from "../src/evidence.js";
import { FACTORY_SKILL_CONTENT } from "../src/installer.js";
import { prepareSpawnPlan, readTaskGraphSnapshot, registerNativeDispatch, setRunTaskStatus, validateNewTasks,
  type ManagedSpawnPlanEntry } from "../src/orchestrator.js";
import { continueRun, createRepairRun } from "../src/run-management.js";
import { runFileSnapshot } from "../src/repair-store.js";
import { sha256, writeJsonAtomic } from "../src/util.js";
import { failedFixture, fixtureProject, repairTask } from "./helpers/repair-fixture.js";

const roots: string[] = [];
function project(context = false) { const root = fixtureProject(context); roots.push(root); return root; }
afterEach(() => { for (const root of roots.splice(0)) rmSync(root, { recursive: true, force: true }); });
const cliPath = join(dirname(fileURLToPath(import.meta.url)), "../src/cli.ts");
function cli(root: string, args: string[]) {
  return spawnSync(process.execPath, ["--import", "tsx", cliPath, "--project", root, ...args], { encoding: "utf8", windowsHide: true });
}
function register(root: string, runId: string, assignment: ManagedSpawnPlanEntry) {
  const nativeAgentId = "fixture-" + assignment.assignment_id;
  registerNativeDispatch(root, runId, assignment.assignment_id, {
    nativeAgentId, rawToolReceipt: { tool_name: "spawn_agent", agent_id: nativeAgentId, status: "spawned" },
  });
}
function handoff(root: string, runId: string, assignment: ManagedSpawnPlanEntry, proposal: "PASS" | "FAIL" = "PASS") {
  const task = readTaskGraphSnapshot(root, runId).tasks.find((task) => task.task_id === assignment.task_id)!;
  for (const path of task.required_artifacts) writeFileSync(join(root, path), "Offline output of " + task.task_id);
  recordAgentHandoff(root, runId, assignment.assignment_id, {
    summary: "Offline workflow fixture", changed_paths: task.required_artifacts,
    artifacts: task.required_artifacts.map((path) => ({ path, sha256: sha256(readFileSync(join(root, path))) })),
    commands: [], proposed_verdict: proposal,
  });
}

describe("developer workflow", () => {
  it("preflights raw task files without creating run state and rejects invalid new runs", () => {
    const root = project();
    const tasks = [repairTask()];
    writeJsonAtomic(join(root, "tasks.json"), { tasks });
    const before = runFileSnapshot(root, root);
    const result = cli(root, ["tasks", "validate", "--tasks", "tasks.json", "--json"]);
    assert.equal(result.status, 0, result.stderr);
    const validation = JSON.parse(result.stdout);
    assert.equal(validation.status, "VALID");
    assert.equal(validation.worker_count, 1);
    assert.equal(validation.verifier_count, 1);
    assert.deepEqual(validation.ready_task_ids, ["worker"]);
    assert.equal(runFileSnapshot(root, root), before);
    assert.equal(tasks.length, 1);
    const example = JSON.parse(readFileSync(join(dirname(cliPath), "../examples/module-delivery.tasks.json"), "utf8"));
    assert.equal(validateNewTasks(example).worker_count, 2);
    for (const task of [repairTask({ status: "verified" }), repairTask({ dependencies: ["missing"] }),
      repairTask({ required_artifacts: undefined }), repairTask({ acceptance_methods: [""] })]) {
      assert.throws(() => validateNewTasks([task]));
      assert.throws(() => prepareSpawnPlan(root, [task], "invalid"));
    }
    assert.equal(existsSync(join(root, ".codex-factory/runs")), false);
    assert.equal(cli(root, ["tasks", "validate", "--tasks", "tasks.json", "--unknown"]).status, 1);
    assert.equal(cli(root, ["run", "continue", "--run"]).status, 1);
  });

  for (const proposal of ["PASS", "FAIL"] as const) {
    it("advances a dependent two-file task through verification to " + proposal, () => {
      const root = project(true);
      const runId = "workflow";
      const initial = prepareSpawnPlan(root, [repairTask(), repairTask({
        task_id: "delivery", title: "Document the delivered artifact", dependencies: ["worker"],
        write_scope: ["delivery.txt"], required_artifacts: ["delivery.txt"], acceptance_methods: ["exists:delivery.txt"],
      })], runId);
      const worker = initial.assignments[0];
      assert.equal(worker.task_id, "worker");
      assert.deepEqual(continueRun(root, runId).plan?.assignments, initial.assignments);
      assert.deepEqual(continueRun(root, runId).plan?.assignments, initial.assignments);
      register(root, runId, worker);
      const beforeWaiting = runFileSnapshot(root, root);
      const waiting = continueRun(root, runId);
      assert.equal(waiting.status, "WAITING");
      assert.equal(waiting.waiting_for[0].native_agent_id, "fixture-" + worker.assignment_id);
      assert.equal(waiting.plan, null);
      assert.equal(runFileSnapshot(root, root), beforeWaiting);
      handoff(root, runId, worker);
      const review = continueRun(root, runId);
      assert.equal(review.status, "DISPATCH");
      assert.equal(review.delivery.tasks.length, 0);
      const verifier = review.plan!.assignments[0];
      assert.equal(verifier.task_id, "verify-worker");
      register(root, runId, verifier);
      handoff(root, runId, verifier);
      const next = continueRun(root, runId);
      assert.equal(next.verifications[0].verdict, "PASS");
      assert.equal(next.delivery.tasks.length, 1);
      assert.equal(next.delivery.complete, false);
      const second = next.plan!.assignments[0];
      assert.equal(second.task_id, "delivery");
      register(root, runId, second);
      handoff(root, runId, second);
      const finalVerifier = continueRun(root, runId).plan!.assignments[0];
      register(root, runId, finalVerifier);
      handoff(root, runId, finalVerifier, proposal);
      const command = cli(root, ["run", "continue", "--run", runId, "--json"]);
      assert.equal(command.status, proposal === "PASS" ? 0 : 1, command.stderr);
      const final = JSON.parse(command.stdout);
      assert.equal(final.status, proposal === "PASS" ? "COMPLETE" : "FAILED");
      assert.equal(final.verifications[0].verdict, proposal);
      assert.equal(final.plan, null);
      assert.equal(final.delivery.tasks.length, proposal === "PASS" ? 2 : 1);
      assert.equal(final.delivery.basis, "RECORDED_PASS_RECEIPTS");
      assert.equal(final.delivery.tasks[0].artifacts[0].sha256, sha256(readFileSync(join(root, "artifact.txt"))));
      assert.ok(existsSync(join(root, final.delivery.tasks[0].receipt_path)));
      if (proposal === "FAIL") assert.match(final.inspection.tasks.find((task: { task_id: string }) => task.task_id === "delivery").failure_reasons.join(" "), /verifier/);
      writeFileSync(join(root, "artifact.txt"), "Later working tree change");
      const terminalSnapshot = runFileSnapshot(root, root);
      const repeated = continueRun(root, runId);
      assert.equal(repeated.status, final.status);
      assert.deepEqual(repeated.verifications, []);
      assert.deepEqual(repeated.delivery, final.delivery);
      assert.equal(runFileSnapshot(root, root), terminalSnapshot);
      assert.match(cli(root, ["run", "continue", "--run", runId]).stdout, /Verified deliveries:/);
    });
  }

  it("leaves an explicit block alone and starts an approved repair through the same entry", () => {
    const root = project();
    prepareSpawnPlan(root, [repairTask()], "blocked");
    setRunTaskStatus(root, "blocked", "worker", "blocked");
    const before = runFileSnapshot(root, root);
    assert.equal(continueRun(root, "blocked").status, "BLOCKED");
    assert.equal(runFileSnapshot(root, root), before);
    failedFixture(root);
    const failedSnapshot = runFileSnapshot(root, root);
    assert.equal(continueRun(root, "original").status, "FAILED");
    assert.equal(runFileSnapshot(root, root), failedSnapshot);
    const repair = createRepairRun(root, { fromRun: "original", taskId: "worker", tasks: [repairTask()], requestId: "approved-repair" });
    assert.match(repair.next_action, /run continue/);
    const result = continueRun(root, repair.run_id);
    assert.equal(result.status, "DISPATCH");
    assert.equal(result.inspection.repair?.parent_run_id, "original");
  });

  it("installs the controller workflow without claiming autonomous native spawning", () => {
    assert.match(FACTORY_SKILL_CONTENT, /factoryctl tasks validate/);
    assert.match(FACTORY_SKILL_CONTENT, /factoryctl run continue/);
    assert.match(FACTORY_SKILL_CONTENT, /never spawns native agents/);
    assert.match(FACTORY_SKILL_CONTENT, /delivery.tasks/);
    assert.match(FACTORY_SKILL_CONTENT, /After repair is approved/);
  });
});
