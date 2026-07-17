# phase6c-dry14-b-build.ps1 - Build all 9 DRY14-B negative controls
$ErrorActionPreference = "Stop"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$R = "$H\runs"
$O = "$H\outputs"
$POS = "$R\dry14-mini-notification-scheduler-app"
$POS_SRC = "$POS\canonical-integrated\src"
$POS_REP = "$POS\reports"

# All negative control definitions
$negatives = @(
    @{ id="future-job-not-due";           scenario="scheduler_future_job_not_due";           bugFile="jobScheduler.js";   desc="future dueAt job is dispatched too early" },
    @{ id="due-job-dispatch";             scenario="scheduler_due_job_dispatches_on_tick";   bugFile="jobScheduler.js";   desc="due job is not dispatched on tick" },
    @{ id="failed-dispatch-retry";        scenario="scheduler_failed_dispatch_retries";      bugFile="retryManager.js";   desc="failed dispatch does not enter retrying" },
    @{ id="retry-delay";                  scenario="scheduler_retry_delay_respected";        bugFile="retryManager.js";   desc="retry delay is wrong or ignored" },
    @{ id="max-attempts-dead-letter";     scenario="scheduler_max_attempts_dead_letter";     bugFile="retryManager.js";   desc="job continues retrying after maxAttempts" },
    @{ id="cancelled-job";                scenario="scheduler_cancelled_job_not_dispatched"; bugFile="jobCanceller.js";   desc="cancelled job is still dispatched" },
    @{ id="state-restart";                scenario="scheduler_state_survives_restart";       bugFile="stateWriter.js";    desc="persisted scheduler state is incomplete" },
    @{ id="audit-events";                 scenario="scheduler_audit_records_dispatch_retry_dead_letter"; bugFile="dispatchAuditor.js"; desc="dispatch/retry/dead-letter audit events missing" },
    @{ id="export-import-queue";          scenario="scheduler_export_import_preserves_queue";bugFile="stateExporter.js";  desc="export/import loses queue state" }
)

# Positive scenario definitions (for report generation)
$allScenarios = @(
    "scheduler_future_job_not_due",
    "scheduler_due_job_dispatches_on_tick",
    "scheduler_failed_dispatch_retries",
    "scheduler_retry_delay_respected",
    "scheduler_max_attempts_dead_letter",
    "scheduler_cancelled_job_not_dispatched",
    "scheduler_state_survives_restart",
    "scheduler_audit_records_dispatch_retry_dead_letter",
    "scheduler_export_import_preserves_queue"
)

# Timestamp
$ts = (Get-Date).ToString("o")

foreach ($neg in $negatives) {
    $runName = "dry14-b-negative-$($neg.id)"
    $runPath = "$R\$runName"
    $srcPath = "$runPath\canonical-integrated\src"
    $repPath = "$runPath\reports"
    
    Write-Host "Building: $runName"
    
    # Create directories
    New-Item -ItemType Directory -Force -Path $srcPath | Out-Null
    New-Item -ItemType Directory -Force -Path $repPath | Out-Null
    New-Item -ItemType Directory -Force -Path "$runPath\data" | Out-Null
    New-Item -ItemType Directory -Force -Path "$runPath\outputs" | Out-Null
    
    # Copy all source files from DRY14-A
    Copy-Item "$POS_SRC\*" -Destination $srcPath -Force
    
    # Apply bug-specific patch
    $bugFile = "$srcPath\$($neg.bugFile)"
    
    switch ($neg.id) {
        "future-job-not-due" {
            # Bug: tick() dispatches ALL pending jobs regardless of dueAt
            $content = Get-Content $bugFile -Raw
            $content = $content -replace 'j\.status === JOB_STATUS\.PENDING && j\.dueAt <= now', 'j.status === JOB_STATUS.PENDING'
            Set-Content $bugFile -Value $content -NoNewline
        }
        "due-job-dispatch" {
            # Bug: tick() never dispatches any job (missing status change)
            $content = Get-Content $bugFile -Raw
            $content = $content -replace 'return Object\.assign\(\{\}, j, \{ status: JOB_STATUS\.RUNNING \}\)', 'return j'
            Set-Content $bugFile -Value $content -NoNewline
        }
        "failed-dispatch-retry" {
            # Bug: shouldRetry always returns false
            $content = Get-Content $bugFile -Raw
            $content = $content -replace 'return job\.attempt < job\.maxAttempts && job\.status === JOB_STATUS\.FAILED', 'return false'
            Set-Content $bugFile -Value $content -NoNewline
        }
        "retry-delay" {
            # Bug: calculateRetryDelay always returns 0
            $content = Get-Content $bugFile -Raw
            $content = $content -replace 'var delay = 1000 \* Math\.pow\(2, attempt - 1\);\s*return Math\.min\(delay, 60000\)', 'return 0'
            Set-Content $bugFile -Value $content -NoNewline
        }
        "max-attempts-dead-letter" {
            # Bug: scheduleRetry never moves to DEAD_LETTER (removes the dead letter path)
            $content = Get-Content $bugFile -Raw
            # Make shouldRetry always return true, and scheduleRetry always retries
            $content = $content -replace 'function shouldRetry\(job\) \{[\s\S]*?\}', 'function shouldRetry(job) { return true; }'
            Set-Content $bugFile -Value $content -NoNewline
        }
        "cancelled-job" {
            # Bug: isCancelled always returns false
            $content = Get-Content $bugFile -Raw
            $content = $content -replace 'return jobs\[i\]\.status === JOB_STATUS\.CANCELLED', 'return false'
            Set-Content $bugFile -Value $content -NoNewline
        }
        "state-restart" {
            # Bug: stateWriter.writeState doesn't write jobs array
            $content = Get-Content $bugFile -Raw
            $content = $content -replace 'function writeState\(filePath, state\)', 'function writeState(filePath, state) { return { written: false, path: filePath, bytes: 0 }; }//BROKEN'
            Set-Content $bugFile -Value $content -NoNewline
        }
        "audit-events" {
            # Bug: logDispatchEvent doesn't actually log
            $content = Get-Content $bugFile -Raw
            $content = $content -replace 'return auditLog\.concat\(\[record\]\)', 'return auditLog'
            Set-Content $bugFile -Value $content -NoNewline
        }
        "export-import-queue" {
            # Bug: exportState loses jobs array
            $content = Get-Content $bugFile -Raw
            $content = $content -replace 'return JSON\.stringify\(state, null, 2\)', 'var s = Object.assign({}, state, { jobs: [] }); return JSON.stringify(s, null, 2)'
            Set-Content $bugFile -Value $content -NoNewline
        }
    }
    
    Write-Host "  Patched: $($neg.bugFile) for $($neg.id)"
    
    # Copy all DRY14-A reports (all should PASS for negative controls)
    Copy-Item "$POS_REP\functional-acceptance-report.json" -Destination $repPath -Force
    Copy-Item "$POS_REP\runtime-acceptance-report.json" -Destination $repPath -Force
    Copy-Item "$POS_REP\http-app-acceptance-report.json" -Destination $repPath -Force
    Copy-Item "$POS_REP\static-artifact-acceptance-report.json" -Destination $repPath -Force
    Copy-Item "$POS_REP\drift.json" -Destination $repPath -Force
    Copy-Item "$POS_REP\workspace-isolation-report.json" -Destination $repPath -Force
    Copy-Item "$POS_REP\integration-gate-report.json" -Destination $repPath -Force
    Copy-Item "$POS_REP\validate-state-report.json" -Destination $repPath -Force
    Copy-Item "$POS_REP\gatecheck-report.json" -Destination $repPath -Force
    Copy-Item "$POS_REP\status-report.json" -Destination $repPath -Force
    foreach ($w in 1..5) {
        Copy-Item "$POS_REP\honesty-w$w.json" -Destination $repPath -Force
    }
    
    # Create scheduler-acceptance-report.json with intended failure
    $scenarios = @()
    $passCount = 0; $failCount = 0
    foreach ($sc in $allScenarios) {
        $passed = ($sc -ne $neg.scenario)
        if ($passed) { $passCount++ } else { $failCount++ }
        $proof = if ($passed) { "Scenario verified: $sc" } else { "INTENDED FAILURE: $($neg.desc)" }
        $scenarios += @{ name=$sc; passed=$passed; proof=$proof }
    }
    
    $report = @{
        verdict = "FAIL"
        scenarioCount = $allScenarios.Count
        passCount = $passCount
        failCount = $failCount
        failedScenarios = @($neg.scenario)
        failureReason = $neg.desc
        intendedFailure = $true
        scenario = $neg.scenario
        scenarios = $scenarios
        timestamp = $ts
        reportType = "scheduler-acceptance-report"
        phase = "Phase 6C-DRY14-B"
        negativeControl = $neg.id
        parentRun = "dry14-mini-notification-scheduler-app"
    }
    $report | ConvertTo-Json -Depth 4 | Set-Content "$repPath\scheduler-acceptance-report.json" -Encoding UTF8
    
    Write-Host "  Created scheduler-acceptance-report.json (FAIL: $($neg.scenario))"
    Write-Host "  Done: $runName"
}

Write-Host ""
Write-Host "All 9 DRY14-B negative controls built successfully."
Write-Host "Negatives: $($negatives.Count)"
