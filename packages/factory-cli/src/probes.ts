import { closeSync, existsSync, fstatSync, lstatSync, openSync, readSync } from "node:fs";
import { isAbsolute, join, resolve } from "node:path";
import { loadConfig } from "./config.js";
import { assertNoSecrets, assertSafeKnowledgeSourcePath } from "./knowledge.js";
import { prepareRepair } from "./run-management.js";
import { assertWithinRoot, nowIso, parseJsonFileText, readJson, sha256, stableStringify, withFileLock, writeJsonAtomic } from "./util.js";

type Scalar = string | number | boolean | null;
type Channel = "acceptance" | "artifacts" | "reported_commands" | "verifier";

export interface ProbeProposal {
  version: "1.0.0";
  question: string;
  hypotheses: Array<{ id: "H1" | "H2"; cause: string; evidence_refs: Channel[]; expected: Scalar; next_step: string }>;
  observation: { path: string; pointer: string; why_distinguishing: string; provenance: string };
}

interface ProbeData {
  project_id: string;
  from_run: string;
  task_id: string;
  receipt_hash: string;
  proposal: ProbeProposal;
}
interface ProbeDraft {
  version: "1.0.0";
  probe_id: string;
  draft_hash: string;
  created_at: string;
  data: ProbeData;
}
interface ObservationData {
  probe_id: string;
  draft_hash: string;
  observed_at: string;
  user_reply: string;
  file_sha256: string;
  file_mtime: string;
  field_status: "SCALAR" | "MISSING" | "NON_SCALAR";
  value: Scalar;
  matching_hypothesis: "H1" | "H2" | null;
}
interface Observation { data: ObservationData; observation_hash: string }

function text(value: unknown, label: string, max = 2000): asserts value is string {
  if (typeof value !== "string" || !value.trim() || value.length > max || /[\x00-\x08\x0b-\x1f\x7f]/.test(value)) {
    throw new Error(label + " requires bounded nonempty text without control characters");
  }
  assertNoSecrets(value, label);
}
function object(value: unknown, fields: string[]): asserts value is Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value) || Object.keys(value).some((key) => !fields.includes(key))) {
    throw new Error("Invalid probe object or unknown fields");
  }
}
function scalar(value: unknown): value is Scalar {
  return value === null || typeof value === "boolean" ||
    (typeof value === "number" && Number.isFinite(value)) || (typeof value === "string" && value.length <= 1000);
}
function tokens(pointer: unknown): string[] {
  if (typeof pointer !== "string" || pointer.length > 1000 || (pointer !== "" && !pointer.startsWith("/")) || /~[^01]|~$/.test(pointer)) {
    throw new Error("Observation requires an RFC 6901 JSON Pointer, not JSONPath");
  }
  return pointer === "" ? [] : pointer.slice(1).split("/").map((part) => part.replaceAll("~1", "/").replaceAll("~0", "~"));
}
function diagnosticPath(root: string, path: string): string {
  text(path, "diagnostic path", 1000);
  if (isAbsolute(path) || /[\\:*?]/.test(path) || !path.toLowerCase().endsWith(".json") ||
      path.split("/").some((part) => !part || [".", "..", ".git", ".codex", ".agents", ".codex-factory"].includes(part.toLowerCase()))) {
    throw new Error("Select an explicit project-relative diagnostic JSON file outside runtime/instruction state");
  }
  assertSafeKnowledgeSourcePath(path);
  return assertWithinRoot(root, resolve(root, path));
}
function statePath(root: string, id: string, file: string): string {
  if (!/^probe-[a-f0-9]{24}$/.test(id)) throw new Error("Invalid probe ID");
  return assertWithinRoot(root, join(root, ".codex-factory/probes", id, file));
}

export function validateProbeProposal(root: string, value: unknown): asserts value is ProbeProposal {
  object(value, ["version", "question", "hypotheses", "observation"]);
  if (value.version !== "1.0.0") throw new Error("Unsupported probe version");
  text(value.question, "question");
  if (!Array.isArray(value.hypotheses) || value.hypotheses.length !== 2) throw new Error("Provide exactly two hypotheses");
  for (const [index, hypothesis] of value.hypotheses.entries()) {
    object(hypothesis, ["id", "cause", "evidence_refs", "expected", "next_step"]);
    if (hypothesis.id !== "H" + (index + 1)) throw new Error("Hypotheses must be ordered H1, H2");
    text(hypothesis.cause, "cause");
    text(hypothesis.next_step, "next step");
    if (!Array.isArray(hypothesis.evidence_refs) || !hypothesis.evidence_refs.length || hypothesis.evidence_refs.length > 4 ||
        hypothesis.evidence_refs.some((ref) => !["acceptance", "artifacts", "reported_commands", "verifier"].includes(ref))) {
      throw new Error("Reference observed failure channels from repair prepare");
    }
    if (!scalar(hypothesis.expected)) throw new Error("Expected observation must be a bounded JSON scalar");
  }
  if (value.hypotheses[0].expected === value.hypotheses[1].expected) throw new Error("Predictions must differ to distinguish hypotheses");
  object(value.observation, ["path", "pointer", "why_distinguishing", "provenance"]);
  text(value.observation.path, "diagnostic path");
  diagnosticPath(root, value.observation.path);
  tokens(value.observation.pointer);
  text(value.observation.why_distinguishing, "why distinguishing");
  text(value.observation.provenance, "diagnostic provenance");
  assertNoSecrets(JSON.stringify(value), "probe proposal");
}

function source(root: string, data: ProbeData) {
  if (loadConfig(root).project_id !== data.project_id) throw new Error("Probe belongs to a different project");
  const preparation = prepareRepair(root, data.from_run, data.task_id);
  if (preparation.evidence.receipt_hash !== data.receipt_hash) throw new Error("Failed receipt changed; prepare a new probe");
  return preparation;
}

export function createProbeDraft(root: string, fromRun: string, taskId: string, proposal: unknown) {
  validateProbeProposal(root, proposal);
  const preparation = prepareRepair(root, fromRun, taskId);
  if (preparation.status !== "REVIEW_REQUIRED") throw new Error("Follow repair prepare blockers or existing repair before drafting a probe");
  const available: Record<Channel, boolean> = {
    acceptance: preparation.observations.acceptance.failed > 0,
    artifacts: preparation.observations.artifacts.failed > 0,
    reported_commands: preparation.observations.reported_command_failures.total > 0,
    verifier: preparation.observations.verifier_proposal === "FAIL",
  };
  if (proposal.hypotheses.some((item) => item.evidence_refs.some((ref) => !available[ref]))) {
    throw new Error("Referenced failure channel has no observed failure in this receipt");
  }
  const data: ProbeData = { project_id: loadConfig(root).project_id, from_run: fromRun, task_id: taskId,
    receipt_hash: preparation.evidence.receipt_hash, proposal };
  const hash = sha256(stableStringify(data));
  const id = "probe-" + hash.slice(0, 24);
  withFileLock(statePath(root, id, "record.lock"), () => {
    const path = statePath(root, id, "draft.json");
    if (!existsSync(path)) writeJsonAtomic(path, { version: "1.0.0", probe_id: id, draft_hash: hash, created_at: nowIso(), data });
  });
  return inspectProbe(root, id);
}

function readDraft(root: string, id: string): ProbeDraft {
  const draft = readJson<ProbeDraft>(statePath(root, id, "draft.json"));
  if (draft.version !== "1.0.0" || draft.probe_id !== id || draft.draft_hash !== sha256(stableStringify(draft.data)) ||
      id !== "probe-" + draft.draft_hash.slice(0, 24)) throw new Error("Probe draft integrity mismatch");
  validateProbeProposal(root, draft.data.proposal);
  return draft;
}

export function inspectProbe(root: string, id: string) {
  const draft = readDraft(root, id);
  const preparation = source(root, draft.data);
  const path = statePath(root, id, "observation.json");
  const observation = existsSync(path) ? readJson<Observation>(path) : null;
  if (observation && (observation.data.probe_id !== id || observation.data.draft_hash !== draft.draft_hash ||
      observation.observation_hash !== sha256(stableStringify(observation.data)))) throw new Error("Probe observation integrity mismatch");
  const matched = observation?.data.matching_hypothesis;
  return { status: observation ? (matched ? "MATCHED_PREDICTION" : "INCONCLUSIVE") : "REVIEW_REQUIRED",
    draft, observation, draft_path: ".codex-factory/probes/" + id + "/draft.json",
    observation_path: observation ? ".codex-factory/probes/" + id + "/observation.json" : null,
    source_evidence: preparation.evidence, source_verdict: preparation.source_verdict, repair: preparation.repair,
    next_step: observation ? (matched ? draft.data.proposal.hypotheses.find((item) => item.id === matched)!.next_step :
      "Review diagnostic provenance and revise hypotheses; do not select a cause from this observation.") :
      "Review both predictions, diagnostic provenance and the exact draft hash with the user before observing.",
    limitations: ["A matching prediction is a lead, not causal proof. Hypotheses and diagnostic provenance are controller-authored.",
      "Reads one existing JSON file, not a live experiment. File hashes do not prove freshness or producer identity.",
      "No command execution, product writes, repair reservation, native dispatch or acceptance changes.",
      "One observation per draft; repeat calls return history. Approval text is not authenticated human identity."],
  };
}

export function prepareProbeRepair(root: string, id: string) {
  const view = inspectProbe(root, id);
  if (view.status !== "MATCHED_PREDICTION" || !view.observation) {
    throw new Error("A repair lead requires a saved matching prediction; unobserved or inconclusive probes cannot select a cause");
  }
  const preparation = source(root, view.draft.data);
  const hypothesis = view.draft.data.proposal.hypotheses.find((item) => item.id === view.observation!.data.matching_hypothesis)!;
  const guidance = ["[Factory probe lead " + id + "]",
    "A historical matching prediction, NOT a proven root cause. Review diagnostic provenance before changing code.",
    "Failed receipt: " + preparation.evidence.receipt_path + " (SHA256 " + preparation.evidence.receipt_hash + ")",
    "Probe draft: " + view.draft_path + " (SHA256 " + view.draft.draft_hash + ")",
    "Observation: " + view.observation_path + " (SHA256 " + view.observation.observation_hash + ")",
    "Observed at: " + view.observation.data.observed_at + "; diagnostic SHA256: " + view.observation.data.file_sha256,
    "Diagnostic provenance (controller report): " + view.draft.data.proposal.observation.provenance,
    "Candidate " + hypothesis.id + ": " + hypothesis.cause,
    "Observed " + view.draft.data.proposal.observation.pointer + " = " + JSON.stringify(view.observation.data.value),
    "Investigation direction: " + hypothesis.next_step,
    "Preserve original behavior examples, write_scope, acceptance and required artifacts. Guidance is not repair approval or PASS.",
    "[End Factory probe lead]"].join("\n");
  const tasks = preparation.status === "BLOCKED" ? null :
    preparation.suggested_tasks?.map((task) => ({ ...task, description: task.description + "\n\n" + guidance })) ?? null;
  return { status: preparation.status, from_run: preparation.from_run, task_id: preparation.task_id,
    probe_id: id, tasks, observation_path: view.observation_path, repair: preparation.repair, blockers: preparation.blockers,
    next_actions: preparation.next_actions,
    limitations: ["Read-only task preparation; no repair reserved, no diagnostic rerun and no approval implied.",
      "The task description includes a historical lead, not an established cause. Scope and acceptance remain unchanged.",
      "Existing repairs must be resumed; repair create performs its original locked request and attempt checks."] };
}

function readDiagnostic(root: string, path: string) {
  const absolute = diagnosticPath(root, path);
  const info = lstatSync(absolute);
  if (!info.isFile() || info.isSymbolicLink() || info.size > 65536) throw new Error("Diagnostic must be a regular JSON file no larger than 64 KiB");
  const fd = openSync(absolute, "r");
  try {
    const before = fstatSync(fd);
    if (!before.isFile() || before.size > 65536) throw new Error("Diagnostic file changed or exceeds budget");
    const buffer = Buffer.alloc(65537);
    let length = 0;
    while (length < buffer.length) {
      const count = readSync(fd, buffer, length, buffer.length - length, null);
      if (!count) break;
      length += count;
    }
    const after = fstatSync(fd);
    if (length > 65536 || before.size !== after.size || before.mtimeMs !== after.mtimeMs || before.ctimeMs !== after.ctimeMs) {
      throw new Error("Diagnostic changed during observation or exceeds budget");
    }
    const bytes = buffer.subarray(0, length);
    const content = bytes.toString("utf8");
    if (bytes.includes(0) || !Buffer.from(content).equals(bytes)) throw new Error("Diagnostic must be UTF-8 JSON");
    assertNoSecrets(content, "diagnostic");
    let value: unknown;
    try { value = parseJsonFileText(content); } catch { throw new Error("Diagnostic is not valid JSON"); }
    return { value, hash: sha256(bytes), mtime: after.mtime.toISOString() };
  } finally { closeSync(fd); }
}

export function observeProbe(root: string, id: string, input: { draftHash: string; userReply: string }) {
  text(input.userReply, "approval reply", 3000);
  return withFileLock(statePath(root, id, "record.lock"), () => {
    const view = inspectProbe(root, id);
    if (input.draftHash !== view.draft.draft_hash) throw new Error("Approval must match the reviewed draft hash");
    if (view.observation) return view;
    if (source(root, view.draft.data).status !== "REVIEW_REQUIRED") throw new Error("Repair state changed; review repair prepare before observing");
    const proposal = view.draft.data.proposal;
    const file = readDiagnostic(root, proposal.observation.path);
    let value: unknown = file.value;
    let missing = false;
    for (const token of tokens(proposal.observation.pointer)) {
      if (value === null || typeof value !== "object" || !Object.hasOwn(value, token) ||
          (Array.isArray(value) && !/^(0|[1-9][0-9]*)$/.test(token))) { missing = true; break; }
      value = (value as Record<string, unknown>)[token];
    }
    const fieldStatus = missing ? "MISSING" : scalar(value) ? "SCALAR" : "NON_SCALAR";
    const matching = fieldStatus === "SCALAR" ? proposal.hypotheses.find((item) => item.expected === value)?.id ?? null : null;
    const data: ObservationData = { probe_id: id, draft_hash: view.draft.draft_hash, observed_at: nowIso(), user_reply: input.userReply,
      file_sha256: file.hash, file_mtime: file.mtime, field_status: fieldStatus,
      value: fieldStatus === "SCALAR" ? value as Scalar : null, matching_hypothesis: matching };
    writeJsonAtomic(statePath(root, id, "observation.json"), { data, observation_hash: sha256(stableStringify(data)) });
    return inspectProbe(root, id);
  });
}

export function probeTemplate(): ProbeProposal {
  return { version: "1.0.0", question: "Why did retries=0 still retry?",
    hypotheses: [
      { id: "H1", cause: "Configuration normalization replaced explicit zero with a default.", evidence_refs: ["verifier"],
        expected: 3, next_step: "Inspect defaulting in configuration normalization, keeping the original acceptance contract." },
      { id: "H2", cause: "The retry loop ignores a correctly normalized zero.", evidence_refs: ["verifier"],
        expected: 0, next_step: "Inspect retry-loop termination, keeping the original acceptance contract." },
    ], observation: { path: "diagnostic.json", pointer: "/normalized/retries",
      why_distinguishing: "The two explanations predict different normalized values before the loop starts.",
      provenance: "Replace with how this diagnostic was produced for the failing input and current revision; do not assume freshness." } };
}
