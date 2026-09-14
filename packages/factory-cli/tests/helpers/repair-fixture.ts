import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { initializeConfig } from "../../src/config.js";
import { initializeContextSpace } from "../../src/context-space.js";
import { recordAgentHandoff, verifyTaskCompletion } from "../../src/evidence.js";
import { prepareSpawnPlan, readTaskGraphSnapshot, registerNativeDispatch } from "../../src/orchestrator.js";
import type { FactoryTask } from "../../src/types.js";
import { sha256 } from "../../src/util.js";

export function repairTask(overrides: Partial<FactoryTask> = {}): FactoryTask {
  return {
    task_id: "worker", title: "Bounded artifact repair", description: "Produce the approved artifact",
    role: "implementation", status: "pending", dependencies: [], write_scope: ["artifact.txt"],
    required_artifacts: ["artifact.txt"], acceptance_methods: ["exists:artifact.txt"], ...overrides,
  };
}

export function fixtureProject(context = false): string {
  const root = mkdtempSync(join(tmpdir(), "codex-factory-repair-"));
  initializeConfig(root, { multiAgent: true, externalContext: context, maxThreads: 4 });
  if (context) initializeContextSpace(root);
  return root;
}

/** Offline host fixtures only. Filesystem checks and Factory receipts use the real runtime. */
export function completeFixtureRun(root: string, runId: string, proposal: "PASS" | "FAIL", artifactContent?: string): void {
  const plan = prepareSpawnPlan(root, readTaskGraphSnapshot(root, runId).tasks, runId);
  const worker = plan.assignments.find((item) => item.task_id === "worker");
  assert.ok(worker);
  const register = (assignmentId: string, nativeId: string): void => {
    registerNativeDispatch(root, runId, assignmentId, {
      nativeAgentId: nativeId, rawToolReceipt: { tool_name: "spawn_agent", agent_id: nativeId, status: "spawned" },
    });
  };
  register(worker.assignment_id, "fixture-worker-" + runId);
  writeFileSync(join(root, "artifact.txt"), artifactContent ?? "Offline fixture output " + runId + "\n");
  recordAgentHandoff(root, runId, worker.assignment_id, {
    summary: "Offline fixture worker handoff", changed_paths: ["artifact.txt"],
    artifacts: [{ path: "artifact.txt", sha256: sha256(readFileSync(join(root, "artifact.txt"))) }],
    commands: [], proposed_verdict: "PASS",
  });
  const review = prepareSpawnPlan(root, readTaskGraphSnapshot(root, runId).tasks, runId);
  const verifier = review.assignments.find((item) => item.profile_id === "factory_verifier");
  assert.ok(verifier);
  register(verifier.assignment_id, "fixture-verifier-" + runId);
  recordAgentHandoff(root, runId, verifier.assignment_id, {
    summary: "Offline independent verifier fixture", changed_paths: [], artifacts: [], commands: [], proposed_verdict: proposal,
  });
  assert.equal(verifyTaskCompletion(root, runId, "worker", verifier.assignment_id).verdict, proposal);
}

export function failedFixture(root: string, runId = "original"): string {
  prepareSpawnPlan(root, [repairTask()], runId);
  completeFixtureRun(root, runId, "FAIL");
  return runId;
}
