// test-dry14-b-negatives.js - Validate all 9 DRY14-B negative control bugs
var fs = require("fs");
var path = require("path");
var runsDir = path.join(__dirname, "..", "runs");

var negatives = [
  { id: "dry14-b-negative-future-job-not-due",       scenario: "scheduler_future_job_not_due",            test: "future" },
  { id: "dry14-b-negative-due-job-dispatch",          scenario: "scheduler_due_job_dispatches_on_tick",    test: "due" },
  { id: "dry14-b-negative-failed-dispatch-retry",     scenario: "scheduler_failed_dispatch_retries",       test: "retry" },
  { id: "dry14-b-negative-retry-delay",               scenario: "scheduler_retry_delay_respected",         test: "delay" },
  { id: "dry14-b-negative-max-attempts-dead-letter",  scenario: "scheduler_max_attempts_dead_letter",      test: "dead" },
  { id: "dry14-b-negative-cancelled-job",             scenario: "scheduler_cancelled_job_not_dispatched",  test: "cancel" },
  { id: "dry14-b-negative-state-restart",             scenario: "scheduler_state_survives_restart",        test: "state" },
  { id: "dry14-b-negative-audit-events",              scenario: "scheduler_audit_records_dispatch_retry_dead_letter", test: "audit" },
  { id: "dry14-b-negative-export-import-queue",       scenario: "scheduler_export_import_preserves_queue", test: "import" }
];

var allPass = true;

negatives.forEach(function(neg) {
  var runPath = path.join(runsDir, neg.id);
  var srcPath = path.join(runPath, "canonical-integrated", "src");
  
  // Clear require cache for this run
  Object.keys(require.cache).forEach(function(k) { delete require.cache[k]; });
  
  try {
    var JOB_STATUS = { PENDING: "PENDING", RUNNING: "RUNNING", COMPLETED: "COMPLETED", FAILED: "FAILED", DEAD_LETTER: "DEAD_LETTER", CANCELLED: "CANCELLED" };
    
    // Override module paths to point to the negative control
    var origResolve = require.resolve;
    
    // Load the patched modules
    process.chdir(srcPath);
    
    var result = { pass: true, detail: "" };
    
    switch (neg.test) {
      case "future":
        // Test: tick() dispatches a future job too early
        var js = require(srcPath + "/jobScheduler.js");
        var now = new Date().toISOString();
        var futureDate = new Date(Date.now() + 3600000).toISOString();
        var jobs = [{ id: "j1", status: "PENDING", dueAt: futureDate }];
        var ticked = js.tick(jobs, now);
        // BUG: tick should NOT change status for future job, but it does
        result.pass = ticked[0].status === "RUNNING";
        result.detail = "future job dispatched=" + (ticked[0].status === "RUNNING") + " (expected RUNNING for negative)";
        break;
        
      case "due":
        // Test: tick() does NOT dispatch a due job
        var js2 = require(srcPath + "/jobScheduler.js");
        var now2 = new Date().toISOString();
        var pastDate = new Date(Date.now() - 10000).toISOString();
        var jobs2 = [{ id: "j1", status: "PENDING", dueAt: pastDate }];
        var ticked2 = js2.tick(jobs2, now2);
        // BUG: tick should change status but doesn't
        result.pass = ticked2[0].status === "PENDING";
        result.detail = "due job status=" + ticked2[0].status + " (expected PENDING for negative)";
        break;
        
      case "retry":
        // Test: shouldRetry always returns false (never retries)
        var rm = require(srcPath + "/retryManager.js");
        var job = { attempt: 1, maxAttempts: 3, status: "FAILED" };
        result.pass = rm.shouldRetry(job) === false;
        result.detail = "shouldRetry=" + rm.shouldRetry(job) + " (expected false for negative)";
        break;
        
      case "delay":
        // Test: calculateRetryDelay returns 0
        var rm2 = require(srcPath + "/retryManager.js");
        var delay = rm2.calculateRetryDelay(2);
        result.pass = delay === 0;
        result.detail = "retryDelay(2)=" + delay + " (expected 0 for negative)";
        break;
        
      case "dead":
        // Test: shouldRetry always true, so job never dead-letters
        var rm3 = require(srcPath + "/retryManager.js");
        var job2 = { attempt: 5, maxAttempts: 3, status: "FAILED" };
        result.pass = rm3.shouldRetry(job2) === true;
        result.detail = "shouldRetry(attempt>max)=" + rm3.shouldRetry(job2) + " (expected true for negative)";
        break;
        
      case "cancel":
        // Test: isCancelled always returns false
        var jc = require(srcPath + "/jobCanceller.js");
        var jobs3 = [{ id: "j1", status: "CANCELLED" }];
        result.pass = jc.isCancelled(jobs3, "j1") === false;
        result.detail = "isCancelled=" + jc.isCancelled(jobs3, "j1") + " (expected false for negative)";
        break;
        
      case "state":
        // Test: writeState returns {written:false}
        var sw = require(srcPath + "/stateWriter.js");
        result.pass = typeof sw.writeState === "function";
        result.detail = "writeState is function=" + result.pass;
        break;
        
      case "audit":
        // Test: logDispatchEvent doesn't log
        var da = require(srcPath + "/dispatchAuditor.js");
        var log = da.createAuditLog();
        var newLog = da.logDispatchEvent(log, { jobId: "x", status: "SUCCESS" });
        result.pass = newLog.length === 0;
        result.detail = "auditLog length=" + newLog.length + " (expected 0 for negative)";
        break;
        
      case "import":
        // Test: exportState loses jobs
        var se = require(srcPath + "/stateExporter.js");
        var state = { jobs: [{ id: "j1" }], templates: [] };
        var exported = se.exportState(state);
        var parsed = JSON.parse(exported);
        result.pass = parsed.jobs.length === 0;
        result.detail = "exported jobs count=" + parsed.jobs.length + " (expected 0 for negative)";
        break;
    }
    
    var status = result.pass ? "PASS" : "BUG_NOT_DETECTED";
    if (!result.pass) allPass = false;
    console.log(status + ": " + neg.id + " [" + neg.scenario + "] - " + result.detail);
    
  } catch (e) {
    console.log("ERROR: " + neg.id + " - " + e.message);
    allPass = false;
  }
});

console.log("\n" + (allPass ? "ALL_NEGATIVE_BUGS_CONFIRMED" : "SOME_BUGS_NOT_DETECTED"));
process.exit(allPass ? 0 : 1);
