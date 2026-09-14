import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { afterEach, describe, it } from "node:test";
import { fileURLToPath } from "node:url";
import { FACTORY_SKILL_CONTENT } from "../src/installer.js";
import { createProbeDraft, inspectProbe, observeProbe, prepareProbeRepair, probeTemplate } from "../src/probes.js";
import { runFileSnapshot } from "../src/repair-store.js";
import { continueRun, createRepairRun, prepareRepair } from "../src/run-management.js";
import { readTaskGraphSnapshot } from "../src/orchestrator.js";
import { readJson, sha256, writeJsonAtomic } from "../src/util.js";
import { completeFixtureRun, failedFixture, fixtureProject, repairTask } from "./helpers/repair-fixture.js";

const roots: string[] = [];
function project() { const root = fixtureProject(); roots.push(root); failedFixture(root); return root; }
afterEach(() => { for (const root of roots.splice(0)) rmSync(root, { recursive: true, force: true }); });
function draft(root: string) { return createProbeDraft(root, "original", "worker", probeTemplate()); }
function observe(root: string, view: ReturnType<typeof draft>) {
  return observeProbe(root, view.draft.probe_id, { draftHash: view.draft.draft_hash, userReply: "Offline fixture approval" });
}

describe("hypothesis probes", () => {
  it("carries a probe lead through real repair planning, idempotent CLI create and independent fixture verification", () => {
    const root = project();
    const view = draft(root);
    assert.throws(() => prepareProbeRepair(root, view.draft.probe_id), /saved matching prediction/);
    writeJsonAtomic(join(root, "diagnostic.json"), { normalized: { retries: 0 } });
    observe(root, view);
    const before = runFileSnapshot(root, root);
    const prepared = prepareProbeRepair(root, view.draft.probe_id);
    assert.equal(runFileSnapshot(root, root), before);
    assert.deepEqual({ ...prepared.tasks![0], description: repairTask().description }, repairTask());
    assert.ok(prepared.tasks![0].description.includes(prepared.observation_path!));
    assert.match(prepared.tasks![0].description, /NOT a proven root cause/);
    const cliPath = join(dirname(fileURLToPath(import.meta.url)), "../src/cli.ts");
    const cli = (args: string[]) => spawnSync(process.execPath, ["--import", "tsx", cliPath, "--project", root, ...args, "--json"],
      { encoding: "utf8", windowsHide: true });
    assert.equal(cli(["probe", "repair-plan", "--id", view.draft.probe_id]).status, 0);
    const args = ["repair", "create", "--from-run", "original", "--task", "worker", "--probe", view.draft.probe_id, "--request-id", "guided"];
    assert.equal(cli([...args, "--reuse-task"]).status, 1);
    const wrong = [...args]; wrong[wrong.indexOf("--task") + 1] = "other";
    assert.match(cli(wrong).stderr, /different failed run\/task/);
    const created = cli(args);
    assert.equal(created.status, 0, created.stderr);
    assert.deepEqual(JSON.parse(cli(args).stdout), JSON.parse(created.stdout));
    const runId = JSON.parse(created.stdout).run_id;
    const continuation = continueRun(root, runId);
    assert.match(continuation.plan!.assignments[0].prompt, /Investigation direction/);
    const graph = readTaskGraphSnapshot(root, runId);
    assert.match(graph.tasks.find((task) => task.task_id === "worker")!.description, /retry-loop termination/);
    assert.match(graph.tasks.find((task) => task.profile_id === "factory_verifier")!.description, /full description/);
    completeFixtureRun(root, runId, "PASS");
    assert.equal(continueRun(root, runId).status, "COMPLETE");
    assert.equal(prepareRepair(root, "original", "worker").source_verdict, "FAIL");
    assert.equal(prepareProbeRepair(root, view.draft.probe_id).status, "EXISTING_REPAIR");
    assert.deepEqual(JSON.parse(cli(args).stdout), JSON.parse(created.stdout));
  });

  it("binds a reviewed observation to failure evidence without changing the run or repair budget", () => {
    const root = project();
    const before = runFileSnapshot(root, join(root, ".codex-factory/runs/original"));
    const preparation = prepareRepair(root, "original", "worker");
    const view = draft(root);
    assert.equal(view.status, "REVIEW_REQUIRED");
    assert.equal(view.draft.data.receipt_hash, preparation.evidence.receipt_hash);
    assert.deepEqual(draft(root), view);
    const snapshot = runFileSnapshot(root, root);
    assert.deepEqual(inspectProbe(root, view.draft.probe_id), view);
    assert.equal(runFileSnapshot(root, root), snapshot);
    writeFileSync(join(root, "diagnostic.json"), '\uFEFF{"normalized":{"retries":3}}');
    const observed = observe(root, view);
    assert.equal(observed.status, "MATCHED_PREDICTION");
    assert.equal(observed.observation!.data.matching_hypothesis, "H1");
    assert.equal(observed.observation!.data.file_sha256, sha256(readFileSync(join(root, "diagnostic.json"))));
    assert.match(observed.next_step, /configuration normalization/);
    assert.equal(observed.source_verdict, "FAIL");
    assert.equal(observed.repair.remaining_attempts, 2);
    assert.deepEqual(prepareRepair(root, "original", "worker"), preparation);
    assert.equal(runFileSnapshot(root, join(root, ".codex-factory/runs/original")), before);
    writeJsonAtomic(join(root, "diagnostic.json"), { normalized: { retries: 0 } });
    assert.deepEqual(observe(root, view), observed);
  });

  it("requires distinct predictions and actual failing channels", () => {
    const root = project();
    const proposal = probeTemplate();
    proposal.hypotheses[1].expected = 3;
    assert.throws(() => createProbeDraft(root, "original", "worker", proposal), /Predictions must differ/);
    proposal.hypotheses[1].expected = 0;
    proposal.hypotheses[0].evidence_refs = ["acceptance"];
    assert.throws(() => createProbeDraft(root, "original", "worker", proposal), /no observed failure/);
    proposal.hypotheses.pop();
    assert.throws(() => createProbeDraft(root, "original", "worker", proposal), /exactly two/);
    assert.equal(existsSync(join(root, ".codex-factory/probes")), false);
  });

  it("keeps unexpected values, missing fields and non-scalars inconclusive; decodes JSON Pointer escapes", () => {
    const root = project();
    for (const [index, value] of [0, "0", null, {}, undefined].entries()) {
      const proposal = probeTemplate();
      proposal.question += " case " + index;
      proposal.observation.pointer = "/a~1b/~0key/0";
      const view = createProbeDraft(root, "original", "worker", proposal);
      writeJsonAtomic(join(root, "diagnostic.json"), value === undefined ? {} : { "a/b": { "~key": [value] } });
      const result = observe(root, view);
      assert.equal(result.status, index === 0 ? "MATCHED_PREDICTION" : "INCONCLUSIVE");
      assert.equal(result.observation!.data.matching_hypothesis, index === 0 ? "H2" : null);
      assert.equal(result.observation!.data.field_status, index === 3 ? "NON_SCALAR" : index === 4 ? "MISSING" : "SCALAR");
    }
    const proposal = probeTemplate();
    proposal.observation.pointer = "/bad~2escape";
    assert.throws(() => createProbeDraft(root, "original", "worker", proposal), /JSON Pointer/);
  });

  it("rejects mismatched approval, altered drafts and observations after a repair was created", () => {
    const root = project();
    const view = draft(root);
    assert.throws(() => observeProbe(root, view.draft.probe_id, { draftHash: "wrong", userReply: "yes" }), /reviewed draft hash/);
    assert.throws(() => observeProbe(root, view.draft.probe_id, { draftHash: view.draft.draft_hash, userReply: " " }), /approval reply/);
    const path = join(root, ".codex-factory/probes", view.draft.probe_id, "draft.json");
    const changed = readJson<typeof view.draft>(path);
    changed.data.proposal.hypotheses[0].expected = 99;
    writeJsonAtomic(path, changed);
    assert.throws(() => inspectProbe(root, view.draft.probe_id), /integrity mismatch/);
    writeJsonAtomic(path, view.draft);
    createRepairRun(root, { fromRun: "original", taskId: "worker", requestId: "existing", tasks: [repairTask()] });
    assert.throws(() => observe(root, view), /Repair state changed/);
    assert.throws(() => draft(root), /existing repair/);
  });

  it("rejects escaped, sensitive, malformed and oversized diagnostic input without recording an observation", () => {
    const root = project();
    for (const path of ["../outside.json", "C:/outside.json", ".codex-factory/config.json", "secrets.json"]) {
      const proposal = probeTemplate(); proposal.observation.path = path;
      assert.throws(() => createProbeDraft(root, "original", "worker", proposal));
    }
    const view = draft(root);
    for (const content of ["not JSON", " ".repeat(65537), '{"private_key":"-----BEGIN PRIVATE KEY-----"}']) {
      writeFileSync(join(root, "diagnostic.json"), content);
      assert.throws(() => observe(root, view));
      assert.equal(inspectProbe(root, view.draft.probe_id).observation, null);
    }
  });

  it("exposes the complete CLI path and installs the optional controller protocol", () => {
    const root = project();
    const cliPath = join(dirname(fileURLToPath(import.meta.url)), "../src/cli.ts");
    const cli = (args: string[]) => spawnSync(process.execPath, ["--import", "tsx", cliPath, "--project", root, ...args],
      { encoding: "utf8", windowsHide: true });
    const template = cli(["probe", "template", "--json"]);
    assert.equal(template.status, 0, template.stderr);
    writeFileSync(join(root, "proposal.json"), template.stdout);
    const created = cli(["probe", "draft", "--from-run", "original", "--task", "worker", "--file", "proposal.json", "--json"]);
    assert.equal(created.status, 0, created.stderr);
    const view = JSON.parse(created.stdout) as ReturnType<typeof draft>;
    assert.match(cli(["probe", "show", "--id", view.draft.probe_id]).stdout, /Expected: 3/);
    writeJsonAtomic(join(root, "diagnostic.json"), { normalized: { retries: 0 } });
    const result = cli(["probe", "observe", "--id", view.draft.probe_id, "--draft-hash", view.draft.draft_hash,
      "--reply", "Offline CLI approval", "--json"]);
    assert.equal(result.status, 0, result.stderr);
    assert.equal(JSON.parse(result.stdout).observation.data.matching_hypothesis, "H2");
    assert.equal(cli(["probe", "observe", "--id", view.draft.probe_id]).status, 1);
    assert.equal(cli(["probe", "template", "--unknown"]).status, 1);
    assert.match(FACTORY_SKILL_CONTENT, /Skip probes when they would not change the repair decision/);
  });
});
