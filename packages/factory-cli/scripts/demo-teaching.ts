import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { initializeConfig } from "../src/config.js";
import { writeJsonAtomic } from "../src/util.js";
import type { listTeachingLessons } from "../src/teaching.js";

const args = process.argv.slice(2);
if (args.length && (args.length !== 1 || args[0] !== "--publish-demo")) {
  throw new Error("Usage: npm run demo:teach [-- --publish-demo]");
}
const packageRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const root = mkdtempSync(join(tmpdir(), "factory-teach-demo-"));
mkdirSync(join(root, "src"));
mkdirSync(join(root, "empty-hooks"));
function git(arguments_: string[]) {
  const result = spawnSync("git", ["-c", "user.name=Factory Offline Demo", "-c", "user.email=demo@example.invalid",
    "-c", "core.hooksPath=" + join(root, "empty-hooks"), "-c", "core.fsmonitor=false", ...arguments_],
    { cwd: root, shell: false, windowsHide: true, encoding: "utf8" });
  if (result.status !== 0) throw new Error("Demo Git setup failed: " + result.stderr);
}
git(["init", "--quiet"]);
git(["config", "core.autocrlf", "false"]);
writeFileSync(join(root, "src/retry.mjs"), "export function retryCount(options) { return options.retries || 3; }\n");
git(["add", "src/retry.mjs"]);
git(["commit", "--quiet", "--no-gpg-sign", "-m", "Offline teaching fixture"]);
writeFileSync(join(root, "src/retry.mjs"), "export function retryCount(options) { return options.retries ?? 3; }\n");
initializeConfig(root, { multiAgent: false, externalContext: false });
function cli(arguments_: string[], json = true) {
  const result = spawnSync(process.execPath, ["--import", "tsx", join(packageRoot, "src/cli.ts"), "--project", root,
    ...arguments_, ...(json ? ["--json"] : [])], { encoding: "utf8", windowsHide: true });
  if (result.status !== 0) throw new Error(result.stderr || result.error?.message || "CLI failed");
  return json ? JSON.parse(result.stdout) : result.stdout;
}
const source = cli(["teach", "capture", "--path", "src/retry.mjs", "--note", "OFFLINE DEMO: explicit retries=0 must survive defaulting."]);
const lesson = cli(["teach", "template"]);
writeJsonAtomic(join(root, "lesson.json"), lesson);
const draft = cli(["teach", "draft", "--source", source.source_id, "--file", "lesson.json"]);
process.stdout.write("OFFLINE DEMO with a pre-authored lesson, not a model learning experiment.\nProject: " + root + "\n\n");
process.stdout.write(cli(["teach", "show", "--id", draft.draft_id], false));
if (args.length) {
  const published = cli(["teach", "publish", "--id", draft.draft_id, "--draft-hash", draft.draft_hash,
    "--reply", "OFFLINE DEMO approval, not a real user teaching event"]);
  if (readFileSync(join(root, published.skill_path), "utf8") !== draft.preview) throw new Error("Published Skill differs from preview");
  const catalog = cli(["teach", "list"]) as ReturnType<typeof listTeachingLessons>;
  process.stdout.write("\nDiscover project lessons before preparing the next task:\n" + cli(["teach", "list"], false) + "\n");
  const selected = catalog.lessons.find((entry) => entry.available_for_reuse && entry.name === "factory-learned-preserve-explicit-zero");
  if (!selected) throw new Error("Expected demo lesson was not available in the catalog");
  writeJsonAtomic(join(root, "next-task.json"), [{ task_id: "timeout", title: "Preserve explicit timeout zero",
    description: "Confirmed example: timeoutMs=0 disables the timeout; missing values use the local timeout default.",
    role: "implementation", status: "pending", dependencies: [], write_scope: ["src/timeout.mjs"],
    required_artifacts: ["src/timeout.mjs"], acceptance_methods: ["exists:src/timeout.mjs"] }]);
  const applied = cli(["teach", "apply", "--id", selected.lesson_id, "--tasks", "next-task.json", "--task", "timeout",
    "--reason", "OFFLINE DEMO: zero also has defined meaning for timeoutMs; its default is independent of retries."]);
  writeJsonAtomic(join(root, "next-task-prepared.json"), applied);
  cli(["tasks", "validate", "--tasks", "next-task-prepared.json"]);
  process.stdout.write(JSON.stringify({ demo_only: true, status: published.status,
    skill_path: join(root, published.skill_path), effectiveness: published.effectiveness,
    prepared_task: join(root, "next-task-prepared.json"), task_status: applied.status,
    note: "The Skill is real; the demonstration and approval are offline fixtures. No live transfer or model improvement measured." }, null, 2) + "\n");
} else {
  process.stdout.write("\nStopped before publication. Preview publishing only inside a fresh temporary demo project with:\n" +
    "npm run demo:teach -- --publish-demo\n");
}
