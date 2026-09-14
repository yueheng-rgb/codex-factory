import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync, readFileSync, rmSync } from "node:fs";
import { dirname, join } from "node:path";
import { afterEach, describe, it } from "node:test";
import { fileURLToPath } from "node:url";
import { chooseClarification, createClarification, formatClarification, inspectClarification,
  readConfirmedClarificationTasks, validateClarificationProposal, type ClarificationProposal } from "../src/clarification.js";
import { FACTORY_SKILL_CONTENT, initializeFactoryProject } from "../src/installer.js";
import { prepareSpawnPlan, readTaskGraphSnapshot, registerNativeDispatch } from "../src/orchestrator.js";
import { recordAgentHandoff } from "../src/evidence.js";
import { continueRun } from "../src/run-management.js";
import { readJson, writeJsonAtomic } from "../src/util.js";
import { fixtureProject, repairTask } from "./helpers/repair-fixture.js";
import { runFileSnapshot } from "../src/repair-store.js";

const roots: string[] = [];
const packageRoot = dirname(dirname(fileURLToPath(import.meta.url)));
function project(context = false) { const root = fixtureProject(context); roots.push(root); return root; }
function proposal(): ClarificationProposal { return readJson(join(packageRoot, "examples/behavior-contrast.json")); }
function cli(root: string, args: string[]) {
  return spawnSync(process.execPath, ["--import", "tsx", join(packageRoot, "src/cli.ts"), "--project", root, ...args],
    { encoding: "utf8", windowsHide: true });
}
afterEach(() => { for (const root of roots.splice(0)) rmSync(root, { recursive: true, force: true }); });

describe("result-contrast clarification", () => {
  it("records a comparable draft without creating a run, is idempotent and shows no default", () => {
    const root = project();
    const source = proposal();
    const draft = createClarification(root, source);
    assert.equal(draft.status, "AWAITING_USER");
    assert.equal(draft.tasks_file, null);
    assert.equal(draft.selected_option, null);
    const template = cli(root, ["clarify", "template", "--json"]);
    assert.equal(template.status, 0, template.stderr);
    assert.deepEqual(validateClarificationProposal(JSON.parse(template.stdout)), source);
    const snapshot = runFileSnapshot(root, root);
    assert.deepEqual(createClarification(root, source), draft);
    assert.deepEqual(inspectClarification(root, draft.clarification_id), draft);
    assert.equal(runFileSnapshot(root, root), snapshot);
    assert.equal(existsSync(join(root, ".codex-factory/runs")), false);
    assert.match(formatClarification(draft), /Neither option fits/);
    assert.match(formatClarification(draft), /keep-first/);
    assert.match(formatClarification(draft), /keep-last/);
    assert.throws(() => readConfirmedClarificationTasks(root, source), /Unconfirmed/);
    source.question += " Please clarify again.";
    assert.notEqual(createClarification(root, source).clarification_id, draft.clarification_id);
  });

  it("rejects incomplete, non-contrasting, incomparable and over-scoped proposals", () => {
    const cases: Array<(value: ClarificationProposal) => void> = [
      (v) => { v.question = " "; },
      (v) => { v.options.pop(); },
      (v) => { v.options[1].id = v.options[0].id; },
      (v) => { v.options[1].examples = structuredClone(v.options[0].examples); },
      (v) => { v.options[1].examples[0].input = "different scenario"; },
      (v) => { v.options[0].examples = []; },
      (v) => { Object.assign(v.options[0], { write_scope: ["**"] }); },
      (v) => { v.task.status = "verified"; },
      (v) => { v.task.dependencies = ["unbound-task"]; },
      (v) => { v.task.write_scope = []; },
    ];
    for (const mutate of cases) { const value = proposal(); mutate(value); assert.throws(() => validateClarificationProposal(value)); }
    assert.throws(() => validateClarificationProposal(null));
  });

  for (const option of ["keep-first", "keep-last"]) {
    it("compiles only " + option + " into the real CLI planning contract", () => {
      const root = project(option === "keep-last");
      const source = proposal();
      writeJsonAtomic(join(root, "contrast.json"), source);
      const created = cli(root, ["clarify", "create", "--file", "contrast.json", "--json"]);
      assert.equal(created.status, 0, created.stderr);
      const draft = JSON.parse(created.stdout);
      assert.equal(cli(root, ["plan", "--tasks", "contrast.json"]).status, 1);
      const draftPath = ".codex-factory/clarifications/" + draft.clarification_id + "/draft.json";
      assert.equal(cli(root, ["tasks", "validate", "--tasks", draftPath]).status, 1);
      assert.equal(existsSync(join(root, ".codex-factory/runs")), false);
      const reply = "I choose " + option;
      const chosen = cli(root, ["clarify", "choose", "--id", draft.clarification_id, "--option", option,
        "--draft-hash", draft.draft_hash, "--reply", reply, "--json"]);
      assert.equal(chosen.status, 0, chosen.stderr);
      const view = JSON.parse(chosen.stdout);
      assert.equal(view.status, "CONFIRMED");
      const envelope = readJson(join(root, view.tasks_file));
      const tasks = readConfirmedClarificationTasks(root, envelope)!;
      assert.equal(tasks.length, 1);
      assert.deepEqual(tasks[0].write_scope, source.task.write_scope);
      assert.deepEqual(tasks[0].acceptance_methods, source.task.acceptance_methods);
      assert.deepEqual(tasks[0].required_artifacts, source.task.required_artifacts);
      assert.ok(tasks[0].description.includes(source.options.find((item) => item.id === option)!.requirement));
      assert.ok(!tasks[0].description.includes(source.options.find((item) => item.id !== option)!.requirement));
      assert.match(tasks[0].description, /not proof of PASS/);
      assert.equal(cli(root, ["tasks", "validate", "--tasks", view.tasks_file, "--json"]).status, 0);
      const planned = cli(root, ["plan", "--tasks", view.tasks_file, "--run", "chosen", "--json"]);
      assert.equal(planned.status, 0, planned.stderr);
      const plan = JSON.parse(planned.stdout);
      assert.ok(plan.assignments[0].prompt.includes(tasks[0].description));
      const graph = readTaskGraphSnapshot(root, "chosen");
      assert.match(graph.tasks.find((task) => task.role === "verifier")!.description, /confirmed behavior examples/);
      const repeatedSnapshot = runFileSnapshot(root, root);
      assert.deepEqual(chooseClarification(root, draft.clarification_id, { optionId: option, draftHash: draft.draft_hash, userReply: reply }), view);
      assert.equal(runFileSnapshot(root, root), repeatedSnapshot);
      assert.equal(cli(root, ["clarify", "show", "--id", draft.clarification_id]).status, 0);
    });
  }

  it("rejects stale consent, conflicting repeats and changed saved/exported contracts", () => {
    const root = project();
    const draft = createClarification(root, proposal());
    const input = { optionId: "keep-first", draftHash: draft.draft_hash, userReply: "Keep the first record" };
    assert.throws(() => chooseClarification(root, draft.clarification_id, { ...input, userReply: " " }));
    assert.throws(() => chooseClarification(root, draft.clarification_id, { ...input, draftHash: "old" }), /Stale/);
    assert.throws(() => chooseClarification(root, draft.clarification_id, { ...input, optionId: "neither" }), /Unknown option/);
    const confirmed = chooseClarification(root, draft.clarification_id, input);
    assert.throws(() => chooseClarification(root, draft.clarification_id, { ...input, optionId: "keep-last" }), /already recorded/);
    const path = join(root, confirmed.tasks_file!);
    const envelope = readJson<{ tasks: Array<{ description: string }> }>(path);
    envelope.tasks[0].description = "Unapproved alternative";
    assert.throws(() => readConfirmedClarificationTasks(root, envelope), /differs/);
    writeJsonAtomic(path, envelope);
    assert.throws(() => inspectClarification(root, draft.clarification_id), /does not match/);
    const root2 = project();
    const draft2 = createClarification(root2, proposal());
    const path2 = join(root2, ".codex-factory/clarifications", draft2.clarification_id, "draft.json");
    const changed = readJson<{ proposal: ClarificationProposal }>(path2);
    changed.proposal.options[0].requirement = "Silently changed";
    writeJsonAtomic(path2, changed);
    assert.throws(() => chooseClarification(root2, draft2.clarification_id, { ...input, draftHash: draft2.draft_hash }), /draft changed/);
    assert.equal(cli(root, ["clarify", "choose", "--id", draft.clarification_id, "--option", "keep-first"]).status, 1);
    assert.equal(cli(root, ["clarify", "show", "--id", draft.clarification_id, "--force"]).status, 1);
  });

  it("keeps confirmation separate from acceptance and preserves existing raw task input", () => {
    const root = project();
    const source = proposal();
    source.task = repairTask({ required_artifacts: [] });
    const draft = createClarification(root, source);
    const confirmed = chooseClarification(root, draft.clarification_id, {
      optionId: "keep-last", draftHash: draft.draft_hash, userReply: "OFFLINE fixture reply", });
    const tasks = readConfirmedClarificationTasks(root, readJson(join(root, confirmed.tasks_file!)))!;
    const plan = prepareSpawnPlan(root, tasks, "missing-artifact");
    const worker = plan.assignments[0];
    registerNativeDispatch(root, plan.run_id, worker.assignment_id, { nativeAgentId: "fixture-worker",
      rawToolReceipt: { tool_name: "spawn_agent", agent_id: "fixture-worker", status: "spawned" } });
    recordAgentHandoff(root, plan.run_id, worker.assignment_id, { summary: "Offline fixture with no artifact", commands: [],
      changed_paths: [], artifacts: [], proposed_verdict: "PASS" });
    const verifier = continueRun(root, plan.run_id).plan!.assignments[0];
    registerNativeDispatch(root, plan.run_id, verifier.assignment_id, { nativeAgentId: "fixture-verifier",
      rawToolReceipt: { tool_name: "spawn_agent", agent_id: "fixture-verifier", status: "spawned" } });
    recordAgentHandoff(root, plan.run_id, verifier.assignment_id, { summary: "Offline fixture rejects missing output", commands: [],
      changed_paths: [], artifacts: [], proposed_verdict: "FAIL" });
    assert.equal(continueRun(root, plan.run_id).status, "FAILED");
    writeJsonAtomic(join(root, "legacy.json"), [repairTask()]);
    const legacy = cli(root, ["plan", "--tasks", "legacy.json", "--run", "legacy", "--json"]);
    assert.equal(legacy.status, 0, legacy.stderr);
    assert.match(FACTORY_SKILL_CONTENT, /actual user's explicit answer/);
    assert.match(FACTORY_SKILL_CONTENT, /never for replacing running tasks/);
    initializeFactoryProject(root);
    assert.match(readFileSync(join(root, ".gitignore"), "utf8"), /\.codex-factory\/clarifications\//);
    assert.match(readFileSync(join(root, ".agents/skills/codex-factory/SKILL.md"), "utf8"), /factoryctl clarify template/);
    assert.match(readFileSync(join(packageRoot, "scripts/demo-clarification.ts"), "utf8"), /PLANNED_NOT_EXECUTED/);
  });
});
