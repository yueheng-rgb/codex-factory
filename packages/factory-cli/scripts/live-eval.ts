import { copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, isAbsolute, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { initializeFactoryProject } from "../src/installer.js";
import { initializeContextSpace } from "../src/context-space.js";
import { prepareSpawnPlan, readTaskGraphSnapshot, registerNativeDispatch, readAgentRegistry } from "../src/orchestrator.js";
import { createRepairRun, inspectRun } from "../src/run-management.js";
import { recordAgentHandoff } from "../src/evidence.js";
import { managedRunDirectory, runFileSnapshot } from "../src/repair-store.js";
import type { FactoryTask } from "../src/types.js";
import { assertWithinRoot, readJson, sha256, stableStringify, writeJsonAtomic } from "../src/util.js";
import { admitBudget, bindBudgetAgent, budgetStatus, captureBudgetCompletion, hasBudget, initializeBudget, observeBudget } from "./eval-budget.js";
import type { BudgetObservation } from "./eval-budget.js";

const caseDirectory = resolve(dirname(fileURLToPath(import.meta.url)), "../evals/cases");
const definitions = [
  { id: "normalize", kind: "natural", description: "Implement normalizeTags(values) exported from solution.cjs: require an array containing only strings (otherwise throw TypeError), trim each string, lowercase with JavaScript toLowerCase, discard empty strings, deduplicate in first-seen order, never mutate input. Handle Unicode strings and prototype-like keys. Edit only solution.cjs. Run node check.cjs; check.cjs is read-only." },
  { id: "lower-bound", kind: "seeded_repair", description: "Implement lowerBound(array, target) exported from solution.cjs: for an ascending array of finite numbers return the first index whose value is >= target, or array.length if absent. Empty arrays and duplicates are supported. Use O(log n) time and O(1) extra space; do not mutate the input. Inputs are prevalidated. Edit only solution.cjs; run node check.cjs; check.cjs is read-only." },
] as const;

function prepare() {
  const directory = mkdtempSync(join(tmpdir(), "factory-live-eval-"));
  const cases = definitions.map((definition) => {
    const root = join(directory, definition.id);
    mkdirSync(root);
    const git = spawnSync("git", ["init", "--quiet"], { cwd: root, encoding: "utf8", windowsHide: true });
    if (git.error || git.status !== 0) throw new Error("Evaluation Git initialization failed; preserve " + directory + " for diagnosis");
    for (const file of ["solution.cjs", "check.cjs"]) copyFileSync(join(caseDirectory, definition.id, file), join(root, file));
    initializeFactoryProject(root, { multiAgent: true, externalContext: true, maxThreads: 2 });
    initializeContextSpace(root);
    initializeBudget(root);
    const task: FactoryTask = {
      task_id: "worker", title: definition.id, description: definition.description,
      role: "implementation", status: "pending", dependencies: [], write_scope: ["solution.cjs"],
      acceptance_methods: ["command:node check.cjs"], required_artifacts: ["solution.cjs"],
    };
    writeJsonAtomic(join(root, ".codex-factory", "eval-task.json"), task);
    const plan = prepareSpawnPlan(root, [task], "initial");
    return { ...definition, root, git_initialized: true, initial_run_id: "initial", check_sha256: sha256(readFileSync(join(root, "check.cjs"))),
      task, first_assignment: plan.assignments[0] };
  });
  const manifest = { version: 1, mode: "NATIVE_HOST_EVAL", created_at: new Date().toISOString(), cases,
    limitations: ["Two public synthetic cases, not a model benchmark or production success estimate.",
      "Seeded initial failure is deliberate and excluded from natural first-attempt metrics.",
      "The controller records actual tool responses; JSON files are not cryptographic host attestations."] };
  writeJsonAtomic(join(directory, "manifest.json"), manifest);
  return { manifest: join(directory, "manifest.json"), cases: cases.map(({ id, root, first_assignment }) => ({ id, root, assignment_id: first_assignment.assignment_id })) };
}

function register(root: string, runId: string, assignmentId: string, observationPath: string) {
  const observation = readJson<{ tool: string; started_at: string; returned_at: string; response: { agent_id: string; nickname: string | null } }>(assertWithinRoot(root, resolve(observationPath)));
  if (observation.tool !== "multi_agent_v1__spawn_agent" || !observation.response?.agent_id ||
      !Number.isFinite(Date.parse(observation.started_at)) || !Number.isFinite(Date.parse(observation.returned_at)) ||
      Date.parse(observation.returned_at) < Date.parse(observation.started_at)) {
    throw new Error("Expected a captured successful native spawn observation, never an offline fixture");
  }
  const budget = hasBudget(root) ? bindBudgetAgent(root, runId, assignmentId, observation) : null;
  const registration = registerNativeDispatch(root, runId, assignmentId, {
    nativeAgentId: observation.response.agent_id, nativeNickname: observation.response.nickname ?? undefined,
    rawToolReceipt: {
      schema: "factory_controller_observed_native_response_v1", tool_name: "spawn_agent", status: "spawned",
      host_response: observation.response,
      observation_sha256: sha256(stableStringify(observation)),
      note: "Tool name and spawned status are controller metadata for a successful invocation; host_response is preserved verbatim.",
    },
  });
  return { ...registration, evaluation_budget: budget };
}

interface EvalManifest {
  mode: string;
  limitations: string[];
  cases: Array<{ id: string; kind: string; root: string; check_sha256: string }>;
}

interface HostObservation {
  tool: string;
  started_at: string;
  returned_at: string;
  response: {
    agent_id?: string;
    status?: Record<string, { completed?: string; errored?: string } | string>;
    thread?: { id: string };
    turns?: Array<{ id: string; status: string; durationMs?: number; completedAt?: number;
      error?: { message?: string } | null;
      items?: Array<{ type: string; phase?: string; text?: string }> }>;
  };
}

function completedText(observation: HostObservation, agentId: string): string | undefined {
  if (observation.tool === "multi_agent_v1__wait_agent") {
    const status = observation.response.status?.[agentId];
    return typeof status === "object" ? status.completed : undefined;
  }
  if (observation.tool === "mcp__codex_app__read_thread" && observation.response.thread?.id === agentId) {
    return observation.response.turns?.find((turn) => turn.status === "completed")?.items
      ?.find((item) => item.type === "agentMessage" && item.phase === "final_answer")?.text;
  }
  return undefined;
}

function recordHandoff(root: string, runId: string, assignmentId: string, observationPath: string) {
  const entry = readAgentRegistry(root, runId).entries.find((entry) => entry.assignment_ids.includes(assignmentId));
  if (!entry?.native_agent_id) throw new Error("Assignment has no registered native agent");
  const observation = readJson<HostObservation>(assertWithinRoot(root, resolve(observationPath)));
  const handoff = capturedHandoff(root, observation, entry.native_agent_id);
  if (hasBudget(root)) captureBudgetCompletion(root, runId, assignmentId, entry.native_agent_id, observation as BudgetObservation);
  return recordAgentHandoff(root, runId, assignmentId, handoff);
}

function capturedHandoff(root: string, observation: HostObservation, agentId: string) {
  const final = completedText(observation, agentId);
  const line = final?.split(/\r?\n/).find((line) => line.startsWith("FACTORY_HANDOFF_JSON="));
  if (!line) throw new Error("Captured host completion has no structured handoff");
  const handoff = JSON.parse(line.slice("FACTORY_HANDOFF_JSON=".length));
  if (!handoff || !Array.isArray(handoff.changed_paths) || handoff.changed_paths.some((path: unknown) => typeof path !== "string") ||
      !Array.isArray(handoff.artifacts) || handoff.artifacts.some((artifact: { path?: unknown; sha256?: unknown } | null) =>
        !artifact || typeof artifact.path !== "string" || typeof artifact.sha256 !== "string" || !/^[a-f0-9]{64}$/i.test(artifact.sha256)) ||
      !["PASS", "FAIL", "BLOCKED"].includes(handoff.proposed_verdict)) {
    throw new Error("Invalid handoff schema: require changed_paths:string[], artifacts:[{path,sha256}], proposed_verdict:PASS|FAIL|BLOCKED. Preserve the rejected observation and request a corrected handoff; do not remove failed commands.");
  }
  const projectPath = (path: string): string => {
    const absolute = assertWithinRoot(root, isAbsolute(path) ? path : resolve(root, path));
    return relative(root, absolute).replaceAll("\\", "/");
  };
  handoff.changed_paths = handoff.changed_paths.map(projectPath);
  handoff.artifacts = handoff.artifacts.map((artifact: { path: string; sha256: string }) => ({ ...artifact, path: projectPath(artifact.path) }));
  return handoff;
}

function hostTiming(root: string, runId: string) {
  const path = join(root, ".codex-factory", "host-observations");
  const observations = existsSync(path) ? readdirSync(path).filter((name) => name.endsWith(".json"))
    .map((name) => readJson<HostObservation>(join(path, name))) : [];
  return readAgentRegistry(root, runId).entries.map((entry) => {
    if (!entry.native_agent_id) return { native_agent_id: null, observation_complete: false, wall_elapsed_ms: null };
    const spawns = observations.filter((item) => item.tool === "multi_agent_v1__spawn_agent" && item.response?.agent_id === entry.native_agent_id);
    const completions = observations.filter((item) => typeof completedText(item, entry.native_agent_id!) === "string");
    if (spawns.length !== 1 || completions.length !== 1) throw new Error("Missing or duplicate captured host observations for " + entry.native_agent_id);
    const captured = capturedHandoff(root, completions[0], entry.native_agent_id);
    for (const assignmentId of entry.assignment_ids) {
      const recorded = readJson<{ report: unknown }>(join(managedRunDirectory(root, runId), "handoffs", assignmentId + ".json"));
      if (stableStringify(recorded.report) !== stableStringify(captured)) throw new Error("Captured completion differs from recorded handoff: " + assignmentId);
    }
    const native = readJson<{ raw_tool_receipt: { observation_sha256: string } }>(join(root, entry.native_receipts[0].receipt_path));
    if (native.raw_tool_receipt.observation_sha256 !== sha256(stableStringify(spawns[0]))) throw new Error("Host observation hash mismatch");
    const recoveredTurn = completions[0].tool === "mcp__codex_app__read_thread"
      ? completions[0].response.turns?.find((turn) => turn.status === "completed") : undefined;
    const endedAt = recoveredTurn?.completedAt ? recoveredTurn.completedAt * 1000 : Date.parse(completions[0].returned_at);
    const elapsed = endedAt - Date.parse(spawns[0].started_at);
    if (!Number.isFinite(elapsed) || elapsed < 0) throw new Error("Invalid host observation timing");
    const failures = new Map<string, string>();
    for (const observation of observations.filter((item) => item.response?.thread?.id === entry.native_agent_id)) {
      for (const turn of observation.response.turns ?? []) {
        if (turn.status === "failed") failures.set(turn.id, turn.error?.message ?? "Host turn failed");
      }
    }
    return { native_agent_id: entry.native_agent_id, observation_complete: true, wall_elapsed_ms: elapsed,
      timing_basis: recoveredTurn ? "host_completed_at" : "controller_wait_returned_at",
      host_reported_turn_duration_ms: recoveredTurn?.durationMs ?? null,
      interrupted_turns: failures.size,
      interruption_categories: [...failures.values()].map((message) => /usage limit/i.test(message) ? "HOST_USAGE_LIMIT" : "HOST_ERROR") };
  });
}

function checkpoint(root: string) {
  const status = inspectRun(root, "initial").status;
  if (!["FAILED", "PASSED"].includes(status)) throw new Error("Checkpoint requires a terminal initial run");
  const result = { run_id: "initial", snapshot_sha256: runFileSnapshot(root, managedRunDirectory(root, "initial")) };
  const path = join(root, ".codex-factory", "eval-initial-snapshot.json");
  if (existsSync(path) && stableStringify(readJson(path)) !== stableStringify(result)) throw new Error("Initial snapshot changed");
  if (!existsSync(path)) writeJsonAtomic(path, result);
  return result;
}

function summarize(manifestPath: string) {
  const manifest = readJson<EvalManifest>(manifestPath);
  const cases = manifest.cases.map((item) => {
    if (sha256(readFileSync(join(item.root, "check.cjs"))) !== item.check_sha256) throw new Error("Acceptance script changed: " + item.id);
    const runIds = readdirSync(join(item.root, ".codex-factory", "runs"), { withFileTypes: true })
      .filter((entry) => entry.isDirectory()).map((entry) => entry.name);
    const runs = runIds.map((runId) => {
      const inspection = inspectRun(item.root, runId);
      if (runId !== "initial" && inspection.repair?.root_run_id !== "initial") throw new Error("Unlinked evaluation run");
      const directory = managedRunDirectory(item.root, runId);
      const receipts = inspection.tasks.flatMap((task) => task.evidence.filter((evidence) => evidence.path.endsWith("/receipt.json")));
      const acceptance = receipts.length ? readJson<{ acceptance_checks: Array<{ duration_ms?: number }> }>(join(item.root, receipts[0].path)) : undefined;
      const agents = hostTiming(item.root, runId);
      return { run_id: runId, status: inspection.status, agents,
        repair_index: inspection.repair?.repair_index ?? 0,
        failure_reasons: inspection.tasks.flatMap((task) => task.failure_reasons),
        acceptance_duration_ms: acceptance?.acceptance_checks.reduce((sum, check) => sum + (check.duration_ms ?? 0), 0) ?? null,
        evidence_snapshot_sha256: runFileSnapshot(item.root, directory) };
    }).sort((left, right) => left.repair_index - right.repair_index);
    const snapshotPath = join(item.root, ".codex-factory", "eval-initial-snapshot.json");
    const preserved = existsSync(snapshotPath) ? readJson<{ snapshot_sha256: string }>(snapshotPath).snapshot_sha256 === runs[0].evidence_snapshot_sha256 : null;
    if (preserved === false) throw new Error("Original evaluation evidence changed");
    return { case_id: item.id, kind: item.kind, root: item.root, runs, original_evidence_preserved: preserved,
      evaluation_budget: hasBudget(item.root) ? budgetStatus(item.root) : null,
      outcome: runs.at(-1)?.status ?? "NOT_RUN" };
  });
  const natural = cases.filter((item) => item.kind === "natural");
  return { version: 1, generated_at: new Date().toISOString(), mode: manifest.mode, cases,
    metrics: { natural_cases: natural.length, natural_first_attempt_pass: natural.filter((item) => item.runs[0].status === "PASSED").length,
      seeded_cases: cases.filter((item) => item.kind === "seeded_repair").length,
      final_pass: cases.filter((item) => item.outcome === "PASSED").length,
      native_agent_executions: cases.flatMap((item) => item.runs.flatMap((run) => run.agents)).filter((agent) => agent.native_agent_id).length,
      host_interrupted_turns: cases.flatMap((item) => item.runs.flatMap((run) => run.agents)).reduce((sum, agent) => sum + (agent.interrupted_turns ?? 0), 0),
      tokens: null, cost: null, model: "inherited; exact host model not reported" },
    limitations: [...manifest.limitations, "Token usage and monetary cost are unavailable, not zero. Host wall time includes controller waiting/polling, not pure model inference time.",
      "Evaluation budgets require controller cooperation, not an independent watchdog. Old campaigns without ledgers remain unmeasured; quality PASS is separate from budget compliance."] };
}

const [command, ...args] = process.argv.slice(2);
let result: unknown;
if (command === "prepare" && args.length === 0) result = prepare();
else if (command === "budget-init" && args.length === 1) result = initializeBudget(args[0]);
else if (command === "budget-admit" && args.length === 5) result = admitBudget(args[0], args[1], args[2], args[3] as "worker" | "verifier", Number(args[4]));
else if (command === "budget-status" && args.length === 1) result = budgetStatus(args[0]);
else if (["budget-bind", "budget-observe"].includes(command) && args.length === (command === "budget-bind" ? 4 : 3)) {
  const observation = readJson<BudgetObservation>(assertWithinRoot(args[0], resolve(args.at(-1)!)));
  result = command === "budget-bind" ? bindBudgetAgent(args[0], args[1], args[2], observation) : observeBudget(args[0], args[1], observation);
}
else if (command === "register" && args.length === 4) result = register(...args as [string, string, string, string]);
else if (command === "handoff" && args.length === 4) result = recordHandoff(...args as [string, string, string, string]);
else if (command === "summarize" && args.length === 1) result = summarize(args[0]);
else if (command === "checkpoint" && args.length === 1) result = checkpoint(args[0]);
else if (command === "repair" && [2, 3].includes(args.length)) {
  if (hasBudget(args[0])) {
    const budget = budgetStatus(args[0]);
    if (budget.action !== "IDLE" || budget.rounds_started >= budget.max_rounds || budget.remaining_ms < 10_000) throw new Error("Repair exceeds shared evaluation budget or prior execution is unresolved");
  }
  checkpoint(args[0]);
  result = createRepairRun(args[0], { fromRun: args[2] ?? "initial", taskId: "worker",
    tasks: [readJson<FactoryTask>(join(args[0], ".codex-factory", "eval-task.json"))], requestId: args[1] });
}
else if (command === "plan" && args.length === 2) result = prepareSpawnPlan(args[0], readTaskGraphSnapshot(args[0], args[1]).tasks, args[1]);
else throw new Error("Usage: live-eval.ts prepare | budget-init/status <root> | budget-admit <root> <run> <assignment> <worker|verifier> <round> | budget-bind <root> <run> <assignment> <observation> | budget-observe <root> <agent> <observation> | register/handoff <root> <run> <assignment> <observation> | plan <root> <run> | checkpoint <root> | repair <root> <request-id> | summarize <manifest>");
process.stdout.write(JSON.stringify(result, null, 2) + "\n");
