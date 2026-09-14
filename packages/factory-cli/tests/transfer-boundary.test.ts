import assert from "node:assert/strict";
import { existsSync, readFileSync, rmSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { tmpdir } from "node:os";
import { test } from "node:test";
import { dispatchTrial, gradeTrial, prepareTransferBoundary, reviewTrial } from "../scripts/eval-transfer-boundary.js";
import { budgetStatus } from "../scripts/eval-budget.js";

test("two task variants calibrate, share business inputs across arms and exclude controller answers", () => {
  const prepared = prepareTransferBoundary();
  const directory = dirname(dirname(prepared.manifest));
  assert.equal(dirname(directory), resolve(tmpdir()));
  assert.match(directory, /factory-transfer-boundary-/);
  try {
    const manifest = JSON.parse(readFileSync(prepared.manifest, "utf8"));
    assert.equal(manifest.trials.length, 6);
    assert.equal(manifest.calibration.rows.length, 8);
    assert.ok(manifest.calibration.rows.every((row: { matched: boolean }) => row.matched));
    for (const id of ["t3", "t4"]) {
      const trials = manifest.trials.filter((trial: { case_id: string }) => trial.case_id === id);
      assert.equal(new Set(trials.map((trial: { input_sha256: string }) => trial.input_sha256)).size, 1);
    }
    for (const trial of manifest.trials) {
      assert.equal(existsSync(join(trial.root, "grade.cjs")), false);
      assert.equal(existsSync(join(trial.root, "controller")), false);
      assert.equal(budgetStatus(trial.root).rounds_started, 0);
      assert.throws(() => gradeTrial(prepared.manifest, trial.id), /No completed host attempt/);
    }
    assert.throws(() => dispatchTrial(prepared.manifest, "t3-C"), /ENOENT/);
    const c = manifest.trials.find((trial: { id: string }) => trial.id === "t3-C");
    const applied = reviewTrial(prepared.manifest, c.id, { lesson_id: c.lesson_id, reason: "OFFLINE unit fixture: current tickets explicitly inherit the corrected legacy convention." });
    assert.ok(applied.effective_task_bytes > applied.original_task_bytes);
    const excluded = reviewTrial(prepared.manifest, "t4-C", { lesson_id: null, reason: "OFFLINE unit fixture: current exact-text boundary excludes import normalization." });
    assert.equal(excluded.effective_task_bytes, excluded.original_task_bytes);
    assert.throws(() => reviewTrial(prepared.manifest, "t4-C", { lesson_id: null, reason: "Overwrite" }), /already frozen/);
    const dispatch = dispatchTrial(prepared.manifest, "t4-C");
    assert.equal(dispatch.budget.action, "DISPATCH_ALLOWED");
    assert.equal(dispatch.role, "worker");
    assert.ok(!dispatch.prompt.includes("[Factory lesson "));
    assert.throws(() => dispatchTrial(prepared.manifest, "t4-C"), /still active/);
    assert.equal(budgetStatus(dispatch.root).admissions[0].agent_id, null, "Preparing a dispatch is not a native execution");
  } finally { rmSync(directory, { recursive: true, force: true }); }
});
