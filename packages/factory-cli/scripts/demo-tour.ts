import { spawnSync } from "node:child_process";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { writeJsonAtomic } from "../src/util.js";

if (process.argv.length > 2) throw new Error("Usage: npm run demo:tour (offline examples only)");

const packageRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const reportRoot = mkdtempSync(join(tmpdir(), "factory-tour-"));
const steps = [
  { id: "clarify", title: "Clarify intent with contrasting outcomes", script: "demo-clarification.ts",
    args: ["--option", "keep-last"], endpoint: "Confirmed example enters the task plan; no native execution." },
  { id: "teach", title: "Discover and reuse a bounded lesson", script: "demo-teaching.ts",
    args: ["--publish-demo"], endpoint: "Fixture lesson is published, discovered and attached to a separate pending task." },
  { id: "probe", title: "Use an observation to choose a repair lead", script: "demo-probe.ts",
    args: ["--repair-demo"], endpoint: "A matched prediction enters a repair dispatch plan; no actual repair is executed." },
];
const results: Array<{
  id: string; title: string; command: string[]; intended_endpoint: string;
  exit_code: number | null; signal: string | null; error: string | null;
  stdout_path: string; stderr_path: string; completed: boolean;
}> = [];

process.stdout.write("Factory offline tour: three separate examples, not one real development task.\n" +
  "Selections, approvals and host receipts are fixtures. No model calls or native agents.\n" +
  "Output: " + reportRoot + "\n");

for (const [index, step] of steps.entries()) {
  process.stdout.write("\n[" + (index + 1) + "/" + steps.length + "] " + step.title + "\n");
  const args = ["--import", "tsx", join(packageRoot, "scripts", step.script), ...step.args];
  const child = spawnSync(process.execPath, args, {
    cwd: packageRoot, shell: false, windowsHide: true, encoding: "utf8", timeout: 120000, maxBuffer: 4 * 1024 * 1024,
  });
  const stdoutPath = join(reportRoot, step.id + ".stdout.txt");
  const stderrPath = join(reportRoot, step.id + ".stderr.txt");
  writeFileSync(stdoutPath, child.stdout ?? "", "utf8");
  writeFileSync(stderrPath, child.stderr ?? "", "utf8");
  const completed = !child.error && child.status === 0;
  results.push({ id: step.id, title: step.title, command: [process.execPath, ...args], intended_endpoint: step.endpoint,
    exit_code: child.status, signal: child.signal, error: child.error?.message ?? null,
    stdout_path: stdoutPath, stderr_path: stderrPath, completed });
  process.stdout.write((completed ? "Demo completed" : "Demo stopped") + "; exit=" + child.status + "\n" +
    "Intended endpoint: " + step.endpoint + "\nLog: " + stdoutPath + "\n");
  if (!completed) {
    process.stdout.write("Inspect: " + stderrPath + (child.error ? "\n" + child.error.message : "") + "\n");
    break;
  }
}

const completed = results.length === steps.length && results.every((step) => step.completed);
const report = { version: "1.0.0", demo_only: true, status: completed ? "COMPLETED" : "STOPPED",
  generated_at: new Date().toISOString(), results, not_run: steps.slice(results.length).map((step) => step.id),
  limitations: ["Successful demo processes do not establish successful native Agent execution or measured improvement.",
    "Each scenario uses its own temporary project. Fixture approvals are not user authorization for a real project.",
    "No current project initialization, global Skill publication, model call or native Agent dispatch is performed.",
    "Temporary projects are retained for inspection; their locations are printed in each stdout log."] };
const jsonPath = join(reportRoot, "tour.json");
const markdownPath = join(reportRoot, "README.md");
const link = (path: string) => "<" + path.replaceAll("\\", "/") + ">";
writeJsonAtomic(jsonPath, report);
writeFileSync(markdownPath, ["# Factory Offline Tour", "", "Status: " + report.status,
  "", "Three independent illustrative scenarios. Not a live benchmark or a single completed product task.",
  ...results.flatMap((step) => ["", "## " + step.title, "", "Process exit: " + step.exit_code,
    "", "Intended endpoint: " + step.intended_endpoint,
    "", "[Output](" + link(step.stdout_path) + ") | [Errors](" + link(step.stderr_path) + ")",
    ...(step.error ? ["", "Process error: " + step.error] : [])]),
  "", "Not run: " + (report.not_run.join(", ") || "none"), "", "## Boundaries", "",
  ...report.limitations.map((item) => "- " + item), "", "[Structured results](" + link(jsonPath) + ")", ""].join("\n"), "utf8");
process.stdout.write("\nTour " + report.status + "\nSummary: " + markdownPath + "\nResults: " + jsonPath + "\n");
if (!completed) process.exitCode = 1;
