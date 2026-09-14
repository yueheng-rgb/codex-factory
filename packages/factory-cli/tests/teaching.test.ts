import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { afterEach, describe, it } from "node:test";
import { fileURLToPath } from "node:url";
import { initializeFactoryProject } from "../src/installer.js";
import { initializeConfig } from "../src/config.js";
import { applyTeachingToTasks, captureTeachingSource, createTeachingDraft, inspectTeachingDraft, listTeachingLessons, publishTeachingSkill,
  teachingTemplate, validateTeachingProposal } from "../src/teaching.js";
import { readJson, writeJsonAtomic } from "../src/util.js";
import { repairTask } from "./helpers/repair-fixture.js";
import { runFileSnapshot } from "../src/repair-store.js";

const roots: string[] = [];
const packageRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const before = "export function retryCount(options) { return options.retries || 3; }\n";
const after = "export function retryCount(options) { return options.retries ?? 3; }\n";
function git(root: string, args: string[]) {
  const result = spawnSync("git", ["-c", "user.name=Factory Offline Fixture", "-c", "user.email=fixture@example.invalid",
    "-c", "core.hooksPath=" + join(root, "empty-hooks"), "-c", "core.fsmonitor=false", ...args],
    { cwd: root, encoding: "utf8", windowsHide: true, shell: false });
  assert.equal(result.status, 0, result.stderr);
  return result.stdout;
}
function project(path = "src/retry.mjs", original: string | Buffer = before, changed: string | Buffer = after) {
  const root = mkdtempSync(join(tmpdir(), "factory-teaching-test-"));
  roots.push(root);
  mkdirSync(join(root, "empty-hooks"));
  mkdirSync(dirname(join(root, path)), { recursive: true });
  git(root, ["init", "--quiet"]);
  git(root, ["config", "core.autocrlf", "false"]);
  writeFileSync(join(root, path), original);
  git(root, ["add", "--", path]);
  git(root, ["commit", "--quiet", "--no-gpg-sign", "-m", "Offline teaching fixture"]);
  initializeConfig(root, { multiAgent: false, externalContext: false });
  writeFileSync(join(root, path), changed);
  return root;
}
function capture(root: string, path = "src/retry.mjs") {
  return captureTeachingSource(root, { path, note: "OFFLINE fixture: retries=0 is valid and must not be replaced by the fallback." });
}
function cli(root: string, args: string[]) {
  return spawnSync(process.execPath, ["--import", "tsx", join(packageRoot, "src/cli.ts"), "--project", root, ...args],
    { encoding: "utf8", windowsHide: true });
}
afterEach(() => { for (const root of roots.splice(0)) rmSync(root, { recursive: true, force: true }); });

describe("diff teaching", () => {
  it("accepts the repository root with either Windows drive-letter case", { skip: process.platform !== "win32" }, () => {
    const root = project();
    assert.match(root, /^[A-Za-z]:/);
    const upper = root[0].toUpperCase() + root.slice(1);
    const lower = root[0].toLowerCase() + root.slice(1);
    const first = capture(upper);
    const second = capture(lower);
    assert.equal(first.status, "CAPTURED");
    assert.equal(second.source_id, first.source_id);
  });

  it("rejects a project directory below the Git repository root", () => {
    const root = project();
    const child = join(root, "src");
    initializeConfig(child, { multiAgent: false, externalContext: false });
    assert.throws(() => capture(child, "retry.mjs"), /Teaching project must be the Git repository root/);
    assert.equal(existsSync(join(child, ".codex-factory/teaching")), false);
  });

  it("discovers an empty catalog without creating teaching state and validates pagination", () => {
    const root = project();
    const beforeSnapshot = runFileSnapshot(root, root);
    const result = cli(root, ["teach", "list", "--json"]);
    assert.equal(result.status, 0, result.stderr);
    const catalog = JSON.parse(result.stdout) as ReturnType<typeof listTeachingLessons>;
    assert.equal(catalog.status, "EMPTY");
    assert.deepEqual(catalog.lessons, []);
    assert.equal(catalog.next_offset, null);
    assert.equal(runFileSnapshot(root, root), beforeSnapshot);
    assert.equal(existsSync(join(root, ".codex-factory/teaching")), false);
    for (const args of [["--limit", "0"], ["--limit", "101"], ["--offset", "-1"], ["--offset", "1.5"], ["--limit"]]) {
      assert.equal(cli(root, ["teach", "list", ...args]).status, 1);
    }
  });

  it("shows conditions and exclusions, separating reusable lessons from drafts, conflicts and damaged records", () => {
    const root = project();
    const source = capture(root);
    const lesson = createTeachingDraft(root, source.source_id, teachingTemplate());
    publishTeachingSkill(root, lesson.draft_id, { draftHash: lesson.draft_hash, userReply: "OFFLINE fixture approval" });
    const pending = createTeachingDraft(root, source.source_id, { ...teachingTemplate(), name: "pending-lesson" });
    const conflict = createTeachingDraft(root, source.source_id, { ...teachingTemplate(), name: "changed-lesson" });
    publishTeachingSkill(root, conflict.draft_id, { draftHash: conflict.draft_hash, userReply: "OFFLINE fixture approval" });
    writeFileSync(join(root, conflict.skill_path), "User edited this Skill; do not overwrite.");
    const unreadable = "lesson-" + "f".repeat(24);
    writeJsonAtomic(join(root, ".codex-factory/teaching/drafts", unreadable, "draft.json"), { invalid: true });
    const beforeSnapshot = runFileSnapshot(root, root);
    const catalog = listTeachingLessons(root);
    assert.equal(catalog.status, "PARTIAL");
    assert.equal(catalog.total_records, 4);
    assert.equal(catalog.available_in_page, 1);
    const available = catalog.lessons.find((entry) => entry.available_for_reuse)!;
    assert.equal(available.lesson_id, lesson.draft_id);
    assert.deepEqual(available.applies_when, teachingTemplate().applies_when);
    assert.deepEqual(available.do_not_apply_when, teachingTemplate().do_not_apply_when);
    assert.deepEqual(available.counterexample, teachingTemplate().counterexample);
    assert.equal(catalog.lessons.find((entry) => entry.lesson_id === pending.draft_id)!.status, "REVIEW_REQUIRED");
    assert.equal(catalog.lessons.find((entry) => entry.lesson_id === conflict.draft_id)!.status, "CONFLICT");
    assert.equal(catalog.lessons.find((entry) => entry.lesson_id === unreadable)!.status, "UNREADABLE");
    assert.ok(!JSON.stringify(catalog).includes("OFFLINE fixture approval"));
    assert.ok(!JSON.stringify(catalog).includes(before.trim()));
    assert.equal(Object.hasOwn(available, "preview"), false);
    const page = listTeachingLessons(root, { limit: 2 });
    assert.equal(page.next_offset, 2);
    const next = listTeachingLessons(root, { limit: 2, offset: page.next_offset! });
    assert.equal(next.next_offset, null);
    assert.deepEqual([...page.lessons, ...next.lessons], catalog.lessons);
    const shown = cli(root, ["teach", "list"]);
    assert.equal(shown.status, 0, shown.stderr);
    assert.match(shown.stdout, /Do not apply when:/);
    assert.match(shown.stdout, /Counterexample:/);
    assert.match(shown.stdout, /Reusable: no/);
    assert.equal(runFileSnapshot(root, root), beforeSnapshot);
  });

  it("applies one published lesson to one pending task without losing confirmed behavior or changing other contracts", () => {
    const root = project();
    const source = capture(root);
    const lesson = createTeachingDraft(root, source.source_id, teachingTemplate());
    const tasks = [repairTask({ description: "Confirmed example: timeoutMs=0 disables the timer." }),
      repairTask({ task_id: "other", write_scope: ["other.txt"], required_artifacts: ["other.txt"], acceptance_methods: ["exists:other.txt"] })];
    const reason = "Explicit zero is meaningful for timeoutMs just as it is for retries; retain different defaults.";
    assert.throws(() => applyTeachingToTasks(root, lesson.draft_id, tasks, "worker", reason), /published Skill/);
    publishTeachingSkill(root, lesson.draft_id, { draftHash: lesson.draft_hash, userReply: "OFFLINE fixture approval" });
    const catalog = JSON.parse(cli(root, ["teach", "list", "--json"]).stdout) as ReturnType<typeof listTeachingLessons>;
    const selected = catalog.lessons.find((entry) => entry.available_for_reuse);
    assert.ok(selected);
    assert.equal(selected.lesson_id, lesson.draft_id);
    writeJsonAtomic(join(root, "tasks.json"), tasks);
    const before = runFileSnapshot(root, root);
    const result = cli(root, ["teach", "apply", "--id", selected.lesson_id, "--tasks", "tasks.json", "--task", "worker", "--reason", reason, "--json"]);
    assert.equal(result.status, 0, result.stderr);
    const prepared = JSON.parse(result.stdout) as ReturnType<typeof applyTeachingToTasks>;
    assert.equal(runFileSnapshot(root, root), before);
    assert.ok(prepared.tasks[0].description.startsWith(tasks[0].description));
    assert.match(prepared.tasks[0].description, /Do Not Apply When/);
    assert.match(prepared.tasks[0].description, /Counterexample/);
    const appliedText = prepared.tasks[0].description;
    const proposal = teachingTemplate();
    for (const text of [...proposal.applies_when, ...proposal.do_not_apply_when,
      ...proposal.rules.flatMap((rule) => [rule.instruction, rule.rationale]),
      proposal.example.scenario, proposal.example.expected_behavior,
      proposal.counterexample.scenario, proposal.counterexample.expected_behavior]) assert.ok(appliedText.includes(text));
    assert.ok(appliedText.includes(lesson.skill_path));
    assert.ok(!appliedText.includes("factory-source:"));
    assert.ok(!appliedText.includes("Full source and the user's reply remain"));
    assert.ok(Buffer.byteLength(appliedText.slice(tasks[0].description.length)) < Buffer.byteLength(lesson.preview));
    assert.deepEqual({ ...prepared.tasks[0], description: tasks[0].description }, tasks[0]);
    assert.deepEqual(prepared.tasks[1], tasks[1]);
    assert.deepEqual(applyTeachingToTasks(root, lesson.draft_id, prepared.tasks, "worker", reason), prepared);
    writeJsonAtomic(join(root, "prepared.json"), prepared);
    assert.equal(cli(root, ["tasks", "validate", "--tasks", "prepared.json", "--json"]).status, 0);
    initializeConfig(root, { multiAgent: true });
    const planned = cli(root, ["plan", "--tasks", "prepared.json", "--run", "lesson-use", "--json"]);
    assert.equal(planned.status, 0, planned.stderr);
    const assignments = JSON.parse(planned.stdout).assignments as Array<{ task_id: string; prompt: string }>;
    assert.match(assignments.find((item) => item.task_id === "worker")!.prompt, /Confirmed example: timeoutMs=0/);
    assert.match(assignments.find((item) => item.task_id === "worker")!.prompt, /Counterexample/);
    assert.throws(() => applyTeachingToTasks(root, lesson.draft_id, [{ ...tasks[0], status: "in_progress" }], "worker", reason), /pending\/ready/);
    assert.throws(() => applyTeachingToTasks(root, lesson.draft_id, tasks, "worker", " "), /applicability reason/);
    writeFileSync(join(root, lesson.skill_path), "Unreviewed changed content");
    assert.throws(() => applyTeachingToTasks(root, lesson.draft_id, tasks, "worker", reason), /CONFLICT/);
  });

  it("captures only the selected real Git change and keeps repeatable candidates undiscoverable", () => {
    const root = project("src/retry [1].mjs");
    writeFileSync(join(root, "unrelated.txt"), "Do not harvest this file");
    const originalStatus = git(root, ["diff", "--stat"]);
    const source = capture(root, "src/retry [1].mjs");
    assert.equal(source.data.before, before);
    assert.equal(source.data.after, after);
    assert.ok(source.data.diff.includes("-" + before.trim()));
    assert.ok(source.data.diff.includes("+" + after.trim()));
    assert.ok(!JSON.stringify(source).includes("Do not harvest this file"));
    assert.deepEqual(capture(root, "src/retry [1].mjs"), source);
    const draft = createTeachingDraft(root, source.source_id, teachingTemplate());
    assert.equal(draft.status, "REVIEW_REQUIRED");
    assert.equal(draft.effectiveness, "UNMEASURED");
    assert.equal(existsSync(join(root, ".agents")), false);
    assert.deepEqual(createTeachingDraft(root, source.source_id, teachingTemplate()), draft);
    assert.deepEqual(inspectTeachingDraft(root, draft.draft_id), draft);
    assert.equal(git(root, ["diff", "--stat"]), originalStatus);
    assert.equal(readFileSync(join(root, "src/retry [1].mjs"), "utf8"), after);
  });

  it("walks the real CLI through preview and explicitly approved project-local publication", () => {
    const root = project();
    initializeFactoryProject(root);
    const result = cli(root, ["teach", "capture", "--path", "src/retry.mjs", "--note", "OFFLINE: preserve explicit zero", "--json"]);
    assert.equal(result.status, 0, result.stderr);
    const source = JSON.parse(result.stdout);
    const template = cli(root, ["teach", "template", "--json"]);
    assert.equal(template.status, 0, template.stderr);
    const lesson = JSON.parse(template.stdout);
    writeJsonAtomic(join(root, "lesson.json"), lesson);
    const proposed = cli(root, ["teach", "draft", "--source", source.source_id, "--file", "lesson.json", "--json"]);
    assert.equal(proposed.status, 0, proposed.stderr);
    const draft = JSON.parse(proposed.stdout);
    const shown = cli(root, ["teach", "show", "--id", draft.draft_id]);
    assert.equal(shown.status, 0, shown.stderr);
    assert.ok(shown.stdout.includes(draft.preview));
    assert.equal(existsSync(join(root, draft.skill_path)), false);
    const args = ["teach", "publish", "--id", draft.draft_id, "--draft-hash", draft.draft_hash, "--reply", "OFFLINE fixture approval", "--json"];
    const published = cli(root, args);
    assert.equal(published.status, 0, published.stderr);
    const view = JSON.parse(published.stdout);
    assert.equal(view.status, "PUBLISHED");
    const content = readFileSync(join(root, view.skill_path), "utf8");
    assert.equal(content, draft.preview);
    assert.equal(view.skill_name, "factory-learned-preserve-explicit-zero");
    assert.ok(content.startsWith("---\nname: " + view.skill_name + "\n"));
    assert.ok(content.includes(lesson.do_not_apply_when[0]));
    assert.ok(content.includes(lesson.example.expected_behavior));
    assert.ok(content.includes(lesson.counterexample.expected_behavior));
    assert.ok(!content.includes("OFFLINE fixture approval"));
    assert.ok(!content.includes(before));
    assert.equal(JSON.parse(cli(root, args).stdout).approved_at, view.approved_at);
    assert.ok(readFileSync(join(root, ".gitignore"), "utf8").includes(".codex-factory/teaching/"));
    assert.ok(readFileSync(join(root, ".agents/skills/codex-factory/SKILL.md"), "utf8").includes("factoryctl teach capture"));
    assert.equal(readFileSync(join(root, "src/retry.mjs"), "utf8"), after);
  });

  it("requires grounded changes and both applicability and a counterexample", () => {
    const root = project();
    const source = capture(root);
    const bad = teachingTemplate();
    bad.rules[0].before_excerpt = "invented before";
    assert.throws(() => createTeachingDraft(root, source.source_id, bad), /removed before excerpt/);
    bad.rules[0].before_excerpt = "export function";
    assert.throws(() => createTeachingDraft(root, source.source_id, bad), /removed before excerpt/);
    const absentBoundary = teachingTemplate();
    absentBoundary.do_not_apply_when = [];
    assert.throws(() => validateTeachingProposal(absentBoundary), /do_not_apply_when/);
    const malformed = teachingTemplate();
    malformed.name = "../escape";
    assert.throws(() => validateTeachingProposal(malformed), /hyphenated/);
    const extra = { ...teachingTemplate(), shell_command: "execute without approval" };
    assert.throws(() => validateTeachingProposal(extra), /unknown fields/);
    const same = teachingTemplate();
    same.counterexample.scenario = same.example.scenario;
    assert.throws(() => validateTeachingProposal(same), /must differ/);
  });

  it("does not copy unchanged, binary, oversized, secret or agent-instruction files", () => {
    const unchanged = project("same.mjs", before, before);
    assert.throws(() => capture(unchanged, "same.mjs"), /No source change/);
    const binary = project("binary.dat", Buffer.from([0, 1]), Buffer.from([0, 2]));
    assert.throws(() => capture(binary, "binary.dat"), /not binary/);
    const large = project("large.txt", "a", "b".repeat(33000));
    assert.throws(() => capture(large, "large.txt"), /32 KiB/);
    const secret = project("config.mjs", "const api_key = 'sk-" + "a".repeat(25) + "';", after);
    assert.throws(() => capture(secret, "config.mjs"), (error: Error) => error.message.includes("Potential secret") && !error.message.includes("sk-"));
    const env = project(".env", "A=1", "A=2");
    assert.throws(() => capture(env, ".env"), /Sensitive credential file/);
    const root = project();
    assert.throws(() => capture(root, ".agents/skills/example/SKILL.md"), /product source file/);
    assert.throws(() => capture(root, "../escape"), /escapes/);
    assert.throws(() => captureTeachingSource(root, { path: "src/retry.mjs", base: "--help", note: "fixture" }), /Git read failed/);
  });

  it("rejects stale approval and preserves existing or later edited skills", () => {
    const root = project();
    const draft = createTeachingDraft(root, capture(root).source_id, teachingTemplate());
    const approved = { draftHash: draft.draft_hash, userReply: "OFFLINE fixture approval" };
    assert.throws(() => publishTeachingSkill(root, draft.draft_id, { ...approved, draftHash: "stale" }), /Stale/);
    assert.throws(() => publishTeachingSkill(root, draft.draft_id, { ...approved, userReply: " " }), /nonempty/);
    assert.equal(existsSync(join(root, draft.skill_path)), false);
    mkdirSync(dirname(join(root, draft.skill_path)), { recursive: true });
    writeFileSync(join(root, draft.skill_path), "Existing user-owned Skill");
    assert.throws(() => publishTeachingSkill(root, draft.draft_id, approved), /already exists/);
    assert.equal(inspectTeachingDraft(root, draft.draft_id).status, "CONFLICT");
    assert.equal(readFileSync(join(root, draft.skill_path), "utf8"), "Existing user-owned Skill");
    const newName = teachingTemplate();
    newName.name = "preserve-explicit-zero-v2";
    const next = createTeachingDraft(root, draft.source_id, newName);
    publishTeachingSkill(root, next.draft_id, { ...approved, draftHash: next.draft_hash });
    assert.throws(() => publishTeachingSkill(root, next.draft_id, { draftHash: next.draft_hash, userReply: "different reply" }), /different reply/);
    writeFileSync(join(root, next.skill_path), "User later refined this Skill");
    assert.throws(() => publishTeachingSkill(root, next.draft_id, { ...approved, draftHash: next.draft_hash }), /conflicts/);
    assert.equal(readFileSync(join(root, next.skill_path), "utf8"), "User later refined this Skill");
  });

  it("binds historical source and draft, without claiming they are the current working tree", () => {
    const root = project();
    const source = capture(root);
    const draft = createTeachingDraft(root, source.source_id, teachingTemplate());
    writeFileSync(join(root, "src/retry.mjs"), after + "// Later unrelated edit\n");
    assert.equal(publishTeachingSkill(root, draft.draft_id, { draftHash: draft.draft_hash, userReply: "OFFLINE: approve this historical example" }).status, "PUBLISHED");
    const sourcePath = join(root, source.source_file);
    const changed = readJson<{ data: { before: string } }>(sourcePath);
    changed.data.before = "different source";
    writeJsonAtomic(sourcePath, changed);
    assert.throws(() => inspectTeachingDraft(root, draft.draft_id), /integrity/);
    assert.equal(cli(root, ["teach", "publish", "--id", draft.draft_id]).status, 1);
    assert.equal(cli(root, ["teach", "template", "--force"]).status, 1);
    assert.equal(cli(root, ["teach", "capture", "--path", "src/retry.mjs", "--base", "--note", "fixture"]).status, 1);
  });
});
