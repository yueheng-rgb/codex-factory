import assert from "node:assert/strict";
import { test } from "node:test";
import { COMMAND_OUTCOME_POLICY, reportedCommandOutcomes } from "../src/command-outcome.js";

const listing = "rg --files --hidden .codex-factory -g '*verif*' -g '*receipt*' -g '*baseline*' -g '!native-receipts/**'";
const outcome = (command: string, exit_code = 1, acceptance: string[] = []) =>
  reportedCommandOutcomes([{ command, exit_code }], acceptance, COMMAND_OUTCOME_POLICY)[0];

test("recognizes the pilot's standalone no-match listing without erasing the original exit", () => {
  const report = { command: listing, exit_code: 1 };
  assert.deepEqual(reportedCommandOutcomes([report], [], COMMAND_OUTCOME_POLICY), ["NO_MATCH"]);
  assert.equal(report.exit_code, 1);
  assert.equal(outcome('rg.exe --files "src files" --glob "*.ts"'), "NO_MATCH");
  assert.equal(outcome(listing, 0), "SUCCESS");
});

test("keeps acceptance failures, actual execution errors and unknown commands blocking", () => {
  assert.equal(outcome(listing, 1, ["command:" + listing]), "FAILURE");
  for (const code of [2, -1, 127]) assert.equal(outcome(listing, code), "FAILURE");
  for (const command of ["npm test", "node test.cjs", "rg pattern file", "grep text file",
    "rg --files --unknown", "rg --files -g", "rg --files --pre command"])
    assert.equal(outcome(command), "FAILURE", command);
});

test("never treats shell wrappers, interpolation or compound commands as a no-match diagnostic", () => {
  for (const command of ["rg --files; npm test", "rg --files && npm test", "rg --files | node fail.cjs",
    "rg --files\nnpm test", "pwsh -Command 'rg --files'", '"rg" --files',
    'rg --files "$env:HOME"', "rg --files `n", "rg --files > output.txt", "rg --files 'unclosed"])
    assert.equal(outcome(command), "FAILURE", command);
});

test("old receipts retain strict semantics and unknown policies fail closed", () => {
  assert.deepEqual(reportedCommandOutcomes([{ command: listing, exit_code: 1 }], []), ["FAILURE"]);
  assert.throws(() => reportedCommandOutcomes([], [], "future-policy"), /Unsupported/);
});

const acceptance = "command:node --test public.test.cjs";
const checked = { method: acceptance, status: "PASS", exit_code: 0,
  stdout_sha256: "a".repeat(64), stderr_sha256: "b".repeat(64) };
const failedReport = { command: "node --test public.test.cjs", exit_code: 1 };

test("recovers a reported failure only from the matching controller acceptance recheck", () => {
  assert.deepEqual(reportedCommandOutcomes([failedReport], [acceptance], COMMAND_OUTCOME_POLICY, [checked]), ["RECHECK_PASSED"]);
  assert.equal(failedReport.exit_code, 1);
  const alias = " cmd: node --test public.test.cjs ";
  assert.deepEqual(reportedCommandOutcomes([failedReport], [alias], COMMAND_OUTCOME_POLICY, [{ ...checked, method: alias }]), ["RECHECK_PASSED"]);
});

test("recheck requires full contract binding, successful execution and output digests", () => {
  for (const checks of [[], [{ ...checked, method: "command:other" }], [{ ...checked, status: "FAIL" }],
    [{ ...checked, exit_code: 1 }], [{ ...checked, exit_code: null }], [{ ...checked, stdout_sha256: undefined }],
    [{ ...checked, stderr_sha256: "bad" }], [checked, checked]]) {
    assert.deepEqual(reportedCommandOutcomes([failedReport], [acceptance], COMMAND_OUTCOME_POLICY, checks), ["FAILURE"]);
  }
  assert.deepEqual(reportedCommandOutcomes([failedReport], [acceptance, acceptance], COMMAND_OUTCOME_POLICY,
    [checked, { ...checked, status: "FAIL", exit_code: 1 }]), ["FAILURE"]);
  for (const exit_code of [-1, 126, 127, 130, 256, null, "1"]) {
    assert.deepEqual(reportedCommandOutcomes([{ ...failedReport, exit_code }], [acceptance], COMMAND_OUTCOME_POLICY, [checked]), ["FAILURE"]);
  }
});

test("self-declared expected exits, unrelated and compound commands cannot borrow a passing check", () => {
  for (const command of ["node missing.cjs", "node cli.cjs report invalid.json", "Get-ChildItem self.test.cjs",
    failedReport.command + " && node fail.cjs", "pwsh -Command '" + failedReport.command + "'"]) {
    const report = { command, exit_code: 1, expected_exit_code: 1, phase: "before-edit", parent_command: failedReport.command };
    assert.deepEqual(reportedCommandOutcomes([report], [acceptance], COMMAND_OUTCOME_POLICY, [checked]), ["FAILURE"]);
  }
});

test("v1 and unversioned receipt outcomes never acquire recovery retrospectively", () => {
  for (const policy of [undefined, "rg-files-v1"]) {
    assert.deepEqual(reportedCommandOutcomes([failedReport], [acceptance], policy, [checked]), ["FAILURE"]);
  }
});
