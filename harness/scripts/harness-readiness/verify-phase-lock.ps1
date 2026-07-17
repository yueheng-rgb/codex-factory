# verify-phase-lock.ps1 — Phase 6C-H9-P2 Part C
# Closed-phase replay guard. Prevents Codex from restarting closed phases.
param(
    [Parameter(Mandatory=$true)][string]$RequestedPhase,
    [string]$PhaseLockPath = "",
    [switch]$Json
)
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
if (-not $PhaseLockPath) { $PhaseLockPath = "$H\governance\harness-readiness\current-phase-lock.json" }
$errors = @()
$passes = @()
$exitCode = 0
$ts = (Get-Date).ToString("o")

# Check 1: Phase lock exists
if (-not (Test-Path $PhaseLockPath)) {
    $result = @{verdict="FAIL_MISSING_EVIDENCE"; reason="Phase lock not found"; requestedPhase=$RequestedPhase; checkedAt=$ts}
    Write-Output ($result | ConvertTo-Json)
    exit 1
}
$passes += "Phase lock exists"

try {
    $lock = Get-Content $PhaseLockPath -Raw | ConvertFrom-Json
} catch {
    $result = @{verdict="FAIL_HARNESS_NOISE"; reason="Phase lock malformed"; requestedPhase=$RequestedPhase; checkedAt=$ts}
    Write-Output ($result | ConvertTo-Json)
    exit 1
}

# Check 2: Phase lock has required fields
$requiredFields = @("currentTrustedPhase","allowedNextPhase","forbiddenClosedPhases","activeRunId","activeRunStatus")
foreach ($f in $requiredFields) {
    if (-not $lock.$f) { $errors += "Phase lock missing field: $f"; $exitCode = 1 }
    else { $passes += "Field present: $f" }
}

# Check 3: Requested phase is not a closed phase
if ($lock.forbiddenClosedPhases -contains $RequestedPhase) {
    $errors += "CLOSED_PHASE_REPLAY_BLOCKED: $RequestedPhase is in forbiddenClosedPhases"
    $exitCode = 1
} else {
    $passes += "Phase not closed: $RequestedPhase"
}

# Check 4: If active run is quarantined, block DRY18-A
if ($lock.activeRunStatus -eq "QUARANTINED_PARTIAL_RUN" -and $RequestedPhase -match "DRY18-A|DRY18") {
    $errors += "QUARANTINED_RUN_BLOCKED: $RequestedPhase blocked while active run ($($lock.activeRunId)) is QUARANTINED_PARTIAL_RUN"
    $exitCode = 1
}

# Check 5: Requested phase must be allowedNextPhase (if not H9-P2 or a sub-phase of it)
if ($RequestedPhase -ne $lock.allowedNextPhase -and $RequestedPhase -notmatch "^H9-P2") {
    $errors += "PHASE_NOT_ALLOWED: $RequestedPhase is not allowedNextPhase ($($lock.allowedNextPhase))"
    $exitCode = 1
} else {
    $passes += "Phase allowed: $RequestedPhase"
}

# Check 6: Stale context detection — phase lock has update timestamp
if (-not $lock.phaseLockUpdatedAt) {
    $errors += "STALE_CONTEXT: No phaseLockUpdatedAt timestamp"
    $exitCode = 1
} else {
    $passes += "Phase lock timestamp present"
}

# Check 7: Resume blocked check
if ($lock.resumeBlocked -eq $true -and $RequestedPhase -match "DRY18-A") {
    $errors += "RESUME_BLOCKED: Active run resume is blocked: $($lock.resumeBlockingReasons -join '; ')"
    $exitCode = 1
}

# Classification
$classification = if ($exitCode -eq 0) { "PASS" } else {
    $errStr = $errors -join " "
    if ($errStr -match "CLOSED_PHASE_REPLAY") { "FAIL_CONTRACT_DRIFT" }
    elseif ($errStr -match "QUARANTINED|RESUME_BLOCKED|PHASE_NOT_ALLOWED") { "FAIL_CONTRACT_DRIFT" }
    elseif ($errStr -match "STALE_CONTEXT|missing field") { "FAIL_MISSING_EVIDENCE" }
    else { "FAIL_HARNESS_NOISE" }
}

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{
    verdict = $verdict
    classification = $classification
    requestedPhase = $RequestedPhase
    allowedNextPhase = $lock.allowedNextPhase
    activeRunStatus = $lock.activeRunStatus
    resumeBlocked = $lock.resumeBlocked
    passes = $passes
    errors = $errors
    checkedAt = $ts
}
Write-Output ($result | ConvertTo-Json -Depth 3)
exit $exitCode

