var fs = require("fs");
var path = require("path");
var crypto = require("crypto");

var base = "C:/Codex_App_Factory/harness/runs/h2-hardened-factory-pipeline/fixtures";
var harnessRoot = "C:/Codex_App_Factory/harness";
var runId = "h2-hardened-factory-pipeline";

function sha256(s) { return crypto.createHash("sha256").update(s,"utf8").digest("hex").toUpperCase(); }
function ensureDir(d) { fs.mkdirSync(d, {recursive:true}); }
function writeJson(p, obj) { fs.writeFileSync(p, JSON.stringify(obj,null,4),"utf8"); }
function writeJs(p, content) { fs.writeFileSync(p, content,"utf8"); }
function copyDir(src, dst) {
    ensureDir(dst);
    fs.readdirSync(src).forEach(function(f) {
        var sf = path.join(src,f), df = path.join(dst,f);
        if (fs.statSync(sf).isDirectory()) copyDir(sf,df);
        else fs.copyFileSync(sf,df);
    });
}

function makeHashChainEvent(events, eventType, actorRole, payload) {
    var prev = events.length > 0 ? events[events.length-1].eventHash : "GENESIS";
    var evt = {
        runId: runId, eventType: eventType, timestamp: new Date().toISOString(),
        actorRole: actorRole, payload: payload,
        previousEventHash: prev
    };
    var canonical = {};
    Object.keys(evt).sort().forEach(function(k) { canonical[k] = evt[k]; });
    evt.eventHash = sha256(JSON.stringify(canonical));
    return evt;
}

function writeRunState(dir, events) {
    var lines = events.map(function(e) { return JSON.stringify(e); });
    fs.writeFileSync(path.join(dir,"RUN_STATE.jsonl"), lines.join("\n")+"\n","utf8");
}

function makeWorkerWorkspace(dir, workerId, files) {
    var src = path.join(dir, "src");
    ensureDir(src);
    var results = [];
    files.forEach(function(f) {
        writeJs(path.join(src, f.file), f.content);
        results.push({ relativePath: f.file, sizeBytes: Buffer.byteLength(f.content,"utf8"), sha256: sha256(f.content) });
    });
    return results;
}

function makeFreezeManifest(dir, workerId, workspacePath, files) {
    var manifest = {
        runId: runId, workerId: workerId, workerName: "worker-"+workerId,
        workspacePath: workspacePath, frozenAt: new Date().toISOString(),
        fileCount: files.length, totalBytes: files.reduce(function(s,f){return s+f.sizeBytes},0),
        files: files.sort(function(a,b){ return a.relativePath.localeCompare(b.relativePath); })
    };
    var canonical = {};
    Object.keys(manifest).sort().forEach(function(k) { canonical[k] = manifest[k]; });
    manifest.manifestHash = sha256(JSON.stringify(canonical));
    return manifest;
}

function makeAcceptanceReports(dir, verdict, scenarios, intendedFailure, failedScenario) {
    ensureDir(dir);
    writeJson(path.join(dir,"gatecheck-report.json"), {
        phase:"Phase 6C-H2", reportType:"gatecheck-report", timestamp:new Date().toISOString(),
        verdict:"GATES_PASS", gates:[{name:"GateCheck",passed:true}]
    });
    writeJson(path.join(dir,"functional-acceptance-report.json"), {
        phase:"Phase 6C-H2", reportType:"functional-acceptance-report", timestamp:new Date().toISOString(),
        verdict:"PASS", checks:[]
    });
    writeJson(path.join(dir,"runtime-acceptance-report.json"), {
        phase:"Phase 6C-H2", reportType:"runtime-acceptance-report", timestamp:new Date().toISOString(),
        verdict:"PASS", nodeVersion:"v20"
    });
    writeJson(path.join(dir,"http-app-acceptance-report.json"), {
        phase:"Phase 6C-H2", reportType:"http-app-acceptance-report", timestamp:new Date().toISOString(),
        verdict:"PASS", endpoints:[]
    });
    writeJson(path.join(dir,"static-artifact-acceptance-report.json"), {
        phase:"Phase 6C-H2", reportType:"static-artifact-acceptance-report", timestamp:new Date().toISOString(),
        verdict:"PASS", artifacts:[]
    });
    writeJson(path.join(dir,"drift.json"), {
        phase:"Phase 6C-H2", reportType:"drift-report", timestamp:new Date().toISOString(),
        verdict:"NO_DRIFT"
    });
    
    var searchReport = {
        phase:"Phase 6C-H2", reportType:"search-pagination-performance-acceptance-report",
        timestamp: new Date().toISOString(), verdict: verdict, passCount: verdict==="PASS"?scenarios.length:scenarios.length-1,
        failCount: verdict==="PASS"?0:1, scenarioCount: scenarios.length, scenarios: scenarios
    };
    if (verdict === "FAIL") {
        searchReport.intendedFailure = intendedFailure || false;
        searchReport.scenario = failedScenario || "";
        searchReport.failedScenarios = [failedScenario];
        searchReport.failureReason = "Intended failure for fixture testing";
        searchReport.performanceEvidence = {
            fixtureSize: 1000, elapsedMs: 12, budgetMs: 1000, withinBudget: true
        };
    }
    writeJson(path.join(dir,"search-pagination-performance-acceptance-report.json"), searchReport);
}

var scenarios = [
    {name:"search_text_matches_expected_items",passed:true,elapsedMs:12,details:"Scenario verified"},
    {name:"filter_category_status_price_combination",passed:true,elapsedMs:8,details:"Scenario verified"},
    {name:"sort_price_name_stable_order",passed:true,elapsedMs:5,details:"Scenario verified"},
    {name:"pagination_offset_no_duplicates",passed:true,elapsedMs:4,details:"Scenario verified"},
    {name:"pagination_cursor_roundtrip",passed:true,elapsedMs:6,details:"Scenario verified"},
    {name:"invalid_query_rejected",passed:true,elapsedMs:2,details:"Scenario verified"},
    {name:"large_fixture_generated",passed:true,elapsedMs:45,details:"Scenario verified"},
    {name:"performance_budget_query_under_limit",passed:true,elapsedMs:18,details:"Query completed in 18ms, well under 1000ms budget"},
    {name:"facets_counts_correct",passed:true,elapsedMs:3,details:"Scenario verified"}
];

var w1Files = [
    {file:"itemTypes.js", content:'// itemTypes.js — worker-1\nexports.ItemType = "category";\nexports.createItem = function(d){return d;};'},
    {file:"itemStore.js", content:'// itemStore.js — worker-1\nvar itemTypes = require("./itemTypes.js");\nexports.store = [];\nexports.addItem = function(i){exports.store.push(i);};'},
    {file:"filterByCategory.js", content:'// filterByCategory.js — worker-1\nexports.filterByCategory = function(items,cat){return items.filter(function(i){return i.category===cat;});};'},
    {file:"filterByStatus.js", content:'// filterByStatus.js — worker-1\nexports.filterByStatus = function(items,s){return items.filter(function(i){return i.status===s;});};'},
    {file:"filterByPrice.js", content:'// filterByPrice.js — worker-1\nexports.filterByPrice = function(items,min,max){return items.filter(function(i){return i.price>=min&&i.price<=max;});};'},
    {file:"sortItems.js", content:'// sortItems.js — worker-1\nexports.sortItems = function(items,key){return items.sort(function(a,b){return a[key]-b[key];});};'}
];

var w2Files = [
    {file:"searchTypes.js", content:'// searchTypes.js — worker-2\nexports.SearchQuery = function(q){this.q=q;};'},
    {file:"normalizeText.js", content:'// normalizeText.js — worker-2\nvar itemTypes = require("./itemTypes.js");\nexports.normalizeText = function(t){return t.toLowerCase().trim();};'},
    {file:"tokenizeText.js", content:'// tokenizeText.js — worker-2\nexports.tokenizeText = function(t){return t.split(/\\s+/);};'},
    {file:"buildIndex.js", content:'// buildIndex.js — worker-2\nexports.buildIndex = function(items){var idx={};items.forEach(function(i){idx[i.id]=i;});return idx;};'},
    {file:"searchIndex.js", content:'// searchIndex.js — worker-2\nexports.searchIndex = function(index,q){return Object.values(index).filter(function(i){return i.name&&i.name.indexOf(q)>=0;});};'},
    {file:"searchComposer.js", content:'// searchComposer.js — worker-2\nvar searchIndex = require("./searchIndex.js");\nexports.composeSearch = function(index,q){return searchIndex.searchIndex(index,q);};'}
];

// ==========================================================
// Fixture 1: hardened-good-run
// ==========================================================
console.log("Creating fixture 1: hardened-good-run");
var f1 = path.join(base, "hardened-good-run");
ensureDir(f1);

var w1Dir = path.join(f1, "worker-1-workspace");
var w2Dir = path.join(f1, "worker-2-workspace");
var w1FileList = makeWorkerWorkspace(w1Dir, 1, w1Files);
var w2FileList = makeWorkerWorkspace(w2Dir, 2, w2Files);

// Freeze manifests
var freezeDir = path.join(f1, "worker-freeze-manifests");
ensureDir(freezeDir);
var w1Freeze = makeFreezeManifest(freezeDir, 1, w1Dir, w1FileList);
var w2Freeze = makeFreezeManifest(freezeDir, 2, w2Dir, w2FileList);
writeJson(path.join(freezeDir,"worker-1.freeze.json"), w1Freeze);
writeJson(path.join(freezeDir,"worker-2.freeze.json"), w2Freeze);

// Integration — copy all files to canonical
var canonDir = path.join(f1, "canonical-integrated", "src");
ensureDir(canonDir);
w1Files.concat(w2Files).forEach(function(f) {
    fs.writeFileSync(path.join(canonDir, f.file), f.content, "utf8");
});

// Integration patch ledger (1 patch recorded for wiring)
var integrationDir = path.join(f1, "canonical-integrated");
ensureDir(integrationDir);
var integrationFile = path.join(f1, "canonical-integrated", "integrationWiring.js");
fs.writeFileSync(integrationFile, '// integrationWiring.js — connects worker-1 and worker-2\nvar itemTypes = require("./itemTypes.js");\nvar normalizeText = require("./normalizeText.js");\nconsole.log("Wired");\n',"utf8");

var beforeHash = "0000000000000000000000000000000000000000000000000000000000000000";
var afterHash = sha256(fs.readFileSync(integrationFile,"utf8"));
var patchEvent = {
    runId: runId, patchId: "PATCH-1-202606220000", timestamp: new Date().toISOString(),
    actorRole: "Integrator", reason: "Add integration wiring file",
    affectedFiles: ["integrationWiring.js"], beforeHash: beforeHash, afterHash: afterHash,
    operation: "add", sourceWorker: "",
    previousPatchEventHash: "GENESIS"
};
var patchCanonical = {};
Object.keys(patchEvent).sort().forEach(function(k) { patchCanonical[k] = patchEvent[k]; });
patchEvent.patchEventHash = sha256(JSON.stringify(patchCanonical));
var ledgerPath = path.join(f1, "integration-patches.jsonl");
fs.writeFileSync(ledgerPath, JSON.stringify(patchEvent)+"\n","utf8");

// RUN_STATE
var events = [];
events.push(makeHashChainEvent(events, "run_started", "MainAgent", {contractPath:"run-contract.json"}));
events.push(makeHashChainEvent(events, "worker_started", "Worker1", {workerId:1}));
events.push(makeHashChainEvent(events, "worker_completed", "Worker1", {workerId:1}));
events.push(makeHashChainEvent(events, "worker_frozen", "Integrator", {workerId:1,manifestHash:w1Freeze.manifestHash}));
events.push(makeHashChainEvent(events, "worker_started", "Worker2", {workerId:2}));
events.push(makeHashChainEvent(events, "worker_completed", "Worker2", {workerId:2}));
events.push(makeHashChainEvent(events, "worker_frozen", "Integrator", {workerId:2,manifestHash:w2Freeze.manifestHash}));
events.push(makeHashChainEvent(events, "integration_started", "Integrator", {workerCount:2}));
events.push(makeHashChainEvent(events, "integration_patch_recorded", "Integrator", {patchCount:1}));
events.push(makeHashChainEvent(events, "integration_completed", "Integrator", {}));
events.push(makeHashChainEvent(events, "verification_started", "Verifier", {}));
events.push(makeHashChainEvent(events, "verification_completed", "Verifier", {errors:0}));
events.push(makeHashChainEvent(events, "report_written", "Verifier", {}));
events.push(makeHashChainEvent(events, "run_passed", "MainAgent", {exitCode:0}));
writeRunState(f1, events);

// Reports
var reportsDir = path.join(f1, "reports");
makeAcceptanceReports(reportsDir, "PASS", scenarios, false, null);

// Run contract
writeJson(path.join(f1,"run-contract.json"), {
    runId: runId, phase: "Phase 6C-H2", projectProfile: "synthetic-fixture",
    requiredWorkers: 2, minimumJsFiles: 8, minimumNamedExports: 6,
    minimumCrossWorkerDeps: 2, requiredScenarioCount: 9,
    requiredAcceptanceLayers: ["GateCheck","Functional","Runtime","HTTP","Static","Search"],
    requiredArtifacts: ["RUN_STATE.jsonl","reports/search-pagination-performance-acceptance-report.json","canonical-integrated"],
    noExternalPackages: true, nodeBuiltinsOnly: true,
    requireRunState: true, requireWorkerFreeze: true,
    requireIntegrationLedger: true, requireVerifierHashLock: true
});

console.log("Fixture 1 done: hardened-good-run");

// ==========================================================
// Fixture 2: missing-run-state
// ==========================================================
console.log("Creating fixture 2: missing-run-state");
var f2 = path.join(base, "missing-run-state");
ensureDir(f2);
copyDir(f1, f2);
// Delete RUN_STATE
var statePath = path.join(f2, "RUN_STATE.jsonl");
if (fs.existsSync(statePath)) fs.unlinkSync(statePath);
console.log("Fixture 2 done: missing-run-state");

// ==========================================================
// Fixture 3: worker-mutated-after-freeze
// ==========================================================
console.log("Creating fixture 3: worker-mutated-after-freeze");
var f3 = path.join(base, "worker-mutated-after-freeze");
ensureDir(f3);
copyDir(f1, f3);
// Mutate a frozen worker file after freeze
var mutFile = path.join(f3, "worker-1-workspace", "src", "itemTypes.js");
fs.writeFileSync(mutFile, '// MUTATED AFTER FREEZE\nexports.ItemType = "modified";\nexports.createItem = function(d){return null;};',"utf8");
// Also mutate the canonical copy to simulate the mutation propagating
var mutCanonFile = path.join(f3, "canonical-integrated", "src", "itemTypes.js");
if (fs.existsSync(mutCanonFile)) {
    fs.writeFileSync(mutCanonFile, '// MUTATED AFTER FREEZE\nexports.ItemType = "modified";\nexports.createItem = function(d){return null;};',"utf8");
}
console.log("Fixture 3 done: worker-mutated-after-freeze");

// ==========================================================
// Fixture 4: unrecorded-integration-change
// ==========================================================
console.log("Creating fixture 4: unrecorded-integration-change");
var f4 = path.join(base, "unrecorded-integration-change");
ensureDir(f4);
copyDir(f1, f4);
// Add file to canonical without patch ledger
var unrecordedFile = path.join(f4, "canonical-integrated", "src", "unrecordedChange.js");
fs.writeFileSync(unrecordedFile, '// This file was added WITHOUT a patch ledger entry',"utf8");
// Delete ledger to simulate missing record
var ledgerPath4 = path.join(f4, "integration-patches.jsonl");
if (fs.existsSync(ledgerPath4)) fs.unlinkSync(ledgerPath4);
console.log("Fixture 4 done: unrecorded-integration-change");

// ==========================================================
// Fixture 5: verifier-tampered
// ==========================================================
console.log("Creating fixture 5: verifier-tampered");
var f5 = path.join(base, "verifier-tampered");
ensureDir(f5);
copyDir(f1, f5);
// Add a tampered verifier registry — copy the real one with wrong hash
var realReg = JSON.parse(fs.readFileSync(path.join(harnessRoot,"governance/harness-core/verifier-registry.json"),"utf8"));
if (realReg.registry && realReg.registry.length > 0) {
    // Tamper the first entry's hash
    realReg.registry[0].sha256 = "0000000000000000000000000000000000000000000000000000000000000000";
    var tamperedRegDir = path.join(f5, "tampered-registry");
    ensureDir(tamperedRegDir);
    writeJson(path.join(tamperedRegDir,"tampered-registry.json"), realReg);
    // Add a tampered registry path marker
    writeJson(path.join(f5,"verifier-tampered-evidence.json"), {
        note: "Verifier registry entry hash tampered",
        tamperedRegistryPath: path.join(tamperedRegDir,"tampered-registry.json").replace(/\\/g,"\\\\")
    });
}
console.log("Fixture 5 done: verifier-tampered");

// ==========================================================
// Fixture 6: threshold-drift-without-reconciliation
// ==========================================================
console.log("Creating fixture 6: threshold-drift");
var f6 = path.join(base, "threshold-drift-without-reconciliation");
ensureDir(f6);
copyDir(f1, f6);
// Override contract with thresholds that don't match
writeJson(path.join(f6,"run-contract.json"), {
    runId: runId, phase: "Phase 6C-H2", projectProfile: "synthetic-fixture",
    requiredWorkers: 2, minimumJsFiles: 200, minimumNamedExports: 500,
    minimumCrossWorkerDeps: 100, requiredScenarioCount: 50,
    requiredAcceptanceLayers: ["GateCheck","Functional","Runtime","HTTP","Static","Search"],
    requiredArtifacts: ["RUN_STATE.jsonl"],
    noExternalPackages: true, nodeBuiltinsOnly: true,
    requireRunState: true, requireWorkerFreeze: true,
    requireIntegrationLedger: true, requireVerifierHashLock: true
});
console.log("Fixture 6 done: threshold-drift");

// ==========================================================
// Fixture 7: report-pending-claims-pass
// ==========================================================
console.log("Creating fixture 7: report-pending-claims-pass");
var f7 = path.join(base, "report-pending-claims-pass");
ensureDir(f7);
copyDir(f1, f7);
// Write a report that says PASS but has PENDING in it
var pendingReport = [
    "# Phase 6C-H2 Fixture Report",
    "",
    "**Verdict:** **PASS**",
    "**Summary:** PASS — all checks pass",
    "",
    "## Verifier Status",
    "",
    "| Check | Result |",
    "|-------|:---:|",
    "| Verifier run | PENDING — verifier not yet run |",
    "| Evidence check | PASS |",
    "",
    "## Note",
    "",
    "This report claims PASS but verifier is PENDING."
].join("\n");
var reportsDir7 = path.join(f7, "reports");
ensureDir(reportsDir7);
fs.writeFileSync(path.join(reportsDir7,"H2_FIXTURE_REPORT.md"), pendingReport, "utf8");
console.log("Fixture 7 done: report-pending-claims-pass");

// ==========================================================
// Fixture 8: target-gate-failure-clean
// ==========================================================
console.log("Creating fixture 8: target-gate-failure-clean");
var f8 = path.join(base, "target-gate-failure-clean");
ensureDir(f8);
copyDir(f1, f8);
// Modify scenarios to have a target failure
var failScenarios = JSON.parse(JSON.stringify(scenarios));
failScenarios[3] = {name:"pagination_offset_no_duplicates",passed:false,elapsedMs:4,details:"INTENDED FAILURE: offset pagination produces duplicate items across pages"};
var reportsDir8 = path.join(f8, "reports");
makeAcceptanceReports(reportsDir8, "FAIL", failScenarios, true, "pagination_offset_no_duplicates");
console.log("Fixture 8 done: target-gate-failure-clean");

console.log("\nAll 8 fixtures created.");
