# verify-resume-safety.ps1 — Phase 6C-H9-P2 Part D
# Post-compression / partial-run resume safety guard.
param(
    [Parameter(Mandatory=$true)][string]$RunDir,
    [string]$PhaseLockPath = "",
    [string]$QuarantineReportPath = "",
    [string]$ManualPassDetectorScript = "",
    [switch]$Json
)
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
if (-not $PhaseLockPath) { $PhaseLockPath = "$H\governance\harness-readiness\current-phase-lock.json" }
if (-not $QuarantineReportPath) { $QuarantineReportPath = "$H\outputs\PHASE_6C_DRY18_A_PARTIAL_RUN_QUARANTINE_REPORT.md" }
if (-not $ManualPassDetectorScript) { $ManualPassDetectorScript = "$H\scripts\harness-readiness\detect-manual-pass-evidence.ps1" }

$errors = @()
$passes = @()
$exitCode = 0
$ts = (Get-Date).ToString("o")
$resumeAllowed = $false

# Check 1: Phase lock exists
if (-not (Test-Path $PhaseLockPath)) {
    $errors += "Phase lock not found"
    $exitCode = 1
} else { $passes += "Phase lock present" }

# Check 2: Active run status understood
try {
    $lock = Get-Content $PhaseLockPath -Raw | ConvertFrom-Json
    if (-not $lock.activeRunStatus) { $errors += "Active run status missing in phase lock"; $exitCode = 1 }
    else { $passes += "Active run status: $($lock.activeRunStatus)" }
} catch { $errors += "Phase lock unreadable"; $exitCode = 1 }

# Check 3: Quarantine report exists
if (-not (Test-Path $QuarantineReportPath)) {
    $errors += "Quarantine report not found"
    $exitCode = 1
} else { $passes += "Quarantine report present" }

# Check 4: No manually written PASS evidence treated as verifier output
$manualPassResults = $null
if (Test-Path $ManualPassDetectorScript) {
    $mpRaw = & powershell -NoProfile -File $ManualPassDetectorScript -RunDir $RunDir 2>&1 | Out-String
    try { $manualPassResults = $mpRaw | ConvertFrom-Json } catch {}
    if ($manualPassResults -and $manualPassResults.manualPassRiskDetected -eq $true) {
        $errors += "MANUAL_PASS_EVIDENCE: $($manualPassResults.findings.Count) files with manual PASS risk"
        $exitCode = 1
    } elseif ($manualPassResults) {
        $passes += "No manual PASS evidence detected"
    }
} else {
    $errors += "Manual PASS detector script not found"
    $exitCode = 1
}

# Check 5: Readiness evidence has command/transcript/verifier output
$readinessJson = Join-Path $RunDir "readiness\dry18-readiness.json"
if (Test-Path $readinessJson) {
    try {
        $rj = Get-Content $readinessJson -Raw | ConvertFrom-Json
        $hasCommand = ($rj.command -or $rj.verifierScript -or $rj.transcriptPath)
        if (-not $hasCommand) {
            $errors += "READINESS_NO_VERIFIER: dry18-readiness.json has no command/transcript/verifier output"
            $exitCode = 1
        } else { $passes += "Readiness evidence has verifier output" }
    } catch { $errors += "Cannot parse readiness JSON"; $exitCode = 1 }
}

# Check 6: Pre-spawn evidence has verifier output
$preSpawnJson = Join-Path $RunDir "readiness\pre-spawn-validation-result.json"
if (Test-Path $preSpawnJson) {
    try {
        $ps = Get-Content $preSpawnJson -Raw | ConvertFrom-Json
        $hasValidator = ($ps.validatorScript -or $ps.command -or $ps.transcriptPath)
        if (-not $hasValidator) {
            $errors += "PRE_SPAWN_NO_VALIDATOR: pre-spawn-validation-result.json has no verify-pre-spawn output"
            $exitCode = 1
        } else { $passes += "Pre-spawn evidence has verifier output" }
    } catch { $errors += "Cannot parse pre-spawn JSON"; $exitCode = 1 }
}

# Check 7: Worker ownership violations detected
$worker4Health = Join-Path $RunDir "workspace\worker-4-workspace\src\healthChecker.js"
$worker4Contract = Join-Path $RunDir "contracts\worker-4-contract.json"
$ownershipViolation = $false
if ((Test-Path $worker4Health) -and (Test-Path $worker4Contract)) {
    try {
        $wc4 = Get-Content $worker4Contract -Raw | ConvertFrom-Json
        if ($wc4.ownedFiles -contains "healthChecker.js") {
            # Owned by worker, but check if freeze exists
            $freezeDir = Join-Path $RunDir "worker-freeze-manifests"
            $freezeManifests = @(Get-ChildItem $freezeDir -Filter "*.freeze.json" -ErrorAction SilentlyContinue)
            if ($freezeManifests.Count -eq 0) {
                # No freeze manifests — can't prove worker wrote it
                $ownershipViolation = $true
                $errors += "OWNERSHIP_BOUNDARY_RISK: healthChecker.js in worker-4 workspace but no freeze manifest"
                $exitCode = 1
            } else { $passes += "Worker 4 has freeze manifest" }
        }
    } catch {}
}
if (-not $ownershipViolation) {
    # Check if RUN_STATE has worker completion events
    $stateFile = Join-Path $RunDir "RUN_STATE.jsonl"
    if (Test-Path $stateFile) {
        $passes += "RUN_STATE exists for ownership verification"
    } else {
        # No RUN_STATE at all — cannot verify worker ownership
        $ownershipViolation = $true
        $errors += "OWNERSHIP_BOUNDARY_RISK: No RUN_STATE, cannot verify workers executed"
        $exitCode = 1
    }
}

# Check 8: If ownership violation, resume blocked
if ($ownershipViolation) { $errors += "RESUME_BLOCKED: Worker ownership violation detected"; $exitCode = 1 }

# Check 9: If worker spawning incomplete, resume requires plan
$workerDirs = @(Get-ChildItem (Join-Path $RunDir "workspace") -Directory -ErrorAction SilentlyContinue)
$contractDirs = @(Get-ChildItem (Join-Path $RunDir "contracts") -Filter "worker-*.json" -ErrorAction SilentlyContinue)
if ($workerDirs.Count -lt 5 -or $contractDirs.Count -lt 5) {
    $errors += "WORKER_SPAWN_INCOMPLETE: $($workerDirs.Count) workspaces, $($contractDirs.Count) contracts"
    $exitCode = 1
} else { $passes += "Worker spawns complete (5 workers)" }

# Check 10: Context compression — resume capsule required
$resumeCapsulePath = Join-Path $RunDir "resume-capsule.json"
if (-not (Test-Path $resumeCapsulePath)) {
    # Context compression suspected — check for RUN_STATE events
    $stateFile = Join-Path $RunDir "RUN_STATE.jsonl"
    if (-not (Test-Path $stateFile)) {
        $errors += "CONTEXT_COMPRESSION_RESUME_BLOCKED: No RUN_STATE, no resume capsule — stale context risk"
        $exitCode = 1
    } else { $passes += "RUN_STATE present (resume context available)" }
} else { $passes += "Resume capsule present" }

# Check 11: Closed reports unchanged
$closedReports = @(
    "$H\outputs\PHASE_6C_DRY14_MINI_NOTIFICATION_SCHEDULER_REPORT.md",
    "$H\outputs\PHASE_6C_DRY15_MINI_CATALOG_SEARCH_PERFORMANCE_REPORT.md",
    "$H\outputs\PHASE_6C_DRY15_B_SEARCH_PAGINATION_PERFORMANCE_NEGATIVE_CONTROLS_REPORT.md",
    "$H\outputs\PHASE_6C_H1_FACTORY_CORE_HARDENING_REPORT.md",
    "$H\outputs\PHASE_6C_H1_P1_EVIDENCE_RECONCILIATION_REPORT.md"
)
$modifiedClosed = @()
foreach ($cr in $closedReports) {
    if (Test-Path $cr) {
        $mtime = (Get-Item $cr).LastWriteTime
        if ($mtime -gt (Get-Date "2026-06-22T20:00:00+08:00")) {
            $modifiedClosed += (Split-Path $cr -Leaf)
        }
    }
}
if ($modifiedClosed.Count -gt 0) {
    $errors += "CLOSED_REPORT_MODIFIED: $($modifiedClosed -join ', ')"
    $exitCode = 1
} else { $passes += "Closed reports unchanged" }

# Determine resume safety
$resumeAllowed = ($exitCode -eq 0)
$requiredNextAction = if ($errors -match "OWNERSHIP_BOUNDARY|MANUAL_PASS") {
    "Create explicit resume plan documenting worker ownership resolution and manual PASS evidence remediation"
} elseif ($errors -match "CONTEXT_COMPRESSION") {
    "Create resume capsule with current state before attempting resume"
} else { "Proceed with H9-P2 completion" }

$classification = if ($exitCode -eq 0) { "PASS" } else {
    $errStr = $errors -join " "
    if ($errStr -match "OWNERSHIP_BOUNDARY|MANUAL_PASS|RESUME_BLOCKED") { "FAIL_CONTRACT_DRIFT" }
    elseif ($errStr -match "not found|MISSING|unreadable") { "FAIL_MISSING_EVIDENCE" }
    else { "FAIL_HARNESS_NOISE" }
}

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{
    verdict = $verdict
    classification = $classification
    resumeAllowed = $resumeAllowed
    blockingReasons = $errors
    requiredNextAction = $requiredNextAction
    passes = $passes
    checkedAt = $ts
}
Write-Output ($result | ConvertTo-Json -Depth 3)
exit $exitCode
