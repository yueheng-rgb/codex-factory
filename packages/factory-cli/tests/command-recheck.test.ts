import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { afterEach, test } from "node:test";
import { recordAgentHandoff, verifyTaskCompletion } from "../src/evidence.js";
import { prepareSpawnPlan, readTaskGraphSnapshot, registerNativeDispatch } from "../src/orchestrator.js";
import { inspectRun, prepareRepair } from "../src/run-management.js";
import { sha256, stableStringify } from "../src/util.js";
import { fixtureProject, repairTask } from "./helpers/repair-fixture.js";

const roots: string[] = [];
afterEach(() => {
  for (const root of roots.splice(0)) rmSync(root, { recursive: true, force: true });
});

// Native IDs are offline fixtures. Command executions, logs and receipt checks are real.
function scenario(options: { context?: boolean; broken?: boolean; unknown?: boolean; mutates?: boolean; proposal?: "PASS" | "FAIL" } = {}) {
  const root = fixtureProject(options.context);
  roots.push(root);
  const command = "node check.cjs";
  writeFileSync(join(root, "check.cjs"), "const fs=require('node:fs'); if(!fs.existsSync('artifact.txt')||fs.readFileSync('artifact.txt','utf8')!=='fixed')process.exit(1); console.log('accepted');\n");
  const runId = "recheck";
  const methods = ["command:" + command];
  if (options.mutates) methods.push('command:node -e "require(\'node:fs\').writeFileSync(\'artifact.txt\',\'changed by check\')"');
  const worker = prepareSpawnPlan(root, [repairTask({ acceptance_methods: methods })], runId).assignments[0];
  const register = (id: string) => registerNativeDispatch(root, runId, id, {
    nativeAgentId: "fixture-" + id, rawToolReceipt: { tool_name: "spawn_agent", agent_id: "fixture-" + id, status: "spawned" },
  });
  register(worker.assignment_id);
  const run = (file: string) => spawnSync(process.execPath, [file], { cwd: root, encoding: "utf8", windowsHide: true });
  const before = run("check.cjs");
  assert.equal(before.status, 1);
  writeFileSync(join(root, "artifact.txt"), options.broken ? "broken" : "fixed");
  const after = run("check.cjs");
  const commands = [{ command, exit_code: before.status! }, { command, exit_code: after.status! }];
  if (options.unknown) commands.push({ command: "node missing.cjs", exit_code: run("missing.cjs").status! });
  recordAgentHandoff(root, runId, worker.assignment_id, {
    summary: "Actual failing reproduction followed by attempted fix", changed_paths: ["artifact.txt"],
    artifacts: [{ path: "artifact.txt", sha256: sha256(readFileSync(join(root, "artifact.txt"))) }],
    commands, proposed_verdict: "PASS",
  });
  const review = prepareSpawnPlan(root, readTaskGraphSnapshot(root, runId).tasks, runId).assignments[0];
  register(review.assignment_id);
  recordAgentHandoff(root, runId, review.assignment_id, {
    summary: "Offline independent review fixture", changed_paths: [], artifacts: [],
    commands: [{ command, exit_code: run("check.cjs").status! }], proposed_verdict: options.proposal ?? "PASS",
  });
  const receipt = verifyTaskCompletion(root, runId, "worker", review.assignment_id);
  const directory = join(root, ".codex-factory/runs", runId, "verification/worker");
  return { root, runId, receipt, directory, worker };
}

test("real controller recheck resolves the earlier failure without changing its recorded exit", () => {
  for (const context of [false, true]) {
    const s = scenario({ context });
    assert.equal(s.receipt.verdict, "PASS");
    assert.deepEqual(s.receipt.command_outcomes?.worker, ["RECHECK_PASSED", "SUCCESS"]);
    assert.equal(s.receipt.acceptance_checks[0].exit_code, 0);
    const handoff = JSON.parse(readFileSync(join(s.root, ".codex-factory/runs", s.runId, "handoffs", s.worker.assignment_id + ".json"), "utf8"));
    assert.equal(handoff.report.commands[0].exit_code, 1);
    assert.equal(inspectRun(s.root, s.runId).status, "PASSED");
    assert.deepEqual(prepareSpawnPlan(s.root, readTaskGraphSnapshot(s.root, s.runId).tasks, s.runId).assignments, []);
  }
});

test("a genuinely failing current check or independent rejection still fails", () => {
  for (const options of [{ broken: true }, { proposal: "FAIL" as const }]) {
    const s = scenario(options);
    assert.equal(s.receipt.verdict, "FAIL");
    assert.equal(inspectRun(s.root, s.runId).status, "FAILED");
  }
});

test("unrelated failures remain blocking and repair preparation excludes only the recovered check", () => {
  const s = scenario({ unknown: true });
  assert.equal(s.receipt.verdict, "FAIL");
  assert.deepEqual(s.receipt.command_outcomes?.worker, ["RECHECK_PASSED", "SUCCESS", "FAILURE"]);
  const repair = prepareRepair(s.root, s.runId, "worker");
  assert.equal(repair.observations.reported_command_failures.total, 1);
  assert.equal(repair.observations.reported_command_failures.items[0].command, "node missing.cjs");
});

test("a passing acceptance command cannot replace the delivered artifact during recheck", () => {
  const s = scenario({ mutates: true });
  assert.ok(s.receipt.acceptance_checks.every(check => check.status === "PASS"));
  assert.equal(s.receipt.verdict, "FAIL");
  assert.ok(s.receipt.failure_reasons.includes("One or more physical artifact checks failed"));
  assert.equal(inspectRun(s.root, s.runId).status, "FAILED");
});

test("receipt reload rejects removed or altered recheck logs", () => {
  for (const stream of ["stdout", "stderr"]) {
    const s = scenario();
    const path = join(s.directory, "01-" + stream + ".log");
    if (stream === "stdout") writeFileSync(path, "altered");
    else rmSync(path);
    assert.throws(() => inspectRun(s.root, s.runId), /recheck log/i);
  }
});

test("rehashed receipt cannot invent recovery, change its contract or substitute a log digest", () => {
  for (const mutation of ["outcome", "exit", "method", "digest"]) {
    const s = scenario();
    const path = join(s.directory, "receipt.json");
    const receipt = JSON.parse(readFileSync(path, "utf8"));
    if (mutation === "outcome") receipt.command_outcomes.worker[0] = "SUCCESS";
    if (mutation === "exit") receipt.acceptance_checks[0].exit_code = 1;
    if (mutation === "method") receipt.acceptance_checks[0].method = "command:other";
    if (mutation === "digest") receipt.acceptance_checks[0].stdout_sha256 = "0".repeat(64);
    const { receipt_hash: ignored, ...unsigned } = receipt;
    receipt.receipt_hash = sha256(stableStringify(unsigned));
    writeFileSync(path, JSON.stringify(receipt));
    assert.throws(() => inspectRun(s.root, s.runId), /receipt/i);
  }
});
