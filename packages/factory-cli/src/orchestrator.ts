import {
  existsSync,
  lstatSync,
  readdirSync,
  readFileSync,
  readlinkSync,
} from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { getAgentProfile, profileForTask } from "./agents.js";
import { ALL_AGENT_CAPABILITIES, skillIdsForTask } from "./capabilities.js";
import { factoryDirectory, loadConfig } from "./config.js";
import { reportedCommandOutcomes } from "./command-outcome.js";
import { managedAgentContent } from "./installer.js";
import {
  appendTrustedContextEvent,
  createContextPacket,
  eventVisibleToRole,
  initializeContextSpace,
  readAllContextEventsInternal,
  relativePacketPath,
  verifyContextLedger,
  verifyContextPacket,
} from "./context-space.js";
import { appendAssignmentKnowledgeContext } from "./memory-packet.js";
import { assertRepairRunCommitted } from "./repair-store.js";
import type {
  AgentProfile,
  ContextEvent,
  ContextPacket,
  FactoryTask,
  SpawnPlan,
  SpawnPlanEntry,
} from "./types.js";
import {
  assertWithinRoot,
  ensureDirectory,
  newId,
  nowIso,
  readJson,
  sha256,
  stableStringify,
  withFileLock,
  writeJsonAtomic,
} from "./util.js";

export type DispatchAction = "spawn" | "followup";

export interface ManagedSpawnPlanEntry extends SpawnPlanEntry {
  action: DispatchAction;
  instance_key: string;
  logical_display_name: string;
  logical_icon: string;
  reuse_native_agent_id?: string;
}

export interface ManagedSpawnPlan extends Omit<SpawnPlan, "assignments"> {
  assignments: ManagedSpawnPlanEntry[];
  native_spawn_required: true;
}

export type NativeAgentLifecycle =
  | "planned"
  | "spawned"
  | "running"
  | "idle"
  | "completed"
  | "failed"
  | "closed";

export interface NativeAgentRegistryEntry {
  instance_key: string;
  profile_id: string;
  profile_kind: "resident" | "temporary";
  codex_agent_name: string;
  logical_display_name: string;
  logical_icon: string;
  nickname_candidates: string[];
  native_agent_id: string | null;
  native_nickname: string | null;
  lifecycle: NativeAgentLifecycle;
  assignment_ids: string[];
  task_ids: string[];
  created_at: string;
  updated_at: string;
  native_receipts: Array<{
    assignment_id: string;
    tool_name: "spawn_agent" | "followup_task";
    recorded_at: string;
    receipt_sha256: string;
    receipt_path: string;
  }>;
  baselines?: Array<{
    assignment_id: string;
    path: string;
    sha256: string;
    wave_write_scopes: string[][];
  }>;
}

export interface NativeAgentRegistry {
  version: "1.0.0";
  run_id: string;
  project_id: string;
  warning: string;
  entries: NativeAgentRegistryEntry[];
}

export interface NativeDispatchReceiptInput {
  nativeAgentId: string;
  nativeNickname?: string;
  rawToolReceipt: unknown;
  toolName?: "spawn_agent" | "followup_task";
}

function receiptValuesForKeys(value: unknown, keys: Set<string>, depth = 0): string[] {
  if (depth > 4 || value === null || typeof value !== "object") return [];
  const values: string[] = [];
  for (const [key, item] of Object.entries(value as Record<string, unknown>)) {
    const normalizedKey = key.toLowerCase().replaceAll("-", "_");
    if (keys.has(normalizedKey) && (typeof item === "string" || typeof item === "number")) {
      values.push(String(item));
    }
    if (item !== null && typeof item === "object") {
      values.push(...receiptValuesForKeys(item, keys, depth + 1));
    }
  }
  return values;
}

function verifyNativeToolReceipt(
  rawReceipt: unknown,
  nativeAgentId: string,
  nativeNickname: string | undefined,
  expectedTool: "spawn_agent" | "followup_task",
): void {
  if (rawReceipt === null || typeof rawReceipt !== "object" || Array.isArray(rawReceipt)) {
    throw new Error("Native tool receipt must be a structured object");
  }
  const ids = receiptValuesForKeys(
    rawReceipt,
    new Set(["agent_id", "agentid", "native_agent_id", "thread_id", "threadid"]),
  );
  if (!ids.includes(nativeAgentId)) {
    throw new Error("Native agent id does not match the structured tool receipt");
  }
  if (nativeNickname?.trim()) {
    const nicknames = receiptValuesForKeys(
      rawReceipt,
      new Set(["nickname", "native_nickname", "display_name", "displayname"]),
    );
    if (!nicknames.includes(nativeNickname.trim())) {
      throw new Error("Native nickname was provided but is not present in the tool receipt");
    }
  }
  const toolNames = receiptValuesForKeys(rawReceipt, new Set(["tool_name", "toolname"]));
  if (toolNames.length !== 1 || toolNames[0] !== expectedTool) {
    throw new Error("Native tool receipt does not identify the expected tool exactly");
  }
  const statuses = receiptValuesForKeys(rawReceipt, new Set(["status", "state"]));
  const allowedStatuses = expectedTool === "spawn_agent"
    ? new Set(["spawned", "running", "accepted"])
    : new Set(["running", "accepted", "sent"]);
  if (statuses.length === 0 || !statuses.some((status) => allowedStatuses.has(status))) {
    throw new Error("Native tool receipt does not contain an accepted host status");
  }
}

export function readCurrentSpawnPlan(projectRoot: string, runId: string): ManagedSpawnPlan {
  assertRepairRunCommitted(projectRoot, runId);
  const directory = runDirectory(projectRoot, runId);
  const planPath = join(directory, "spawn-plan.json");
  const runPath = join(directory, "run.json");
  if (!existsSync(planPath) || !existsSync(runPath)) {
    throw new Error("Run plan metadata is missing");
  }
  const plan = readJson<ManagedSpawnPlan>(planPath);
  const run = readJson<{ run_id?: string; spawn_plan_sha256?: string }>(runPath);
  if (
    plan.run_id !== runId ||
    run.run_id !== runId ||
    run.spawn_plan_sha256 !== sha256(stableStringify(plan))
  ) {
    throw new Error("Spawn plan integrity verification failed");
  }
  return plan;
}

function runDirectory(projectRoot: string, runId: string): string {
  if (!/^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$/.test(runId)) {
    throw new Error("Invalid run id: " + runId);
  }
  return assertWithinRoot(projectRoot, join(factoryDirectory(projectRoot), "runs", runId));
}

function registryPath(projectRoot: string, runId: string): string {
  return join(runDirectory(projectRoot, runId), "agent-registry.json");
}

export interface MutableTaskGraphSnapshot {
  version: "1.0.0";
  run_id: string;
  generated_at: string;
  updated_at?: string;
  tasks: FactoryTask[];
  graph_sha256: string;
}

export function readTaskGraphSnapshot(
  projectRoot: string,
  runId: string,
): MutableTaskGraphSnapshot {
  assertRepairRunCommitted(projectRoot, runId);
  const path = join(runDirectory(projectRoot, runId), "task-graph.json");
  if (!existsSync(path)) throw new Error("Task graph not found for run: " + runId);
  const graph = readJson<MutableTaskGraphSnapshot>(path);
  if (graph.run_id !== runId) throw new Error("Task graph run_id mismatch");
  const actualHash = sha256(stableStringify(graph.tasks));
  if (graph.graph_sha256 !== actualHash) {
    throw new Error("Task graph hash mismatch; refusing unverified runtime state");
  }
  return graph;
}

export function setRunTaskStatus(
  projectRoot: string,
  runId: string,
  taskId: string,
  next: FactoryTask["status"],
): FactoryTask {
  const path = join(runDirectory(projectRoot, runId), "task-graph.json");
  return withFileLock(path + ".lock", () => {
    const graph = readTaskGraphSnapshot(projectRoot, runId);
    const task = graph.tasks.find((item) => item.task_id === taskId);
    if (!task) throw new Error("Unknown run task: " + taskId);
    const allowed: Record<FactoryTask["status"], FactoryTask["status"][]> = {
      pending: ["ready", "assigned", "blocked", "failed"],
      ready: ["assigned", "blocked", "failed"],
      assigned: ["in_progress", "blocked", "handoff", "failed"],
      in_progress: ["blocked", "handoff", "failed"],
      handoff: ["verified", "failed", "blocked"],
      verified: [],
      blocked: ["pending", "ready", "failed"],
      failed: [],
    };
    if (task.status !== next && !allowed[task.status].includes(next)) {
      throw new Error("Invalid task status transition: " + task.status + " -> " + next);
    }
    if (task.status === next) return task;
    task.status = next;
    graph.updated_at = nowIso();
    graph.graph_sha256 = sha256(stableStringify(graph.tasks));
    writeJsonAtomic(path, graph);
    return task;
  });
}

export function validateTaskGraph(tasks: FactoryTask[]): void {
  if (!Array.isArray(tasks) || tasks.length === 0) {
    throw new Error("Task graph must contain at least one task");
  }
  const ids = new Set<string>();
  const allowedStatuses = new Set<FactoryTask["status"]>([
    "pending",
    "ready",
    "assigned",
    "in_progress",
    "handoff",
    "verified",
    "blocked",
    "failed",
  ]);
  for (const task of tasks) {
    if (!task || typeof task !== "object") throw new Error("Each task must be an object");
    if (typeof task.task_id !== "string" || !/^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$/.test(task.task_id)) {
      throw new Error("Invalid task_id: " + String(task.task_id));
    }
    if (ids.has(task.task_id)) throw new Error("Duplicate task_id: " + task.task_id);
    ids.add(task.task_id);
    if ([task.title, task.description, task.role].some((value) => typeof value !== "string" || !value.trim())) {
      throw new Error("Task " + task.task_id + " requires title, description, and role");
    }
    if (!allowedStatuses.has(task.status)) {
      throw new Error("Task " + task.task_id + " has invalid status: " + String(task.status));
    }
    if (!Array.isArray(task.dependencies) || !Array.isArray(task.write_scope)) {
      throw new Error("Task " + task.task_id + " has invalid dependency or scope arrays");
    }
    if (!Array.isArray(task.acceptance_methods) || task.acceptance_methods.length === 0) {
      throw new Error("Task " + task.task_id + " requires at least one acceptance method");
    }
    if (!Array.isArray(task.required_artifacts)) {
      throw new Error("Task " + task.task_id + " has invalid required_artifacts");
    }
    for (const field of ["dependencies", "write_scope", "acceptance_methods", "required_artifacts"] as const) {
      if (task[field].some((value) => typeof value !== "string" || !value.trim())) {
        throw new Error("Task " + task.task_id + " requires nonempty strings in " + field);
      }
    }
    if (
      task.required_capabilities !== undefined &&
      (!Array.isArray(task.required_capabilities) ||
        task.required_capabilities.some((capability) => !ALL_AGENT_CAPABILITIES.has(capability)))
    ) {
      throw new Error("Task " + task.task_id + " has unknown required_capabilities");
    }
    profileForTask(task);
    for (const scope of task.write_scope) normalizedScope(scope);
  }
  for (const task of tasks) {
    for (const dependency of task.dependencies) {
      if (!ids.has(dependency)) {
        throw new Error("Task " + task.task_id + " has missing dependency " + dependency);
      }
      if (dependency === task.task_id) {
        throw new Error("Task " + task.task_id + " cannot depend on itself");
      }
    }
  }

  const byId = new Map(tasks.map((task) => [task.task_id, task]));
  const visiting = new Set<string>();
  const visited = new Set<string>();
  const visit = (taskId: string, chain: string[]): void => {
    if (visiting.has(taskId)) {
      throw new Error("Task graph cycle: " + [...chain, taskId].join(" -> "));
    }
    if (visited.has(taskId)) return;
    visiting.add(taskId);
    for (const dependency of byId.get(taskId)?.dependencies ?? []) {
      visit(dependency, [...chain, taskId]);
    }
    visiting.delete(taskId);
    visited.add(taskId);
  };
  for (const task of tasks) visit(task.task_id, []);
}

export function addAutomaticVerificationTasks(tasks: FactoryTask[]): FactoryTask[] {
  const result = tasks.map((task) => ({
    ...task,
    dependencies: [...task.dependencies],
    write_scope: [...task.write_scope],
    acceptance_methods: [...task.acceptance_methods],
    required_artifacts: [...task.required_artifacts],
    ...(task.required_capabilities
      ? { required_capabilities: [...task.required_capabilities] }
      : {}),
  }));
  const existingIds = new Set(result.map((task) => task.task_id));
  for (const task of tasks) {
    const profile = profileForTask(task);
    if (profile.profile_id === "factory_verifier") continue;
    const covered = result.some(
      (candidate) =>
        getAgentProfile("factory_verifier").profile_id ===
          profileForTask(candidate).profile_id &&
        candidate.dependencies.includes(task.task_id),
    );
    if (covered) continue;
    const baseId = "verify-" + task.task_id;
    let verifierTaskId = baseId.slice(0, 120);
    let suffix = 2;
    while (existingIds.has(verifierTaskId)) {
      verifierTaskId = (baseId.slice(0, 112) + "-" + suffix).slice(0, 120);
      suffix += 1;
    }
    existingIds.add(verifierTaskId);
    result.push({
      task_id: verifierTaskId,
      title: "Independently verify " + task.title,
      description:
        "Re-run the target task acceptance methods, inspect required physical artifacts and hashes, and issue a skeptical PASS/FAIL proposal for " +
        task.task_id +
        ". Read that target's full description in the authoritative task graph, including any confirmed behavior examples. " +
        "Check that scoped tests and physical behavior cover those examples; a recorded user choice is not PASS evidence. " +
        "Do not repair implementation defects.",
      role: "verifier",
      profile_id: "factory_verifier",
      required_capabilities: [
        "independent-verification",
        ...(task.required_capabilities ?? []).filter((capability) =>
          [
            "frontend", "backend", "database", "auth-security", "mobile",
            "testing", "e2e-testing", "smoke-testing", "negative-testing",
          ].includes(capability),
        ),
      ],
      status: "pending",
      dependencies: [task.task_id],
      write_scope: [],
      acceptance_methods: ["independent-review:" + task.task_id],
      required_artifacts: [],
    });
  }
  return result;
}

function validateInitialTaskStates(tasks: FactoryTask[]): void {
  const unsafe = tasks.filter((task) => !["pending", "ready"].includes(task.status));
  if (unsafe.length > 0) {
    throw new Error(
      "A new run accepts only pending/ready task states; runtime states require verified run receipts: " +
        unsafe.map((task) => task.task_id + "=" + task.status).join(", "),
    );
  }
}

export function validateNewTasks(tasks: FactoryTask[]) {
  validateTaskGraph(tasks);
  validateInitialTaskStates(tasks);
  const graph = addAutomaticVerificationTasks(tasks);
  validateTaskGraph(graph);
  const summaries = graph.map((task) => ({
    task_id: task.task_id, title: task.title, profile_id: profileForTask(task).profile_id,
    dependencies: [...task.dependencies], write_scope: [...task.write_scope],
    acceptance_methods: [...task.acceptance_methods], required_artifacts: [...task.required_artifacts],
  }));
  for (const task of summaries.filter((item) => item.profile_id === "factory_verifier")) {
    if (task.dependencies.length !== 1 || task.write_scope.length ||
        summaries.find((item) => item.task_id === task.dependencies[0])?.profile_id === "factory_verifier") {
      throw new Error("Verifier " + task.task_id + " must be read-only and depend on exactly one worker");
    }
  }
  return { version: "1.0.0" as const, status: "VALID" as const,
    worker_count: summaries.filter((task) => task.profile_id !== "factory_verifier").length,
    verifier_count: summaries.filter((task) => task.profile_id === "factory_verifier").length,
    ready_task_ids: summaries.filter((task) => !task.dependencies.length).map((task) => task.task_id),
    tasks: summaries,
    limitations: ["Task structure only; no dispatch, acceptance commands, host readiness or current artifacts are checked.",
      "The scheduler still enforces thread capacity, role policy and concurrent write scopes."],
  };
}

export function verifyPersistedRuntimeClaims(
  projectRoot: string,
  runId: string,
  tasks: FactoryTask[],
  registry: NativeAgentRegistry,
  providedContextEvents?: ContextEvent[],
): void {
  const externalContextEnabled = loadConfig(projectRoot).features.external_context.enabled;
  const contextEvents = externalContextEnabled
    ? providedContextEvents ?? readAllContextEventsInternal(projectRoot)
    : [];
  const assignmentForTask = (taskId: string): { assignmentId: string; entry: NativeAgentRegistryEntry } | undefined => {
    for (const entry of registry.entries) {
      const index = entry.task_ids.indexOf(taskId);
      if (index >= 0) return { assignmentId: entry.assignment_ids[index], entry };
    }
    return undefined;
  };
  const assignmentForId = (
    assignmentId: string,
  ): { assignmentId: string; taskId: string; entry: NativeAgentRegistryEntry } | undefined => {
    const matches: Array<{
      assignmentId: string;
      taskId: string;
      entry: NativeAgentRegistryEntry;
    }> = [];
    for (const entry of registry.entries) {
      for (let index = 0; index < entry.assignment_ids.length; index += 1) {
        if (entry.assignment_ids[index] === assignmentId) {
          const taskId = entry.task_ids[index];
          if (!taskId) throw new Error("Registry assignment has no task binding: " + assignmentId);
          matches.push({ assignmentId, taskId, entry });
        }
      }
    }
    if (matches.length > 1) {
      throw new Error("Registry assignment is bound more than once: " + assignmentId);
    }
    return matches[0];
  };
  const verifyNativeAssignment = (binding: {
    assignmentId: string;
    taskId: string;
    entry: NativeAgentRegistryEntry;
  }): string => {
    const nativeId = binding.entry.native_agent_id;
    if (!nativeId) {
      throw new Error("Assignment has no native Agent ID: " + binding.assignmentId);
    }
    const metadata = binding.entry.native_receipts.find(
      (receipt) => receipt.assignment_id === binding.assignmentId,
    );
    if (!metadata) {
      throw new Error("Assignment has no native dispatch receipt: " + binding.assignmentId);
    }
    const receiptPath = assertWithinRoot(projectRoot, resolve(projectRoot, metadata.receipt_path));
    if (!existsSync(receiptPath)) {
      throw new Error("Native dispatch receipt file is missing: " + binding.assignmentId);
    }
    const nativeReceipt = readJson<Record<string, unknown>>(receiptPath);
    const actualHash = sha256(stableStringify(nativeReceipt));
    if (
      actualHash !== metadata.receipt_sha256 ||
      nativeReceipt.run_id !== runId ||
      nativeReceipt.assignment_id !== binding.assignmentId ||
      nativeReceipt.native_agent_id !== nativeId ||
      nativeReceipt.tool_name !== metadata.tool_name
    ) {
      throw new Error("Native dispatch receipt binding is invalid: " + binding.assignmentId);
    }
    if (
      externalContextEnabled &&
      !contextEvents.some(
        (event) =>
          event.kind === "agent_event" &&
          event.payload.assignment_id === binding.assignmentId &&
          event.payload.native_agent_id === nativeId &&
          event.payload.tool_name === metadata.tool_name &&
          event.payload.receipt_sha256 === actualHash,
      )
    ) {
      throw new Error(
        "Native dispatch receipt is not bound into the context ledger: " + binding.assignmentId,
      );
    }
    return nativeId;
  };
  const readBoundHandoff = (binding: {
    assignmentId: string;
    taskId: string;
    entry: NativeAgentRegistryEntry;
  }): { handoff: Record<string, unknown>; hash: string } => {
    const nativeId = verifyNativeAssignment(binding);
    const path = join(
      runDirectory(projectRoot, runId),
      "handoffs",
      binding.assignmentId + ".json",
    );
    if (!existsSync(path)) {
      throw new Error("Assignment has no handoff receipt: " + binding.assignmentId);
    }
    const handoff = readJson<Record<string, unknown>>(path);
    const recordedHash = String(handoff.handoff_hash ?? "");
    const { handoff_hash: _ignored, ...unsigned } = handoff;
    if (
      recordedHash !== sha256(stableStringify(unsigned)) ||
      handoff.run_id !== runId ||
      handoff.assignment_id !== binding.assignmentId ||
      handoff.task_id !== binding.taskId ||
      handoff.native_agent_id !== nativeId
    ) {
      throw new Error("Handoff receipt binding is invalid: " + binding.assignmentId);
    }
    if (
      externalContextEnabled &&
      !contextEvents.some(
        (event) =>
          event.kind === "evidence" &&
          event.payload.task_id === binding.taskId &&
          event.payload.assignment_id === binding.assignmentId &&
          event.payload.handoff_hash === recordedHash &&
          event.payload.verification_state === "RECORDED_UNVERIFIED",
      )
    ) {
      throw new Error("Handoff receipt is not bound into the context ledger: " + binding.taskId);
    }
    return { handoff, hash: recordedHash };
  };
  for (const task of tasks) {
    const assignment = assignmentForTask(task.task_id);
    if (["assigned", "in_progress", "handoff", "verified", "failed"].includes(task.status) && !assignment) {
      throw new Error("Runtime task state has no registered assignment: " + task.task_id);
    }
    if (task.status === "in_progress" && assignment) {
      const binding = assignmentForId(assignment.assignmentId);
      if (!binding) throw new Error("In-progress task assignment is missing: " + task.task_id);
      verifyNativeAssignment(binding);
    }
    if (task.status === "handoff") {
      const binding = assignment ? assignmentForId(assignment.assignmentId) : undefined;
      if (!binding) throw new Error("Handoff state assignment is missing: " + task.task_id);
      readBoundHandoff(binding);
    }
    if (task.status === "verified" || task.status === "failed") {
      const isVerifierTask = profileForTask(task).profile_id === "factory_verifier";
      const receiptTaskId = isVerifierTask ? task.dependencies[0] : task.task_id;
      if (!receiptTaskId) {
        throw new Error("Verified verifier task has no target dependency: " + task.task_id);
      }
      const path = join(
        runDirectory(projectRoot, runId),
        "verification",
        receiptTaskId,
        "receipt.json",
      );
      if (!existsSync(path)) throw new Error("Verified task has no verification receipt: " + task.task_id);
      const receipt = readJson<Record<string, unknown>>(path);
      const recordedHash = String(receipt.receipt_hash ?? "");
      const { receipt_hash: _ignored, ...unsigned } = receipt;
      const workerAssignmentId = String(receipt.worker_assignment_id ?? "");
      const verifierAssignmentId = String(receipt.verifier_assignment_id ?? "");
      const workerBinding = assignmentForId(workerAssignmentId);
      const verifierBinding = assignmentForId(verifierAssignmentId);
      if (!workerBinding || !verifierBinding) {
        throw new Error("Verification receipt references an unknown assignment: " + task.task_id);
      }
      const verifierTask = tasks.find((candidate) => candidate.task_id === verifierBinding.taskId);
      const workerTask = tasks.find((candidate) => candidate.task_id === receiptTaskId);
      if (
        workerBinding.taskId !== receiptTaskId ||
        verifierBinding.entry.profile_id !== "factory_verifier" ||
        !verifierTask?.dependencies.includes(receiptTaskId) ||
        verifierTask.status !== "verified" ||
        workerTask?.status !== (receipt.verdict === "FAIL" ? "failed" : "verified")
      ) {
        throw new Error("Verification receipt assignment roles are invalid: " + task.task_id);
      }
      const workerNativeId = verifyNativeAssignment(workerBinding);
      const verifierNativeId = verifyNativeAssignment(verifierBinding);
      const workerHandoff = readBoundHandoff(workerBinding);
      const verifierHandoff = readBoundHandoff(verifierBinding);
      const verifierReport = verifierHandoff.handoff.report;
      const verifierProposal =
        verifierReport !== null && typeof verifierReport === "object"
          ? (verifierReport as Record<string, unknown>).proposed_verdict
          : undefined;
      const reportedCommands = (handoff: Record<string, unknown>): Array<Record<string, unknown>> => {
        const report = handoff.report;
        if (report === null || typeof report !== "object") {
          throw new Error("Bound handoff report is invalid: " + task.task_id);
        }
        const commands = (report as Record<string, unknown>).commands;
        if (!Array.isArray(commands) || commands.some((command) => command === null || typeof command !== "object")) {
          throw new Error("Bound handoff commands are invalid: " + task.task_id);
        }
        return commands as Array<Record<string, unknown>>;
      };
      const workerCommands = reportedCommands(workerHandoff.handoff);
      const verifierCommands = reportedCommands(verifierHandoff.handoff);
      const artifactChecks = Array.isArray(receipt.artifact_checks)
        ? receipt.artifact_checks as Array<Record<string, unknown>>
        : [];
      const acceptanceChecks = Array.isArray(receipt.acceptance_checks)
        ? receipt.acceptance_checks as Array<Record<string, unknown>>
        : [];
      const expectedFailureReasons: string[] = [];
      const commandOutcomes = {
        worker: reportedCommandOutcomes(workerCommands, workerTask.acceptance_methods, receipt.command_policy),
        verifier: reportedCommandOutcomes(verifierCommands, workerTask.acceptance_methods, receipt.command_policy),
      };
      if (commandOutcomes.worker.includes("FAILURE")) {
        expectedFailureReasons.push("Worker reported at least one failing command");
      }
      if (commandOutcomes.verifier.includes("FAILURE")) {
        expectedFailureReasons.push("Independent verifier reported at least one failing command");
      }
      if (artifactChecks.some((check) => check.status !== "PASS")) {
        expectedFailureReasons.push("One or more physical artifact checks failed");
      }
      if (
        acceptanceChecks.length === 0 ||
        acceptanceChecks.some((check) => check.status !== "PASS")
      ) {
        expectedFailureReasons.push("One or more independently executed acceptance checks failed");
      }
      if (verifierProposal !== "PASS") {
        expectedFailureReasons.push("Independent native verifier did not propose PASS");
      }
      const expectedVerdict = expectedFailureReasons.length === 0 ? "PASS" : "FAIL";
      const observedArtifacts = workerHandoff.handoff.observed_artifacts;
      if (!Array.isArray(observedArtifacts) || observedArtifacts.some((artifact) =>
        !artifact || typeof artifact.path !== "string")) {
        throw new Error("Bound handoff artifact manifest is invalid: " + task.task_id);
      }
      const expectedArtifactMethods = [
        ...observedArtifacts.map((artifact) => "artifact:" + artifact.path),
        ...workerTask.required_artifacts.filter((path) => !observedArtifacts.some((artifact) => artifact.path === path))
          .map((path) => "required-artifact:" + path),
      ];
      const receiptSemanticsMatch =
        (receipt.command_policy === undefined ? receipt.command_outcomes === undefined :
          stableStringify(receipt.command_outcomes) === stableStringify(commandOutcomes)) &&
        Array.isArray(receipt.artifact_checks) &&
        stableStringify(artifactChecks.map((check) => check.method)) === stableStringify(expectedArtifactMethods) &&
        artifactChecks.every((check) => ["PASS", "FAIL"].includes(String(check.status))) &&
        Array.isArray(receipt.acceptance_checks) &&
        stableStringify(acceptanceChecks.map((check) => check.method)) === stableStringify(workerTask.acceptance_methods) &&
        acceptanceChecks.every((check) => ["PASS", "FAIL"].includes(String(check.status))) &&
        stableStringify(receipt.failure_reasons) === stableStringify(expectedFailureReasons) &&
        receipt.verdict === expectedVerdict;
      const receiptBindingsMatch =
        receipt.worker_assignment_id === workerBinding.assignmentId &&
        receipt.worker_native_agent_id === workerNativeId &&
        receipt.verifier_assignment_id === verifierBinding.assignmentId &&
        receipt.verifier_native_agent_id === verifierNativeId &&
        workerNativeId !== verifierNativeId &&
        receipt.source_handoff_hash === workerHandoff.hash &&
        receipt.verifier_handoff_hash === verifierHandoff.hash &&
        verifierProposal === receipt.independent_verifier_proposal &&
        ["PASS", "FAIL", "BLOCKED"].includes(String(verifierProposal));
      if (
        receipt.run_id !== runId ||
        receipt.task_id !== receiptTaskId ||
        (!isVerifierTask && receipt.verdict !== (task.status === "failed" ? "FAIL" : "PASS")) ||
        !["PASS", "FAIL"].includes(String(receipt.verdict)) ||
        (!isVerifierTask && receipt.worker_assignment_id !== assignment?.assignmentId) ||
        (isVerifierTask && receipt.verifier_assignment_id !== assignment?.assignmentId) ||
        !receiptBindingsMatch ||
        !receiptSemanticsMatch ||
        recordedHash !== sha256(stableStringify(unsigned))
      ) {
        throw new Error("Verification receipt is invalid: " + task.task_id);
      }
      if (
        externalContextEnabled &&
        !contextEvents.some(
          (event) =>
            ["evidence", "rejected_claim"].includes(event.kind) &&
            event.payload.task_id === receiptTaskId &&
            event.payload.receipt_hash === recordedHash &&
            event.payload.verdict === receipt.verdict,
        )
      ) {
        throw new Error("Verification receipt is not bound into the context ledger: " + task.task_id);
      }
    }
  }
}

function normalizedScope(scope: string): string {
  const raw = scope.trim().replaceAll("\\", "/");
  if (!raw) throw new Error("Write scope cannot be empty");
  if (raw.startsWith("/") || /^[A-Za-z]:\//.test(raw) || raw.startsWith("//")) {
    throw new Error("Write scope must be project-relative: " + scope);
  }
  const segments: string[] = [];
  for (const segment of raw.split("/")) {
    if (!segment || segment === ".") continue;
    if (segment === "..") throw new Error("Write scope cannot escape the project: " + scope);
    segments.push(segment);
  }
  if (segments.length === 0) return ".";
  return segments.join("/").toLowerCase();
}

interface FilesystemManifestEntry {
  path: string;
  kind: "file" | "symlink";
  sha256: string;
}

interface AssignmentBaseline {
  version: "1.0.0";
  run_id: string;
  assignment_id: string;
  captured_at: string;
  task_write_scope: string[];
  wave_write_scopes: string[][];
  excluded_directories: string[];
  entries: FilesystemManifestEntry[];
  manifest_sha256: string;
}

const BASELINE_EXCLUDED_DIRECTORIES = new Set([
  ".git",
  ".codex-factory",
  "node_modules",
  ".next",
  ".cache",
  ".turbo",
  "coverage",
]);

function filesystemManifest(projectRoot: string): FilesystemManifestEntry[] {
  const root = resolve(projectRoot);
  const entries: FilesystemManifestEntry[] = [];
  const walk = (directory: string): void => {
    for (const name of readdirSync(directory).sort((left, right) => left.localeCompare(right))) {
      if (BASELINE_EXCLUDED_DIRECTORIES.has(name)) continue;
      const absolute = join(directory, name);
      const relativePath = relative(root, absolute).replaceAll("\\", "/");
      const stat = lstatSync(absolute);
      if (stat.isSymbolicLink()) {
        entries.push({
          path: relativePath,
          kind: "symlink",
          sha256: sha256(readlinkSync(absolute)),
        });
      } else if (stat.isDirectory()) {
        walk(absolute);
      } else if (stat.isFile()) {
        entries.push({ path: relativePath, kind: "file", sha256: sha256(readFileSync(absolute)) });
      }
    }
  };
  walk(root);
  return entries;
}

function writeAssignmentBaseline(
  projectRoot: string,
  runId: string,
  assignmentId: string,
  taskWriteScope: string[],
  waveWriteScopes: string[][],
  entries: FilesystemManifestEntry[],
): { path: string; sha256: string } {
  const unsigned = {
    version: "1.0.0" as const,
    run_id: runId,
    assignment_id: assignmentId,
    captured_at: nowIso(),
    task_write_scope: taskWriteScope,
    wave_write_scopes: waveWriteScopes,
    excluded_directories: [...BASELINE_EXCLUDED_DIRECTORIES].sort(),
    entries,
  };
  const baseline: AssignmentBaseline = {
    ...unsigned,
    manifest_sha256: sha256(stableStringify(unsigned)),
  };
  const path = join(runDirectory(projectRoot, runId), "baselines", assignmentId + ".json");
  writeJsonAtomic(path, baseline);
  return {
    path: relative(resolve(projectRoot), path).replaceAll("\\", "/"),
    sha256: baseline.manifest_sha256,
  };
}

function pathMatchesAnyScope(path: string, scopes: string[]): boolean {
  const normalizedPath = normalizedScope(path);
  return scopes.some((scope) => {
    const normalized = normalizedScope(scope);
    return (
      ["*", "."].includes(normalized) ||
      normalizedPath === normalized ||
      normalizedPath.startsWith(normalized + "/")
    );
  });
}

export function verifyAssignmentPhysicalDiff(
  projectRoot: string,
  runId: string,
  assignmentId: string,
  reportedChangedPaths: string[],
): string[] {
  const registry = readAgentRegistry(projectRoot, runId);
  const entry = registry.entries.find((candidate) =>
    candidate.assignment_ids.includes(assignmentId),
  );
  const baselineRecord = entry?.baselines?.find(
    (candidate) => candidate.assignment_id === assignmentId,
  );
  if (!baselineRecord) {
    throw new Error("Assignment has no physical filesystem baseline: " + assignmentId);
  }
  const baselinePath = assertWithinRoot(projectRoot, resolve(projectRoot, baselineRecord.path));
  const baseline = readJson<AssignmentBaseline>(baselinePath);
  const { manifest_sha256: recordedHash, ...unsigned } = baseline;
  if (
    recordedHash !== baselineRecord.sha256 ||
    recordedHash !== sha256(stableStringify(unsigned)) ||
    baseline.run_id !== runId ||
    baseline.assignment_id !== assignmentId
  ) {
    throw new Error("Assignment filesystem baseline failed integrity verification");
  }
  const before = new Map(
    baseline.entries.map((item) => [item.path, item.kind + ":" + item.sha256]),
  );
  const after = new Map(
    filesystemManifest(projectRoot).map((item) => [item.path, item.kind + ":" + item.sha256]),
  );
  const allPaths = new Set([...before.keys(), ...after.keys()]);
  const changed = [...allPaths]
    .filter((path) => before.get(path) !== after.get(path))
    .sort((left, right) => left.localeCompare(right));
  const waveScopes = baseline.wave_write_scopes.flat();
  const outsideWave = changed.filter((path) => !pathMatchesAnyScope(path, waveScopes));
  if (outsideWave.length > 0) {
    throw new Error(
      "Physical diff contains out-of-scope paths: " + outsideWave.join(", "),
    );
  }
  const taskChanged = changed.filter((path) =>
    pathMatchesAnyScope(path, baseline.task_write_scope),
  );
  const normalizedReported = reportedChangedPaths.map(normalizedScope).sort();
  const unreported = taskChanged.filter(
    (path) => !normalizedReported.includes(normalizedScope(path)),
  );
  const falselyReported = normalizedReported.filter(
    (path) => !taskChanged.some((changedPath) => normalizedScope(changedPath) === path),
  );
  if (unreported.length > 0 || falselyReported.length > 0) {
    throw new Error(
      [
        unreported.length > 0 ? "unreported physical changes: " + unreported.join(", ") : "",
        falselyReported.length > 0
          ? "reported paths absent from physical diff: " + falselyReported.join(", ")
          : "",
      ]
        .filter(Boolean)
        .join("; "),
    );
  }
  return taskChanged;
}

function scopeItemsConflict(left: string, right: string): boolean {
  const a = normalizedScope(left);
  const b = normalizedScope(right);
  if (["*", ".", "/"].includes(a) || ["*", ".", "/"].includes(b)) return true;
  return a === b || a.startsWith(b + "/") || b.startsWith(a + "/");
}

export function writeScopesConflict(left: string[], right: string[]): boolean {
  return left.some((a) => right.some((b) => scopeItemsConflict(a, b)));
}

function instanceKey(profile: AgentProfile, assignmentId: string): string {
  return profile.kind === "resident"
    ? "resident:" + profile.profile_id + ":" + assignmentId
    : "temporary:" + assignmentId;
}

function emptyRegistry(runId: string, projectId: string): NativeAgentRegistry {
  return {
    version: "1.0.0",
    run_id: runId,
    project_id: projectId,
    warning:
      "A registry record is provenance, not independent proof. A native ID must come from the host tool receipt, and task PASS requires a separate verifier receipt.",
    entries: [],
  };
}

export function readAgentRegistry(projectRoot: string, runId: string): NativeAgentRegistry {
  assertRepairRunCommitted(projectRoot, runId);
  const config = loadConfig(projectRoot);
  const path = registryPath(projectRoot, runId);
  return existsSync(path) ? readJson<NativeAgentRegistry>(path) : emptyRegistry(runId, config.project_id);
}

function createBoundedTaskCapsule(
  projectRoot: string,
  runId: string,
  assignmentId: string,
  task: FactoryTask,
  profile: AgentProfile,
): string {
  const config = loadConfig(projectRoot);
  const unsigned = {
    version: "1.0.0",
    project_id: config.project_id,
    run_id: runId,
    assignment_id: assignmentId,
    generated_at: nowIso(),
    target_role: profile.role,
    task,
    authority: "bounded_task_contract_and_physical_repository_only",
    frontend_summary_trusted: false,
    forbidden_assumptions: [
      "Agent self-report proves completion",
      "A claimed artifact exists without a physical file and hash",
      "Historical PASS applies to the current source tree",
    ],
  };
  const capsule = { ...unsigned, capsule_hash: sha256(stableStringify(unsigned)) };
  const path = join(runDirectory(projectRoot, runId), "task-capsules", assignmentId + ".json");
  writeJsonAtomic(path, capsule);
  return relative(resolve(projectRoot), path).replaceAll("\\", "/");
}

export function verifyAssignmentInput(
  projectRoot: string,
  file: string,
  expected: { runId: string; targetRole: string; assignmentId: string },
): { valid: boolean; stale: boolean; kind: "task_capsule" | "context_packet" | "unknown"; issues: string[] } {
  let kind: "task_capsule" | "context_packet" | "unknown" = "unknown";
  try {
    const config = loadConfig(projectRoot);
    const registry = readAgentRegistry(projectRoot, expected.runId);
    const entries = registry.entries.filter((entry) => entry.assignment_ids.includes(expected.assignmentId));
    if (registry.project_id !== config.project_id || registry.run_id !== expected.runId || entries.length !== 1) {
      throw new Error("Assignment is not uniquely registered in this project/run");
    }
    const entry = entries[0];
    if (getAgentProfile(entry.profile_id).role !== expected.targetRole) {
      throw new Error("Assignment target_role mismatch");
    }
    const path = assertWithinRoot(projectRoot, resolve(projectRoot, file));
    const input = readJson<Record<string, unknown>>(path);
    if (!input || typeof input !== "object" || Array.isArray(input)) {
      throw new Error("Assignment input must be a JSON object");
    }
    const capsule = Object.hasOwn(input, "capsule_hash");
    const packet = Object.hasOwn(input, "packet_hash");
    if (capsule === packet) throw new Error("Unknown or ambiguous assignment input format");
    if (packet) {
      kind = "context_packet";
      return { ...verifyContextPacket(projectRoot, input as unknown as ContextPacket, expected), kind };
    }
    kind = "task_capsule";
    const issues: string[] = [];
    const { capsule_hash, ...unsigned } = input;
    if (capsule_hash !== sha256(stableStringify(unsigned))) issues.push("Capsule hash mismatch");
    if (input.version !== "1.0.0") issues.push("Unsupported capsule version");
    if (input.project_id !== config.project_id) issues.push("Capsule project_id mismatch");
    if (input.run_id !== expected.runId) issues.push("Capsule run_id mismatch");
    if (input.assignment_id !== expected.assignmentId) issues.push("Capsule assignment_id mismatch");
    if (input.target_role !== expected.targetRole) issues.push("Capsule target_role mismatch");
    const capsulePath = resolve(runDirectory(projectRoot, expected.runId), "task-capsules", expected.assignmentId + ".json");
    if (path !== capsulePath) issues.push("Capsule is not at the registered assignment location");
    if (input.authority !== "bounded_task_contract_and_physical_repository_only" || input.frontend_summary_trusted !== false) {
      issues.push("Capsule authority boundary mismatch");
    }
    const taskId = entry.task_ids[entry.assignment_ids.indexOf(expected.assignmentId)];
    const task = readTaskGraphSnapshot(projectRoot, expected.runId).tasks.find((item) => item.task_id === taskId);
    if (!task || !input.task || typeof input.task !== "object" || Array.isArray(input.task)) {
      issues.push("Capsule task contract is missing");
    } else {
      // Dispatch advances status; the bounded contract must remain unchanged.
      const { status: storedStatus, ...contract } = task;
      const { status: capsuleStatus, ...capsuleContract } = input.task as Record<string, unknown>;
      if (stableStringify(contract) !== stableStringify(capsuleContract)) {
        issues.push("Capsule task contract does not match the persisted task graph");
      }
    }
    return { valid: issues.length === 0, stale: false, kind, issues };
  } catch (error) {
    return { valid: false, stale: false, kind, issues: [error instanceof Error ? error.message : String(error)] };
  }
}

function createAssignmentPacket(
  projectRoot: string,
  runId: string,
  assignmentId: string,
  task: FactoryTask,
  profile: AgentProfile,
): string {
  const config = loadConfig(projectRoot);
  if (!config.features.external_context.enabled) {
    return createBoundedTaskCapsule(projectRoot, runId, assignmentId, task, profile);
  }

  const taskContract = {
    run_id: runId,
    assignment_id: assignmentId,
    task_id: task.task_id,
    title: task.title,
    description: task.description,
    role: task.role,
    dependencies: task.dependencies,
    write_scope: task.write_scope,
    acceptance_methods: task.acceptance_methods,
    required_artifacts: task.required_artifacts,
    state: "planned_for_native_dispatch",
    visible_to_roles: [profile.role, "main_controller", "verifier", "drift_auditor"],
  };
  const taskEvent = appendTrustedContextEvent(
    projectRoot,
    "task_state",
    "main_controller",
    taskContract,
    {
      basis: "trusted_internal",
      authority: "factory_control_plane",
      source: {
        kind: "control_plane_receipt",
        reference:
          "factory://run/" + runId + "/assignment/" + assignmentId + "/task-contract",
        sha256: sha256(stableStringify({
          task,
          profile_id: profile.profile_id,
          run_id: runId,
          assignment_id: assignmentId,
        })),
      },
    },
  );
  const knowledgeEvent = appendAssignmentKnowledgeContext(
    projectRoot,
    runId,
    assignmentId,
    task,
    profile,
  );
  const contextualIds = readAllContextEventsInternal(projectRoot)
    .filter(
      (event) =>
        eventVisibleToRole(event, profile.role) &&
        (event.payload.run_id === undefined || event.payload.run_id === runId) &&
        (["requirement", "decision", "risk", "rejected_claim", "frontend_summary"].includes(
          event.kind,
        ) ||
          event.event_id === taskEvent.event_id ||
          (event.payload.run_id === runId && typeof event.payload.task_id === "string" &&
            task.dependencies.includes(event.payload.task_id))),
    )
    .slice(-78)
    .map((event) => event.event_id);
  if (knowledgeEvent && !contextualIds.includes(knowledgeEvent.event_id)) {
    contextualIds.push(knowledgeEvent.event_id);
  }
  if (!contextualIds.includes(taskEvent.event_id)) contextualIds.push(taskEvent.event_id);
  const packet = createContextPacket(projectRoot, runId, profile.role, {
    sourceEventIds: contextualIds,
    maxEvents: 80,
  });
  const packetVerification = verifyContextPacket(projectRoot, packet.packet, {
    runId,
    targetRole: profile.role,
    assignmentId,
  });
  if (!packetVerification.valid) {
    throw new Error(
      "Generated Context Packet failed verification: " +
        packetVerification.issues.join("; "),
    );
  }
  return relativePacketPath(projectRoot, packet.path);
}

function assignmentPrompt(
  projectRoot: string,
  runId: string,
  assignmentId: string,
  task: FactoryTask,
  profile: AgentProfile,
  packetPath: string,
  registry: NativeAgentRegistry,
): string {
  const rolePath = ".codex/agents/" + profile.codex_agent_name + ".toml";
  const roleFile = join(projectRoot, rolePath);
  const installedRole = existsSync(roleFile) &&
    readFileSync(assertWithinRoot(projectRoot, roleFile), "utf8") === managedAgentContent(profile, projectRoot);
  const professionalSkills = skillIdsForTask(task, profile).map(
    (skillId) => ".agents/skills/" + skillId + "/SKILL.md",
  );
  const repair = assertRepairRunCommitted(projectRoot, runId);
  const dependencyInputs = task.dependencies.map((taskId) => {
    const entry = registry.entries.find((item) => item.task_ids.includes(taskId));
    const assignment = entry?.assignment_ids[entry.task_ids.indexOf(taskId)];
    return {
      task_id: taskId,
      ...(assignment ? { handoff_path: ".codex-factory/runs/" + runId + "/handoffs/" + assignment + ".json" } : {}),
    };
  });
  return [
    "FACTORY_ASSIGNMENT=" + JSON.stringify({ run_id: runId, assignment_id: assignmentId }),
    "Factory managed assignment for run " + runId + ", task " + task.task_id + ".",
    "Use project root: " + resolve(projectRoot) + ".",
    "Load and verify the role Context Packet/capsule at: " + packetPath + ".",
    "Before work, run: factoryctl context assignment-verify --project " +
      JSON.stringify(resolve(projectRoot)) +
      " --file " +
      JSON.stringify(packetPath) +
      " --run " +
      JSON.stringify(runId) +
      " --role " +
      JSON.stringify(profile.role) +
      " --assignment " +
      JSON.stringify(assignmentId) +
      ".",
    "This command handles both Context Packets and task capsules. Stop if it fails; do not invent a JSON hash procedure.",
    "After successful verification, load your assigned profile and its role Skills, task-relevant files and the professional Skills listed below. Do not routinely reload the main-controller codex-factory Skill or run whole-project doctor; consult them for a concrete setup or integrity issue. This does not waive user rules, failed checks, scope or acceptance.",
    "Do not inherit or trust the frontend compressed conversation; fork context is disabled.",
    "Treat untrusted_context_candidates as leads only. Source-bound knowledge_retrieval entries in trusted_context may be used, but cite their entry_id, source_uri, and source_sha256.",
    installedRole
      ? "Required role profile: " + rolePath + ". Read its developer_instructions before work; stop if the profile is missing."
      : "Role contract: " + profile.developer_instructions,
    "Required capabilities: " +
      ((task.required_capabilities ?? []).join(", ") || "inferred from the bounded task") +
      ".",
    "Professional Skills to load before work: " +
      (professionalSkills.join(", ") || "no additional domain Skill") +
      ".",
    "Task: " + task.title + " — " + task.description,
    "Allowed write scope: " + (task.write_scope.join(", ") || "read-only") + ".",
    "Acceptance methods: " + task.acceptance_methods.join(" | ") + ".",
    "Required artifacts: " + (task.required_artifacts.join(", ") || "none declared") + ".",
    ...(dependencyInputs.length ? [
      "Dependency inputs in this run: " + JSON.stringify(dependencyInputs),
      "Read the referenced handoffs for artifact paths, then inspect the physical files you need. Handoffs are reported output, not PASS decisions; consult this run's task graph and verification receipts for acceptance state. Input references do not expand your write scope.",
    ] : []),
    ...(repair ? [
      "Repair source: " + JSON.stringify({
        parent_run_id: repair.parent_run_id,
        failed_task_id: repair.failed_task_id,
        attempt: repair.repair_index,
        receipt_path: ".codex-factory/runs/" + repair.parent_run_id + "/verification/" + repair.failed_task_id + "/receipt.json",
        task_graph_path: ".codex-factory/runs/" + repair.parent_run_id + "/task-graph.json",
      }),
      "Read the parent receipt's failure_reasons and acceptance_checks first. Follow its assignment IDs to parent handoffs and read command logs only as needed. Consult the parent task graph for prior upstream inputs. Treat these as historical observations, not current command results or a replacement for this task's contract. Do not modify parent records; rerun current acceptance.",
      "For a read-only summary of specific failures, the original contract and upstream inputs, run factoryctl repair prepare --project " +
        JSON.stringify(resolve(projectRoot).replaceAll("\\", "/")) + " --from-run " + repair.parent_run_id + " --task " + repair.failed_task_id +
        " --json. Use its observations as repair context only; its next_actions are for the main controller. Do not create, continue or spawn additional runs.",
    ] : []),
    profile.profile_id === "factory_verifier"
      ? "Return an independent PASS/FAIL/BLOCKED proposal; the main controller records the final verdict with factoryctl verify. Do not dispatch another verifier."
      : "Return a factual handoff and a PASS/FAIL/BLOCKED proposal only; the main controller must dispatch an independent verifier before accepting your work.",
    "End the final assistant message with one single-line FACTORY_HANDOFF_JSON=<json> object.",
    'Handoff fields: summary:string; changed_paths:string[]; artifacts:Array<{path:string,sha256:string}>; commands:Array<{command:string,exit_code:number}>; proposed_verdict:"PASS"|"FAIL"|"BLOCKED"; caveats:string[]; unresolved_risks:string[].',
    "Use project-relative paths and actual 64-hex SHA256 artifact hashes, never filename-only artifact arrays. Include required artifacts even when no edits were needed; changed_paths must then be [].",
    "Report actual command results from this attempt, including nonzero exits. Describe historical failures separately in caveats, not as commands you executed. Do not invent commands, hashes or successful results.",
    "Temporary agents must not spawn children. Send progress and the final handoff only to the main controller.",
  ].join("\n");
}

function selectReadyTasks(
  tasks: FactoryTask[],
  availableSlots: number,
  allowTemporaryAgents: boolean,
  alreadyAssignedTaskIds: Set<string>,
  residentState: Map<string, "busy">,
  allowedResidentProfiles: Set<string>,
): {
  selected: Array<{ task: FactoryTask; profile: AgentProfile }>;
  blocked: Array<{ task_id: string; blocked_by: string[] }>;
} {
  const byId = new Map(tasks.map((task) => [task.task_id, task]));
  const active = tasks.filter((task) =>
    ["assigned", "in_progress", "handoff"].includes(task.status),
  );
  const selected: Array<{ task: FactoryTask; profile: AgentProfile }> = [];
  const blocked: Array<{ task_id: string; blocked_by: string[] }> = [];
  let newThreadSelections = 0;

  const dispatchPriority = (task: FactoryTask): number => {
    const profileId = profileForTask(task).profile_id;
    return new Map<string, number>([
      ["factory_verifier", 0],
      ["factory_drift_auditor", 1],
      ["factory_router", 2],
      ["factory_librarian", 2],
      ["factory_tester", 3],
      ["factory_integrator", 4],
      ["factory_researcher", 5],
      ["factory_implementer", 6],
    ]).get(profileId) ?? 10;
  };
  const orderedTasks = tasks
    .map((task, index) => ({ task, index }))
    .sort((left, right) =>
      dispatchPriority(left.task) - dispatchPriority(right.task) || left.index - right.index,
    )
    .map(({ task }) => task);

  for (const task of orderedTasks) {
    if (!["pending", "ready"].includes(task.status)) continue;
    if (alreadyAssignedTaskIds.has(task.task_id)) {
      blocked.push({ task_id: task.task_id, blocked_by: ["already_dispatched_in_run"] });
      continue;
    }
    const profile = profileForTask(task);
    const verifierTask = profile.profile_id === "factory_verifier";
    const incomplete = task.dependencies.filter((dependency) => {
      const dependencyStatus = byId.get(dependency)?.status;
      return verifierTask
        ? !["handoff", "verified"].includes(String(dependencyStatus))
        : dependencyStatus !== "verified";
    });
    if (incomplete.length > 0) {
      blocked.push({ task_id: task.task_id, blocked_by: incomplete });
      continue;
    }
    if (profile.kind === "temporary" && !allowTemporaryAgents) {
      blocked.push({ task_id: task.task_id, blocked_by: ["policy:temporary_agents_disabled"] });
      continue;
    }
    if (profile.kind === "resident" && !allowedResidentProfiles.has(profile.profile_id)) {
      blocked.push({
        task_id: task.task_id,
        blocked_by: ["policy:resident_profile_not_configured:" + profile.profile_id],
      });
      continue;
    }
    if (
      profile.kind === "resident" &&
      selected.some((item) => item.profile.profile_id === profile.profile_id)
    ) {
      blocked.push({
        task_id: task.task_id,
        blocked_by: ["resident_serialization:" + profile.profile_id],
      });
      continue;
    }
    if (profile.kind === "resident" && residentState.get(profile.profile_id) === "busy") {
      blocked.push({
        task_id: task.task_id,
        blocked_by: ["resident_busy:" + profile.profile_id],
      });
      continue;
    }
    if (newThreadSelections >= availableSlots) {
      blocked.push({ task_id: task.task_id, blocked_by: ["capacity:no_thread_slot"] });
      continue;
    }
    if (!profile.read_only) {
      const activeConflict = active.find((item) => {
        const activeProfile = profileForTask(item);
        return !activeProfile.read_only && writeScopesConflict(task.write_scope, item.write_scope);
      });
      if (activeConflict) {
        blocked.push({ task_id: task.task_id, blocked_by: ["scope:" + activeConflict.task_id] });
        continue;
      }
      const selectedConflict = selected.find(
        (item) =>
          !item.profile.read_only && writeScopesConflict(task.write_scope, item.task.write_scope),
      );
      if (selectedConflict) {
        blocked.push({
          task_id: task.task_id,
          blocked_by: ["scope:" + selectedConflict.task.task_id],
        });
        continue;
      }
    }
    selected.push({ task, profile });
    newThreadSelections += 1;
  }
  return { selected, blocked };
}

export function withRunControllerLock<T>(
  projectRoot: string,
  runId: string,
  operation: () => T,
): T {
  assertRepairRunCommitted(projectRoot, runId);
  const directory = runDirectory(projectRoot, runId);
  ensureDirectory(directory);
  return withFileLock(join(directory, "controller.lock"), operation);
}

export function prepareSpawnPlan(
  projectRoot: string,
  tasks: FactoryTask[],
  requestedRunId?: string,
): ManagedSpawnPlan {
  const runId = requestedRunId ?? newId("run");
  if (!existsSync(join(runDirectory(projectRoot, runId), "task-graph.json"))) validateNewTasks(tasks);
  return withRunControllerLock(projectRoot, runId, () =>
    prepareSpawnPlanUnlocked(projectRoot, tasks, runId),
  );
}

function prepareSpawnPlanUnlocked(
  projectRoot: string,
  tasks: FactoryTask[],
  requestedRunId: string,
): ManagedSpawnPlan {
  const root = resolve(projectRoot);
  const config = loadConfig(root);
  if (!config.features.multi_agent.enabled) {
    throw new Error("Managed multi-agent is disabled. Enable it explicitly before planning.");
  }
  if (config.features.multi_agent.execution_mode !== "codex_native") {
    throw new Error("Only codex_native automatic dispatch is supported");
  }
  if (config.features.multi_agent.max_depth !== 1) {
    throw new Error("Refusing plan: max_depth must be 1");
  }
  const runId = requestedRunId;
  const targetRunDirectory = runDirectory(root, runId);
  const taskGraphAlreadyExists = existsSync(join(targetRunDirectory, "task-graph.json"));
  if (taskGraphAlreadyExists) validateTaskGraph(tasks);
  else validateNewTasks(tasks);
  let plannedTasks = addAutomaticVerificationTasks(tasks);
  validateTaskGraph(plannedTasks);
  if (taskGraphAlreadyExists) {
    const persisted = readTaskGraphSnapshot(root, runId);
    if (stableStringify(plannedTasks) !== stableStringify(persisted.tasks)) {
      throw new Error(
        "Provided task graph does not exactly match the authoritative persisted run graph",
      );
    }
    plannedTasks = persisted.tasks;
  } else {
    validateInitialTaskStates(plannedTasks);
  }

  if (config.features.external_context.enabled) {
    initializeContextSpace(root);
    const ledger = verifyContextLedger(root);
    if (!ledger.valid) {
      throw new Error("Context ledger is invalid; refusing dispatch: " + ledger.issues.join("; "));
    }
  }

  ensureDirectory(targetRunDirectory);
  const registry = readAgentRegistry(root, runId);
  const registryBaseHash = sha256(stableStringify(registry));
  if (taskGraphAlreadyExists) {
    verifyPersistedRuntimeClaims(root, runId, plannedTasks, registry);
    const currentPlan = readCurrentSpawnPlan(root, runId);
    const pendingDispatches = currentPlan.assignments.filter((assignment) => {
      const entry = registry.entries.find((candidate) =>
        candidate.assignment_ids.includes(assignment.assignment_id),
      );
      return !entry?.native_receipts.some(
        (receipt) => receipt.assignment_id === assignment.assignment_id,
      );
    });
    if (pendingDispatches.length > 0) {
      return {
        ...currentPlan,
        assignments: pendingDispatches,
        instructions_for_main_agent: [
          "Resume the existing unregistered native dispatches before planning another wave.",
          ...currentPlan.instructions_for_main_agent,
        ],
      };
    }
  }
  const alreadyAssigned = new Set(registry.entries.flatMap((entry) => entry.task_ids));
  const duplicateInstanceKeys = registry.entries
    .map((entry) => entry.instance_key)
    .filter((key, index, keys) => keys.indexOf(key) !== index);
  if (duplicateInstanceKeys.length > 0) {
    throw new Error(
      "Agent registry contains duplicate instance keys: " + [...new Set(duplicateInstanceKeys)].join(", "),
    );
  }
  const openNativeThreads = registry.entries.filter(
    (entry) =>
      entry.native_agent_id !== null &&
      ["spawned", "running"].includes(entry.lifecycle),
  ).length;
  const residentState = new Map<string, "busy">();
  for (const entry of registry.entries.filter(
    (item) =>
      item.profile_kind === "resident" &&
      item.native_agent_id !== null &&
      ["spawned", "running"].includes(item.lifecycle),
  )) {
    residentState.set(entry.profile_id, "busy");
  }
  const availableSlots = Math.max(
    0,
    config.features.multi_agent.max_threads - openNativeThreads,
  );
  const { selected, blocked } = selectReadyTasks(
    plannedTasks,
    availableSlots,
    config.features.multi_agent.allow_temporary_agents,
    alreadyAssigned,
    residentState,
    new Set(config.features.multi_agent.resident_profiles),
  );
  const generatedAt = nowIso();
  const createdAt = taskGraphAlreadyExists
    ? readJson<{ created_at: string }>(join(targetRunDirectory, "run.json")).created_at
    : generatedAt;
  const assignments: ManagedSpawnPlanEntry[] = [];
  const baselineEntries = filesystemManifest(root);
  const waveWriteScopes = selected
    .filter(({ profile }) => !profile.read_only)
    .map(({ task }) => task.write_scope);

  for (const { task, profile } of selected) {
    const assignmentId = newId("assignment");
    const key = instanceKey(profile, assignmentId);
    const packetPath = createAssignmentPacket(root, runId, assignmentId, task, profile);
    const baseline = writeAssignmentBaseline(
      root,
      runId,
      assignmentId,
      task.write_scope,
      waveWriteScopes,
      baselineEntries,
    );
    const entry: ManagedSpawnPlanEntry = {
      assignment_id: assignmentId,
      task_id: task.task_id,
      profile_id: profile.profile_id,
      codex_agent_name: profile.codex_agent_name,
      profile_kind: profile.kind,
      isolation: config.features.multi_agent.isolation,
      fork_turns: "none",
      context_packet_path: packetPath,
      write_scope: task.write_scope,
      prompt: assignmentPrompt(root, runId, assignmentId, task, profile, packetPath, registry),
      status: "planned",
      action: "spawn",
      instance_key: key,
      logical_display_name: profile.display_name,
      logical_icon: profile.icon,
    };
    assignments.push(entry);

    registry.entries.push({
      instance_key: key,
      profile_id: profile.profile_id,
      profile_kind: profile.kind,
      codex_agent_name: profile.codex_agent_name,
      logical_display_name: profile.display_name,
      logical_icon: profile.icon,
      nickname_candidates: profile.nickname_candidates,
      native_agent_id: null,
      native_nickname: null,
      lifecycle: "planned",
      assignment_ids: [assignmentId],
      task_ids: [task.task_id],
      created_at: generatedAt,
      updated_at: generatedAt,
      native_receipts: [],
      baselines: [
        {
          assignment_id: assignmentId,
          path: baseline.path,
          sha256: baseline.sha256,
          wave_write_scopes: waveWriteScopes,
        },
      ],
    });
  }

  const plan: ManagedSpawnPlan = {
    version: "1.0.0",
    run_id: runId,
    project_id: config.project_id,
    generated_at: generatedAt,
    native_spawn_required: true,
    max_parallel: availableSlots,
    max_depth: 1,
    assignments,
    blocked_tasks: blocked,
    instructions_for_main_agent: [
      "Act automatically: do not ask the user to open windows or copy prompts.",
      "For action=spawn, use the host's supported isolation option: fork_turns=none or fork_context=false, and the declared profile/task prompt. Never enable context inheritance.",
      "Resident means a durable specialist profile, not a reusable conversation. Spawn a fresh isolated execution instance for every assignment.",
      "Record the actual native tool result (ID and host nickname) with factoryctl agent register-spawn; never invent either value.",
      "Keep a single sub-agent layer. Workers must not spawn children.",
      "Wait/steer through the main controller. A worker handoff is never a PASS decision.",
      "Dispatch an independent verifier and require physical artifacts, hashes, exact commands, and exit codes before PASS.",
    ],
  };

  const selectedTaskIds = new Set(assignments.map((assignment) => assignment.task_id));
  const persistedTasks = plannedTasks.map((task) =>
    selectedTaskIds.has(task.task_id) ? { ...task, status: "assigned" as const } : task,
  );
  const graphSnapshot = {
    version: "1.0.0",
    run_id: runId,
    generated_at: generatedAt,
    tasks: persistedTasks,
    graph_sha256: sha256(stableStringify(persistedTasks)),
  };
  const taskGraphPath = join(targetRunDirectory, "task-graph.json");
  withFileLock(taskGraphPath + ".lock", () => {
    if (taskGraphAlreadyExists) {
      const current = readTaskGraphSnapshot(root, runId);
      if (stableStringify(current.tasks) !== stableStringify(plannedTasks)) {
        throw new Error("Task graph changed concurrently while planning; retry the wave");
      }
    }
    writeJsonAtomic(taskGraphPath, graphSnapshot);
  });
  writeJsonAtomic(join(targetRunDirectory, "spawn-plan.json"), plan);
  const agentRegistryPath = registryPath(root, runId);
  withFileLock(agentRegistryPath + ".lock", () => {
    const current = readAgentRegistry(root, runId);
    if (sha256(stableStringify(current)) !== registryBaseHash) {
      throw new Error("Agent registry changed concurrently while planning; retry the wave");
    }
    writeJsonAtomic(agentRegistryPath, registry);
  });
  writeJsonAtomic(join(targetRunDirectory, "run.json"), {
    version: "1.0.0",
    run_id: runId,
    project_id: config.project_id,
    created_at: createdAt,
    status: assignments.length > 0 ? "AWAITING_NATIVE_DISPATCH" : "NO_READY_TASKS",
    config_sha256: sha256(stableStringify(config)),
    task_graph_sha256: graphSnapshot.graph_sha256,
    spawn_plan_sha256: sha256(stableStringify(plan)),
  });
  return plan;
}

export function registerNativeDispatch(
  projectRoot: string,
  runId: string,
  assignmentId: string,
  input: NativeDispatchReceiptInput,
): NativeAgentRegistryEntry {
  return withRunControllerLock(projectRoot, runId, () =>
    registerNativeDispatchUnlocked(projectRoot, runId, assignmentId, input),
  );
}

function registerNativeDispatchUnlocked(
  projectRoot: string,
  runId: string,
  assignmentId: string,
  input: NativeDispatchReceiptInput,
): NativeAgentRegistryEntry {
  const root = resolve(projectRoot);
  const config = loadConfig(root);
  if (!config.features.multi_agent.enabled) throw new Error("Managed multi-agent is disabled");
  if (!input.nativeAgentId.trim()) throw new Error("Native agent id is required");
  readTaskGraphSnapshot(root, runId);
  const toolName = input.toolName ?? "spawn_agent";
  const planEntry = readCurrentSpawnPlan(root, runId).assignments.find(
    (assignment) => assignment.assignment_id === assignmentId,
  );
  if (!planEntry) throw new Error("Assignment is not present in the current verified spawn plan");
  const expectedTool = planEntry.action === "spawn" ? "spawn_agent" : "followup_task";
  if (toolName !== expectedTool) {
    throw new Error(
      "Native tool receipt does not match planned action: expected " + expectedTool,
    );
  }
  verifyNativeToolReceipt(
    input.rawToolReceipt,
    input.nativeAgentId,
    input.nativeNickname,
    expectedTool,
  );
  const path = registryPath(root, runId);
  const registered = withFileLock(path + ".lock", () => {
    const registry = readAgentRegistry(root, runId);
    const entry = registry.entries.find((item) => item.assignment_ids.includes(assignmentId));
    if (!entry) throw new Error("Unknown assignment in registry: " + assignmentId);
    if (
      toolName === "spawn_agent" &&
      entry.native_agent_id &&
      entry.native_agent_id !== input.nativeAgentId
    ) {
      throw new Error("Resident instance already has a different native agent id");
    }
    if (
      registry.entries.some(
        (item) => item !== entry && item.native_agent_id === input.nativeAgentId,
      )
    ) {
      throw new Error("Native agent id is already registered to another instance");
    }
    const receipt = {
      tool_name: toolName,
      run_id: runId,
      assignment_id: assignmentId,
      native_agent_id: input.nativeAgentId,
      native_nickname: input.nativeNickname ?? null,
      recorded_at: nowIso(),
      raw_tool_receipt: input.rawToolReceipt,
      warning: "This preserves the host receipt but does not replace independent task verification.",
    };
    const receiptPath = join(
      runDirectory(root, runId),
      "native-receipts",
      assignmentId + "-" + toolName + ".json",
    );
    writeJsonAtomic(receiptPath, receipt);
    const receiptHash = sha256(stableStringify(receipt));
    entry.native_agent_id = input.nativeAgentId;
    entry.native_nickname = input.nativeNickname?.trim() || entry.native_nickname;
    entry.lifecycle = toolName === "spawn_agent" ? "spawned" : "running";
    entry.updated_at = receipt.recorded_at;
    entry.native_receipts.push({
      assignment_id: assignmentId,
      tool_name: toolName,
      recorded_at: receipt.recorded_at,
      receipt_sha256: receiptHash,
      receipt_path: relative(root, receiptPath).replaceAll("\\", "/"),
    });
    const taskId = entry.task_ids[entry.assignment_ids.indexOf(assignmentId)];
    writeJsonAtomic(path, registry);
    return {
      entry: structuredClone(entry),
      receiptHash,
      receiptFileSha256: sha256(readFileSync(receiptPath)),
      receiptPath: relative(root, receiptPath).replaceAll("\\", "/"),
      taskId,
    };
  });
  setRunTaskStatus(root, runId, registered.taskId, "in_progress");
  if (config.features.external_context.enabled) {
    appendTrustedContextEvent(
      root,
      "agent_event",
      "main_controller",
      {
        run_id: runId,
        assignment_id: assignmentId,
        profile_id: registered.entry.profile_id,
        native_agent_id: input.nativeAgentId,
        native_nickname: registered.entry.native_nickname,
        tool_name: toolName,
        receipt_sha256: registered.receiptHash,
        lifecycle: registered.entry.lifecycle,
        visible_to_roles: ["main_controller", "verifier", "drift_auditor"],
      },
      {
        basis: "trusted_internal",
        authority: "factory_control_plane",
        source: {
          kind: "control_plane_receipt",
          reference: registered.receiptPath,
          sha256: registered.receiptFileSha256,
        },
      },
    );
  }
  return registered.entry;
}

export function updateNativeAgentLifecycle(
  projectRoot: string,
  runId: string,
  nativeAgentId: string,
  next: NativeAgentLifecycle,
): NativeAgentRegistryEntry {
  return withRunControllerLock(projectRoot, runId, () =>
    updateNativeAgentLifecycleUnderControllerLock(
      projectRoot,
      runId,
      nativeAgentId,
      next,
    ),
  );
}

export function updateNativeAgentLifecycleUnderControllerLock(
  projectRoot: string,
  runId: string,
  nativeAgentId: string,
  next: NativeAgentLifecycle,
): NativeAgentRegistryEntry {
  const allowed: Record<NativeAgentLifecycle, NativeAgentLifecycle[]> = {
    planned: ["spawned", "failed"],
    spawned: ["running", "idle", "completed", "failed", "closed"],
    running: ["idle", "completed", "failed", "closed"],
    idle: ["running", "completed", "failed", "closed"],
    completed: ["closed"],
    failed: ["closed"],
    closed: [],
  };
  if (!Object.prototype.hasOwnProperty.call(allowed, next)) {
    throw new Error("Unknown native lifecycle state: " + String(next));
  }
  const path = registryPath(projectRoot, runId);
  return withFileLock(path + ".lock", () => {
    const registry = readAgentRegistry(projectRoot, runId);
    const entry = registry.entries.find((item) => item.native_agent_id === nativeAgentId);
    if (!entry) throw new Error("Unknown native agent id: " + nativeAgentId);
    if (!allowed[entry.lifecycle].includes(next)) {
      throw new Error("Invalid lifecycle transition: " + entry.lifecycle + " -> " + next);
    }
    entry.lifecycle = next;
    entry.updated_at = nowIso();
    writeJsonAtomic(path, registry);
    return entry;
  });
}

export function getAgentProfileForAssignment(
  projectRoot: string,
  runId: string,
  assignmentId: string,
): AgentProfile {
  const registry = readAgentRegistry(projectRoot, runId);
  const entry = registry.entries.find((item) => item.assignment_ids.includes(assignmentId));
  if (!entry) throw new Error("Unknown assignment: " + assignmentId);
  return getAgentProfile(entry.profile_id);
}
