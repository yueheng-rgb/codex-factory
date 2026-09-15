import { spawnSync } from "node:child_process";
import { existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { performance } from "node:perf_hooks";
import { fileURLToPath } from "node:url";
import { caseIds, diagnosticGuidance, externalGrader, inputs, reference, taskFor, type CaseId } from "../evals/diagnostic-routine/fixture.js";
import { initializeFactoryProject } from "../src/installer.js";
import { prepareSpawnPlan } from "../src/orchestrator.js";
import { readJson, sha256, stableStringify, writeJsonAtomic } from "../src/util.js";
import { budgetStatus, initializeBudget } from "./eval-budget.js";

type Arm = "A" | "B" | "C";
const packageRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const fileHash = (path: string) => sha256(readFileSync(path));
function write(root: string, path: string, content: string) {
  mkdirSync(dirname(join(root, path)), { recursive: true });
  writeFileSync(join(root, path), content, "utf8");
}
function execute(root: string, args: string[], env: Record<string, string> = {}) {
  const environment = { ...process.env, ...env };
  delete environment.NODE_TEST_CONTEXT;
  const result = spawnSync(process.execPath, args, { cwd: root, encoding: "utf8", shell: false, windowsHide: true, timeout: 30_000, env: environment });
  return { exit_code: result.status, stdout: result.stdout, stderr: result.stderr, error: result.error?.message ?? null };
}
function checks(root: string, grader: string) {
  const visible = execute(root, ["--test", "public.test.cjs"]);
  const external = execute(root, ["--test", grader], { FACTORY_TRIAL_ROOT: root });
  return { visible, external, pass: [visible, external].every(result => result.exit_code === 0 && !result.error) };
}

export interface Trial {
  id: string; case_id: CaseId; arm: Arm; root: string;
  task: ReturnType<typeof taskFor>; input_sha256: string;
  input_hashes: Record<string, string>; frozen: Record<string, string>;
  budget_root: string; run_id: string | null; assignment_id: string | null;
  controller_guidance: string | null; prompt: string; preparation_ms: number;
}
interface Manifest {
  kind: "PREPARED_DEVELOPMENT_VARIANTS_NOT_NATIVE_RESULTS";
  created_at: string; fixture_sha256: string; adapter_sha256: string;
  grader_hashes: Record<CaseId, string>; trials: Trial[];
  calibration: Array<{ case_id: CaseId; variant: string; expected_pass: boolean; matched: boolean; checks: ReturnType<typeof checks> }>;
}

export function prepareDiagnosticRoutine() {
  const directory = mkdtempSync(join(tmpdir(), "factory-diagnostic-routine-"));
  const controller = join(directory, "controller");
  mkdirSync(controller);
  const calibration: Manifest["calibration"] = [];
  const graderHashes = {} as Record<CaseId, string>;
  for (const id of caseIds) {
    const gradePath = join(controller, id + "-grade.cjs");
    write(controller, id + "-grade.cjs", externalGrader(id));
    graderHashes[id] = fileHash(gradePath);
    for (const variant of ["seeded-incorrect", "reference"] as const) {
      const root = join(controller, "calibration", id, variant);
      for (const [path, content] of Object.entries(inputs(id))) write(root, path, content);
      if (variant === "reference") for (const [path, content] of Object.entries(reference(id))) write(root, path, content);
      const result = checks(root, gradePath);
      const expected = variant === "reference";
      // Both visible and external checks must independently separate seed and reference.
      const matched = [result.visible, result.external].every(item => !item.error && (item.exit_code === 0) === expected && item.exit_code !== null);
      calibration.push({ case_id: id, variant, expected_pass: expected, matched, checks: result });
      if (!matched) throw new Error("Calibration failed: " + id + "/" + variant + " " + JSON.stringify(result));
    }
  }
  const trials: Trial[] = [];
  for (const id of caseIds) for (const arm of ["A", "B", "C"] as const) {
    const started = performance.now();
    const trialId = id + "-" + arm;
    const root = join(directory, "trials", trialId);
    const files = inputs(id);
    for (const [path, content] of Object.entries(files)) write(root, path, content);
    write(root, "AGENTS.md", "# Approved synthetic development task\nRead TASK.md and docs/contract.md. Work only in this project and declared write_scope. Do not read sibling trials, controller material, external grader or reference code. No new dependencies or child agents. Normal inspection and self-tests are allowed.\n");
    const task = taskFor(id);
    const guidance = id === "t5" && arm === "C" ? diagnosticGuidance : null;
    if (guidance) task.description += "\n" + guidance;
    // A remains a plain project: its shared evaluation budget is controller-owned.
    const budgetRoot = arm === "A" ? join(controller, "budgets", trialId) : root;
    initializeBudget(budgetRoot);
    const runId = arm === "A" ? null : "initial";
    if (arm !== "A") {
      initializeFactoryProject(root, { multiAgent: true, externalContext: false, maxThreads: 2 });
      writeJsonAtomic(join(root, ".codex-factory/eval-task.json"), task);
    }
    const plan = arm === "A" ? null : prepareSpawnPlan(root, [task], runId!);
    const worker = plan?.assignments.find(item => item.profile_id !== "factory_verifier");
    if (plan && (!worker || plan.assignments.length !== 1)) throw new Error("Expected one ready Worker; Verifier must wait for actual completion");
    const prompt = `Work only in ${root.replaceAll("\\", "/")}. Read AGENTS.md. The synthetic design is approved. Only edit ${task.write_scope.join(", ")}.\n` +
      (worker ? worker.prompt : task.description);
    const frozen = Object.fromEntries([...Object.keys(files), "AGENTS.md"].filter(path => !task.write_scope.includes(path)).map(path => [path, fileHash(join(root, path))]));
    trials.push({ id: trialId, case_id: id, arm, root, task, frozen,
      input_hashes: Object.fromEntries(Object.entries(files).map(([path, content]) => [path, sha256(content)])),
      input_sha256: sha256(stableStringify(files)), budget_root: budgetRoot, run_id: runId,
      assignment_id: worker?.assignment_id ?? null, controller_guidance: guidance,
      prompt, preparation_ms: performance.now() - started });
  }
  const manifest: Manifest = { kind: "PREPARED_DEVELOPMENT_VARIANTS_NOT_NATIVE_RESULTS", created_at: new Date().toISOString(),
    fixture_sha256: fileHash(join(packageRoot, "evals/diagnostic-routine/fixture.ts")),
    adapter_sha256: fileHash(fileURLToPath(import.meta.url)), grader_hashes: graderHashes, trials, calibration };
  const path = join(controller, "manifest.json");
  writeJsonAtomic(path, manifest);
  write(controller, "manifest.sha256", fileHash(path) + "\n");
  return { directory, manifest: path, trials, calibration: calibration.map(({ case_id, variant, expected_pass, matched }) => ({ case_id, variant, expected_pass, matched })) };
}

export function gradeDiagnosticRoutine(projectRoot: string, id: CaseId) {
  if (!caseIds.includes(id)) throw new Error("Unknown case: " + id);
  const root = resolve(projectRoot);
  const controller = join(dirname(dirname(root)), "controller");
  const path = join(controller, "manifest.json");
  if (fileHash(path) !== readFileSync(join(controller, "manifest.sha256"), "utf8").trim()) throw new Error("Frozen manifest changed");
  const manifest = readJson<Manifest>(path);
  const trial = manifest.trials.find(item => resolve(item.root) === root && item.case_id === id);
  if (!trial || manifest.kind !== "PREPARED_DEVELOPMENT_VARIANTS_NOT_NATIVE_RESULTS") throw new Error("Root/case is not a prepared trial");
  const gradePath = join(controller, id + "-grade.cjs");
  if (fileHash(gradePath) !== manifest.grader_hashes[id]) throw new Error("Frozen grader changed");
  const violations = Object.entries(trial.frozen).filter(([file, hash]) => {
    const target = join(root, file);
    return !existsSync(target) || !lstatSync(target).isFile() || fileHash(target) !== hash;
  }).map(([file]) => file);
  // Fail closed before executing a changed public test or shared diagnostic.
  const result = violations.length ? null : checks(root, gradePath);
  return { kind: "OFFLINE_CONTROLLER_CODE_GRADE_NOT_NATIVE_SUCCESS", trial_id: trial.id,
    code_pass: violations.length === 0 && result?.pass === true, frozen_violations: violations, checks: result,
    artifact_hashes: Object.fromEntries(trial.task.write_scope.filter(file => existsSync(join(root, file))).map(file => [file, fileHash(join(root, file))])),
    budget: budgetStatus(trial.budget_root), native_evaluation: "NOT_ASSESSED", factory_verdict: null,
    limitations: "Development code check only. No native receipts are created or validated here. External output must remain controller-only and must not be fed back for repairs. Keep all attempts, failures and budget observations separately." };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const [command, ...args] = process.argv.slice(2);
  let result: unknown;
  if (command === "prepare" && args.length === 0) result = prepareDiagnosticRoutine();
  else if (command === "grade" && args.length === 2) result = gradeDiagnosticRoutine(args[0], args[1] as CaseId);
  else throw new Error("Usage: eval-diagnostic-routine.ts prepare | grade <trial-root> <t5|t6>");
  process.stdout.write(JSON.stringify(result, null, 2) + "\n");
}
