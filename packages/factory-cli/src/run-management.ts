import { existsSync, readdirSync } from "node:fs";
import { isAbsolute, join, relative, resolve } from "node:path";
import { profileForTask } from "./agents.js";
import { factoryDirectory, loadConfig } from "./config.js";
import { reportedCommandOutcomes } from "./command-outcome.js";
import { readVerifiedContextEventsReadonly } from "./context-space.js";
import { verifyTaskCompletion, type AcceptanceCheck, type RecordedHandoff, type VerificationReceipt } from "./evidence.js";
import {
  addAutomaticVerificationTasks, prepareSpawnPlan, readAgentRegistry, readCurrentSpawnPlan,
  readTaskGraphSnapshot, validateTaskGraph, verifyPersistedRuntimeClaims,
  withRunControllerLock, type ManagedSpawnPlan, type NativeAgentRegistry,
} from "./orchestrator.js";
import {
  assertRepairRunCommitted, managedRunDirectory, readRepairJournal, repairJournalPath,
  requireIdentifier, RunManagementError, runFileSnapshot, taskContractHash,
  type RepairJournal, type RepairLink,
} from "./repair-store.js";
import type { FactoryTask } from "./types.js";
import { assertWithinRoot, nowIso, readJson, sha256, stableStringify, withFileLock, writeJsonAtomic } from "./util.js";

export interface RunInspection {
  version: "1.0.0";
  run_id: string;
  project_id: string;
  integrity: "VERIFIED";
  status: "PASSED" | "FAILED" | "BLOCKED" | "RUNNING" | "AWAITING_DISPATCH" | "READY";
  host_liveness: "UNKNOWN";
  repair?: RepairLink;
  tasks: Array<{
    task_id: string;
    status: FactoryTask["status"];
    blocked_by: string[];
    failure_reasons: string[];
    evidence: Array<{ path: string; sha256: string }>;
  }>;
  next_actions: string[];
  limitations: string[];
}

interface RunListEntry {
  run_id: string;
  created_at: string | null;
  status: RunInspection["status"] | "UNAVAILABLE";
  verified_tasks: number | null;
  total_tasks: number | null;
  parent_run_id: string | null;
  repair_index: number | null;
  error?: string;
}

export function listRuns(root: string, limit = 10) {
  if (!Number.isInteger(limit) || limit < 1 || limit > 50) {
    throw new Error("--limit must be an integer between 1 and 50");
  }
  const config = loadConfig(root);
  const directory = assertWithinRoot(root, join(factoryDirectory(root), "runs"));
  const candidates = (existsSync(directory) ? readdirSync(directory, { withFileTypes: true }) : [])
    .filter((entry) => entry.isDirectory() || entry.isSymbolicLink())
    .map((entry) => {
      let createdAt: string | null = null;
      try {
        const path = assertWithinRoot(root, join(managedRunDirectory(root, entry.name), "run.json"));
        const metadata = readJson<{ created_at?: string }>(path);
        const time = typeof metadata.created_at === "string" ? Date.parse(metadata.created_at) : NaN;
        if (Number.isFinite(time)) createdAt = new Date(time).toISOString();
      } catch { /* Keep unreadable runs discoverable; inspection below reports the problem. */ }
      return { run_id: entry.name, created_at: createdAt };
    })
    .sort((left, right) => (right.created_at ?? "").localeCompare(left.created_at ?? "") || left.run_id.localeCompare(right.run_id));
  const runs: RunListEntry[] = candidates.slice(0, limit).map((item) => {
    try {
      const result = inspectRun(root, item.run_id);
      return { ...item, status: result.status,
        verified_tasks: result.tasks.filter((task) => task.status === "verified").length,
        total_tasks: result.tasks.length,
        parent_run_id: result.repair?.parent_run_id ?? null,
        repair_index: result.repair?.repair_index ?? null };
    } catch (error) {
      return { ...item, status: "UNAVAILABLE", verified_tasks: null, total_tasks: null,
        parent_run_id: null, repair_index: null,
        error: error instanceof Error ? error.message : "Run could not be read" };
    }
  });
  return { version: "1.0.0" as const, project_id: config.project_id,
    total: candidates.length, limit, has_more: candidates.length > runs.length,
    host_liveness: "UNKNOWN" as const, runs };
}

function validateRegistry(registry: NativeAgentRegistry, tasks: FactoryTask[], runId: string, projectId: string): void {
  if (registry.version !== "1.0.0" || registry.run_id !== runId || registry.project_id !== projectId || !Array.isArray(registry.entries)) {
    throw new RunManagementError("RUN_INTEGRITY", "Agent registry identity or structure is invalid");
  }
  const instances = new Set<string>();
  const assignments = new Set<string>();
  const assignedTasks = new Set<string>();
  for (const entry of registry.entries) {
    if (instances.has(entry.instance_key) || !Array.isArray(entry.assignment_ids) || !Array.isArray(entry.task_ids) ||
        entry.assignment_ids.length !== entry.task_ids.length || !Array.isArray(entry.native_receipts) ||
        !["planned", "spawned", "running", "idle", "completed", "failed", "closed"].includes(entry.lifecycle)) {
      throw new RunManagementError("RUN_INTEGRITY", "Agent registry contains invalid or duplicate bindings");
    }
    instances.add(entry.instance_key);
    for (let index = 0; index < entry.assignment_ids.length; index++) {
      const id = entry.assignment_ids[index];
      requireIdentifier(id);
      const task = tasks.find((item) => item.task_id === entry.task_ids[index]);
      if (!task || assignments.has(id) || assignedTasks.has(task.task_id) || profileForTask(task).profile_id !== entry.profile_id) {
        throw new RunManagementError("RUN_INTEGRITY", "Agent assignment does not uniquely match its task and profile");
      }
      assignments.add(id);
      assignedTasks.add(task.task_id);
    }
  }
}

export function inspectRun(root: string, runId: string): RunInspection {
  try { return inspectRunSnapshot(root, runId); }
  catch (error) {
    if (error instanceof RunManagementError) throw error;
    throw new RunManagementError("RUN_INTEGRITY", error instanceof Error ? error.message : "Run evidence could not be read");
  }
}

export interface RunContinuation {
  version: "1.0.0";
  run_id: string;
  status: "DISPATCH" | "WAITING" | "BLOCKED" | "FAILED" | "COMPLETE";
  inspection: RunInspection;
  verifications: VerificationReceipt[];
  plan: ManagedSpawnPlan | null;
  waiting_for: Array<{ task_id: string; assignment_id: string; native_agent_id: string }>;
  delivery: {
    basis: "RECORDED_PASS_RECEIPTS";
    complete: boolean;
    tasks: Array<{ task_id: string; title: string; verified_at: string; receipt_path: string;
      artifacts: RecordedHandoff["observed_artifacts"] }>;
  };
  next_actions: string[];
}

export function continueRun(root: string, runId: string): RunContinuation {
  let inspection = inspectRun(root, runId);
  const verifications: VerificationReceipt[] = [];
  let plan: ManagedSpawnPlan | null = null;
  let graph = readTaskGraphSnapshot(root, runId).tasks;
  let registry = readAgentRegistry(root, runId);
  // Each underlying operation locks and revalidates its own state. A retry keeps completed receipts.
  if (!["FAILED", "PASSED"].includes(inspection.status)) {
    for (const verifier of graph.filter((task) => task.status === "handoff" && profileForTask(task).profile_id === "factory_verifier")) {
      const target = graph.find((task) => task.task_id === verifier.dependencies[0]);
      const entry = registry.entries.find((item) => item.task_ids.includes(verifier.task_id));
      const assignment = entry?.assignment_ids[entry.task_ids.indexOf(verifier.task_id)];
      if (target?.status !== "handoff" || !assignment) continue;
      const receipt = verifyTaskCompletion(root, runId, target.task_id, assignment);
      verifications.push(receipt);
      if (receipt.verdict === "FAIL") break;
    }
    inspection = inspectRun(root, runId);
    graph = readTaskGraphSnapshot(root, runId).tasks;
    registry = readAgentRegistry(root, runId);
    if (!["FAILED", "PASSED"].includes(inspection.status)) {
      const currentPlan = readCurrentSpawnPlan(root, runId);
      const unregistered = currentPlan.assignments.some((assignment) =>
        graph.some((task) => task.task_id === assignment.task_id && task.status === "assigned") &&
        !registry.entries.some((entry) => entry.native_receipts.some((receipt) => receipt.assignment_id === assignment.assignment_id)));
      const assigned = new Set(registry.entries.flatMap((entry) => entry.task_ids));
      const ready = inspection.tasks.some((task) => ["pending", "ready"].includes(task.status) &&
        !task.blocked_by.length && !assigned.has(task.task_id));
      if (unregistered || ready) {
        plan = prepareSpawnPlan(root, graph, runId);
        graph = readTaskGraphSnapshot(root, runId).tasks;
        // A recorded assignment may have been explicitly blocked after its plan was generated.
        plan = { ...plan, assignments: plan.assignments.filter((assignment) =>
          graph.some((task) => task.task_id === assignment.task_id && task.status === "assigned")) };
        inspection = inspectRun(root, runId);
        registry = readAgentRegistry(root, runId);
      }
    }
  }
  const waiting = registry.entries.flatMap((entry) => entry.task_ids.flatMap((taskId, index) => {
    const assignmentId = entry.assignment_ids[index];
    return entry.native_agent_id && entry.native_receipts.some((receipt) => receipt.assignment_id === assignmentId) &&
      graph.some((task) => task.task_id === taskId && ["assigned", "in_progress"].includes(task.status))
      ? [{ task_id: taskId, assignment_id: assignmentId, native_agent_id: entry.native_agent_id }] : [];
  }));
  const directory = managedRunDirectory(root, runId);
  const delivered = graph.filter((task) => task.status === "verified" && profileForTask(task).profile_id !== "factory_verifier").map((task) => {
    const receiptPath = join(directory, "verification", task.task_id, "receipt.json");
    const receipt = readJson<VerificationReceipt>(assertWithinRoot(root, receiptPath));
    const handoff = readJson<RecordedHandoff>(assertWithinRoot(root, join(directory, "handoffs", receipt.worker_assignment_id + ".json")));
    return { task_id: task.task_id, title: task.title, verified_at: receipt.verified_at,
      receipt_path: relative(root, receiptPath).replaceAll("\\", "/"), artifacts: handoff.observed_artifacts };
  });
  const status: RunContinuation["status"] = inspection.status === "FAILED" ? "FAILED"
    : inspection.status === "PASSED" ? "COMPLETE" : plan?.assignments.length ? "DISPATCH"
    : waiting.length ? "WAITING" : "BLOCKED";
  return { version: "1.0.0", run_id: runId, status, inspection, verifications, plan,
    waiting_for: waiting, delivery: { basis: "RECORDED_PASS_RECEIPTS", complete: status === "COMPLETE", tasks: delivered },
    next_actions: [
      ...(status === "DISPATCH" ? ["Check the host before dispatching returned assignments. Register actual native receipts; never duplicate an existing spawn."] : []),
      ...(plan?.blocked_tasks ?? []).map((task) => "Scheduler blocked " + task.task_id + ": " + task.blocked_by.join(", ")),
      ...inspection.next_actions,
      ...(["DISPATCH", "WAITING"].includes(status) ? ["After recording handoffs, call factoryctl run continue --project " +
        JSON.stringify(resolve(root).replaceAll("\\", "/")) + " --run " + runId + " --json."] : []),
    ],
  };
}

function nextRunActions(root: string, runId: string, status: RunInspection["status"],
  tasks: RunInspection["tasks"], graph: FactoryTask[], registry: NativeAgentRegistry, plan: ManagedSpawnPlan): string[] {
  if (status === "FAILED") return [
    ...graph.filter((task) => task.status === "failed" && profileForTask(task).profile_id !== "factory_verifier").map((task) =>
      "Prepare repair context: factoryctl repair prepare --project " + JSON.stringify(resolve(root).replaceAll("\\", "/")) +
      " --from-run " + runId + " --task " + task.task_id + " --json"),
    "Read failed task receipt; confirm all previous executions stopped, then use factoryctl repair create after approval. Never reset failed tasks.",
  ];
  if (status === "PASSED") return ["Run complete. No further dispatch or verification is required for this recorded run."];
  const project = " --project " + JSON.stringify(resolve(root).replaceAll("\\", "/"));
  const run = " --run " + runId;
  const actions: string[] = [];
  for (const task of graph.filter((item) => item.status === "handoff" && profileForTask(item).profile_id === "factory_verifier")) {
    const target = graph.find((item) => item.task_id === task.dependencies[0]);
    const entry = registry.entries.find((item) => item.task_ids.includes(task.task_id));
    const assignment = entry?.assignment_ids[entry.task_ids.indexOf(task.task_id)];
    if (target?.status === "handoff" && assignment) {
      actions.push("Verifier handoff recorded for " + target.task_id + "; execute acceptance: factoryctl verify" + project + run +
        " --task " + target.task_id + " --verifier-assignment " + assignment);
    }
  }
  const unregistered = plan.assignments.filter((assignment) =>
    graph.some((task) => task.task_id === assignment.task_id && task.status === "assigned") &&
    !registry.entries.some((entry) => entry.native_receipts.some((receipt) => receipt.assignment_id === assignment.assignment_id)));
  if (unregistered.length) {
    actions.push("Unregistered dispatches: " + unregistered.map((item) => item.task_id + " (" + item.assignment_id + ")").join(", ") +
      ". Check the host first: record an existing spawn's actual receipt, or dispatch this existing assignment if it has not started. Do not blindly spawn again.");
    actions.push("Recover the existing plan: factoryctl plan" + project + run + " --json");
  } else {
    const assigned = new Set(registry.entries.flatMap((entry) => entry.task_ids));
    const ready = tasks.filter((task) => ["pending", "ready"].includes(task.status) && !task.blocked_by.length && !assigned.has(task.task_id));
    if (ready.length) actions.push("Dependencies ready for " + ready.map((task) => task.task_id).join(", ") +
      "; ask the scheduler for the next wave (capacity and scope rules still apply): factoryctl plan" + project + run + " --json");
  }
  const waiting = registry.entries.filter((entry) => entry.native_agent_id && entry.task_ids.some((id) =>
    graph.some((task) => task.task_id === id && ["assigned", "in_progress"].includes(task.status))));
  if (waiting.length) {
    actions.push("Await or recover handoffs from " + waiting.map((entry) => entry.task_ids.join(",") + " (" + entry.native_agent_id + ")").join("; ") +
      ". These are recorded IDs, not a live host status. Check the host before retrying or changing lifecycle.");
    actions.push("Recorded executions: factoryctl agent status" + project + run + " --json");
  }
  if (!actions.length) {
    actions.push("Resolve blocked tasks or execution policy before replanning; no immediate dispatch or acceptance step is identified.");
    actions.push("Recorded executions: factoryctl agent status" + project + run + " --json");
  }
  return actions;
}

function inspectRunSnapshot(root: string, runId: string): RunInspection {
  const directory = managedRunDirectory(root, runId);
  if (!existsSync(directory)) throw new RunManagementError("RUN_NOT_FOUND", "Run not found: " + runId);
  const before = runFileSnapshot(root, directory);
  const repair = assertRepairRunCommitted(root, runId);
  for (const name of ["run.json", "task-graph.json", "spawn-plan.json", "agent-registry.json"]) {
    if (!existsSync(join(directory, name))) throw new RunManagementError("RUN_INTEGRITY", "Run is missing " + name);
  }
  const config = loadConfig(root);
  const metadata = readJson<{ version: string; run_id: string; project_id: string }>(join(directory, "run.json"));
  const graph = readTaskGraphSnapshot(root, runId);
  validateTaskGraph(graph.tasks);
  const registry = readAgentRegistry(root, runId);
  validateRegistry(registry, graph.tasks, runId, config.project_id);
  const plan = readCurrentSpawnPlan(root, runId);
  if (metadata.version !== "1.0.0" || metadata.run_id !== runId || metadata.project_id !== config.project_id ||
      plan.project_id !== config.project_id || !Array.isArray(plan.assignments)) {
    throw new RunManagementError("RUN_INTEGRITY", "Run metadata or spawn plan identity is invalid");
  }
  for (const assignment of plan.assignments) {
    if (!registry.entries.some((entry) => entry.assignment_ids.some((id, index) =>
      id === assignment.assignment_id && entry.task_ids[index] === assignment.task_id && entry.profile_id === assignment.profile_id))) {
      throw new RunManagementError("RUN_INTEGRITY", "Spawn plan assignment is not registered");
    }
  }
  const events = config.features.external_context.enabled ? readVerifiedContextEventsReadonly(root) : [];
  verifyPersistedRuntimeClaims(root, runId, graph.tasks, registry, events);
  const tasks = graph.tasks.map((task) => {
    const isVerifier = profileForTask(task).profile_id === "factory_verifier";
    const receiptTaskId = isVerifier ? task.dependencies[0] : task.task_id;
    const evidence: RunInspection["tasks"][number]["evidence"] = [];
    for (const entry of registry.entries) {
      const index = entry.task_ids.indexOf(task.task_id);
      if (index < 0) continue;
      const assignment = entry.assignment_ids[index];
      if (["in_progress", "handoff", "verified", "failed"].includes(task.status)) {
        const native = entry.native_receipts.find((item) => item.assignment_id === assignment)!;
        evidence.push({ path: native.receipt_path, sha256: native.receipt_sha256 });
      }
      if (["handoff", "verified", "failed"].includes(task.status)) {
        const path = join(directory, "handoffs", assignment + ".json");
        const handoff = readJson<{ handoff_hash: string }>(path);
        evidence.push({ path: relative(root, path).replaceAll("\\", "/"), sha256: handoff.handoff_hash });
      }
    }
    let failureReasons: string[] = [];
    if (["verified", "failed"].includes(task.status)) {
      const path = join(directory, "verification", receiptTaskId, "receipt.json");
      const receipt = readJson<VerificationReceipt>(path);
      evidence.push({ path: relative(root, path).replaceAll("\\", "/"), sha256: receipt.receipt_hash });
      if (!isVerifier) failureReasons = receipt.failure_reasons;
    }
    return {
      task_id: task.task_id, status: task.status, failure_reasons: failureReasons, evidence,
      blocked_by: task.dependencies.filter((id) => {
        const dependency = graph.tasks.find((item) => item.task_id === id)!;
        return isVerifier ? !["handoff", "verified", "failed"].includes(dependency.status) : dependency.status !== "verified";
      }),
    };
  });
  const statuses = tasks.map((task) => task.status);
  const status: RunInspection["status"] = statuses.includes("failed") ? "FAILED"
    : statuses.every((item) => item === "verified") ? "PASSED"
    : statuses.some((item) => ["in_progress", "handoff"].includes(item)) ? "RUNNING"
    : statuses.includes("assigned") ? "AWAITING_DISPATCH"
    : tasks.some((task) => ["pending", "ready"].includes(task.status) && task.blocked_by.length === 0) ? "READY" : "BLOCKED";
  if (before !== runFileSnapshot(root, directory)) {
    throw new RunManagementError("RUN_CHANGED", "Run changed during inspection; retry the read-only command");
  }
  return {
    version: "1.0.0", run_id: runId, project_id: config.project_id, integrity: "VERIFIED", status,
    host_liveness: "UNKNOWN", ...(repair ? { repair } : {}), tasks,
    next_actions: nextRunActions(root, runId, status, tasks, graph.tasks, registry, plan),
    limitations: ["Historical receipt integrity only; acceptance commands are not rerun and current artifacts may differ.",
      "Host liveness is not queried. File hashes are not protection against a same-permission malicious process."],
  };
}

export interface RepairRequest {
  fromRun: string;
  taskId: string;
  tasks: FactoryTask[];
  requestId: string;
}

function recordedTaskOutput(root: string, runId: string, taskId: string) {
  const directory = managedRunDirectory(root, runId);
  const receiptPath = assertWithinRoot(root, join(directory, "verification", taskId, "receipt.json"));
  const receipt = readJson<VerificationReceipt>(receiptPath);
  const workerPath = assertWithinRoot(root, join(directory, "handoffs", receipt.worker_assignment_id + ".json"));
  const verifierPath = assertWithinRoot(root, join(directory, "handoffs", receipt.verifier_assignment_id + ".json"));
  return { receipt, worker: readJson<RecordedHandoff>(workerPath), verifier: readJson<RecordedHandoff>(verifierPath),
    receipt_path: relative(root, receiptPath).replaceAll("\\", "/"),
    worker_handoff_path: relative(root, workerPath).replaceAll("\\", "/"),
    verifier_handoff_path: relative(root, verifierPath).replaceAll("\\", "/"),
  };
}

export function prepareRepair(root: string, fromRun: string, taskId: string) {
  requireIdentifier(taskId);
  const inspection = inspectRun(root, fromRun);
  const directory = managedRunDirectory(root, fromRun);
  const before = runFileSnapshot(root, directory);
  const graph = readTaskGraphSnapshot(root, fromRun);
  const original = graph.tasks.find((task) => task.task_id === taskId);
  if (!original) throw new RunManagementError("TASK_NOT_FOUND", "Failed task not found");
  if (original.status !== "failed" || profileForTask(original).profile_id === "factory_verifier") {
    throw new RunManagementError("NOT_REPAIRABLE", "Repair preparation requires an independently verified failed worker task");
  }
  const source = recordedTaskOutput(root, fromRun, taskId);
  const projectFlag = " --project " + JSON.stringify(resolve(root).replaceAll("\\", "/"));
  const rootRun = inspection.repair?.root_run_id ?? fromRun;
  const rootTask = inspection.repair?.root_task_id ?? taskId;
  const index = inspection.repair?.repair_index ?? 0;
  const journalsDirectory = assertWithinRoot(root, join(factoryDirectory(root), "repairs"));
  const journals = (existsSync(journalsDirectory) ? readdirSync(journalsDirectory) : [])
    .filter((name) => name.endsWith(".json"))
    .map((name) => readRepairJournal(root, name.slice(0, -5)))
    .filter((record) => record.link.root_run_id === rootRun && record.link.root_task_id === rootTask);
  const children = journals.filter((record) => record.link.parent_run_id === fromRun && record.link.failed_task_id === taskId);
  if (children.length > 1) throw new RunManagementError("REPAIR_CONFLICT", "Multiple repairs are reserved for this failed task");
  const child = children[0];
  const childInspection = child?.state === "COMMITTED" ? inspectRun(root, child.link.new_run_id) : undefined;
  const blockers: Array<{ code: string; message: string }> = [];
  if (!loadConfig(root).features.multi_agent.enabled) {
    blockers.push({ code: "MULTI_AGENT_DISABLED", message: "Repair creation requires multi-agent mode to be explicitly enabled." });
  }
  const registry = readAgentRegistry(root, fromRun);
  if (registry.entries.some((entry) => !["completed", "closed"].includes(entry.lifecycle)) ||
      graph.tasks.some((task) => ["assigned", "in_progress", "handoff"].includes(task.status))) {
    blockers.push({ code: "ACTIVE_EXECUTION", message: "Resolve previous host executions before creating a repair; recorded IDs are not live host status." });
  }
  if (child?.state === "PREPARING") {
    blockers.push({ code: "REPAIR_INCOMPLETE", message: "An incomplete repair is already reserved. Preserve its journal; do not recreate or dispatch it." });
  } else if (!child && index >= 2) {
    blockers.push({ code: "REPAIR_LIMIT", message: "Two repair attempts have been used. Review the task with the user; do not start an ordinary run to bypass the limit." });
  } else if (!child && journals.some((record) => record.link.repair_index >= index + 1)) {
    blockers.push({ code: "REPAIR_CONFLICT", message: "Another repair already reserved this chain step. Inspect the existing chain before proceeding." });
  }
  const dependenciesVerified = original.dependencies.every((id) => graph.tasks.find((task) => task.task_id === id)?.status === "verified");
  const suggestedTasks: FactoryTask[] | null = dependenciesVerified ? [{ ...original, status: "pending", dependencies: [] }] : null;
  if (!dependenciesVerified) {
    blockers.push({ code: "UPSTREAM_NOT_VERIFIED", message: "Same-task reuse requires verified upstream tasks; prepare an explicit helper plan instead." });
  }

  // Reused tasks lose dependency edges in the child graph; keep original upstream inputs discoverable.
  const inputs = original.dependencies.map((id) => ({ run_id: fromRun, task_id: id }));
  let ancestor = inspection.repair;
  while (ancestor) {
    const parent = inspectRun(root, ancestor.parent_run_id);
    const origin = readTaskGraphSnapshot(root, ancestor.parent_run_id).tasks.find((task) => task.task_id === ancestor!.failed_task_id);
    for (const id of origin?.dependencies ?? []) inputs.push({ run_id: ancestor.parent_run_id, task_id: id });
    ancestor = parent.repair;
  }
  const upstream = inputs.map((input) => {
    const task = readTaskGraphSnapshot(root, input.run_id).tasks.find((item) => item.task_id === input.task_id)!;
    const output = task.status === "verified" && profileForTask(task).profile_id !== "factory_verifier"
      ? recordedTaskOutput(root, input.run_id, input.task_id) : undefined;
    return { ...input, status: task.status, receipt_path: output?.receipt_path ?? null,
      handoff_path: output?.worker_handoff_path ?? null, artifacts: output?.worker.observed_artifacts ?? [] };
  });
  const failingChecks = (checks: AcceptanceCheck[]) => ({
    total: checks.length, passed: checks.filter((check) => check.status === "PASS").length,
    failed: checks.filter((check) => check.status !== "PASS").length,
    items: checks.flatMap((check, position) => check.status === "PASS" ? [] : [{ index: position + 1, ...check }]).slice(0, 20),
  });
  const workerOutcomes = reportedCommandOutcomes(source.worker.report.commands, original.acceptance_methods, source.receipt.command_policy);
  const verifierOutcomes = reportedCommandOutcomes(source.verifier.report.commands, original.acceptance_methods, source.receipt.command_policy);
  const reportedFailures = [
    ...source.worker.report.commands.filter((_, index) => workerOutcomes[index] === "FAILURE")
      .map((command) => ({ source: "WORKER_HANDOFF" as const, handoff_path: source.worker_handoff_path, ...command })),
    ...source.verifier.report.commands.filter((_, index) => verifierOutcomes[index] === "FAILURE")
      .map((command) => ({ source: "VERIFIER_HANDOFF" as const, handoff_path: source.verifier_handoff_path, ...command })),
  ];
  const status = child?.state === "COMMITTED" ? "EXISTING_REPAIR" as const : blockers.length ? "BLOCKED" as const : "REVIEW_REQUIRED" as const;
  const nextActions: string[] = [];
  if (child?.state === "COMMITTED") {
    if (childInspection!.status === "PASSED") {
      nextActions.push("The existing repair passed. Read its delivery with factoryctl run continue" + projectFlag + " --run " + child.link.new_run_id + " --json. The original failed run stays unchanged.");
    } else if (childInspection!.status === "FAILED") {
      const failed = readTaskGraphSnapshot(root, child.link.new_run_id).tasks.filter((task) =>
        task.status === "failed" && profileForTask(task).profile_id !== "factory_verifier");
      nextActions.push(...failed.map((task) => "Prepare from the failed repair, not its original parent: factoryctl repair prepare" + projectFlag +
        " --from-run " + child.link.new_run_id + " --task " + task.task_id + " --json"));
    } else {
      nextActions.push("Inspect the existing repair and check the host before continuing it: factoryctl run inspect" + projectFlag + " --run " + child.link.new_run_id + " --json");
      nextActions.push("factoryctl run continue" + projectFlag + " --run " + child.link.new_run_id + " --json");
    }
  } else if (!blockers.length) {
    nextActions.push("Review the observations and confirm prior host executions stopped. Obtain repair approval before creating a new run.");
    nextActions.push("factoryctl repair create" + projectFlag + " --from-run " + fromRun + " --task " + taskId +
      " --reuse-task --request-id <stable-request-id> --json");
  } else {
    nextActions.push(...blockers.map((blocker) => blocker.message));
  }
  if (before !== runFileSnapshot(root, directory)) throw new RunManagementError("RUN_CHANGED", "Run changed during repair preparation; retry");
  return { version: "1.0.0" as const, status, read_only: true as const, from_run: fromRun, task_id: taskId,
    root_cause: "NOT_INFERRED" as const, source_verdict: source.receipt.verdict,
    failure_reasons: source.receipt.failure_reasons,
    evidence: { receipt_path: source.receipt_path, receipt_hash: source.receipt.receipt_hash,
      worker_handoff_path: source.worker_handoff_path, verifier_handoff_path: source.verifier_handoff_path,
      verification_directory: relative(root, join(directory, "verification", taskId)).replaceAll("\\", "/") },
    observations: { acceptance: failingChecks(source.receipt.acceptance_checks), artifacts: failingChecks(source.receipt.artifact_checks),
      reported_command_failures: { total: reportedFailures.length, items: reportedFailures.slice(0, 20) },
      verifier_proposal: source.receipt.independent_verifier_proposal },
    task_contract: original, suggested_tasks: suggestedTasks, upstream_inputs: upstream,
    repair: { root_run_id: rootRun, root_task_id: rootTask, current_attempt: index, limit: 2,
      remaining_attempts: Math.max(0, 2 - Math.max(index, ...journals.map((record) => record.link.repair_index))),
      existing_child: child ? { run_id: child.link.new_run_id, state: child.state,
        status: childInspection?.status ?? null, journal_path: relative(root, repairJournalPath(root, child.link.new_run_id)).replaceAll("\\", "/") } : null },
    blockers, next_actions: nextActions,
    limitations: ["Observed failure channels, not inferred code/environment root causes; FAIL rules are unchanged.",
      "Handoff commands are agent reports, not independent controller executions. Each failure list shows at most 20 items; read the referenced evidence for the rest.",
      "Historical artifacts only; inspect current inputs before reuse. This output grants no approval, reserves no attempt, and executes no commands.",
      "Repair availability is a snapshot; repair create rechecks the current state under its existing locks."],
  };
}

function normalizedRepairScope(root: string, scope: string): string {
  if (typeof scope !== "string" || !scope.trim() || isAbsolute(scope) || /^[A-Za-z]:/.test(scope)) {
    throw new RunManagementError("SCOPE_EXPANSION", "Repair scope must be project-relative");
  }
  const path = scope.replaceAll("\\", "/").replace(/\/$/, "");
  if (path.split("/").some((part) => !part || part === "." || part === "..") || /[*?\[\]:]/.test(path)) {
    throw new RunManagementError("SCOPE_EXPANSION", "Repair scope requires explicit paths without traversal or globs");
  }
  assertWithinRoot(root, resolve(root, path));
  return process.platform === "win32" ? path.toLowerCase() : path;
}

function validateRepairTasks(root: string, original: FactoryTask, drafts: FactoryTask[]): FactoryTask[] {
  validateTaskGraph(drafts);
  const scopes = original.write_scope.map((scope) => normalizedRepairScope(root, scope));
  for (const task of drafts) {
    if (!["pending", "ready"].includes(task.status) || profileForTask(task).profile_id === "factory_verifier") {
      throw new RunManagementError("INVALID_REPAIR", "Supply pending/ready worker tasks only; independent verifiers are generated automatically");
    }
    for (const values of [task.acceptance_methods, task.required_artifacts]) {
      if (values.some((value) => typeof value !== "string" || !value.trim())) {
        throw new RunManagementError("INVALID_REPAIR", "Repair acceptance and artifact entries must be nonempty strings");
      }
    }
    for (const scope of task.write_scope) {
      const candidate = normalizedRepairScope(root, scope);
      if (!scopes.some((parent) => candidate === parent || candidate.startsWith(parent + "/"))) {
        throw new RunManagementError("SCOPE_EXPANSION", "Repair task expands the approved write_scope: " + task.task_id);
      }
    }
  }
  const target = drafts.find((task) => task.task_id === original.task_id);
  if (!target || profileForTask(target).profile_id !== profileForTask(original).profile_id ||
      !original.acceptance_methods.every((item) => target.acceptance_methods.includes(item)) ||
      !original.required_artifacts.every((item) => target.required_artifacts.includes(item)) ||
      !(original.required_capabilities ?? []).every((item) => target.required_capabilities?.includes(item))) {
    throw new RunManagementError("ACCEPTANCE_WEAKENED", "Repair must retain the failed task ID, profile, capabilities, acceptance methods and required artifacts");
  }
  const dependencies = new Set<string>();
  const visit = (task: FactoryTask): void => {
    for (const id of task.dependencies) {
      if (!dependencies.has(id)) { dependencies.add(id); visit(drafts.find((item) => item.task_id === id)!); }
    }
  };
  visit(target);
  if (drafts.some((task) => task !== target && !dependencies.has(task.task_id))) {
    throw new RunManagementError("INVALID_REPAIR", "The original target must transitively depend on every repair helper task");
  }
  const tasks = addAutomaticVerificationTasks(drafts);
  validateTaskGraph(tasks);
  return tasks;
}

function repairResult(link: RepairLink) {
  return { status: "CREATED" as const, run_id: link.new_run_id, repair: link,
    next_action: "factoryctl run continue --run " + link.new_run_id + " --json" };
}

export function createRepairRun(root: string, request: RepairRequest): ReturnType<typeof repairResult> {
  for (const id of [request.fromRun, request.taskId, request.requestId]) requireIdentifier(id);
  const config = loadConfig(root);
  if (!config.features.multi_agent.enabled) throw new RunManagementError("INVALID_REPAIR", "Repair runs require multi-agent mode");
  const runId = "repair-r1-" + sha256(stableStringify([config.project_id, request.requestId])).slice(0, 32);
  const requestHash = sha256(stableStringify(request));
  const journalPath = repairJournalPath(root, runId);
  const lockPath = assertWithinRoot(root, join(factoryDirectory(root), "repairs", "controller.lock"));
  // Serialize the reservation across all parents, then hold the parent controller stable.
  return withFileLock(lockPath, () => {
    if (existsSync(journalPath)) {
      const previous = readRepairJournal(root, runId);
      if (previous.link.request_hash !== requestHash) throw new RunManagementError("REQUEST_CONFLICT", "request-id was already used with different input");
      assertRepairRunCommitted(root, runId);
      inspectRun(root, runId);
      return repairResult(previous.link);
    }
    inspectRun(root, request.fromRun);
    return withRunControllerLock(root, request.fromRun, () => withFileLock(
      join(managedRunDirectory(root, request.fromRun), "task-graph.json.lock"), () => {
      inspectRun(root, request.fromRun);
      const graph = readTaskGraphSnapshot(root, request.fromRun);
      const original = graph.tasks.find((task) => task.task_id === request.taskId);
      if (!original) throw new RunManagementError("TASK_NOT_FOUND", "Failed task not found");
      if (original.status !== "failed" || profileForTask(original).profile_id === "factory_verifier") {
        throw new RunManagementError("NOT_REPAIRABLE", "Repair requires an independently verified failed worker task");
      }
      const registry = readAgentRegistry(root, request.fromRun);
      if (registry.entries.some((entry) => !["completed", "closed"].includes(entry.lifecycle)) ||
          graph.tasks.some((task) => ["assigned", "in_progress", "handoff"].includes(task.status))) {
        throw new RunManagementError("ACTIVE_EXECUTION", "Previous executions are active or unknown; resolve their host state before repair");
      }
      const tasks = validateRepairTasks(root, original, request.tasks);
      const parentLink = assertRepairRunCommitted(root, request.fromRun);
      const rootRun = parentLink?.root_run_id ?? request.fromRun;
      const rootTask = parentLink?.root_task_id ?? request.taskId;
      const repairIndex = (parentLink?.repair_index ?? 0) + 1;
      if (repairIndex > 2) throw new RunManagementError("REPAIR_LIMIT", "Repair chain limit of 2 reached; request a new design review");
      const journalDirectory = assertWithinRoot(root, join(factoryDirectory(root), "repairs"));
      for (const name of readdirSync(journalDirectory).filter((name) => name.endsWith(".json"))) {
        const other = readRepairJournal(root, name.slice(0, -5)).link;
        if (other.parent_run_id === request.fromRun && other.failed_task_id === request.taskId) {
          throw new RunManagementError("REPAIR_CONFLICT", "A repair is already reserved for this failed task; inspect that child run");
        }
        if (other.root_run_id === rootRun && other.root_task_id === rootTask && other.repair_index >= repairIndex) {
          throw new RunManagementError("REPAIR_CONFLICT", "Another repair already reserved this chain step");
        }
      }
      const directory = managedRunDirectory(root, runId);
      if (existsSync(directory)) throw new RunManagementError("REPAIR_INCOMPLETE", "Repair directory exists without a committed journal; preserve it for diagnosis");
      const receiptPath = join(managedRunDirectory(root, request.fromRun), "verification", request.taskId, "receipt.json");
      const receipt = readJson<VerificationReceipt>(receiptPath);
      const createdAt = nowIso();
      const link: RepairLink = {
        version: "1.0.0", project_id: config.project_id, root_run_id: rootRun, root_task_id: rootTask,
        parent_run_id: request.fromRun, failed_task_id: request.taskId, new_run_id: runId,
        request_id: request.requestId, request_hash: requestHash, parent_receipt_hash: receipt.receipt_hash,
        parent_receipt_path: relative(root, receiptPath).replaceAll("\\", "/"),
        task_contract_hash: taskContractHash(tasks), repair_index: repairIndex, repair_limit: 2, created_at: createdAt,
      };
      const record: RepairJournal = { state: "PREPARING", link, link_hash: sha256(stableStringify(link)) };
      // Final journal replacement is the visibility boundary, not a cross-file ACID transaction.
      writeJsonAtomic(journalPath, record);
      writeJsonAtomic(join(directory, "repair-origin.json"), { link_hash: record.link_hash });
      const plan: ManagedSpawnPlan = {
        version: "1.0.0", run_id: runId, project_id: config.project_id, generated_at: createdAt,
        native_spawn_required: true, max_parallel: config.features.multi_agent.max_threads, max_depth: 1,
        assignments: [], blocked_tasks: [], instructions_for_main_agent: ["Use factoryctl plan for the first repair wave."],
      };
      const emptyRegistry: NativeAgentRegistry = {
        version: "1.0.0", run_id: runId, project_id: config.project_id, warning: "No host execution dispatched.", entries: [],
      };
      const graphHash = sha256(stableStringify(tasks));
      writeJsonAtomic(join(directory, "task-graph.json"), {
        version: "1.0.0", run_id: runId, generated_at: createdAt, tasks, graph_sha256: graphHash,
      });
      writeJsonAtomic(join(directory, "agent-registry.json"), emptyRegistry);
      writeJsonAtomic(join(directory, "spawn-plan.json"), plan);
      writeJsonAtomic(join(directory, "run.json"), {
        version: "1.0.0", run_id: runId, project_id: config.project_id, created_at: createdAt, status: "READY",
        config_sha256: sha256(stableStringify(config)), task_graph_sha256: graphHash, spawn_plan_sha256: sha256(stableStringify(plan)),
      });
      writeJsonAtomic(journalPath, { ...record, state: "COMMITTED" });
      return repairResult(link);
    }));
  });
}
