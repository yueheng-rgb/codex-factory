import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { runFileSnapshot } from "../src/repair-store.js";
import { writeJsonAtomic } from "../src/util.js";
import { failedFixture, fixtureProject } from "../tests/helpers/repair-fixture.js";

const args = process.argv.slice(2);
if (args.length && (args.length !== 1 || !["--observe-demo", "--repair-demo"].includes(args[0]))) {
  throw new Error("Usage: npm run demo:probe [-- --observe-demo | --repair-demo]");
}
const root = fixtureProject();
failedFixture(root, "offline-failure");
const before = runFileSnapshot(root, join(root, ".codex-factory/runs/offline-failure"));
const cliPath = join(dirname(dirname(fileURLToPath(import.meta.url))), "src/cli.ts");
function cli(arguments_: string[]) {
  const result = spawnSync(process.execPath, ["--import", "tsx", cliPath, "--project", root, ...arguments_, "--json"],
    { encoding: "utf8", windowsHide: true });
  if (result.status !== 0) throw new Error(result.stderr || result.error?.message || "CLI failed");
  return JSON.parse(result.stdout);
}
const proposal = cli(["probe", "template"]);
proposal.observation.provenance = "OFFLINE DEMO: diagnostic generated below from a known buggy normalizer with input retries=0; not a production trace.";
writeJsonAtomic(join(root, "proposal.json"), proposal);
const draft = cli(["probe", "draft", "--from-run", "offline-failure", "--task", "worker", "--file", "proposal.json"]);
process.stdout.write("OFFLINE DEMO: fixture host receipts and pre-authored hypotheses; real CLI and file observation.\nProject: " + root + "\n");
process.stdout.write(JSON.stringify(draft, null, 2) + "\n");
if (args.length) {
  // Deliberately reproduce explicit-zero defaulting; the probe itself runs no code.
  const normalize = (options: { retries: number }) => ({ retries: options.retries || 3 });
  writeJsonAtomic(join(root, "diagnostic.json"), { normalized: normalize({ retries: 0 }) });
  const result = cli(["probe", "observe", "--id", draft.draft.probe_id, "--draft-hash", draft.draft.draft_hash,
    "--reply", "OFFLINE DEMO approval; not a real user authorization event"]);
  assert.equal(result.observation.data.matching_hypothesis, "H1");
  assert.equal(result.source_verdict, "FAIL");
  assert.equal(result.repair.remaining_attempts, 2);
  assert.equal(runFileSnapshot(root, join(root, ".codex-factory/runs/offline-failure")), before);
  writeJsonAtomic(join(root, "demo-report.json"), result);
  process.stdout.write(JSON.stringify({ demo_only: true, status: result.status,
    matching_hypothesis: result.observation.data.matching_hypothesis, observed_value: result.observation.data.value,
    next_step: result.next_step, original_verdict: result.source_verdict, remaining_repairs: result.repair.remaining_attempts,
    report: join(root, "demo-report.json"), limitation: "No live Agent, automatic experiment or repair-effectiveness measurement." }, null, 2) + "\n");
  if (args[0] === "--repair-demo") {
    const preview = cli(["probe", "repair-plan", "--id", draft.draft.probe_id]);
    writeJsonAtomic(join(root, "repair-preview.json"), preview);
    const createArgs = ["repair", "create", "--from-run", "offline-failure", "--task", "worker",
      "--probe", draft.draft.probe_id, "--request-id", "offline-guided-repair"];
    const repair = cli(createArgs);
    assert.equal(cli(createArgs).run_id, repair.run_id);
    const continuation = cli(["run", "continue", "--run", repair.run_id]);
    assert.ok(continuation.plan.assignments[0].prompt.includes(preview.observation_path));
    assert.equal(runFileSnapshot(root, join(root, ".codex-factory/runs/offline-failure")), before);
    writeJsonAtomic(join(root, "repair-dispatch.json"), continuation);
    process.stdout.write(JSON.stringify({ demo_only: true, repair_run: repair.run_id, status: continuation.status,
      guidance_reached_worker: true, native_agent_started: false,
      preview: join(root, "repair-preview.json"), dispatch: join(root, "repair-dispatch.json"),
      note: "Stopped before host dispatch. A prepared repair is not a completed fix." }, null, 2) + "\n");
  }
} else {
  process.stdout.write("Stopped before observation. Run npm run demo:probe -- --observe-demo for an isolated approved fixture.\n");
}
