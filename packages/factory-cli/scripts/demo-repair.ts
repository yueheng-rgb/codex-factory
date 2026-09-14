import assert from "node:assert/strict";
import { prepareSpawnPlan } from "../src/orchestrator.js";
import { createRepairRun, inspectRun } from "../src/run-management.js";
import { managedRunDirectory, runFileSnapshot } from "../src/repair-store.js";
import { writeJsonAtomic } from "../src/util.js";
import { completeFixtureRun, fixtureProject, repairTask } from "../tests/helpers/repair-fixture.js";
import { join } from "node:path";

const root = fixtureProject(true);
const task = repairTask({ acceptance_methods: [
  "command:node -e \"if(require('node:fs').readFileSync('artifact.txt','utf8').trim() !== 'ready') process.exit(1)\"",
] });
prepareSpawnPlan(root, [task], "demo-original");
completeFixtureRun(root, "demo-original", "FAIL", "broken\n");
const before = runFileSnapshot(root, managedRunDirectory(root, "demo-original"));
const original = inspectRun(root, "demo-original");
assert.equal(original.status, "FAILED");
assert.ok(original.tasks[0].failure_reasons.includes("One or more independently executed acceptance checks failed"));
const request = { fromRun: "demo-original", taskId: "worker", tasks: [task], requestId: "demo-repair-1" };
writeJsonAtomic(join(root, "repair-tasks.json"), [task]);
const repair = createRepairRun(root, request);
assert.deepEqual(createRepairRun(root, request), repair);
completeFixtureRun(root, repair.run_id, "PASS", "ready\n");
assert.equal(inspectRun(root, repair.run_id).status, "PASSED");
assert.equal(before, runFileSnapshot(root, managedRunDirectory(root, "demo-original")));
const report = {
  mode: "OFFLINE_HOST_FIXTURE", project: root, original: inspectRun(root, "demo-original"),
  repaired: inspectRun(root, repair.run_id), original_evidence_unchanged: true,
  note: "Host dispatch receipts are simulated. Filesystem writes, shell acceptance checks, receipt binding and repair runtime are real. No paid model or remote CI was called.",
};
writeJsonAtomic(join(root, "demo-report.json"), report);
process.stdout.write(JSON.stringify(report, null, 2) + "\n");
