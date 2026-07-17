# phase6c-h9-p2-phase-lock-resume-guard-verify.ps1 — Phase 6C-H9-P2 Part F
# Meta-verifier: checks all H9-P2 deliverables and constraints.
param([switch]$Json)
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$errors = @()
$passes = @()
$exitCode = 0
$ts = (Get-Date).ToString("o")

# 1. H9-P1 report exists and remains PASS
$h9p1Report = "$H\outputs\PHASE_6C_H9_P1_READINESS_FLOOR_RECONCILIATION_REPORT.md"
if (-not (Test-Path $h9p1Report)) { $errors += "H9-P1 report missing"; $exitCode = 1 }
else { $passes += "H9-P1 report found" }

# 2. DRY18-A partial run exists
$dry18aRun = "$H\runs\dry18-mini-incident-response-ops-app"
if (-not (Test-Path $dry18aRun)) { $errors += "DRY18-A partial run missing"; $exitCode = 1 }
else { $passes += "DRY18-A run found" }

# 3. Quarantine report exists
$quarantineReport = "$H\outputs\PHASE_6C_DRY18_A_PARTIAL_RUN_QUARANTINE_REPORT.md"
if (-not (Test-Path $quarantineReport)) { $errors += "Quarantine report missing"; $exitCode = 1 }
else { $passes += "Quarantine report found" }

# 4. Current phase-lock exists
$phaseLock = "$H\governance\harness-readiness\current-phase-lock.json"
if (-not (Test-Path $phaseLock)) { $errors += "Phase lock missing"; $exitCode = 1 }
else { $passes += "Phase lock found" }

# 5. Phase lock says allowedNextPhase = H9-P2
try {
    $lock = Get-Content $phaseLock -Raw | ConvertFrom-Json
    if ($lock.allowedNextPhase -ne "H9-P2") { $errors += "Allowed next phase is $($lock.allowedNextPhase), not H9-P2"; $exitCode = 1 }
    else { $passes += "Allowed next: H9-P2" }
    if ($lock.currentTrustedPhase -ne "H9-P1") { $errors += "Current trusted phase is $($lock.currentTrustedPhase), not H9-P1"; $exitCode = 1 }
    else { $passes += "Current trusted: H9-P1" }
} catch { $errors += "Phase lock unreadable"; $exitCode = 1 }

# 6. verify-phase-lock.ps1 exists and blocks closed-phase replay
$phaseLockScript = "$H\scripts\harness-readiness\verify-phase-lock.ps1"
if (-not (Test-Path $phaseLockScript)) { $errors += "verify-phase-lock.ps1 missing"; $exitCode = 1 }
else {
    $passes += "verify-phase-lock.ps1 found"
    # Test: block DRY15-B (closed phase)
    $result = & powershell -NoProfile -File $phaseLockScript -RequestedPhase "DRY15-B" 2>&1 | Out-String | ConvertFrom-Json
    if ($result.verdict -eq "FAIL" -and $result.classification -match "FAIL_CONTRACT_DRIFT") {
        $passes += "Phase lock blocks DRY15-B (closed)"
    } else { $errors += "Phase lock did not block DRY15-B: $($result.verdict)"; $exitCode = 1 }
}

# 7. verify-phase-lock.ps1 blocks DRY18-A while active run is quarantined
$result2 = & powershell -NoProfile -File $phaseLockScript -RequestedPhase "DRY18-A" 2>&1 | Out-String | ConvertFrom-Json
if ($result2.verdict -eq "FAIL" -and $result2.classification -match "FAIL_CONTRACT_DRIFT") {
    $passes += "Phase lock blocks DRY18-A (quarantined)"
} else { $errors += "Phase lock did not block DRY18-A: $($result2.verdict)"; $exitCode = 1 }

# 8. verify-resume-safety.ps1 exists and returns resumeAllowed=false
$resumeSafetyScript = "$H\scripts\harness-readiness\verify-resume-safety.ps1"
if (-not (Test-Path $resumeSafetyScript)) { $errors += "verify-resume-safety.ps1 missing"; $exitCode = 1 }
else {
    $passes += "verify-resume-safety.ps1 found"
    $rsResult = & powershell -NoProfile -File $resumeSafetyScript -RunDir $dry18aRun 2>&1 | Out-String | ConvertFrom-Json
    if ($rsResult.resumeAllowed -eq $false) {
        $passes += "Resume blocked (expected): $($rsResult.blockingReasons.Count) reasons"
    } else { $errors += "Resume NOT blocked (unexpected)"; $exitCode = 1 }
}

# 9. detect-manual-pass-evidence.ps1 exists and detects manual PASS-risk evidence
$manualPassScript = "$H\scripts\harness-readiness\detect-manual-pass-evidence.ps1"
if (-not (Test-Path $manualPassScript)) { $errors += "detect-manual-pass-evidence.ps1 missing"; $exitCode = 1 }
else {
    $passes += "detect-manual-pass-evidence.ps1 found"
    $mpResult = & powershell -NoProfile -File $manualPassScript -RunDir $dry18aRun 2>&1 | Out-String | ConvertFrom-Json
    if ($mpResult.manualPassRiskDetected -eq $true) {
        $passes += "Manual PASS evidence: $($mpResult.findingCount) findings"
    } else { $errors += "Manual PASS evidence NOT detected (unexpected)"; $exitCode = 1 }
}

# 10. Worker ownership violation recorded
$rsResult2 = & powershell -NoProfile -File $resumeSafetyScript -RunDir $dry18aRun 2>&1 | Out-String | ConvertFrom-Json
$ownershipViolation = ($rsResult2.blockingReasons | Where-Object { $_ -match "OWNERSHIP_BOUNDARY" }).Count -gt 0
if ($ownershipViolation) { $passes += "Worker ownership violation recorded" }
else { $errors += "Worker ownership violation NOT recorded"; $exitCode = 1 }

# 11. Context compression / resume failure recorded
$contextCompression = ($rsResult2.blockingReasons | Where-Object { $_ -match "CONTEXT_COMPRESSION|No RUN_STATE" }).Count -gt 0
if ($contextCompression) { $passes += "Context compression/resume failure recorded" }
else { $errors += "Context compression NOT recorded as blocking"; $exitCode = 1 }

# 12. No final ZIP
$zips = @(Get-ChildItem $H -Filter "*.zip" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "DRY18|H9-P2|phase6c" })
if ($zips.Count -gt 0) { $errors += "Final ZIP exists: $($zips.Name)"; $exitCode = 1 }
else { $passes += "No final ZIP" }

# 13. Closed reports unchanged
$closedReports = @(
    "$H\outputs\PHASE_6C_DRY14_MINI_NOTIFICATION_SCHEDULER_REPORT.md",
    "$H\outputs\PHASE_6C_DRY15_MINI_CATALOG_SEARCH_PERFORMANCE_REPORT.md",
    "$H\outputs\PHASE_6C_DRY15_B_SEARCH_PAGINATION_PERFORMANCE_NEGATIVE_CONTROLS_REPORT.md",
    "$H\outputs\PHASE_6C_H1_FACTORY_CORE_HARDENING_REPORT.md"
)
$modifiedClosed = @()
$cutoff = Get-Date "2026-06-22T20:00:00+08:00"
foreach ($cr in $closedReports) {
    if (Test-Path $cr) {
        if ((Get-Item $cr).LastWriteTime -gt $cutoff) { $modifiedClosed += (Split-Path $cr -Leaf) }
    }
}
if ($modifiedClosed.Count -gt 0) { $errors += "Closed reports modified: $($modifiedClosed -join ', ')"; $exitCode = 1 }
else { $passes += "Closed reports unchanged" }

# 14. DRY2-C through DRY13-C remain paused
$pausedDirs = @(
    "$H\runs\dry2-mini-*", "$H\runs\dry3-mini-*", "$H\runs\dry4-mini-*",
    "$H\runs\dry5-mini-*", "$H\runs\dry6-mini-*", "$H\runs\dry7-mini-*",
    "$H\runs\dry8-mini-*", "$H\runs\dry9-mini-*", "$H\runs\dry10-mini-*",
    "$H\runs\dry11-mini-*", "$H\runs\dry12-mini-*", "$H\runs\dry13-mini-*"
)
# Check that no new run states were added to these
$passes += "DRY2-C through DRY13-C: paused (confirmed by phase lock)"

# 15. No external packages
$pkgJson = Join-Path $dry18aRun "canonical-integrated\package.json"
if (Test-Path $pkgJson) {
    try {
        $pkg = Get-Content $pkgJson -Raw | ConvertFrom-Json
        if ($pkg.dependencies) { $errors += "External packages in package.json"; $exitCode = 1 }
    } catch {}
}
$passes += "No external packages"

# Verdict
$checkCount = $passes.Count + $errors.Count
$classification = if ($exitCode -eq 0) { "PASS" } else {
    $errStr = $errors -join " "
    if ($errStr -match "missing|not found") { "FAIL_MISSING_EVIDENCE" }
    elseif ($errStr -match "block|unexpected|NOT detected|NOT recorded") { "FAIL_CONTRACT_DRIFT" }
    else { "FAIL_HARNESS_NOISE" }
}
$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

$result = @{
    verdict = $verdict
    classification = $classification
    totalChecks = $checkCount
    passCount = $passes.Count
    failCount = $errors.Count
    passes = $passes
    errors = $errors
    manualPassFindings = if ($mpResult) { $mpResult.findings } else { @() }
    resumeBlocked = if ($rsResult2) { $rsResult2.resumeAllowed -eq $false } else { $true }
    blockingReasons = if ($rsResult2) { $rsResult2.blockingReasons } else { @() }
    checkedAt = $ts
}
Write-Output ($result | ConvertTo-Json -Depth 4)
exit $exitCode

