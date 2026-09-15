import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import { caseIds, inputs, reference } from "../evals/diagnostic-routine/fixture.js";
import { gradeDiagnosticRoutine, prepareDiagnosticRoutine } from "../scripts/eval-diagnostic-routine.js";
import { budgetStatus } from "../scripts/eval-budget.js";
import { readAgentRegistry, readTaskGraphSnapshot } from "../src/orchestrator.js";
import { sha256 } from "../src/util.js";

const script = join(dirname(fileURLToPath(import.meta.url)), "../scripts/eval-diagnostic-routine.ts");
const run = (...args: string[]) => spawnSync(process.execPath, ["--import", "tsx", script, ...args], { encoding: "utf8", windowsHide: true, timeout: 30_000 });
function removePrepared(directory: string) {
  const target = resolve(directory);
  assert.equal(dirname(target), resolve(tmpdir()));
  assert.match(target, /[\\/]factory-diagnostic-routine-[^\\/]+$/);
  rmSync(target, { recursive: true, force: true });
}

test("diagnostic/routine preparation, calibration, routing and external integrity", async t => {
  const prepared = prepareDiagnosticRoutine();
  try {
    await t.test("references pass and seeds independently fail both graders", () => {
      assert.equal(prepared.calibration.length, 4);
      assert.ok(prepared.calibration.every(row => row.matched));
      assert.equal(prepared.calibration.filter(row => row.expected_pass).length, 2);
      assert.equal(prepared.trials.length, 6);
      for (const id of caseIds) {
        const trials = prepared.trials.filter(row => row.case_id === id);
        assert.equal(new Set(trials.map(row => row.input_sha256)).size, 1);
        assert.equal(Object.keys(inputs(id)).filter(path => path.endsWith(".cjs") && path !== "public.test.cjs").length, 8);
        for (const trial of trials) {
          for (const [path, hash] of Object.entries(trial.input_hashes)) assert.equal(sha256(readFileSync(join(trial.root, path))), hash);
          assert.ok(trial.frozen["public.test.cjs"]);
          assert.ok(trial.frozen["src/diagnostics.cjs"]);
          assert.ok(trial.frozen["docs/contract.md"]);
          assert.equal(existsSync(join(trial.root, "controller")), false);
          assert.equal(readdirSync(trial.root).some(name => /grade|reference|calibration/.test(name)), false);
          const budget = budgetStatus(trial.budget_root);
          assert.equal(budget.limit_ms, 1_200_000);
          assert.equal(budget.max_rounds, 2);
          assert.deepEqual(budget.admissions, []);
          assert.equal(budget.within_budget, null);
        }
      }
      const t5 = inputs("t5");
      const corrected = { ...t5, ...reference("t5") };
      assert.deepEqual(Object.keys(t5).filter(path => t5[path] !== corrected[path]), ["src/mapping.cjs"]);
    });

    await t.test("plain A has no Factory installation; B/C have pending independent verification without native receipts", () => {
      for (const trial of prepared.trials) {
        if (trial.arm === "A") {
          assert.equal(existsSync(join(trial.root, ".codex-factory")), false);
          assert.equal(existsSync(join(trial.root, ".codex")), false);
          assert.equal(trial.run_id, null);
          assert.equal(trial.assignment_id, null);
        } else {
          const graph = readTaskGraphSnapshot(trial.root, "initial");
          const worker = graph.tasks.find(task => task.task_id === "worker")!;
          const verifier = graph.tasks.find(task => task.role === "verifier")!;
          assert.equal(worker.status, "assigned");
          assert.equal(verifier.status, "pending");
          assert.deepEqual(verifier.dependencies, [worker.task_id]);
          assert.deepEqual(verifier.write_scope, []);
          assert.deepEqual(worker.write_scope, trial.task.write_scope);
          const registry = readAgentRegistry(trial.root, "initial");
          assert.equal(registry.entries.length, 1);
          assert.equal(registry.entries[0].native_agent_id, null);
          assert.deepEqual(registry.entries[0].native_receipts, []);
        }
        if (trial.case_id === "t5" && trial.arm === "C") {
          assert.match(trial.task.description, /Controller guidance \(not probe-module integration\)/);
          assert.match(trial.task.description, /competing hypotheses/);
        } else assert.equal(trial.controller_guidance, null);
      }
      const routine = prepared.trials.filter(row => row.case_id === "t6");
      assert.deepEqual(routine[1].task, routine[2].task);
      assert.doesNotMatch(routine[2].task.description, /lesson|probe|hypothes/i);
    });

    await t.test("root/case grader checks behavior without pretending an offline patch is a native result", () => {
      for (const id of caseIds) {
        const trial = prepared.trials.find(row => row.case_id === id && row.arm === "A")!;
        const seeded = gradeDiagnosticRoutine(trial.root, id);
        assert.equal(seeded.code_pass, false);
        assert.equal(seeded.checks?.visible.exit_code, 1);
        assert.equal(seeded.checks?.external.exit_code, 1);
        for (const [path, content] of Object.entries(reference(id))) writeFileSync(join(trial.root, path), content);
        const corrected = gradeDiagnosticRoutine(trial.root, id);
        assert.equal(corrected.code_pass, true, JSON.stringify(corrected.checks));
        assert.equal(corrected.native_evaluation, "NOT_ASSESSED");
        assert.equal(corrected.factory_verdict, null);
        assert.deepEqual(corrected.budget.admissions, []);
        const cli = run("grade", trial.root, id);
        assert.equal(cli.status, 0, cli.stderr);
        assert.equal(JSON.parse(cli.stdout).code_pass, true);
      }
      assert.throws(() => gradeDiagnosticRoutine(prepared.trials[0].root, "t6"), /Root\/case/);
    });

    await t.test("public-test, diagnostic, data and controller tampering fails closed", () => {
      const trial = prepared.trials[0];
      for (const path of ["public.test.cjs", "src/diagnostics.cjs", "data/repro.json", "docs/contract.md"]) {
        const target = join(trial.root, path);
        const original = readFileSync(target);
        try {
          writeFileSync(target, "throw Error('MUST NOT EXECUTE');\n");
          const grade = gradeDiagnosticRoutine(trial.root, trial.case_id);
          assert.equal(grade.code_pass, false);
          assert.deepEqual(grade.frozen_violations, [path]);
          assert.equal(grade.checks, null);
        } finally { writeFileSync(target, original); }
      }
      for (const path of [prepared.manifest, join(dirname(prepared.manifest), "t5-grade.cjs")]) {
        const original = readFileSync(path);
        try {
          writeFileSync(path, Buffer.concat([original, Buffer.from("\n")]));
          assert.throws(() => gradeDiagnosticRoutine(trial.root, trial.case_id), /Frozen (manifest|grader) changed/);
        } finally { writeFileSync(path, original); }
      }
    });

    await t.test("a second preparation uses fresh projects and rejects extra CLI arguments", () => {
      const second = prepareDiagnosticRoutine();
      try {
        assert.notEqual(second.directory, prepared.directory);
        assert.notEqual(second.trials[0].root, prepared.trials[0].root);
        assert.equal(readFileSync(join(second.trials[0].root, "src/mapping.cjs"), "utf8"), inputs("t5")["src/mapping.cjs"]);
      } finally { removePrepared(second.directory); }
      assert.equal(run("prepare", "unexpected").status, 1);
      assert.equal(run("grade").status, 1);
      assert.equal(run("grade", prepared.trials[0].root, "unknown").status, 1);
    });
  } finally { removePrepared(prepared.directory); }
});
