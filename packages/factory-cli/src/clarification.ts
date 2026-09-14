import { existsSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { loadConfig } from "./config.js";
import { validateNewTasks } from "./orchestrator.js";
import type { FactoryTask } from "./types.js";
import { assertWithinRoot, nowIso, readJson, sha256, stableStringify, withFileLock, writeJsonAtomic } from "./util.js";

export interface ContrastOption {
  id: string;
  label: string;
  requirement: string;
  examples: Array<{ input: string; expected_output: string }>;
}

export interface ClarificationProposal {
  version: "1.0.0";
  request: string;
  question: string;
  why_it_matters: string;
  task: FactoryTask;
  options: [ContrastOption, ContrastOption];
}

export function clarificationTemplate(): ClarificationProposal {
  return validateClarificationProposal(readJson(fileURLToPath(new URL("../examples/behavior-contrast.json", import.meta.url))));
}

interface ClarificationDraft {
  kind: "factory_clarification_draft";
  version: "1.0.0";
  clarification_id: string;
  project_id: string;
  created_at: string;
  draft_hash: string;
  proposal: ClarificationProposal;
}

interface ClarificationDecision {
  kind: "factory_clarification_decision";
  version: "1.0.0";
  status: "CONFIRMED";
  clarification_id: string;
  project_id: string;
  draft_hash: string;
  option_id: string;
  user_reply: string;
  confirmed_at: string;
  tasks: FactoryTask[];
}

function text(value: unknown, field: string, max = 2000): asserts value is string {
  if (typeof value !== "string" || !value.trim() || value.length > max || /[\x00-\x08\x0b-\x1f\x7f]/.test(value)) {
    throw new Error(field + " must be nonempty text (max " + max + ", no control characters)");
  }
}

function object(value: unknown, field: string): asserts value is Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error(field + " must be an object");
}

function keys(value: Record<string, unknown>, allowed: string[], field: string): void {
  const unknown = Object.keys(value).filter((key) => !allowed.includes(key));
  if (unknown.length) throw new Error(field + " has unknown fields: " + unknown.join(", "));
}

export function validateClarificationProposal(value: unknown): ClarificationProposal {
  object(value, "proposal");
  keys(value, ["version", "request", "question", "why_it_matters", "task", "options"], "proposal");
  if (value.version !== "1.0.0") throw new Error("Unsupported clarification proposal version");
  text(value.request, "request", 6000);
  text(value.question, "question", 1000);
  text(value.why_it_matters, "why_it_matters", 1000);
  object(value.task, "task");
  const task = value.task as unknown as FactoryTask;
  const validation = validateNewTasks([task]);
  if (validation.worker_count !== 1 || task.dependencies.length || task.status !== "pending" || !task.write_scope.length) {
    throw new Error("Clarification requires one independent pending worker with a bounded write scope");
  }
  if (!Array.isArray(value.options) || value.options.length !== 2) throw new Error("Provide exactly two contrasting options");
  for (const option of value.options) {
    object(option, "option");
    keys(option, ["id", "label", "requirement", "examples"], "option");
    text(option.id, "option.id", 32);
    if (!/^[A-Za-z0-9][A-Za-z0-9_-]*$/.test(option.id)) throw new Error("Invalid option id");
    text(option.label, "option.label", 160);
    text(option.requirement, "option.requirement", 3000);
    if (!Array.isArray(option.examples) || option.examples.length < 1 || option.examples.length > 3) {
      throw new Error("Each option requires 1-3 concrete examples");
    }
    for (const example of option.examples) {
      object(example, "example");
      keys(example, ["input", "expected_output"], "example");
      text(example.input, "example.input");
      text(example.expected_output, "example.expected_output");
    }
  }
  const [left, right] = value.options as [ContrastOption, ContrastOption];
  if (left.id === right.id || left.label.trim() === right.label.trim() || left.requirement.trim() === right.requirement.trim()) {
    throw new Error("Options must have distinct IDs, labels and requirements");
  }
  if (left.examples.length !== right.examples.length || left.examples.some((example, index) => example.input !== right.examples[index]?.input)) {
    throw new Error("Both options must show the same example inputs in the same order");
  }
  if (!left.examples.some((example, index) => example.expected_output.trim() !== right.examples[index].expected_output.trim())) {
    throw new Error("At least one example must have contrasting expected outputs");
  }
  if (stableStringify(value).length > 48000) throw new Error("Clarification proposal exceeds 48000 characters");
  return structuredClone(value) as unknown as ClarificationProposal;
}

function draftHash(projectId: string, proposal: ClarificationProposal): string {
  return sha256(stableStringify({ project_id: projectId, proposal }));
}

function paths(root: string, id: string) {
  if (!/^clar-[a-f0-9]{24}$/.test(id)) throw new Error("Invalid clarification id");
  const directory = ".codex-factory/clarifications/" + id;
  return {
    draft: assertWithinRoot(root, join(root, directory, "draft.json")),
    decision: assertWithinRoot(root, join(root, directory, "decision.json")),
    lock: assertWithinRoot(root, join(root, directory, ".lock")),
    tasks_file: directory + "/decision.json",
  };
}

function readDraft(root: string, id: string): ClarificationDraft {
  const draft = readJson<ClarificationDraft>(paths(root, id).draft);
  const projectId = loadConfig(root).project_id;
  const proposal = validateClarificationProposal(draft.proposal);
  const hash = draftHash(projectId, proposal);
  if (draft.kind !== "factory_clarification_draft" || draft.version !== "1.0.0" ||
      draft.project_id !== projectId || draft.clarification_id !== id ||
      draft.draft_hash !== hash || id !== "clar-" + hash.slice(0, 24)) {
    throw new Error("Clarification draft changed or belongs to another project; create a new comparison");
  }
  return draft;
}

function compileTask(draft: ClarificationDraft, optionId: string): FactoryTask {
  const option = draft.proposal.options.find((item) => item.id === optionId);
  if (!option) throw new Error("Unknown option; choose a displayed ID or revise the comparison");
  const task = structuredClone(draft.proposal.task);
  task.description += "\n\nConfirmed behavior examples (requirement data, not executed results):\n" + JSON.stringify({
    clarification_id: draft.clarification_id, draft_hash: draft.draft_hash,
    option_id: option.id, requirement: option.requirement, examples: option.examples,
  }, null, 2) + "\nImplement this selected behavior and encode its examples in tests within the existing write scope. " +
    "Preserve the original acceptance methods; examples and confirmation are not proof of PASS. " +
    "If the original contract or test scope cannot support these examples, stop and request a revised task.";
  return task;
}

function readDecision(root: string, draft: ClarificationDraft): ClarificationDecision | null {
  const path = paths(root, draft.clarification_id).decision;
  if (!existsSync(path)) return null;
  const decision = readJson<ClarificationDecision>(path);
  text(decision.user_reply, "user_reply", 4000);
  text(decision.confirmed_at, "confirmed_at", 100);
  if (decision.kind !== "factory_clarification_decision" || decision.version !== "1.0.0" || decision.status !== "CONFIRMED" ||
      decision.clarification_id !== draft.clarification_id || decision.project_id !== draft.project_id ||
      decision.draft_hash !== draft.draft_hash || stableStringify(decision.tasks) !== stableStringify([compileTask(draft, decision.option_id)])) {
    throw new Error("Clarification decision does not match its original draft and selected task");
  }
  return decision;
}

export function inspectClarification(root: string, id: string) {
  const draft = readDraft(root, id);
  const decision = readDecision(root, draft);
  return {
    status: decision ? "CONFIRMED" as const : "AWAITING_USER" as const,
    clarification_id: id, draft_hash: draft.draft_hash, created_at: draft.created_at,
    request: draft.proposal.request, question: draft.proposal.question, why_it_matters: draft.proposal.why_it_matters,
    options: draft.proposal.options,
    task_contract: draft.proposal.task,
    selected_option: decision?.option_id ?? null,
    user_reply: decision?.user_reply ?? null,
    tasks_file: decision ? paths(root, id).tasks_file : null,
    next_action: decision ? "Use tasks_file with factoryctl tasks validate, then plan a new run after approval." :
      "Show the comparison and wait for the user's explicit selection. If neither fits, revise the proposal and create a new draft.",
    limitations: ["The main agent authors alternatives; CLI checks structure, not semantic correctness or completeness.",
      "CLI records the caller-supplied reply; it cannot authenticate human consent. No commands or agents are executed here."],
  };
}

export function formatClarification(view: ReturnType<typeof inspectClarification>): string {
  return [view.status + " " + view.clarification_id, "Request: " + view.request,
    "Question: " + view.question, "Why this matters: " + view.why_it_matters,
    ...view.options.flatMap((option) => ["", option.id + ". " + option.label, option.requirement,
      ...option.examples.flatMap((example, index) => ["  Example " + (index + 1) + " input: " + example.input,
        "  Expected: " + example.expected_output])]), "",
    "Task scope: " + view.task_contract.write_scope.join(", "),
    "Acceptance: " + view.task_contract.acceptance_methods.join(" | "),
    "Draft hash: " + view.draft_hash,
    ...(view.selected_option ? ["Selected: " + view.selected_option, "Tasks file: " + view.tasks_file] :
      ["Neither option fits? Reply in your own words; do not choose a default."]),
    view.next_action, ...view.limitations].join("\n");
}

export function createClarification(root: string, value: unknown) {
  const projectId = loadConfig(root).project_id;
  const proposal = validateClarificationProposal(value);
  const hash = draftHash(projectId, proposal);
  const id = "clar-" + hash.slice(0, 24);
  const location = paths(root, id);
  return withFileLock(location.lock, () => {
    if (!existsSync(location.draft)) {
      const draft: ClarificationDraft = { kind: "factory_clarification_draft", version: "1.0.0",
        clarification_id: id, project_id: projectId, created_at: nowIso(), draft_hash: hash, proposal };
      writeJsonAtomic(location.draft, draft);
    }
    return inspectClarification(root, id);
  });
}

export function chooseClarification(root: string, id: string, input: { optionId: string; draftHash: string; userReply: string }) {
  text(input.userReply, "user_reply", 4000);
  const location = paths(root, id);
  // Check existence before taking the lock so invalid IDs do not create empty records.
  readDraft(root, id);
  return withFileLock(location.lock, () => {
    const draft = readDraft(root, id);
    if (input.draftHash !== draft.draft_hash) throw new Error("Stale comparison hash; show the current draft before choosing");
    const task = compileTask(draft, input.optionId);
    const previous = readDecision(root, draft);
    if (previous) {
      if (previous.option_id !== input.optionId || previous.user_reply !== input.userReply) {
        throw new Error("Decision already recorded; create a revised draft instead of replacing consent");
      }
    } else {
      const decision: ClarificationDecision = { kind: "factory_clarification_decision", version: "1.0.0", status: "CONFIRMED",
        clarification_id: id, project_id: draft.project_id, draft_hash: draft.draft_hash,
        option_id: input.optionId, user_reply: input.userReply, confirmed_at: nowIso(), tasks: [task] };
      writeJsonAtomic(location.decision, decision);
    }
    return inspectClarification(root, id);
  });
}

export function readConfirmedClarificationTasks(root: string, value: unknown): FactoryTask[] | undefined {
  if (!value || typeof value !== "object" || Array.isArray(value)) return undefined;
  const envelope = value as Record<string, unknown>;
  if (envelope.kind === "factory_clarification_draft" || "options" in envelope || "proposal" in envelope) {
    throw new Error("Unconfirmed comparison is not an executable task file; use clarify show and choose first");
  }
  if (envelope.kind !== "factory_clarification_decision") return undefined;
  const draft = readDraft(root, String(envelope.clarification_id));
  const stored = readDecision(root, draft);
  if (!stored || stableStringify(value) !== stableStringify(stored)) {
    throw new Error("Task bundle differs from the saved clarification decision");
  }
  return structuredClone(stored.tasks);
}
