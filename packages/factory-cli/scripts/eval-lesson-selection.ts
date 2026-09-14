import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { createLessonSelectionFixture, lessonSelectionCases, selectionTask } from "../evals/lesson-selection-fixture.js";
import { listTeachingLessons, suggestTeachingLessons } from "../src/teaching.js";
import { ensureDirectory, sha256, writeJsonAtomic } from "../src/util.js";

if (process.argv.length > 2) throw new Error("Usage: npm run eval:lessons (fixed public offline cases)");
const packageRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const { root, ids } = createLessonSelectionFixture();
const baseline = listTeachingLessons(root).lessons.filter((entry) => entry.available_for_reuse);
const rows = lessonSelectionCases.map((item) => {
  const task = selectionTask(item);
  const expected = item.expected.map((key) => ids[key]);
  const result = suggestTeachingLessons(root, [task], task.task_id);
  const selected = result.candidates.map((entry) => entry.lesson_id);
  return { case_id: item.id, task, expected_lesson_ids: expected,
    baseline_ids: baseline.map((entry) => entry.lesson_id), suggested_ids: selected,
    relevant_returned: selected.filter((id) => expected.includes(id)).length,
    irrelevant_returned: selected.filter((id) => !expected.includes(id)).length,
    missed_relevant: expected.filter((id) => !selected.includes(id)),
    baseline_candidate_bytes: Buffer.byteLength(JSON.stringify(baseline), "utf8"),
    suggested_candidate_bytes: Buffer.byteLength(JSON.stringify(result.candidates), "utf8"),
    suggestion: result };
});
const sum = (get: (row: typeof rows[number]) => number) => rows.reduce((total, row) => total + get(row), 0);
const correct = sum((row) => row.relevant_returned);
const returned = sum((row) => row.suggested_ids.length);
const relevant = sum((row) => row.expected_lesson_ids.length);
const baselineBytes = sum((row) => row.baseline_candidate_bytes);
const suggestedBytes = sum((row) => row.suggested_candidate_bytes);
const report = { kind: "MEASURED_DETERMINISTIC_FIXTURE_COMPARISON_NOT_AGENT_SUCCESS", fixture_root: root,
  labels: "Public author-labelled development cases, not a held-out or representative task distribution.",
  fixture_sha256: sha256(readFileSync(join(packageRoot, "evals/lesson-selection-fixture.ts"))),
  implementation_sha256: sha256(readFileSync(join(packageRoot, "src/teaching.ts"))),
  case_count: rows.length, catalog_size: baseline.length, generated_at: new Date().toISOString(),
  metrics: { baseline_returned: baseline.length * rows.length, baseline_relevant_returned: relevant,
    suggested_returned: returned, suggested_relevant_returned: correct, suggested_irrelevant_returned: returned - correct,
    total_relevant_labels: relevant, precision: returned ? correct / returned : null, recall: relevant ? correct / relevant : null,
    no_candidate_cases: rows.filter((row) => !row.suggested_ids.length).map((row) => row.case_id),
    baseline_candidate_bytes: baselineBytes, suggested_candidate_bytes: suggestedBytes,
    candidate_bytes_reduction: baselineBytes ? 1 - suggestedBytes / baselineBytes : null }, rows,
  limitations: ["The baseline displays the whole catalog, not a model selecting wrong lessons. Returning metadata is not automatic application.",
    "Bytes measure compact JSON candidate arrays, including shortlist explanations but excluding command envelopes, full rules, subsequent show/apply and model output. Not tokens, cost or end-to-end context savings.",
    "Errors and paraphrase misses are retained. Counts are specific to these four lessons and nine authored cases; no Agent success-rate or causal improvement is measured."] };
ensureDirectory(join(packageRoot, "outputs"));
const directory = mkdtempSync(join(packageRoot, "outputs/lesson-selection-"));
writeJsonAtomic(join(directory, "comparison.json"), report);
const summary = ["# Task-aware Lesson Selection: Fixed Offline Comparison", "", report.labels,
  "", "Catalog lessons: " + baseline.length + "; tasks: " + rows.length,
  "Returned candidates: " + report.metrics.baseline_returned + " (full catalog) -> " + returned + " (shortlist).",
  "Relevant returned: " + correct + "/" + relevant + "; irrelevant returned: " + (returned - correct) + ".",
  "Candidate JSON bytes: " + baselineBytes + " -> " + suggestedBytes + " (" +
    ((report.metrics.candidate_bytes_reduction ?? 0) * 100).toFixed(2) + "% reduction).", "",
  "| Case | Expected | Returned | Relevant returned | Irrelevant returned | Missed |",
  "| --- | --- | --- | --- | --- | --- |",
  ...rows.map((row) => "| " + [row.case_id, row.expected_lesson_ids.length, row.suggested_ids.length,
    row.relevant_returned, row.irrelevant_returned, row.missed_relevant.length].join(" | ") + " |"),
  "", "## Limits", "", ...report.limitations.map((text) => "- " + text), "",
  "[All inputs, labels and outputs](comparison.json)", ""].join("\n");
writeFileSync(join(directory, "README.md"), summary, "utf8");
process.stdout.write(summary + "\nReport: " + join(directory, "README.md") + "\n");
