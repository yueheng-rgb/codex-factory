import { spawnSync } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { performance } from "node:perf_hooks";
import { common, before, after, definitions, lesson, publicTest, reference, taskFor, type CaseId } from "../evals/transfer-boundary/fixture.js";
import { initializeFactoryProject } from "../src/installer.js";
import { applyTeachingToTasks, captureTeachingSource, createTeachingDraft, publishTeachingSkill, suggestTeachingLessons } from "../src/teaching.js";
import { prepareSpawnPlan, readTaskGraphSnapshot } from "../src/orchestrator.js";
import { inspectRun } from "../src/run-management.js";
import type { FactoryTask } from "../src/types.js";
import { readJson, sha256, stableStringify, writeJsonAtomic } from "../src/util.js";
import { admitBudget, budgetStatus, initializeBudget } from "./eval-budget.js";

const packageRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const grader = join(packageRoot, "evals/transfer-boundary/grade.cjs");
type Arm = "A" | "B" | "C";
interface Trial {
  id: string; case_id: CaseId; arm: Arm; root: string; task: FactoryTask;
  frozen: Record<string, string>; input_sha256: string;
  preparation_ms: number; lesson_id: string | null;
  shortlist: ReturnType<typeof suggestTeachingLessons> | null;
}
interface Manifest {
  kind: string; trials: Trial[]; grader_sha256: string; created_at: string;
  fixture_sha256: string; calibration: ReturnType<typeof calibrate>;
}
const fileHash = (path: string) => sha256(readFileSync(path));
function write(root: string, path: string, content: string) {
  mkdirSync(dirname(join(root, path)), { recursive: true });
  writeFileSync(join(root, path), content, "utf8");
}
function execute(root: string, command: string, args: string[], env: Record<string, string> = {}) {
  const environment = { ...process.env, ...env };
  // The grader is an independent test process, not a nested node:test worker.
  delete environment.NODE_TEST_CONTEXT;
  const result = spawnSync(command, args, { cwd: root, encoding: "utf8", shell: false, windowsHide: true, timeout: 30_000, env: environment });
  return { exit_code: result.status, stdout: result.stdout, stderr: result.stderr, error: result.error?.message ?? null };
}
function inputs(id: CaseId) {
  return { ...common, "TASK.md": taskFor(id).description + "\n", "public.test.cjs": publicTest(id) };
}
function gradeCode(root: string, id: CaseId, gradePath: string) {
  return execute(root, process.execPath, ["--test", gradePath], { FACTORY_TRIAL_ROOT: root, FACTORY_CASE_ID: id });
}

export function calibrate(directory: string) {
  const rows = [];
  for (const id of ["t3", "t4"] as const) {
    const root = join(directory, id);
    for (const [path, content] of Object.entries(inputs(id))) write(root, path, content);
    const target = "src/" + definitions[id].module + ".cjs";
    const variants = [
      { name: "unimplemented", code: common[target], expected: false },
      { name: "reference", code: reference(id), expected: true },
      { name: "wrong-boundary", code: reference(id, id === "t3" ? "r.ticket" : "reference(r.ticket)"), expected: false },
      { name: "negative-zero", code: reference(id).replace("r.cents===0?0:", ""), expected: false },
    ];
    for (const variant of variants) {
      write(root, target, variant.code);
      const result = gradeCode(root, id, grader);
      const matched = (result.exit_code === 0 && !result.error) === variant.expected;
      rows.push({ case_id: id, variant: variant.name, expected_pass: variant.expected, matched, result });
      if (!matched) throw new Error("Calibration failed: " + id + " / " + variant.name + " " + JSON.stringify(result));
    }
  }
  return { kind: "OFFLINE_REFERENCE_AND_MUTANTS_NOT_AGENT_RESULTS", rows };
}

export function prepareTransferBoundary() {
  const directory = mkdtempSync(join(tmpdir(), "factory-transfer-boundary-"));
  const controller = join(directory, "controller");
  mkdirSync(controller);
  const calibration = calibrate(join(controller, "calibration"));
  copyFileSync(grader, join(controller, "grade.cjs"));
  const trials: Trial[] = [];
  for (const id of ["t3", "t4"] as const) {
    for (const arm of (id === "t3" ? ["C", "A", "B"] : ["A", "B", "C"]) as Arm[]) {
      const started = performance.now();
      const root = join(directory, "trials", id + "-" + arm);
      const files = inputs(id);
      for (const [path, content] of Object.entries(files)) write(root, path, content);
      write(root, "AGENTS.md", "# Approved synthetic task\nUse only this trial's business files and explicitly assigned Factory tooling. No sibling roots, controller directory, external grader, reference answers, child agents or new dependencies. Only edit the declared write_scope. Normal local inspection and self-tests are allowed.\n");
      mkdirSync(join(root, "empty-hooks"));
      const git = (args: string[]) => {
        const result = execute(root, "git", ["-c", "core.hooksPath=" + join(root, "empty-hooks"), "-c", "core.fsmonitor=false",
          "-c", "user.name=Offline Fixture", "-c", "user.email=fixture@example.invalid", ...args]);
        if (result.exit_code !== 0 || result.error) throw new Error("Fixture Git setup failed: " + result.stderr);
      };
      git(["init", "--quiet"]); git(["config", "core.autocrlf", "false"]);
      write(root, "src/legacy.cjs", before);
      git(["add", "--", "src/legacy.cjs"]); git(["commit", "--quiet", "--no-gpg-sign", "-m", "Synthetic previous converter"]);
      write(root, "src/legacy.cjs", after);
      const task = taskFor(id);
      let lessonId: string | null = null;
      let shortlist: Trial["shortlist"] = null;
      if (arm !== "A") initializeFactoryProject(root, { multiAgent: true, externalContext: false, maxThreads: 2 });
      if (arm === "C") {
        const source = captureTeachingSource(root, { path: "src/legacy.cjs", note: "Pre-authored synthetic history shared with all arms; not live learning." });
        const draft = createTeachingDraft(root, source.source_id, lesson);
        publishTeachingSkill(root, draft.draft_id, { draftHash: draft.draft_hash, userReply: "Offline fixture publication, not actual user approval or live learning." });
        lessonId = draft.draft_id;
        shortlist = suggestTeachingLessons(root, [task], task.task_id);
      }
      initializeBudget(root);
      writeJsonAtomic(join(root, ".codex-factory/eval-task.json"), task);
      const frozen = Object.fromEntries([...Object.keys(files), "AGENTS.md"].filter((path) => !task.write_scope.includes(path)).map((path) => [path, fileHash(join(root, path))]));
      trials.push({ id: id + "-" + arm, case_id: id, arm, root, task, frozen,
        input_sha256: sha256(stableStringify(files)), preparation_ms: performance.now() - started, lesson_id: lessonId, shortlist });
    }
  }
  const manifest: Manifest = { kind: "PREPARED_DEVELOPMENT_VARIANTS_NOT_LIVE_RESULTS", created_at: new Date().toISOString(), trials,
    grader_sha256: fileHash(join(controller, "grade.cjs")), fixture_sha256: fileHash(join(packageRoot, "evals/transfer-boundary/fixture.ts")), calibration };
  const path = join(controller, "manifest.json");
  writeJsonAtomic(path, manifest);
  return { manifest: path, trials: trials.map(({ id, root, input_sha256, shortlist }) => ({ id, root, input_sha256,
    shortlist_status: shortlist?.status ?? null, candidates: shortlist?.candidates.map((item) => item.lesson_id) ?? [] })), calibration: calibration.kind };
}

function loadTrial(path: string, id: string) {
  const manifest = readJson<Manifest>(path);
  const trial = manifest.trials.find((item) => item.id === id);
  if (!trial) throw new Error("Unknown trial");
  return { manifest, trial, controller: dirname(path) };
}
function assertFrozen(trial: Trial) {
  for (const [path, hash] of Object.entries(trial.frozen)) if (fileHash(join(trial.root, path)) !== hash) throw new Error("Frozen input changed: " + path);
}

export function reviewTrial(path: string, id: string, decision: { lesson_id: string | null; reason: string }) {
  const { trial, controller } = loadTrial(path, id);
  assertFrozen(trial);
  if (trial.arm !== "C" || budgetStatus(trial.root).rounds_started > 0) throw new Error("Review is only for an undispatched C trial");
  const target = join(controller, id + "-review.json");
  if (existsSync(target)) throw new Error("Review already frozen");
  if (!decision || typeof decision.reason !== "string" || !decision.reason.trim() || (decision.lesson_id !== null && decision.lesson_id !== trial.lesson_id)) throw new Error("Choose the available lesson or null, with a current-contract reason");
  const started = performance.now();
  const applied = decision.lesson_id ? applyTeachingToTasks(trial.root, decision.lesson_id, [trial.task], "worker", decision.reason) : null;
  const record = { kind: "CONTROLLER_STATED_REVIEW_NOT_AUTOMATIC_SEMANTIC_SELECTION", ...decision,
    fallback_from_catalog: decision.lesson_id !== null && !trial.shortlist?.candidates.some((item) => item.lesson_id === decision.lesson_id),
    original_task_bytes: Buffer.byteLength(stableStringify(trial.task)),
    effective_task_bytes: Buffer.byteLength(stableStringify(applied?.tasks[0] ?? trial.task)),
    tasks: applied?.tasks ?? [trial.task], local_apply_ms: performance.now() - started,
    reasoning_tokens: null, reasoning_cost: null, reasoning_duration_ms: null };
  writeJsonAtomic(target, record);
  writeJsonAtomic(join(trial.root, ".codex-factory/eval-task.json"), record.tasks[0]);
  return record;
}

export function dispatchTrial(path: string, id: string, role: "worker" | "verifier" = "worker") {
  const { trial, controller } = loadTrial(path, id);
  assertFrozen(trial);
  if (budgetStatus(trial.root).action !== "IDLE") throw new Error("Previous admission still active; do not prepare or dispatch again");
  if (!["worker", "verifier"].includes(role) || (trial.arm === "A" && role === "verifier")) throw new Error("Invalid trial role");
  const task = trial.arm === "C" ? readJson<{ tasks: FactoryTask[] }>(join(controller, id + "-review.json")).tasks[0] : trial.task;
  const runId = "initial";
  const plan = trial.arm === "A" ? null : prepareSpawnPlan(trial.root, role === "worker" ? [task] : readTaskGraphSnapshot(trial.root, runId).tasks, runId);
  const assignment = plan?.assignments.find((item) => (item.profile_id === "factory_verifier") === (role === "verifier"));
  if (trial.arm !== "A" && !assignment) throw new Error("No ready assignment for requested role");
  const assignmentId = assignment?.assignment_id ?? "plain-worker";
  const prompt = `Work only in ${trial.root.replaceAll("\\", "/")}. The synthetic design is approved. Read AGENTS.md. No sibling trials, controller files, external grading or child agents. Only edit ${role === "verifier" ? "nothing (read-only verification)" : task.write_scope.join(", ")}. ` +
    (assignment ? `Follow .codex/agents/${assignment.profile_id}.toml. Factory executable: node ${join(packageRoot, "dist/cli.js").replaceAll("\\", "/")}.\n${assignment.prompt}` : task.description) +
    '\nEnd with FACTORY_HANDOFF_JSON={"summary":"...","changed_paths":[],"artifacts":[{"path":"project-relative file","sha256":"actual hash"}],"commands":[{"command":"actual command","exit_code":0}],"proposed_verdict":"PASS or FAIL or BLOCKED","caveats":[],"unresolved_risks":[]}. Preserve failures. Total shared wall budget is 20 minutes, at most two Worker rounds.';
  const budget = admitBudget(trial.root, runId, assignmentId, role, 1);
  const record = { trial_id: id, root: trial.root, run_id: runId, assignment_id: assignmentId, role, budget, prompt,
    prompt_bytes: Buffer.byteLength(prompt), next: "Use actual native spawn, then live-eval.ts register (B/C) or budget-bind (A); follow budget-status before waiting. This command does not spawn." };
  writeJsonAtomic(join(controller, id + "-" + role + "-dispatch.json"), record);
  return record;
}

export function gradeTrial(path: string, id: string) {
  const { manifest, trial, controller } = loadTrial(path, id);
  const target = join(controller, id + "-result.json");
  if (existsSync(target)) throw new Error("Trial result already frozen");
  const budget = budgetStatus(trial.root);
  if (!budget.terminal_observed || budget.action !== "IDLE") throw new Error("No completed host attempt or execution unresolved; do not grade an unrun fixture");
  const gradePath = join(controller, "grade.cjs");
  if (fileHash(gradePath) !== manifest.grader_sha256) throw new Error("Frozen grader changed");
  const violations = Object.entries(trial.frozen).filter(([file, hash]) => !existsSync(join(trial.root, file)) || fileHash(join(trial.root, file)) !== hash).map(([file]) => file);
  const result = gradeCode(trial.root, trial.case_id, gradePath);
  const record = { trial_id: id, kind: "CONTROLLER_EXTERNAL_CODE_GRADE", budget, frozen_violations: violations,
    code_pass: result.exit_code === 0 && !result.error && violations.length === 0,
    factory_status: trial.arm === "A" ? null : inspectRun(trial.root, "initial").status,
    grade: result, artifact_sha256: fileHash(join(trial.root, "src/" + definitions[trial.case_id].module + ".cjs")),
    limitations: "Code correctness, Factory verdict and budget compliance are separate. Terminal error/shutdown does not imply a successful delivery. Include every admitted trial, including unresolved trials, in campaign reporting." };
  writeJsonAtomic(target, record);
  return record;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const [command, ...args] = process.argv.slice(2);
  let result: unknown;
  if (command === "prepare" && !args.length) result = prepareTransferBoundary();
  else if (command === "review" && args.length === 3) result = reviewTrial(args[0], args[1], readJson(args[2]));
  else if (command === "dispatch" && [2, 3].includes(args.length)) result = dispatchTrial(args[0], args[1], args[2] as "worker" | "verifier" | undefined);
  else if (command === "grade" && args.length === 2) result = gradeTrial(args[0], args[1]);
  else throw new Error("Usage: eval-transfer-boundary.ts prepare | review <manifest> <trial> <decision-json> | dispatch <manifest> <trial> [worker|verifier] | grade <manifest> <trial>");
  process.stdout.write(JSON.stringify(result, null, 2) + "\n");
}
