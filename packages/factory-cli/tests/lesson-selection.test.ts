import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { readFileSync, rmSync, writeFileSync } from "node:fs";
import { basename, dirname, join, resolve } from "node:path";
import { tmpdir } from "node:os";
import { it, type TestContext } from "node:test";
import { fileURLToPath } from "node:url";
import { createLessonSelectionFixture, lessonSelectionCases, selectionTask } from "../evals/lesson-selection-fixture.js";
import { applyTeachingToTasks, listTeachingLessons, suggestTeachingLessons } from "../src/teaching.js";
import { runFileSnapshot } from "../src/repair-store.js";
import { writeJsonAtomic } from "../src/util.js";
import { FACTORY_SKILL_CONTENT } from "../src/installer.js";

function fixture(t: TestContext) {
  const result = createLessonSelectionFixture();
  t.after(() => {
    assert.equal(dirname(result.root), resolve(tmpdir()));
    assert.ok(basename(result.root).startsWith("factory-lesson-selection-"));
    rmSync(result.root, { recursive: true, force: true });
  });
  return result;
}

it("suggests from a task through the CLI and leaves source, task and learned rules unchanged", (t) => {
  const { root, ids } = fixture(t);
  const task = selectionTask(lessonSelectionCases[0]);
  writeJsonAtomic(join(root, "tasks.json"), [task]);
  const before = runFileSnapshot(root, root);
  const command = spawnSync(process.execPath, ["--import", "tsx", fileURLToPath(new URL("../src/cli.ts", import.meta.url)),
    "teach", "suggest", "--project", root, "--tasks", "tasks.json", "--task", task.task_id, "--json"],
    { encoding: "utf8", windowsHide: true });
  assert.equal(command.status, 0, command.stderr);
  const result = JSON.parse(command.stdout) as ReturnType<typeof suggestTeachingLessons>;
  assert.equal(result.candidates[0].lesson_id, ids.zero);
  assert.ok(result.candidates[0].matched_terms.includes("zero"));
  assert.equal(result.candidates[0].review_required, true);
  assert.match(FACTORY_SKILL_CONTENT, /factoryctl teach suggest/);
  assert.match(FACTORY_SKILL_CONTENT, /controller must reject inapplicable candidates/);
  assert.equal(Object.hasOwn(result.candidates[0], "preview"), false);
  assert.equal(runFileSnapshot(root, root), before);
  const applied = applyTeachingToTasks(root, result.candidates[0].lesson_id, [task], task.task_id,
    "OFFLINE: numeric zero is valid here; the empty display-name exclusion does not apply.");
  assert.ok(applied.tasks[0].description.startsWith(task.description));
  assert.deepEqual({ ...applied.tasks[0], description: task.description }, task);
  assert.throws(() => suggestTeachingLessons(root, applied.tasks, task.task_id), /original task/);
});

it("reports exclusions as review clues, permits no match and supports Chinese term overlap without claiming semantics", (t) => {
  const { root, ids } = fixture(t);
  const evaluate = (id: string) => {
    const task = selectionTask(lessonSelectionCases.find((item) => item.id === id)!);
    return suggestTeachingLessons(root, [task], task.task_id);
  };
  assert.equal(evaluate("unrelated").candidates.length, 0);
  const excluded = evaluate("message-exclusion").candidates.find((lesson) => lesson.lesson_id === ids.bom)!;
  assert.ok(excluded);
  assert.ok(excluded.boundary_overlap_terms.includes("messages"));
  assert.equal(excluded.review_required, true);
  assert.equal(evaluate("unicode-chinese").candidates[0].lesson_id, ids.unicode);
  assert.equal(evaluate("paraphrase").status, "NO_LEXICAL_MATCH");
});

it("excludes changed skills and validates task state, limits and partial catalogs", (t) => {
  const { root, ids } = fixture(t);
  const task = selectionTask(lessonSelectionCases[0]);
  const lesson = listTeachingLessons(root).lessons.find((entry) => entry.lesson_id === ids.zero)!;
  const skill = join(root, lesson.skill_path!);
  const original = readFileSync(skill, "utf8");
  writeFileSync(skill, "User revised this rule.");
  assert.ok(!suggestTeachingLessons(root, [task], task.task_id).candidates.some((entry) => entry.lesson_id === ids.zero));
  assert.equal(readFileSync(skill, "utf8"), "User revised this rule.");
  writeFileSync(skill, original);
  writeJsonAtomic(join(root, ".codex-factory/teaching/drafts", "lesson-" + "f".repeat(24), "draft.json"), {});
  const partial = suggestTeachingLessons(root, [task], task.task_id);
  assert.equal(partial.status, "PARTIAL");
  assert.equal(partial.unreadable_records.length, 1);
  assert.equal(partial.candidates[0].lesson_id, ids.zero);
  for (const limit of [0, 6, 1.5]) assert.throws(() => suggestTeachingLessons(root, [task], task.task_id, limit), /limit/);
  assert.throws(() => suggestTeachingLessons(root, [{ ...task, status: "in_progress" }], task.task_id), /pending\/ready/);
});
