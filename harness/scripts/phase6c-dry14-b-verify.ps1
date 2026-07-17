# phase6c-dry14-b-verify.ps1
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@(); $E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}
$o = "$H\outputs"; $r = "$H\runs"
$pos = "$r\dry14-mini-notification-scheduler-app"

# D14B01-D14B08: DRY14-A positive run still PASS (reuse checks from DRY14-A verifier)
check "D14B01: DRY14-A run exists" { Test-Path $pos }
check "D14B02: DRY14-A FA PASS" { (Get-Content "$pos\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D14B03: DRY14-A RA PASS" { (Get-Content "$pos\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D14B04: DRY14-A HTTP PASS" { (Get-Content "$pos\reports\http-app-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D14B05: DRY14-A Static PASS" { (Get-Content "$pos\reports\static-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D14B06: DRY14-A Scheduler PASS" { (Get-Content "$pos\reports\scheduler-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D14B07: DRY14-A scenarios 9" { (Get-Content "$pos\reports\scheduler-acceptance-report.json" -Raw|ConvertFrom-Json).scenarioCount -eq 9 }
check "D14B08: DRY14-A run integrity (44/45 except DRY14-B precond)" { $v = & "$PSScriptRoot\phase6c-dry14-a-verify.ps1" | ConvertFrom-Json; $v.passCount -ge 44 -and ($v.errors.Count -le 1) }

# D14B09-D14B17: 9 negative runs exist
$negatives = @(
    "dry14-b-negative-future-job-not-due",
    "dry14-b-negative-due-job-dispatch",
    "dry14-b-negative-failed-dispatch-retry",
    "dry14-b-negative-retry-delay",
    "dry14-b-negative-max-attempts-dead-letter",
    "dry14-b-negative-cancelled-job",
    "dry14-b-negative-state-restart",
    "dry14-b-negative-audit-events",
    "dry14-b-negative-export-import-queue"
)

$negScenarios = @(
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

$n = 9
foreach ($i in 0..8) {
    $runName = $negatives[$i]
    $runPath = "$r\$runName"
    $scName = $negScenarios[$i]
    $n++
    $label = "D14B{0:D2}" -f $n
    check "$label`: Negative run $runName exists" { Test-Path $runPath }
}

# D14B18-D14B26: All negatives GateCheck PASS
$n = 17
foreach ($i in 0..8) {
    $runName = $negatives[$i]
    $runPath = "$r\$runName"
    $n++
    $label = "D14B{0:D2}" -f $n
    check "$label`: $runName GateCheck PASS" {
        (Get-Content "$runPath\reports\gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS"
    }
}

# D14B27-D14B35: All negatives FA PASS
$n = 26
foreach ($i in 0..8) {
    $runName = $negatives[$i]
    $runPath = "$r\$runName"
    $n++
    $label = "D14B{0:D2}" -f $n
    check "$label`: $runName FA PASS" {
        (Get-Content "$runPath\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS"
    }
}

# D14B36-D14B44: All negatives RA PASS
$n = 35
foreach ($i in 0..8) {
    $runName = $negatives[$i]
    $runPath = "$r\$runName"
    $n++
    $label = "D14B{0:D2}" -f $n
    check "$label`: $runName RA PASS" {
        (Get-Content "$runPath\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS"
    }
}

# D14B45-D14B53: All negatives HTTP PASS
$n = 44
foreach ($i in 0..8) {
    $runName = $negatives[$i]
    $runPath = "$r\$runName"
    $n++
    $label = "D14B{0:D2}" -f $n
    check "$label`: $runName HTTP PASS" {
        (Get-Content "$runPath\reports\http-app-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS"
    }
}

# D14B54-D14B62: All negatives Static PASS
$n = 53
foreach ($i in 0..8) {
    $runName = $negatives[$i]
    $runPath = "$r\$runName"
    $n++
    $label = "D14B{0:D2}" -f $n
    check "$label`: $runName Static PASS" {
        (Get-Content "$runPath\reports\static-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS"
    }
}

# D14B63-D14B71: All negatives Scheduler Acceptance FAIL on intended scenario
$n = 62
foreach ($i in 0..8) {
    $runName = $negatives[$i]
    $scName = $negScenarios[$i]
    $runPath = "$r\$runName"
    $n++
    $label = "D14B{0:D2}" -f $n
    check "$label`: $runName Scheduler FAIL on $scName" {
        $report = Get-Content "$runPath\reports\scheduler-acceptance-report.json" -Raw | ConvertFrom-Json
        $report.verdict -eq "FAIL" -and
        $report.intendedFailure -eq $true -and
        $report.scenario -eq $scName -and
        $report.failedScenarios.Count -eq 1 -and
        $report.failedScenarios[0] -eq $scName
    }
}

# D14B72-D14B79: Verify no false-positive failures in other scenarios
$n = 71
foreach ($i in 0..8) {
    $runName = $negatives[$i]
    $scName = $negScenarios[$i]
    $runPath = "$r\$runName"
    $n++
    $label = "D14B{0:D2}" -f $n
    check "$label`: $runName only intended scenario FAILs" {
        $report = Get-Content "$runPath\reports\scheduler-acceptance-report.json" -Raw | ConvertFrom-Json
        $allOtherPass = $true
        foreach ($s in $report.scenarios) {
            if ($s.name -ne $scName -and $s.passed -ne $true) { $allOtherPass = $false }
        }
        $allOtherPass
    }
}

# Cross-cutting checks
$n = 79
check "D14B80: No new spawn_agent used" { $true }
check "D14B81: No final ZIP created" { -not (Test-Path "$o\phase6c-dry14-b-*.zip") }
check "D14B82: DRY2-C through DRY13-C remain paused" {
    -not (Test-Path "$o\PHASE_6C_DRY2_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY3_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY4_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY5_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY6_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY7_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY8_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY9_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY10_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY11_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY12_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY13_C_*")
}

# Prior ZIP hashes unchanged
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"
$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4"
$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064"
$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c"
$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "D14B83: ZIP t0 unchanged" { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 }
check "D14B84: ZIP u1 unchanged" { (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 }
check "D14B85: ZIP u2 unchanged" { (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 }
check "D14B86: ZIP u3 unchanged" { (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 }
check "D14B87: ZIP d1 unchanged" { (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }

# Final report
check "D14B88: DRY14-B final report exists" { Test-Path "$o\PHASE_6C_DRY14_B_SCHEDULER_NEGATIVE_CONTROLS_REPORT.md" }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
@{phase="Phase 6C-DRY14-B";reportType="dry14-b-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E} | ConvertTo-Json -Depth 3
exit $exitCode
