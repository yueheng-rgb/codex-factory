import { spawnSync } from "node:child_process";
import { mkdtempSync, copyFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { initializeConfig } from "../src/config.js";

const packageRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const args = process.argv.slice(2);
if (args.length && (args.length !== 2 || args[0] !== "--option" || !["keep-first", "keep-last"].includes(args[1]))) {
  throw new Error("Usage: npm run demo:clarify [-- --option keep-first|keep-last]");
}
const root = mkdtempSync(join(tmpdir(), "factory-clarify-demo-"));
initializeConfig(root, { multiAgent: true, externalContext: false, maxThreads: 2 });
copyFileSync(join(packageRoot, "examples/behavior-contrast.json"), join(root, "contrast.json"));
function cli(arguments_: string[], json = true) {
  const result = spawnSync(process.execPath, ["--import", "tsx", join(packageRoot, "src/cli.ts"),
    "--project", root, ...arguments_, ...(json ? ["--json"] : [])], { encoding: "utf8", windowsHide: true });
  if (result.status !== 0) throw new Error(result.stderr || result.error?.message || "CLI failed");
  return json ? JSON.parse(result.stdout) : result.stdout;
}
const draft = cli(["clarify", "create", "--file", "contrast.json"]);
process.stdout.write("Offline clarification demo. No model calls, real user consent, native agents or product implementation.\nProject: " + root + "\n\n");
process.stdout.write(cli(["clarify", "show", "--id", draft.clarification_id], false));
if (args.length) {
  const decision = cli(["clarify", "choose", "--id", draft.clarification_id, "--option", args[1],
    "--draft-hash", draft.draft_hash, "--reply", "OFFLINE DEMO selection: " + args[1]]);
  const validation = cli(["tasks", "validate", "--tasks", decision.tasks_file]);
  const plan = cli(["plan", "--tasks", decision.tasks_file, "--run", "clarification-demo"]);
  process.stdout.write(JSON.stringify({ demo_only: true, status: "PLANNED_NOT_EXECUTED", tasks_file: decision.tasks_file,
    validation: validation.status, run_id: plan.run_id, assignments: plan.assignments.map((item: { task_id: string }) => item.task_id),
    note: "The chosen examples are in the task contract; implementation and independent verification are still required." }, null, 2) + "\n");
} else {
  process.stdout.write("\nStopped before selection. To preview either branch in a fresh demo project:\n" +
    "npm run demo:clarify -- --option keep-first\nnpm run demo:clarify -- --option keep-last\n");
}
