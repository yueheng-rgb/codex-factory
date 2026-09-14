import { existsSync } from "node:fs";
import { join } from "node:path";
import { readJson, sha256, stableStringify, withFileLock, writeJsonAtomic } from "../src/util.js";

export interface BudgetObservation {
  tool: string;
  started_at: string;
  returned_at: string;
  response: {
    agent_id?: string;
    status?: Record<string, { completed?: string; errored?: string } | string>;
    [key: string]: unknown;
  };
}

interface Admission {
  run_id: string;
  assignment_id: string;
  role: "worker" | "verifier";
  round: number;
  admitted_at: number;
  agent_id: string | null;
  ended_at: number | null;
  terminal: string | null;
  stop_requested: boolean;
  observations: Array<{ sha256: string; raw: BudgetObservation }>;
}

interface Budget {
  version: 1;
  limit_ms: number;
  max_rounds: number;
  started_at: number | null;
  updated_at: number;
  admissions: Admission[];
}

const minimumWait = 10_000;
export const budgetPath = (root: string) => join(root, ".codex-factory", "eval-budget.json");
export const hasBudget = (root: string) => existsSync(budgetPath(root));
const active = (budget: Budget) => budget.admissions.find((entry) => entry.ended_at === null);

function update<T>(root: string, now: number, action: (budget: Budget) => T): T {
  return withFileLock(budgetPath(root) + ".lock", () => {
    const budget = readJson<Budget>(budgetPath(root));
    if (budget.version !== 1 || !Number.isSafeInteger(now) || now < budget.updated_at) throw new Error("Invalid budget version or clock moved backwards");
    const result = action(budget);
    budget.updated_at = now;
    writeJsonAtomic(budgetPath(root), budget);
    return result;
  });
}

export function initializeBudget(root: string, limitMs = 1_200_000, maxRounds = 2, now = Date.now()) {
  if (!Number.isSafeInteger(limitMs) || limitMs < minimumWait || !Number.isSafeInteger(maxRounds) || maxRounds < 1) throw new Error("Invalid evaluation budget");
  return withFileLock(budgetPath(root) + ".lock", () => {
    if (hasBudget(root)) throw new Error("Budget already exists; do not reset a trial");
    const budget: Budget = { version: 1, limit_ms: limitMs, max_rounds: maxRounds, started_at: null, updated_at: now, admissions: [] };
    writeJsonAtomic(budgetPath(root), budget);
    return budget;
  });
}

export function admitBudget(root: string, runId: string, assignmentId: string, role: "worker" | "verifier", round: number, now = Date.now()) {
  return update(root, now, (budget) => {
    if (active(budget)) throw new Error("Previous admission still active; capture terminal host status before any new dispatch");
    if (!runId || !assignmentId || !["worker", "verifier"].includes(role) || !Number.isInteger(round) || round < 1 || round > budget.max_rounds) throw new Error("Invalid admission or round limit reached");
    if (budget.admissions.some((entry) => entry.assignment_id === assignmentId && entry.run_id === runId)) throw new Error("Assignment already admitted; retries must not reset their budget");
    const previousRound = budget.admissions.at(-1)?.round ?? 0;
    if (role === "worker" ? round !== previousRound + 1 : round !== previousRound || !budget.admissions.some((entry) => entry.round === round && entry.role === "worker" && entry.run_id === runId)) throw new Error("Expected next Worker round, or Verifier for the current Worker run");
    if (budget.admissions.some((entry) => entry.round === round && entry.role === role)) throw new Error("Role already dispatched in this round");
    const deadline = (budget.started_at ?? now) + budget.limit_ms;
    if (deadline - now < minimumWait) throw new Error("Insufficient remaining budget; do not spawn or resume");
    budget.started_at ??= now;
    budget.admissions.push({ run_id: runId, assignment_id: assignmentId, role, round, admitted_at: now,
      agent_id: null, ended_at: null, terminal: null, stop_requested: false, observations: [] });
    return { action: "DISPATCH_ALLOWED", deadline_at: new Date(deadline).toISOString(), remaining_ms: deadline - now };
  });
}

function checkObservation(observation: BudgetObservation, entry: Admission, now: number) {
  const started = Date.parse(observation.started_at);
  const returned = Date.parse(observation.returned_at);
  const last = entry.observations.at(-1);
  if (!observation.response || !Number.isFinite(started) || !Number.isFinite(returned) ||
      started < entry.admitted_at || returned < started || returned > now ||
      (last && returned < Date.parse(last.raw.returned_at))) throw new Error("Invalid or stale budget observation timestamps");
  return returned;
}

export function bindBudgetAgent(root: string, runId: string, assignmentId: string, observation: BudgetObservation, now = Date.now()) {
  return update(root, now, (budget) => {
    const entry = active(budget);
    if (!entry || entry.run_id !== runId || entry.assignment_id !== assignmentId) throw new Error("Missing pre-dispatch budget admission; stop any unadmitted agent");
    checkObservation(observation, entry, now);
    const digest = sha256(stableStringify(observation));
    if (entry.agent_id) {
      if (entry.observations[0]?.sha256 === digest) return advice(budget, now);
      throw new Error("Admission already bound to a different spawn observation");
    }
    if (observation.tool !== "multi_agent_v1__spawn_agent" || typeof observation.response.agent_id !== "string" || !observation.response.agent_id) throw new Error("Expected actual native spawn response");
    entry.agent_id = observation.response.agent_id;
    entry.observations.push({ sha256: digest, raw: observation });
    return advice(budget, now);
  });
}

export function observeBudget(root: string, agentId: string, observation: BudgetObservation, now = Date.now()) {
  return update(root, now, (budget) => {
    const entry = active(budget);
    if (!entry || !agentId || entry.agent_id !== agentId) throw new Error("Observation does not match active budget agent");
    const returned = checkObservation(observation, entry, now);
    if (observation.tool === "multi_agent_v1__close_agent") {
      // A close response reports the previous status, not confirmed termination.
      entry.stop_requested = true;
    } else if (observation.tool === "multi_agent_v1__wait_agent") {
      const status = observation.response.status?.[agentId];
      if (status === undefined) throw new Error("Wait response has no status for budget agent");
      const terminal = status === "shutdown" ? "shutdown" : typeof status === "object" && status !== null
        ? typeof status.completed === "string" ? "completed" : typeof status.errored === "string" ? "errored" : null : null;
      if (terminal) { entry.terminal = terminal; entry.ended_at = returned; }
    } else throw new Error("Budget observation supports native wait or close only; unknown host state must remain unresolved");
    entry.observations.push({ sha256: sha256(stableStringify(observation)), raw: observation });
    return advice(budget, now);
  });
}

export function captureBudgetCompletion(root: string, runId: string, assignmentId: string, agentId: string, observation: BudgetObservation) {
  const budget = readJson<Budget>(budgetPath(root));
  const entry = budget.admissions.find((item) => item.run_id === runId && item.assignment_id === assignmentId && item.agent_id === agentId);
  if (!entry) throw new Error("Handoff has no budget admission");
  const status = observation.response.status?.[agentId];
  if (observation.tool !== "multi_agent_v1__wait_agent" || typeof status !== "object" || status === null || typeof status.completed !== "string") throw new Error("Budgeted handoff requires captured native completion; recovered timing is unresolved");
  if (entry.ended_at !== null) {
    if (entry.terminal !== "completed" || !entry.observations.some((item) => item.sha256 === sha256(stableStringify(observation)))) throw new Error("Handoff differs from terminal budget observation");
    return;
  }
  observeBudget(root, agentId, observation);
}

function advice(budget: Budget, now: number) {
  const entry = active(budget);
  const remaining = Math.max(0, (budget.started_at ?? now) + budget.limit_ms - now);
  const stop = entry && (remaining < minimumWait || entry.stop_requested);
  return { action: !entry ? "IDLE" : stop ? entry.stop_requested ? "CONFIRM_STOP_REQUIRED" : "STOP_REQUIRED" : entry.agent_id ? "WAIT" : "BIND_OR_STOP_REQUIRED",
    agent_id: entry?.agent_id ?? null, remaining_ms: remaining,
    wait_timeout_ms: entry?.agent_id && !stop ? Math.min(30_000, remaining) : null };
}

export function budgetStatus(root: string, now = Date.now()) {
  return update(root, now, (budget) => {
    const entry = active(budget);
    const end = entry ? now : budget.admissions.at(-1)?.ended_at ?? null;
    const elapsed = end !== null && budget.started_at !== null ? end - budget.started_at : null;
    return { ...advice(budget, now), enforcement: "CONTROLLER_COOPERATIVE", timing_basis: "controller_wall_including_waits_no_pause",
      limit_ms: budget.limit_ms, max_rounds: budget.max_rounds, rounds_started: budget.admissions.filter((item) => item.role === "worker").length,
      elapsed_ms: elapsed, overrun_ms: elapsed === null ? null : Math.max(0, elapsed - budget.limit_ms),
      terminal_observed: budget.admissions.length > 0 && !entry,
      within_budget: elapsed === null || entry ? null : elapsed <= budget.limit_ms,
      tokens: null, cost: null, active_execution_ms: null,
      admissions: budget.admissions.map(({ observations, ...item }) => ({ ...item, observation_hashes: observations.map((item) => item.sha256) })) };
  });
}
