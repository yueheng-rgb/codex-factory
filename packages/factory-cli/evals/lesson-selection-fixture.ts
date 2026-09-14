import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { initializeConfig } from "../src/config.js";
import { captureTeachingSource, createTeachingDraft, publishTeachingSkill, type TeachingProposal } from "../src/teaching.js";
import type { FactoryTask } from "../src/types.js";

const definitions = [
  { id: "zero", name: "preserve-zero", description: "Preserve explicit zero in JavaScript numeric options with nullish defaults.",
    applies: "A numeric timeout or retry option accepts zero; only null or undefined triggers its default.",
    excludes: "An empty display name string intentionally triggers a fallback; do not apply numeric nullish rules.",
    before: "export const retries = value => value || 3;\n", after: "export const retries = value => value ?? 3;\n",
    method: "Use nullish coalescing for validated numeric values; retain the task's own default.",
    example: "timeoutMs=0 disables the timeout", expected: "Keep zero instead of substituting 1000.",
    counter: "A display name falls back on an empty string", counterExpected: "Retain the empty-string fallback, not nullish numeric zero semantics." },
  { id: "bom", name: "file-json-bom", description: "Read local UTF-8 JSON files with a single leading BOM while retaining original bytes.",
    applies: "A local JSON file reader needs explicit compatibility with a leading UTF-8 BOM.",
    excludes: "Strict network JSON messages reject leading BOM markers. Do not apply file tolerance to messages.",
    before: "export const parseFileText = text => JSON.parse(text);\n",
    after: "export const parseFileText = text => JSON.parse(text.startsWith('\uFEFF') ? text.slice(1) : text);\n",
    method: "Strip exactly one leading file BOM from decoded text, without rewriting original bytes or changing message parsing.",
    example: "A saved preferences file starts with a BOM", expected: "Read its JSON value and retain the file bytes.",
    counter: "A strict JSON network message starts with a BOM", counterExpected: "Reject it; file compatibility is not message compatibility." },
  { id: "unicode", name: "unicode-tags", description: "Normalize Unicode tags to NFC before stable deduplication. \u6807\u7b7e\u89c4\u8303\u5316\u540e\u53bb\u91cd\u3002",
    applies: "Canonical Unicode equivalence defines duplicate tags; retain their first appearance and the original input array.",
    excludes: "Opaque identifiers and passwords require exact original code points, not Unicode tag normalization.",
    before: "export const tags = values => [...new Set(values)];\n",
    after: "export const tags = values => [...new Set(values.map(value => value.normalize('NFC')))];\n",
    method: "Normalize each tag to NFC before stable deduplication without mutating the input array.",
    example: "Two labels use composed and decomposed accents", expected: "Return one normalized tag in first-seen order.",
    counter: "Opaque identifiers differ in their original code points", counterExpected: "Keep the identifiers distinct; do not normalize them." },
  { id: "pagination", name: "bounded-page-size", description: "Clamp finite numeric page size to an integer in the inclusive range 1 to 100.",
    applies: "A list API accepts finite page size input and promises a bounded positive integer result.",
    excludes: "Zero-based page index is not page size; preserve index zero rather than clamping it to one.",
    before: "export const pageSize = size => size;\n",
    after: "export const pageSize = size => Math.min(100, Math.max(1, Math.trunc(size)));\n",
    method: "Truncate and clamp validated finite page size; do not reuse the rule for a page index.",
    example: "Page size is 150.5", expected: "Use 100 for this API's configured limit.",
    counter: "The first page has index zero", counterExpected: "Preserve zero; index and size have different contracts." },
];

export const lessonSelectionCases = [
  { id: "zero-positive", title: "Preserve zero timeout", description: "JavaScript numeric timeout option: accept zero, default only when null or undefined.", expected: ["zero"] },
  { id: "bom-positive", title: "Read local JSON preferences", description: "Read UTF-8 JSON files with a leading BOM; preserve original bytes.", expected: ["bom"] },
  { id: "unicode-positive", title: "Deduplicate normalized Unicode tags", description: "Normalize canonically equivalent tag strings before deduplication; retain original input array.", expected: ["unicode"] },
  { id: "pagination-positive", title: "Bound list pagination", description: "Page size must be an integer clamped to 100. Preserve zero-based page index.", expected: ["pagination"] },
  { id: "unrelated", title: "Compute triangle area", description: "Compute half the product of base and height.", expected: [] },
  { id: "message-exclusion", title: "Strict JSON message parsing", description: "Reject a leading BOM in network JSON messages; do not apply file tolerance.", expected: [] },
  { id: "zero-exclusion", title: "Display-name fallback", description: "Empty string should fall back. Do not use nullish numeric zero semantics.", expected: [] },
  { id: "unicode-chinese", title: "\u6807\u7b7e\u53bb\u91cd", description: "\u5148\u5bf9 Unicode \u6807\u7b7e\u505a NFC \u89c4\u8303\u5316\uff0c\u518d\u53bb\u91cd\uff0c\u4fdd\u7559\u8f93\u5165\u987a\u5e8f\u3002", expected: ["unicode"] },
  { id: "paraphrase", title: "Retain disabled timers", description: "Missing duration uses a preset; the disabling value stays unchanged.", expected: ["zero"] },
];

export function selectionTask(item: typeof lessonSelectionCases[number]): FactoryTask {
  return { task_id: item.id, title: item.title, description: item.description, role: "implementation", status: "pending",
    dependencies: [], write_scope: ["artifact.txt"], required_artifacts: ["artifact.txt"], acceptance_methods: ["exists:artifact.txt"] };
}

/** Public, pre-authored development fixtures only; not held-out Agent tasks. */
export function createLessonSelectionFixture() {
  const root = mkdtempSync(join(tmpdir(), "factory-lesson-selection-"));
  mkdirSync(join(root, "empty-hooks"));
  const git = (args: string[]) => {
    const result = spawnSync("git", ["-c", "user.name=Offline Fixture", "-c", "user.email=fixture@example.invalid",
      "-c", "core.hooksPath=" + join(root, "empty-hooks"), "-c", "core.fsmonitor=false", ...args],
      { cwd: root, windowsHide: true, shell: false, encoding: "utf8" });
    if (result.status !== 0 || result.error) throw new Error("Offline fixture Git setup failed");
  };
  git(["init", "--quiet"]);
  git(["config", "core.autocrlf", "false"]);
  for (const d of definitions) writeFileSync(join(root, d.id + ".js"), d.before);
  git(["add", "--", ...definitions.map((d) => d.id + ".js")]);
  git(["commit", "--quiet", "--no-gpg-sign", "-m", "Offline lesson selection fixtures"]);
  initializeConfig(root, { multiAgent: false, externalContext: false });
  const ids: Record<string, string> = {};
  for (const d of definitions) {
    writeFileSync(join(root, d.id + ".js"), d.after);
    const source = captureTeachingSource(root, { path: d.id + ".js", note: "OFFLINE authored fixture: " + d.description });
    const proposal: TeachingProposal = { version: "1.0.0", name: d.name, description: d.description,
      applies_when: [d.applies], do_not_apply_when: [d.excludes],
      rules: [{ instruction: d.method, before_excerpt: d.before.trim(), after_excerpt: d.after.trim(), rationale: d.method }],
      example: { scenario: d.example, expected_behavior: d.expected },
      counterexample: { scenario: d.counter, expected_behavior: d.counterExpected } };
    const draft = createTeachingDraft(root, source.source_id, proposal);
    publishTeachingSkill(root, draft.draft_id, { draftHash: draft.draft_hash, userReply: "OFFLINE fixture approval, not user consent" });
    ids[d.id] = draft.draft_id;
  }
  return { root, ids };
}
