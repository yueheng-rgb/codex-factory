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
