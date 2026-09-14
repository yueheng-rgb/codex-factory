import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { basename, dirname, join, resolve } from "node:path";
import { it, type TestContext } from "node:test";
import { fileURLToPath } from "node:url";
import { getAgentProfile } from "../src/agents.js";
import { FACTORY_SKILL_CONTENT } from "../src/installer.js";
import { prepareSpawnPlan, setRunTaskStatus, verifyAssignmentInput } from "../src/orchestrator.js";
import { readJson, sha256, stableStringify, writeJsonAtomic } from "../src/util.js";
import { fixtureProject, repairTask } from "./helpers/repair-fixture.js";

function fixture(t: TestContext, context = false) {
  const root = fixtureProject(context);
  t.after(() => {
    assert.equal(dirname(root), resolve(tmpdir()));
    assert.ok(basename(root).startsWith("codex-factory-repair-"));
    rmSync(root, { recursive: true, force: true });
  });
  const plan = prepareSpawnPlan(root, [repairTask()], "input-check");
  const assignment = plan.assignments[0];
  const expected = { runId: plan.run_id, targetRole: getAgentProfile(assignment.profile_id).role,
    assignmentId: assignment.assignment_id };
  const path = join(root, assignment.context_packet_path);
  const verify = () => verifyAssignmentInput(root, assignment.context_packet_path, expected);
  return { root, assignment, expected, path, verify };
}

for (const context of [false, true]) {
  it(`uses one CLI and dispatch instruction with external context ${context ? "on" : "off"}`, (t) => {
    const { root, assignment, expected } = fixture(t, context);
    assert.match(assignment.prompt, /Before work, run: factoryctl context assignment-verify/);
    assert.match(assignment.prompt, /After successful verification, load your assigned profile and its role Skills/);
    assert.match(assignment.prompt, /Do not routinely reload the main-controller codex-factory Skill/);
    assert.match(assignment.prompt, /Stop if it fails/);
    assert.match(assignment.prompt, /professional Skills listed below/);
    assert.match(assignment.prompt, /main controller must dispatch an independent verifier/);
    assert.ok(assignment.prompt.indexOf("Before work, run:") < assignment.prompt.indexOf("After successful verification"));
    assert.doesNotMatch(assignment.prompt, /If this is a Context Packet/);
    assert.match(FACTORY_SKILL_CONTENT, /context assignment-verify/);
    const cli = fileURLToPath(new URL("../src/cli.ts", import.meta.url));
    const args = ["--import", "tsx", cli, "context", "assignment-verify", "--project", root,
      "--file", assignment.context_packet_path, "--run", expected.runId, "--role", expected.targetRole,
      "--assignment"];
    const success = spawnSync(process.execPath, [...args, expected.assignmentId, "--json"],
      { encoding: "utf8", windowsHide: true });
    assert.equal(success.status, 0, success.stderr + success.stdout);
    assert.deepEqual(JSON.parse(success.stdout), { valid: true, stale: false,
      kind: context ? "context_packet" : "task_capsule", issues: [] });
    const failure = spawnSync(process.execPath, [...args, "unregistered", "--json"],
      { encoding: "utf8", windowsHide: true });
    assert.equal(failure.status, 1, failure.stderr);
    assert.equal(JSON.parse(failure.stdout).valid, false);
  });
}

it("rejects capsule hash corruption and rehashed changes to the task contract or binding", (t) => {
  const { path, verify, root, assignment, expected } = fixture(t);
  const original = readJson<Record<string, unknown>>(path);
  writeJsonAtomic(path, { ...original, generated_at: "changed" });
  assert.match(verify().issues.join(";"), /hash mismatch/);
  for (const patch of [
    { project_id: "other-project" }, { run_id: "other-run" }, { assignment_id: "other-assignment" },
    { target_role: "verifier" }, { version: "999" },
    { task: { ...(original.task as object), write_scope: ["*"] } },
  ]) {
    const { capsule_hash: oldHash, ...unsigned } = { ...original, ...patch };
    writeJsonAtomic(path, { ...unsigned, capsule_hash: sha256(stableStringify(unsigned)) });
    assert.equal(verify().valid, false, JSON.stringify(patch));
  }
  writeJsonAtomic(path, original);
  assert.equal(verifyAssignmentInput(root, assignment.context_packet_path,
    { ...expected, targetRole: "verifier" }).valid, false);
  assert.equal(verifyAssignmentInput(root, assignment.context_packet_path,
    { ...expected, runId: "other-run" }).valid, false);
});

it("fails closed on missing, malformed and ambiguous inputs", (t) => {
  const { root, path, verify, expected } = fixture(t);
  const original = readJson<Record<string, unknown>>(path);
  for (const content of ["{", "null", "[]", "{}", JSON.stringify({ ...original, packet_hash: "also-present" })]) {
    writeFileSync(path, content);
    assert.equal(verify().valid, false, content);
  }
  assert.equal(verifyAssignmentInput(root, "missing.json", expected).valid, false);
});

it("verifies an original capsule after task failure without changing saved state", (t) => {
  const { root, path, verify, expected } = fixture(t);
  setRunTaskStatus(root, expected.runId, "worker", "failed");
  const paths = [path, ...["run.json", "task-graph.json", "agent-registry.json"].map((name) =>
    join(root, ".codex-factory", "runs", expected.runId, name))];
  const before = paths.map((file) => readFileSync(file));
  assert.equal(verify().valid, true);
  assert.deepEqual(paths.map((file) => readFileSync(file)), before);
});
