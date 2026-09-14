import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { afterEach, describe, it } from "node:test";
import { fileURLToPath } from "node:url";
import { recordAgentHandoff, verifyTaskCompletion, type WorkerCommandReport } from "../src/evidence.js";
import { FACTORY_SKILL_CONTENT } from "../src/installer.js";
import { prepareSpawnPlan, readTaskGraphSnapshot, registerNativeDispatch } from "../src/orchestrator.js";
import { continueRun, createRepairRun, prepareRepair } from "../src/run-management.js";
import { readRepairJournal, repairJournalPath, runFileSnapshot } from "../src/repair-store.js";
import { sha256, writeJsonAtomic } from "../src/util.js";
import { completeFixtureRun, failedFixture, fixtureProject, repairTask } from "./helpers/repair-fixture.js";

const roots: string[] = [];
function project(context = false) { const root = fixtureProject(context); roots.push(root); return root; }
afterEach(() => { for (const root of roots.splice(0)) rmSync(root, { recursive: true, force: true }); });
const cliPath = join(dirname(fileURLToPath(import.meta.url)), "../src/cli.ts");
function cli(root: string, args: string[]) {
  return spawnSync(process.execPath, ["--import", "tsx", cliPath, "--project", root, ...args], { encoding: "utf8", windowsHide: true });
}

// Host IDs and reports are offline fixtures; the control plane executes real acceptance checks.
function finish(root: string, runId: string, taskId: string, proposal: "PASS" | "FAIL", commands: WorkerCommandReport[] = []) {
  const graph = readTaskGraphSnapshot(root, runId).tasks;
  const task = graph.find((item) => item.task_id === taskId)!;
  const worker = prepareSpawnPlan(root, graph, runId).assignments.find((item) => item.task_id === taskId)!;
  const register = (id: string) => registerNativeDispatch(root, runId, id, {
    nativeAgentId: "fixture-" + id, rawToolReceipt: { tool_name: "spawn_agent", agent_id: "fixture-" + id, status: "spawned" },
  });
  register(worker.assignment_id);
  for (const path of task.required_artifacts) writeFileSync(join(root, path), "fixture output " + runId + "/" + taskId);
  recordAgentHandoff(root, runId, worker.assignment_id, {
    summary: "Offline worker fixture", changed_paths: task.required_artifacts,
    artifacts: task.required_artifacts.map((path) => ({ path, sha256: sha256(readFileSync(join(root, path))) })),
    commands, proposed_verdict: "PASS",
  });
  const review = continueRun(root, runId).plan!.assignments.find((item) => item.profile_id === "factory_verifier")!;
  register(review.assignment_id);
  recordAgentHandoff(root, runId, review.assignment_id, {
    summary: "Offline verifier fixture", changed_paths: [], artifacts: [], commands: [], proposed_verdict: proposal,
  });
  return verifyTaskCompletion(root, runId, taskId, review.assignment_id);
}

describe("repair preparation", () => {
  it("does not propose repairing a no-match diagnostic alongside a real failed test", () => {
    const root = project();
    prepareSpawnPlan(root, [repairTask()], "original");
    finish(root, "original", "worker", "PASS", [
      { command: "rg --files --hidden src -g '*.missing'", exit_code: 1 },
      { command: "npm test", exit_code: 1 },
    ]);
    const result = prepareRepair(root, "original", "worker");
    assert.equal(result.source_verdict, "FAIL");
    assert.equal(result.observations.reported_command_failures.total, 1);
    assert.equal(result.observations.reported_command_failures.items[0].command, "npm test");
  });
  it("separates reported command failures from passed acceptance without changing the verdict or files", () => {
    const root = project(true);
    prepareSpawnPlan(root, [repairTask()], "original");
    const commands = Array.from({ length: 23 }, (_, index) => ({ command: "fixture diagnostic " + index, exit_code: 1 }));
    const receipt = finish(root, "original", "worker", "PASS", commands);
    assert.equal(receipt.verdict, "FAIL");
    const before = runFileSnapshot(root, root);
    const result = prepareRepair(root, "original", "worker");
    assert.equal(result.status, "REVIEW_REQUIRED");
    assert.equal(result.source_verdict, "FAIL");
    assert.equal(result.root_cause, "NOT_INFERRED");
    assert.equal(result.observations.acceptance.failed, 0);
    assert.equal(result.observations.artifacts.failed, 0);
    assert.equal(result.observations.verifier_proposal, "PASS");
    assert.equal(result.observations.reported_command_failures.total, 23);
    assert.equal(result.observations.reported_command_failures.items.length, 20);
    assert.equal(result.observations.reported_command_failures.items[0].source, "WORKER_HANDOFF");
    assert.deepEqual(result.suggested_tasks, [repairTask()]);
    assert.equal(result.repair.remaining_attempts, 2);
    assert.equal(result.evidence.receipt_hash, receipt.receipt_hash);
    const output = cli(root, ["repair", "prepare", "--from-run", "original", "--task", "worker", "--json"]);
    assert.equal(output.status, 0, output.stderr);
    assert.deepEqual(JSON.parse(output.stdout), result);
    assert.match(cli(root, ["repair", "prepare", "--from-run", "original", "--task", "worker"]).stdout, /Acceptance: 1\/1 passed/);
    assert.equal(cli(root, ["repair", "prepare", "--from-run", "original", "--task", "worker", "--unknown"]).status, 1);
    assert.equal(cli(root, ["repair", "prepare", "--from-run", "original"]).status, 1);
    assert.equal(runFileSnapshot(root, root), before);
  });

  it("shows a real failed acceptance check and its evidence location without executing it again", () => {
    const root = project();
    prepareSpawnPlan(root, [repairTask({ acceptance_methods: ['command:node -e "process.exit(7)"'] })], "original");
    finish(root, "original", "worker", "PASS");
    const before = runFileSnapshot(root, root);
    const result = prepareRepair(root, "original", "worker");
    assert.equal(result.observations.acceptance.failed, 1);
    assert.equal(result.observations.acceptance.items[0].exit_code, 7);
    assert.equal(result.observations.acceptance.items[0].index, 1);
    assert.equal(result.observations.reported_command_failures.total, 0);
    assert.equal(readFileSync(join(root, result.evidence.verification_directory, "01-stderr.log"), "utf8"), "");
    assert.equal(runFileSnapshot(root, root), before);
  });

  it("preserves upstream input references across repairs and guides the existing chain to its limit", () => {
    const root = project();
    prepareSpawnPlan(root, [repairTask({ task_id: "upstream", write_scope: ["input.txt"],
      required_artifacts: ["input.txt"], acceptance_methods: ["exists:input.txt"] }),
      repairTask({ dependencies: ["upstream"] })], "original");
    finish(root, "original", "upstream", "PASS");
    finish(root, "original", "worker", "FAIL");
    const prepared = prepareRepair(root, "original", "worker");
    assert.equal(prepared.upstream_inputs[0].artifacts[0].path, "input.txt");
    assert.deepEqual(prepared.suggested_tasks![0].dependencies, []);
    const first = createRepairRun(root, { fromRun: "original", taskId: "worker", tasks: prepared.suggested_tasks!, requestId: "repair-1" });
    const existing = prepareRepair(root, "original", "worker");
    assert.equal(existing.status, "EXISTING_REPAIR");
    assert.equal(existing.repair.existing_child?.run_id, first.run_id);
    assert.match(existing.next_actions.join(" "), /run continue/);
    const assignment = continueRun(root, first.run_id).plan!.assignments[0];
    assert.match(assignment.prompt, /factoryctl repair prepare/);
    assert.match(assignment.prompt, /next_actions are for the main controller/);
    finish(root, first.run_id, "worker", "FAIL");
    const secondPreparation = prepareRepair(root, first.run_id, "worker");
    assert.equal(secondPreparation.upstream_inputs[0].run_id, "original");
    assert.equal(secondPreparation.upstream_inputs[0].artifacts[0].path, "input.txt");
    assert.equal(secondPreparation.repair.remaining_attempts, 1);
    assert.match(prepareRepair(root, "original", "worker").next_actions.join(" "), new RegExp("--from-run " + first.run_id));
    const second = createRepairRun(root, { fromRun: first.run_id, taskId: "worker", tasks: secondPreparation.suggested_tasks!, requestId: "repair-2" });
    finish(root, second.run_id, "worker", "FAIL");
    const limited = prepareRepair(root, second.run_id, "worker");
    assert.equal(limited.status, "BLOCKED");
    assert.equal(limited.repair.remaining_attempts, 0);
    assert.ok(limited.blockers.some((blocker) => blocker.code === "REPAIR_LIMIT"));
    assert.doesNotMatch(limited.next_actions.join(" "), /factoryctl repair create/);
    assert.equal(limited.upstream_inputs[0].run_id, "original");
  });

  it("points to the actual failed helper when the repair target has not run yet", () => {
    const root = project();
    const task = repairTask({ write_scope: ["artifact.txt", "helper.txt"] });
    prepareSpawnPlan(root, [task], "original");
    finish(root, "original", "worker", "FAIL");
    const repair = createRepairRun(root, { fromRun: "original", taskId: "worker", requestId: "helper-plan", tasks: [
      repairTask({ task_id: "helper", write_scope: ["helper.txt"], required_artifacts: ["helper.txt"], acceptance_methods: ["exists:helper.txt"] }),
      { ...task, dependencies: ["helper"] },
    ] });
    finish(root, repair.run_id, "helper", "FAIL");
    const result = prepareRepair(root, "original", "worker");
    assert.match(result.next_actions.join(" "), /--task helper --json/);
    assert.doesNotMatch(result.next_actions.join(" "), /--task worker --json/);
    assert.equal(prepareRepair(root, repair.run_id, "helper").status, "REVIEW_REQUIRED");
  });

  it("reports an already successful repair or an incomplete reservation instead of suggesting another create", () => {
    const root = project();
    failedFixture(root);
    const repair = createRepairRun(root, { fromRun: "original", taskId: "worker", tasks: [repairTask()], requestId: "one" });
    completeFixtureRun(root, repair.run_id, "PASS");
    const result = prepareRepair(root, "original", "worker");
    assert.equal(result.source_verdict, "FAIL");
    assert.equal(result.repair.existing_child?.status, "PASSED");
    assert.match(result.next_actions.join(" "), /existing repair passed/);
    assert.throws(() => prepareRepair(root, repair.run_id, "worker"), /failed worker/);
    const record = readRepairJournal(root, repair.run_id);
    writeJsonAtomic(repairJournalPath(root, repair.run_id), { ...record, state: "PREPARING" });
    const before = runFileSnapshot(root, root);
    const incomplete = prepareRepair(root, "original", "worker");
    assert.equal(incomplete.status, "BLOCKED");
    assert.ok(incomplete.blockers.some((blocker) => blocker.code === "REPAIR_INCOMPLETE"));
    assert.equal(incomplete.repair.existing_child?.state, "PREPARING");
    assert.doesNotMatch(incomplete.next_actions.join(" "), /factoryctl run continue/);
    assert.equal(runFileSnapshot(root, root), before);
    assert.match(FACTORY_SKILL_CONTENT, /Before proposing a repair, call `factoryctl repair prepare/);
  });
});
