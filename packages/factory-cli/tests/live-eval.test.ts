import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { tmpdir } from "node:os";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const script = join(dirname(fileURLToPath(import.meta.url)), "../scripts/live-eval.ts");
const run = (...args: string[]) => spawnSync(process.execPath, ["--import", "tsx", script, ...args], { encoding: "utf8", windowsHide: true });

test("live evaluation preparation is isolated, seeded checks fail, and incomplete host evidence is not success", () => {
  const prepared = run("prepare");
  assert.equal(prepared.status, 0, prepared.stderr);
  const result = JSON.parse(prepared.stdout);
  const directory = dirname(result.manifest);
  assert.equal(dirname(resolve(directory)), resolve(tmpdir()));
  assert.match(directory, /factory-live-eval-/);
  try {
    assert.equal(result.cases.length, 2);
    for (const item of result.cases) {
      assert.equal(existsSync(join(item.root, ".agents/skills/codex-factory/SKILL.md")), true);
      assert.equal(existsSync(join(item.root, ".git")), true);
      const check = spawnSync(process.execPath, ["check.cjs"], { cwd: item.root, encoding: "utf8", windowsHide: true });
      assert.equal(check.status, 1, "Unimplemented or intentionally defective seeds must fail before real work");
    }
    const report = run("summarize", result.manifest);
    assert.equal(report.status, 0, report.stderr);
    const body = JSON.parse(report.stdout);
    assert.equal(body.metrics.final_pass, 0);
    assert.equal(body.metrics.tokens, null);
    assert.equal(body.metrics.cost, null);
    assert.equal(body.cases[0].evaluation_budget.enforcement, "CONTROLLER_COOPERATIVE");
    assert.equal(body.cases[0].evaluation_budget.within_budget, null);
    assert.equal(body.metrics.natural_cases, 1);
    assert.equal(body.metrics.seeded_cases, 1);
    assert.equal(run("checkpoint", result.cases[0].root).status, 1);
    const checkPath = join(result.cases[0].root, "check.cjs");
    writeFileSync(checkPath, readFileSync(checkPath, "utf8") + "\n// changed\n");
    assert.equal(run("summarize", result.manifest).status, 1);
  } finally { rmSync(directory, { recursive: true, force: true }); }
});

test("live evaluation CLI rejects extra arguments", () => {
  assert.equal(run("prepare", "unexpected").status, 1);
});

test("offline unit fixtures exercise host capture validation without being counted as live trials", () => {
  const prepared = run("prepare");
  assert.equal(prepared.status, 0, prepared.stderr);
  const result = JSON.parse(prepared.stdout);
  const directory = dirname(result.manifest);
  assert.equal(dirname(resolve(directory)), resolve(tmpdir()));
  assert.match(directory, /factory-live-eval-/);
  try {
    const item = result.cases[0];
    const observationPath = join(item.root, ".codex-factory", "unit-observation.json");
    const admission = run("budget-admit", item.root, "initial", item.assignment_id, "worker", "1");
    assert.equal(admission.status, 0, admission.stderr);
    const observation = {
      tool: "multi_agent_v1__spawn_agent", started_at: new Date().toISOString(), returned_at: "invalid",
      response: { agent_id: "OFFLINE-UNIT-FIXTURE-ONLY", nickname: null },
    };
    writeFileSync(observationPath, JSON.stringify(observation));
    assert.equal(run("register", item.root, "initial", item.assignment_id, observationPath).status, 1);
    observation.returned_at = new Date().toISOString();
    writeFileSync(observationPath, JSON.stringify(observation));
    assert.equal(run("register", item.root, "initial", item.assignment_id, observationPath).status, 0);
    assert.equal(run("summarize", result.manifest).status, 1, "Registered ID alone cannot establish live completion");
    writeFileSync(observationPath, JSON.stringify({
      tool: "multi_agent_v1__wait_agent", response: { status: { "OFFLINE-UNIT-FIXTURE-ONLY": "running" } },
    }));
    assert.equal(run("handoff", item.root, "initial", item.assignment_id, observationPath).status, 1);
    const handoff = { summary: "Unit fixture", changed_paths: ["../../outside.txt"], artifacts: [], commands: [], proposed_verdict: "PASS" };
    const completed = "FACTORY_HANDOFF_JSON=" + JSON.stringify(handoff);
    writeFileSync(observationPath, JSON.stringify({
      tool: "mcp__codex_app__read_thread", response: { thread: { id: "another-agent" },
        turns: [{ status: "completed", items: [{ type: "agentMessage", phase: "final_answer", text: completed }] }] },
    }));
    assert.equal(run("handoff", item.root, "initial", item.assignment_id, observationPath).status, 1);
    writeFileSync(observationPath, JSON.stringify({
      tool: "mcp__codex_app__read_thread", response: { thread: { id: "OFFLINE-UNIT-FIXTURE-ONLY" },
        turns: [{ status: "completed", items: [{ type: "agentMessage", phase: "final_answer", text: completed }] }] },
    }));
    const escaped = run("handoff", item.root, "initial", item.assignment_id, observationPath);
    assert.equal(escaped.status, 1);
    assert.match(escaped.stderr, /escapes project root/);
    writeFileSync(observationPath, JSON.stringify({
      tool: "multi_agent_v1__wait_agent", response: { status: { "OFFLINE-UNIT-FIXTURE-ONLY": {
        completed: "FACTORY_HANDOFF_JSON=" + JSON.stringify({ ...handoff, changed_paths: [], artifacts: ["solution.cjs"] }),
      } } },
    }));
    const malformed = run("handoff", item.root, "initial", item.assignment_id, observationPath);
    assert.equal(malformed.status, 1);
    assert.match(malformed.stderr, /Invalid handoff schema/);
    assert.equal(existsSync(join(item.root, ".codex-factory/runs/initial/handoffs", item.assignment_id + ".json")), false);
    const captures = join(item.root, ".codex-factory/host-observations");
    mkdirSync(captures);
    writeFileSync(join(captures, "spawn.json"), JSON.stringify(observation));
    const valid = { ...handoff, changed_paths: [], proposed_verdict: "FAIL",
      artifacts: [{ path: join(item.root, "solution.cjs"), sha256: createHash("sha256").update(readFileSync(join(item.root, "solution.cjs"))).digest("hex") }] };
    const completion = {
      tool: "multi_agent_v1__wait_agent", started_at: new Date().toISOString(), returned_at: new Date().toISOString(),
      response: { status: { "OFFLINE-UNIT-FIXTURE-ONLY": { completed: "FACTORY_HANDOFF_JSON=" + JSON.stringify(valid) } } },
    };
    const completionPath = join(captures, "completion.json");
    writeFileSync(completionPath, JSON.stringify(completion));
    const accepted = run("handoff", item.root, "initial", item.assignment_id, completionPath);
    assert.equal(accepted.status, 0, accepted.stderr);
    const capturedReport = run("summarize", result.manifest);
    assert.equal(capturedReport.status, 0, capturedReport.stderr);
    assert.equal(JSON.parse(capturedReport.stdout).metrics.final_pass, 0);
    completion.response.status["OFFLINE-UNIT-FIXTURE-ONLY"].completed = "FACTORY_HANDOFF_JSON=" + JSON.stringify({ ...valid, summary: "Altered completion" });
    writeFileSync(completionPath, JSON.stringify(completion));
    const mismatch = run("summarize", result.manifest);
    assert.equal(mismatch.status, 1);
    assert.match(mismatch.stderr, /Captured completion differs from recorded handoff/);
  } finally { rmSync(directory, { recursive: true, force: true }); }
});
