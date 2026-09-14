import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { admitBudget, bindBudgetAgent, budgetStatus, initializeBudget, observeBudget } from "../scripts/eval-budget.js";
import type { BudgetObservation } from "../scripts/eval-budget.js";

// Synthetic clock and host responses only. These are not native evaluation runs.
const epoch = Date.parse("2026-09-13T00:00:00Z");
const observation = (tool: string, time: number, response: BudgetObservation["response"]): BudgetObservation => ({
  tool: "multi_agent_v1__" + tool, started_at: new Date(epoch + time).toISOString(), returned_at: new Date(epoch + time).toISOString(), response,
});
function fixture(run: (root: string) => void) {
  const root = mkdtempSync(join(tmpdir(), "factory-budget-unit-"));
  try { initializeBudget(root, 60_000, 2, epoch); run(root); }
  finally { rmSync(root, { recursive: true, force: true }); }
}
function spawn(root: string, role: "worker" | "verifier", round: number, time: number) {
  const id = role + round;
  admitBudget(root, "run" + round, id, role, round, epoch + time);
  bindBudgetAgent(root, "run" + round, id, observation("spawn_agent", time, { agent_id: id }), epoch + time);
  return id;
}
function complete(root: string, id: string, time: number) {
  observeBudget(root, id, observation("wait_agent", time, { status: { [id]: { completed: "Offline unit fixture" } } }), epoch + time);
}

test("Worker, Verifier and repair share wall budget; idle gaps and waits are charged", () => fixture((root) => {
  const worker = spawn(root, "worker", 1, 0);
  complete(root, worker, 10_000);
  const verifier = spawn(root, "verifier", 1, 20_000);
  assert.equal(budgetStatus(root, epoch + 25_000).remaining_ms, 35_000);
  complete(root, verifier, 30_000);
  const repair = spawn(root, "worker", 2, 35_000);
  assert.equal(budgetStatus(root, epoch + 45_000).wait_timeout_ms, 15_000);
  complete(root, repair, 46_000);
  assert.throws(() => spawn(root, "worker", 3, 47_000), /round limit/);
  const status = budgetStatus(root, epoch + 48_000);
  assert.equal(status.elapsed_ms, 46_000);
  assert.equal(status.rounds_started, 2);
  assert.equal(status.within_budget, true);
  assert.equal(status.tokens, null);
  assert.equal(status.cost, null);
  assert.equal(status.active_execution_ms, null);
}));

test("deadline asks for stop; close is not terminal and late shutdown preserves overrun", () => fixture((root) => {
  const worker = spawn(root, "worker", 1, 0);
  assert.equal(budgetStatus(root, epoch + 51_000).action, "STOP_REQUIRED");
  assert.equal(budgetStatus(root, epoch + 51_000).wait_timeout_ms, null);
  observeBudget(root, worker, observation("close_agent", 52_000, { previous_status: "running" }), epoch + 52_000);
  assert.equal(budgetStatus(root, epoch + 53_000).action, "CONFIRM_STOP_REQUIRED");
  assert.throws(() => spawn(root, "worker", 2, 54_000), /still active/);
  observeBudget(root, worker, observation("wait_agent", 65_000, { status: { [worker]: "shutdown" } }), epoch + 65_000);
  const status = budgetStatus(root, epoch + 66_000);
  assert.equal(status.terminal_observed, true);
  assert.equal(status.overrun_ms, 5_000);
  assert.equal(status.within_budget, false);
  assert.throws(() => spawn(root, "worker", 2, 67_000), /Insufficient/);
}));

test("no clock rollback, reset, overlapping admission, or unadmitted spawn", () => fixture((root) => {
  assert.throws(() => initializeBudget(root), /already exists/);
  assert.throws(() => bindBudgetAgent(root, "run1", "worker1", observation("spawn_agent", 0, { agent_id: "worker1" }), epoch), /Missing pre-dispatch/);
  const worker = spawn(root, "worker", 1, 0);
  assert.throws(() => spawn(root, "worker", 2, 1), /still active/);
  assert.throws(() => observeBudget(root, "different", observation("wait_agent", 2, { status: {} }), epoch + 2), /does not match/);
  assert.throws(() => observeBudget(root, worker, observation("wait_agent", 3, { status: {} }), epoch + 3), /no status/);
  complete(root, worker, 10_000);
  assert.throws(() => budgetStatus(root, epoch + 5_000), /backwards/);
  assert.throws(() => spawn(root, "worker", 1, 11_000), /already admitted/);
}));

test("a slow spawn retains its agent ID and demands stop; future or stale captures are rejected", () => fixture((root) => {
  admitBudget(root, "run1", "worker1", "worker", 1, epoch);
  assert.equal(budgetStatus(root, epoch + 1).action, "BIND_OR_STOP_REQUIRED");
  assert.throws(() => bindBudgetAgent(root, "run1", "worker1", observation("spawn_agent", 80_000, { agent_id: "worker1" }), epoch + 70_000), /timestamps/);
  const advice = bindBudgetAgent(root, "run1", "worker1", observation("spawn_agent", 70_000, { agent_id: "worker1" }), epoch + 70_000);
  assert.equal(advice.action, "STOP_REQUIRED");
  assert.equal(advice.agent_id, "worker1");
  assert.throws(() => complete(root, "worker1", 69_000), /backwards/);
}));

test("empty and unknown host states do not become successful measurements", () => fixture((root) => {
  assert.equal(budgetStatus(root, epoch).within_budget, null);
  assert.equal(budgetStatus(root, epoch).elapsed_ms, null);
  const worker = spawn(root, "worker", 1, 0);
  observeBudget(root, worker, observation("wait_agent", 1, { status: { [worker]: "not_found" } }), epoch + 1);
  assert.equal(budgetStatus(root, epoch + 2).terminal_observed, false);
  assert.equal(budgetStatus(root, epoch + 2).within_budget, null);
}));
