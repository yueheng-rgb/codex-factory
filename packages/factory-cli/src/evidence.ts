import { spawnSync } from "node:child_process";
import {
  existsSync,
  lstatSync,
  readdirSync,
  readFileSync,
  writeFileSync,
} from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { factoryDirectory, loadConfig, loadSecrets } from "./config.js";
import { appendContextEvent, appendTrustedContextEvent } from "./context-space.js";
import {
  readAgentRegistry,
  readTaskGraphSnapshot,
  setRunTaskStatus,
  updateNativeAgentLifecycleUnderControllerLock,
  verifyAssignmentPhysicalDiff,
  withRunControllerLock,
} from "./orchestrator.js";
import type { FactoryTask } from "./types.js";
import {
  assertWithinRoot,
  ensureDirectory,
  nowIso,
  readJson,
  sha256,
  stableStringify,
  writeJsonAtomic,
} from "./util.js";

export interface WorkerCommandReport {
  command: string;
  exit_code: number;
  stdout_sha256?: string;
  stderr_sha256?: string;
}

export interface WorkerArtifactReport {
  path: string;
  sha256: string;
}

export interface WorkerHandoffInput {
  summary: string;
  changed_paths: string[];
  artifacts: WorkerArtifactReport[];
  commands: WorkerCommandReport[];
  proposed_verdict?: "PASS" | "FAIL" | "BLOCKED";
  caveats?: string[];
  unresolved_risks?: string[];
}

export interface RecordedHandoff {
  version: "1.0.0";
  run_id: string;
  assignment_id: string;
  task_id: string;
  profile_id: string;
  native_agent_id: string;
  recorded_at: string;
  verification_state: "RECORDED_UNVERIFIED";
  report: WorkerHandoffInput;
  observed_artifacts: Array<{ path: string; sha256: string; kind: "file" | "directory" }>;
  handoff_hash: string;
}

export interface AcceptanceCheck {
  method: string;
  status: "PASS" | "FAIL";
  detail: string;
  exit_code?: number | null;
  stdout_sha256?: string;
  stderr_sha256?: string;
  duration_ms?: number;
}

export interface VerificationReceipt {
  version: "1.0.0";
  run_id: string;
  task_id: string;
  worker_assignment_id: string;
  worker_native_agent_id: string;
  verifier_assignment_id: string;
  verifier_native_agent_id: string;
  verified_at: string;
  source_handoff_hash: string;
  verifier_handoff_hash: string;
  artifact_checks: AcceptanceCheck[];
  acceptance_checks: AcceptanceCheck[];
  independent_verifier_proposal: "PASS" | "FAIL" | "BLOCKED";
  verdict: "PASS" | "FAIL";
  failure_reasons: string[];
  receipt_hash: string;
}

interface TaskGraphSnapshot {
  run_id: string;
  tasks: FactoryTask[];
}

function runDirectory(projectRoot: string, runId: string): string {
  if (!/^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$/.test(runId)) {
    throw new Error("Invalid run id: " + runId);
  }
  return assertWithinRoot(projectRoot, join(factoryDirectory(projectRoot), "runs", runId));
}

function taskGraph(projectRoot: string, runId: string): TaskGraphSnapshot {
  return readTaskGraphSnapshot(projectRoot, runId);
}

function taskForAssignment(
  projectRoot: string,
  runId: string,
  assignmentId: string,
): { task: FactoryTask; profileId: string; nativeAgentId: string } {
  const registry = readAgentRegistry(projectRoot, runId);
  const entry = registry.entries.find((candidate) =>
    candidate.assignment_ids.includes(assignmentId),
  );
  if (!entry) throw new Error("Unknown assignment: " + assignmentId);
  if (
    !entry.native_agent_id ||
    !entry.native_receipts.some((receipt) => receipt.assignment_id === assignmentId)
  ) {
    throw new Error("Assignment has no recorded native tool receipt: " + assignmentId);
  }
  const taskIndex = entry.assignment_ids.indexOf(assignmentId);
  const taskId = entry.task_ids[taskIndex];
  const task = taskGraph(projectRoot, runId).tasks.find((item) => item.task_id === taskId);
  if (!task) throw new Error("Task not found for assignment: " + assignmentId);
  return { task, profileId: entry.profile_id, nativeAgentId: entry.native_agent_id };
}

function pathInWriteScope(path: string, scopes: string[]): boolean {
  const item = path.replaceAll("\\", "/").replace(/^\.\//, "").replace(/\/+$/, "");
  return scopes.some((rawScope) => {
    const scope = rawScope
      .replaceAll("\\", "/")
      .replace(/^\.\//, "")
      .replace(/\/+$/, "");
    if (["*", ".", ""].includes(scope)) return true;
    return item === scope || item.startsWith(scope + "/");
  });
}

function hashArtifact(projectRoot: string, artifactPath: string): {
  path: string;
  sha256: string;
  kind: "file" | "directory";
} {
  const absolute = assertWithinRoot(projectRoot, resolve(projectRoot, artifactPath));
  if (!existsSync(absolute)) throw new Error("Artifact does not exist: " + artifactPath);
  const stat = lstatSync(absolute);
  if (stat.isSymbolicLink()) throw new Error("Symbolic-link artifacts are not accepted: " + artifactPath);
  const normalized = relative(resolve(projectRoot), absolute).replaceAll("\\", "/");
  if (stat.isFile()) {
    return { path: normalized, sha256: sha256(readFileSync(absolute)), kind: "file" };
  }
  if (!stat.isDirectory()) throw new Error("Unsupported artifact type: " + artifactPath);

  const manifest: Array<{ path: string; sha256: string }> = [];
  const walk = (directory: string): void => {
    for (const name of readdirSync(directory).sort((left, right) => left.localeCompare(right))) {
      const child = join(directory, name);
      const childStat = lstatSync(child);
      if (childStat.isSymbolicLink()) {
        throw new Error("Directory artifact contains a symbolic link: " + relative(projectRoot, child));
      }
      if (childStat.isDirectory()) walk(child);
      else if (childStat.isFile()) {
        manifest.push({
          path: relative(absolute, child).replaceAll("\\", "/"),
          sha256: sha256(readFileSync(child)),
        });
      }
    }
  };
  walk(absolute);
  return {
    path: normalized,
    sha256: sha256(stableStringify(manifest)),
    kind: "directory",
  };
}

function handoffPath(projectRoot: string, runId: string, assignmentId: string): string {
  return join(runDirectory(projectRoot, runId), "handoffs", assignmentId + ".json");
}

export function recordAgentHandoff(
  projectRoot: string,
  runId: string,
  assignmentId: string,
  input: WorkerHandoffInput,
): RecordedHandoff {
  return withRunControllerLock(projectRoot, runId, () =>
    recordAgentHandoffUnlocked(projectRoot, runId, assignmentId, input),
  );
}

function recordAgentHandoffUnlocked(
  projectRoot: string,
  runId: string,
  assignmentId: string,
  input: WorkerHandoffInput,
): RecordedHandoff {
  const root = resolve(projectRoot);
  if (!input.summary?.trim()) throw new Error("Handoff summary is required");
  if (!Array.isArray(input.changed_paths) || !Array.isArray(input.artifacts)) {
    throw new Error("Handoff changed_paths and artifacts must be arrays");
  }
  if (!Array.isArray(input.commands)) throw new Error("Handoff commands must be an array");
  const assignment = taskForAssignment(root, runId, assignmentId);
  if (!(["assigned", "in_progress"] as FactoryTask["status"][]).includes(assignment.task.status)) {
    throw new Error(
      "Handoff can only be recorded for an assigned or in-progress task; current state is " +
        assignment.task.status,
    );
  }
  const targetHandoffPath = handoffPath(root, runId, assignmentId);
  if (existsSync(targetHandoffPath)) {
    throw new Error("Handoff is immutable once recorded: " + assignmentId);
  }
  if (assignment.task.write_scope.length === 0 && input.changed_paths.length > 0) {
    throw new Error("Read-only assignment reported changed files");
  }
  for (const changedPath of input.changed_paths) {
    assertWithinRoot(root, resolve(root, changedPath));
    if (!pathInWriteScope(changedPath, assignment.task.write_scope)) {
      throw new Error("Changed path is outside task write scope: " + changedPath);
    }
  }
  verifyAssignmentPhysicalDiff(root, runId, assignmentId, input.changed_paths);
  const observed = input.artifacts.map((artifact) => {
    const actual = hashArtifact(root, artifact.path);
    if (!/^[a-f0-9]{64}$/i.test(artifact.sha256) || artifact.sha256 !== actual.sha256) {
      throw new Error("Artifact hash mismatch: " + artifact.path);
    }
    return actual;
  });
  for (const required of assignment.task.required_artifacts) {
    if (!observed.some((artifact) => artifact.path === required.replaceAll("\\", "/"))) {
      throw new Error("Required artifact missing from handoff: " + required);
    }
  }
  const duplicatePaths = new Set<string>();
  for (const artifact of observed) {
    if (duplicatePaths.has(artifact.path)) throw new Error("Duplicate artifact: " + artifact.path);
    duplicatePaths.add(artifact.path);
  }
  for (const command of input.commands) {
    if (!command.command?.trim() || !Number.isInteger(command.exit_code)) {
      throw new Error("Each reported command requires command and integer exit_code");
    }
  }
  const unsigned = {
    version: "1.0.0" as const,
    run_id: runId,
    assignment_id: assignmentId,
    task_id: assignment.task.task_id,
    profile_id: assignment.profileId,
    native_agent_id: assignment.nativeAgentId,
    recorded_at: nowIso(),
    verification_state: "RECORDED_UNVERIFIED" as const,
    report: input,
    observed_artifacts: observed,
  };
  const handoff: RecordedHandoff = {
    ...unsigned,
    handoff_hash: sha256(stableStringify(unsigned)),
  };
  writeJsonAtomic(targetHandoffPath, handoff);
  setRunTaskStatus(root, runId, assignment.task.task_id, "handoff");
  const lifecycleTarget = assignment.profileId.startsWith("factory_") &&
      ["factory_router", "factory_librarian", "factory_verifier", "factory_drift_auditor"].includes(
        assignment.profileId,
      )
    ? "idle"
    : "completed";
  updateNativeAgentLifecycleUnderControllerLock(
    root,
    runId,
    assignment.nativeAgentId,
    lifecycleTarget,
  );
  const config = loadConfig(root);
  if (config.features.external_context.enabled) {
    appendContextEvent(root, "evidence", assignment.nativeAgentId, {
      run_id: runId,
      assignment_id: assignmentId,
      task_id: assignment.task.task_id,
      handoff_hash: handoff.handoff_hash,
      verification_state: handoff.verification_state,
      proposed_verdict: input.proposed_verdict ?? null,
      visible_to_roles: ["main_controller", "verifier", "drift_auditor"],
    });
  }
  return handoff;
}

function readRecordedHandoff(
  projectRoot: string,
  runId: string,
  assignmentId: string,
): RecordedHandoff {
  const path = handoffPath(projectRoot, runId, assignmentId);
  if (!existsSync(path)) throw new Error("Recorded handoff not found: " + assignmentId);
  const handoff = readJson<RecordedHandoff>(path);
  const { handoff_hash: _hash, ...unsigned } = handoff;
  if (handoff.handoff_hash !== sha256(stableStringify(unsigned))) {
    throw new Error("Recorded handoff hash mismatch: " + assignmentId);
  }
  return handoff;
}

function redactSecrets(projectRoot: string, text: string): string {
  let redacted = text;
  const config = loadConfig(projectRoot);
  const candidates = new Set(Object.values(loadSecrets(projectRoot)));
  const keyName = config.features.external_search.api_key_env;
  if (keyName && process.env[keyName]) candidates.add(process.env[keyName] as string);
  for (const secret of candidates) {
    if (secret.length >= 6) redacted = redacted.split(secret).join("[REDACTED]");
  }
  return redacted;
}

function executeAcceptanceMethod(
  projectRoot: string,
  runId: string,
  taskId: string,
  index: number,
  method: string,
): AcceptanceCheck {
  const trimmed = method.trim();
  if (trimmed.startsWith("exists:")) {
    const path = trimmed.slice("exists:".length).trim();
    const absolute = assertWithinRoot(projectRoot, resolve(projectRoot, path));
    const exists = existsSync(absolute);
    return {
      method,
      status: exists ? "PASS" : "FAIL",
      detail: exists ? "Physical path exists: " + path : "Physical path missing: " + path,
    };
  }
  if (trimmed.startsWith("json:")) {
    const path = trimmed.slice("json:".length).trim();
    try {
      const absolute = assertWithinRoot(projectRoot, resolve(projectRoot, path));
      JSON.parse(readFileSync(absolute, "utf8"));
      return { method, status: "PASS", detail: "JSON parsed successfully: " + path };
    } catch (error) {
      return { method, status: "FAIL", detail: "JSON check failed: " + (error as Error).message };
    }
  }
  const prefix = trimmed.startsWith("command:")
    ? "command:"
    : trimmed.startsWith("cmd:")
      ? "cmd:"
      : undefined;
  if (!prefix) {
    return {
      method,
      status: "FAIL",
      detail:
        "Unsupported acceptance method. Use command:, exists:, or json: so verification is executable.",
    };
  }
  const command = trimmed.slice(prefix.length).trim();
  if (!command) return { method, status: "FAIL", detail: "Acceptance command is empty" };
  const started = Date.now();
  const result = spawnSync(command, {
    cwd: projectRoot,
    shell: true,
    encoding: "utf8",
    timeout: 120_000,
    maxBuffer: 10 * 1024 * 1024,
    windowsHide: true,
  });
  const stdout = redactSecrets(projectRoot, result.stdout ?? "");
  const stderr = redactSecrets(projectRoot, result.stderr ?? "");
  const logDirectory = join(runDirectory(projectRoot, runId), "verification", taskId);
  ensureDirectory(logDirectory);
  const stdoutPath = join(logDirectory, String(index + 1).padStart(2, "0") + "-stdout.log");
  const stderrPath = join(logDirectory, String(index + 1).padStart(2, "0") + "-stderr.log");
  writeFileSync(stdoutPath, stdout, "utf8");
  writeFileSync(stderrPath, stderr, "utf8");
  const exitCode = result.status;
  return {
    method,
    status: exitCode === 0 && !result.error ? "PASS" : "FAIL",
    detail: result.error
      ? "Command execution failed: " + result.error.message
      : "Command output stored under " + relative(projectRoot, dirname(stdoutPath)).replaceAll("\\", "/"),
    exit_code: exitCode,
    stdout_sha256: sha256(stdout),
    stderr_sha256: sha256(stderr),
    duration_ms: Date.now() - started,
  };
}

function workerAssignmentForTask(
  projectRoot: string,
  runId: string,
  taskId: string,
): { assignmentId: string; nativeAgentId: string } {
  const registry = readAgentRegistry(projectRoot, runId);
  for (const entry of registry.entries) {
    const index = entry.task_ids.indexOf(taskId);
    const assignmentId = index >= 0 ? entry.assignment_ids[index] : undefined;
    if (
      index >= 0 &&
      assignmentId &&
      entry.native_agent_id &&
      entry.native_receipts.some((receipt) => receipt.assignment_id === assignmentId)
    ) {
      return { assignmentId, nativeAgentId: entry.native_agent_id };
    }
  }
  throw new Error("No native worker assignment found for task: " + taskId);
}

export function verifyTaskCompletion(
  projectRoot: string,
  runId: string,
  taskId: string,
  verifierAssignmentId: string,
): VerificationReceipt {
  return withRunControllerLock(projectRoot, runId, () =>
    verifyTaskCompletionUnlocked(projectRoot, runId, taskId, verifierAssignmentId),
  );
}

function verifyTaskCompletionUnlocked(
  projectRoot: string,
  runId: string,
  taskId: string,
  verifierAssignmentId: string,
): VerificationReceipt {
  const root = resolve(projectRoot);
  const graph = taskGraph(root, runId);
  const task = graph.tasks.find((item) => item.task_id === taskId);
  if (!task) throw new Error("Unknown task: " + taskId);
  const worker = workerAssignmentForTask(root, runId, taskId);
  if (task.status !== "handoff") {
    throw new Error(
      "Verification requires the target task to be in handoff state; current state is " +
        task.status,
    );
  }
  const workerHandoff = readRecordedHandoff(root, runId, worker.assignmentId);
  if (
    workerHandoff.run_id !== runId ||
    workerHandoff.assignment_id !== worker.assignmentId ||
    workerHandoff.task_id !== taskId ||
    workerHandoff.native_agent_id !== worker.nativeAgentId
  ) {
    throw new Error("Worker handoff identity is not bound to the target task");
  }
  const verifier = taskForAssignment(root, runId, verifierAssignmentId);
  if (verifier.profileId !== "factory_verifier") {
    throw new Error("Independent verification requires the factory_verifier profile");
  }
  if (verifier.nativeAgentId === worker.nativeAgentId) {
    throw new Error("Worker and verifier must be different native agents");
  }
  if (!verifier.task.dependencies.includes(taskId)) {
    throw new Error("Verifier task does not depend on target task: " + taskId);
  }
  if (verifier.task.status !== "handoff") {
    throw new Error(
      "Verification requires the verifier task to be in handoff state; current state is " +
        verifier.task.status,
    );
  }
  const receiptPath = join(
    runDirectory(root, runId),
    "verification",
    taskId,
    "receipt.json",
  );
  if (existsSync(receiptPath)) {
    throw new Error("Verification receipt is immutable once recorded: " + taskId);
  }
  const verifierHandoff = readRecordedHandoff(root, runId, verifierAssignmentId);
  if (
    verifierHandoff.run_id !== runId ||
    verifierHandoff.assignment_id !== verifierAssignmentId ||
    verifierHandoff.task_id !== verifier.task.task_id ||
    verifierHandoff.native_agent_id !== verifier.nativeAgentId
  ) {
    throw new Error("Verifier handoff identity is not bound to the verifier assignment");
  }
  const verifierProposal = verifierHandoff.report.proposed_verdict ?? "BLOCKED";

  const artifactChecks: AcceptanceCheck[] = workerHandoff.observed_artifacts.map((artifact) => {
    try {
      const current = hashArtifact(root, artifact.path);
      const passed = current.sha256 === artifact.sha256 && current.kind === artifact.kind;
      return {
        method: "artifact:" + artifact.path,
        status: passed ? "PASS" : "FAIL",
        detail: passed ? "Artifact hash is unchanged" : "Artifact hash or kind changed after handoff",
      };
    } catch (error) {
      return {
        method: "artifact:" + artifact.path,
        status: "FAIL",
        detail: (error as Error).message,
      };
    }
  });
  for (const required of task.required_artifacts) {
    if (!workerHandoff.observed_artifacts.some((artifact) => artifact.path === required)) {
      artifactChecks.push({
        method: "required-artifact:" + required,
        status: "FAIL",
        detail: "Required artifact was not bound into the worker handoff",
      });
    }
  }
  const acceptanceChecks = task.acceptance_methods.map((method, index) =>
    executeAcceptanceMethod(root, runId, taskId, index, method),
  );
  const failureReasons: string[] = [];
  if (workerHandoff.report.commands.some((command) => command.exit_code !== 0)) {
    failureReasons.push("Worker reported at least one failing command");
  }
  if (verifierHandoff.report.commands.some((command) => command.exit_code !== 0)) {
    failureReasons.push("Independent verifier reported at least one failing command");
  }
  if (artifactChecks.some((check) => check.status !== "PASS")) {
    failureReasons.push("One or more physical artifact checks failed");
  }
  if (acceptanceChecks.length === 0 || acceptanceChecks.some((check) => check.status !== "PASS")) {
    failureReasons.push("One or more independently executed acceptance checks failed");
  }
  if (verifierProposal !== "PASS") {
    failureReasons.push("Independent native verifier did not propose PASS");
  }
  const unsigned = {
    version: "1.0.0" as const,
    run_id: runId,
    task_id: taskId,
    worker_assignment_id: worker.assignmentId,
    worker_native_agent_id: worker.nativeAgentId,
    verifier_assignment_id: verifierAssignmentId,
    verifier_native_agent_id: verifier.nativeAgentId,
    verified_at: nowIso(),
    source_handoff_hash: workerHandoff.handoff_hash,
    verifier_handoff_hash: verifierHandoff.handoff_hash,
    artifact_checks: artifactChecks,
    acceptance_checks: acceptanceChecks,
    independent_verifier_proposal: verifierProposal,
    verdict: (failureReasons.length === 0 ? "PASS" : "FAIL") as "PASS" | "FAIL",
    failure_reasons: failureReasons,
  };
  const receipt: VerificationReceipt = {
    ...unsigned,
    receipt_hash: sha256(stableStringify(unsigned)),
  };
  writeJsonAtomic(receiptPath, receipt);
  setRunTaskStatus(root, runId, taskId, receipt.verdict === "PASS" ? "verified" : "failed");
  setRunTaskStatus(root, runId, verifier.task.task_id, "verified");
  const config = loadConfig(root);
  if (config.features.external_context.enabled) {
    appendTrustedContextEvent(
      root,
      receipt.verdict === "PASS" ? "evidence" : "rejected_claim",
      "factoryctl",
      {
        run_id: runId,
        task_id: taskId,
        verifier_native_agent_id: verifier.nativeAgentId,
        verdict: receipt.verdict,
        failure_reasons: receipt.failure_reasons,
        receipt_hash: receipt.receipt_hash,
        visible_to_roles: ["main_controller", "verifier", "drift_auditor", "integrator"],
      },
      {
        basis: "independent_verification",
        authority: "factory_independent_verifier",
        verifiedBy: verifier.nativeAgentId,
        source: {
          kind: "verification_receipt",
          reference: relative(root, receiptPath).replaceAll("\\", "/"),
          sha256: sha256(readFileSync(receiptPath)),
        },
      },
    );
  }
  return receipt;
}
