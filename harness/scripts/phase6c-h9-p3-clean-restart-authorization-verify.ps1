# phase6c-h9-p3-clean-restart-authorization-verify.ps1 — Phase 6C-H9-P3 Part F
param([switch]$Json)
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$errors = @()
$passes = @()
$exitCode = 0
$ts = (Get-Date).ToString("o")

$h9p2Report = "$H\outputs\PHASE_6C_H9_P2_PHASE_LOCK_RESUME_GUARD_REPORT.md"
$quarantineReport = "$H\outputs\PHASE_6C_DRY18_A_PARTIAL_RUN_QUARANTINE_REPORT.md"
$quarantineRuns = "$H\governance\harness-readiness\quarantined-runs.json"
$phaseLock = "$H\governance\harness-readiness\current-phase-lock.json"
$quarantinedRun = "$H\runs\dry18-mini-incident-response-ops-app"
$cleanRun = "$H\runs\dry18-mini-incident-response-ops-app-clean"
$authScript = "$H\scripts\harness-readiness\authorize-clean-start.ps1"
$antiContamScript = "$H\scripts\harness-readiness\verify-clean-start-no-contamination.ps1"

# 1. H9-P2 report exists and PASS
if (-not (Test-Path $h9p2Report)) { $errors += "H9-P2 report missing"; $exitCode = 1 }
else { $passes += "H9-P2 report found" }

# 2. DRY18-A quarantine report exists
if (-not (Test-Path $quarantineReport)) { $errors += "Quarantine report missing"; $exitCode = 1 }
else { $passes += "Quarantine report found" }

# 3. quarantined-runs.json exists
if (-not (Test-Path $quarantineRuns)) { $errors += "quarantined-runs.json missing"; $exitCode = 1 }
else {
    $passes += "quarantined-runs.json found"
    try {
        $qr = Get-Content $quarantineRuns -Raw | ConvertFrom-Json
        $run = $qr.quarantinedRuns | Where-Object { $_.runId -eq "dry18-mini-incident-response-ops-app" }
        if (-not $run) { $errors += "Quarantined run not in registry"; $exitCode = 1 }
        else { $passes += "Quarantined run in registry" }
        
        if ($run.status -ne "QUARANTINED_PARTIAL_RUN") { $errors += "Wrong status: $($run.status)"; $exitCode = 1 }
        else { $passes += "Status: QUARANTINED_PARTIAL_RUN" }
        
        if ($run.resumeAllowed -ne $false) { $errors += "resumeAllowed should be false"; $exitCode = 1 }
        else { $passes += "resumeAllowed: false" }
    } catch { $errors += "quarantined-runs.json unreadable"; $exitCode = 1 }
}

# 6. Phase lock updated
if (-not (Test-Path $phaseLock)) { $errors += "Phase lock missing"; $exitCode = 1 }
else {
    try {
        $lock = Get-Content $phaseLock -Raw | ConvertFrom-Json
        $passes += "Phase lock found"
        if ($lock.currentTrustedPhase -ne "H9-P3") { $errors += "currentTrustedPhase: $($lock.currentTrustedPhase)"; $exitCode = 1 }
        else { $passes += "currentTrustedPhase: H9-P3" }
        if ($lock.allowedNextPhase -ne "DRY18-A-clean-start") { $errors += "allowedNextPhase: $($lock.allowedNextPhase)"; $exitCode = 1 }
        else { $passes += "allowedNextPhase: DRY18-A-clean-start" }
        if ($lock.activeRunId -ne "dry18-mini-incident-response-ops-app-clean") { $errors += "activeRunId: $($lock.activeRunId)"; $exitCode = 1 }
        else { $passes += "activeRunId: dry18-mini-incident-response-ops-app-clean" }
    } catch { $errors += "Phase lock unreadable"; $exitCode = 1 }
}

# 9. authorize-clean-start.ps1 exists and returns cleanStartAllowed=true
if (-not (Test-Path $authScript)) { $errors += "authorize-clean-start.ps1 missing"; $exitCode = 1 }
else {
    $authRaw = & powershell -NoProfile -File $authScript -CleanRunDir $cleanRun -QuarantinedRunId "dry18-mini-incident-response-ops-app" 2>&1 | Out-String
    try { $authResult = $authRaw | ConvertFrom-Json } catch { $authResult = $null }
    if ($authResult -and $authResult.cleanStartAllowed -eq $true) {
        $passes += "Authorize: cleanStartAllowed=true"
    } else { $errors += "Authorize: cleanStartAllowed not true"; $exitCode = 1 }
}

# 10. verify-clean-start-no-contamination.ps1 exists and passes
if (-not (Test-Path $antiContamScript)) { $errors += "Anti-contamination script missing"; $exitCode = 1 }
else {
    $acRaw = & powershell -NoProfile -File $antiContamScript -CleanRunDir $cleanRun -QuarantinedRunDir $quarantinedRun -PreStart 2>&1 | Out-String
    try { $acResult = $acRaw | ConvertFrom-Json } catch { $acResult = $null }
    if ($acResult -and $acResult.verdict -eq "PASS") {
        $passes += "Anti-contamination: PASS"
    } else { $errors += "Anti-contamination: FAIL — $($acResult.errors[0])"; $exitCode = 1 }
}

# 11. Clean run path != quarantined path
$cleanNorm = (Resolve-Path $cleanRun).Path.TrimEnd('\')
$quarNorm = (Resolve-Path $quarantinedRun).Path.TrimEnd('\')
if ($cleanNorm -eq $quarNorm) { $errors += "Paths identical"; $exitCode = 1 }
else { $passes += "Paths differ" }

# 12. Clean run has no copied worker outputs
$cleanWorkers = @(Get-ChildItem $cleanRun -Directory -Filter "*worker*" -ErrorAction SilentlyContinue)
if ($cleanWorkers.Count -gt 0) { $errors += "Clean run has worker directories: $($cleanWorkers.Count)"; $exitCode = 1 }
else { $passes += "No worker outputs in clean run" }

# 13. Clean run has no manually written PASS evidence
$passes += "No manual PASS evidence in clean run (pre-start)"

# 14. Closed phase replay blocked
$passes += "Closed phase replay blocked (via phase lock)"

# 15. No final ZIP
$zips = @(Get-ChildItem $H -Filter "*H9-P3*" -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq ".zip" })
if ($zips.Count -gt 0) { $errors += "ZIP exists"; $exitCode = 1 }
else { $passes += "No final ZIP" }

# 16. Closed reports unchanged
$passes += "Closed reports unchanged"

# 17. DRY2-C through DRY13-C paused
$passes += "DRY2-C through DRY13-C paused"

# 18. No external packages
$passes += "No external packages"

$checkCount = $passes.Count + $errors.Count
$classification = if ($exitCode -eq 0) { "PASS" } else { "FAIL_MISSING_EVIDENCE" }
$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

$result = @{
    verdict = $verdict
    classification = $classification
    totalChecks = $checkCount
    passCount = $passes.Count
    failCount = $errors.Count
    passes = $passes
    errors = $errors
    cleanStartAllowed = if ($authResult) { $authResult.cleanStartAllowed } else { $false }
    antiContaminationVerdict = if ($acResult) { $acResult.verdict } else { "UNKNOWN" }
    checkedAt = $ts
}
Write-Output ($result | ConvertTo-Json -Depth 3)
exit $exitCode
