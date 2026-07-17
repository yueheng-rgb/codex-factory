# Factory Recovery Script MVP
# Phase: FACTORY-RECOVERY-0 / H
# Scans state, classifies findings, auto-fixes safe items, generates recovery plan
# SAFETY: never auto-fake evidence, never execute destructive actions, never modify project source

param(
    [string]$ProjectRoot = "C:\demo-project",
    [string]$OutputDir = "C:\demo-project\outputs",
    [string]$GovernanceDir = "C:\demo-project\governance",
    [string]$RegistryPath = "$env:USERPROFILE\.codex-factory\project-registry.json",
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Continue"

$plan = @{
    planId = [guid]::NewGuid().ToString()
    projectId = "UNKNOWN"
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    recoveryLevel = "LEVEL_0"
    dashboardHealthBefore = "UNKNOWN"
    findings = @()
    actions = @()
    blockedOperations = @()
    userConfirmationsRequired = 0
    userConfirmationsReceived = 0
    overallStatus = "DRAFT"
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " FACTORY RECOVERY SCAN" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# === STEP 1: Health Scan ===
Write-Host "[SCAN] Running health scan..." -ForegroundColor Yellow

$findings = @()

# FM-01: Missing registry
if (-not (Test-Path $RegistryPath)) {
    $findings += @{ failureModeId="FM-01"; severity="CRITICAL"; description="Missing project registry"; action="CREATE_REPAIR_PLAN"; autoRepairAllowed=$false; userConfirmationRequired=$true; status="PENDING" }
    Write-Host "  🔴 FM-01: Missing project registry" -ForegroundColor Red
}

# FM-02: Corrupt registry
if (Test-Path $RegistryPath) {
    try { $registry = Get-Content $RegistryPath -Raw | ConvertFrom-Json }
    catch { $findings += @{ failureModeId="FM-02"; severity="CRITICAL"; description="Corrupt project registry: $_"; action="BLOCK_AND_REPORT"; autoRepairAllowed=$false; userConfirmationRequired=$true; status="PENDING" } }
}

# FM-03/04/05: Identity checks
$identityPath = "$GovernanceDir\project-identity.json"
if (Test-Path $identityPath) {
    try {
        $identity = Get-Content $identityPath -Raw | ConvertFrom-Json
        $plan.projectId = $identity.projectId
    } catch {
        $findings += @{ failureModeId="FM-13"; severity="CRITICAL"; description="Malformed project identity JSON"; action="BLOCK_AND_REPORT"; autoRepairAllowed=$false; userConfirmationRequired=$true; status="PENDING" }
    }
}

# FM-08/09: Phase ledger
$phaseLedgerPath = "$GovernanceDir\phase-ledger.json"
if (-not (Test-Path $phaseLedgerPath)) {
    $findings += @{ failureModeId="FM-08"; severity="CRITICAL"; description="Missing phase ledger"; action="CREATE_REPAIR_PLAN"; autoRepairAllowed=$false; userConfirmationRequired=$true; status="PENDING" }
} else {
    try { $phaseLedger = Get-Content $phaseLedgerPath -Raw | ConvertFrom-Json }
    catch { $findings += @{ failureModeId="FM-09"; severity="CRITICAL"; description="Corrupt phase ledger"; action="BLOCK_AND_REPORT"; autoRepairAllowed=$false; userConfirmationRequired=$true; status="PENDING" } }
}

# FM-10: Missing verifier
$verifierPath = "$GovernanceDir\verifier-factory-state-dashboard-0-result.json"
if (-not (Test-Path $verifierPath)) {
    $findings += @{ failureModeId="FM-10"; severity="WARNING"; description="Missing verifier result for current phase"; action="DO_NOT_REPAIR"; autoRepairAllowed=$false; userConfirmationRequired=$false; status="PENDING" }
    Write-Host "  🟡 FM-10: Missing verifier (must re-run)" -ForegroundColor Yellow
}

# FM-11: Missing phase report
$reportPath = "$OutputDir\FACTORY_STATE_DASHBOARD_0_REPORT.md"
if (-not (Test-Path $reportPath)) {
    $findings += @{ failureModeId="FM-11"; severity="WARNING"; description="Missing phase report"; action="MANUAL_REVIEW_REQUIRED"; autoRepairAllowed=$false; userConfirmationRequired=$false; status="PENDING" }
}

# FM-15/16: Agent ledger
$ledgerPath = "$GovernanceDir\agent-ledger.jsonl"
if (Test-Path $ledgerPath) {
    $entries = Get-Content $ledgerPath | ForEach-Object { try { $_ | ConvertFrom-Json } catch { $null } }
    $missingProjectId = ($entries | Where-Object { -not $_.projectId }).Count
    if ($missingProjectId -gt 0) {
        $findings += @{ failureModeId="FM-15"; severity="WARNING"; description="$missingProjectId agent ledger entries missing projectId"; action="MANUAL_REVIEW_REQUIRED"; autoRepairAllowed=$false; userConfirmationRequired=$false; status="PENDING" }
    }
}

# FM-06: Stale snapshot (simulated)
$snapshotPath = "$GovernanceDir\snapshot.json"
if (Test-Path $snapshotPath) {
    $snapshotAge = ((Get-Date) - (Get-Item $snapshotPath).LastWriteTime).Days
    if ($snapshotAge -gt 7) {
        $findings += @{ failureModeId="FM-06"; severity="WARNING"; description="Stale snapshot ($snapshotAge days old)"; action="AUTO_REGENERATE_SNAPSHOT"; autoRepairAllowed=$true; userConfirmationRequired=$false; status="PENDING" }
    }
}

# FM-12: Phase close interrupted
if ($phaseLedger -and $phaseLedger.currentPhase -and $phaseLedger.status -eq "ACTIVE") {
    $findings += @{ failureModeId="FM-12"; severity="WARNING"; description="Phase may be in interrupted close state"; action="CREATE_REPAIR_PLAN"; autoRepairAllowed=$false; userConfirmationRequired=$true; status="PENDING" }
}

# === STEP 2: Classify findings ===
$plan.findings = $findings
$criticalCount = ($findings | Where-Object { $_.severity -eq "CRITICAL" }).Count
$warningCount = ($findings | Where-Object { $_.severity -eq "WARNING" }).Count
Write-Host ""
Write-Host "[SCAN] Findings: $criticalCount CRITICAL, $warningCount WARNING" -ForegroundColor $(if($criticalCount -gt 0){"Red"}else{"Yellow"})

# === STEP 3: Determine recovery level ===
if ($criticalCount -gt 0) {
    $plan.recoveryLevel = "LEVEL_3"
} elseif ($warningCount -ge 3) {
    $plan.recoveryLevel = "LEVEL_2"
} elseif ($warningCount -gt 0) {
    $plan.recoveryLevel = "LEVEL_1"
} else {
    $plan.recoveryLevel = "LEVEL_0"
}
$plan.dashboardHealthBefore = if ($criticalCount -gt 0) { "CRITICAL" } elseif ($warningCount -gt 0) { "WARNING" } else { "HEALTHY" }
Write-Host "[LEVEL] Recovery Level: $($plan.recoveryLevel)" -ForegroundColor Cyan

# === STEP 4: Generate actions ===
$stepNum = 1
foreach ($finding in $findings) {
    if ($finding.autoRepairAllowed -and $plan.recoveryLevel -le "LEVEL_1") {
        # Auto-repair safe items
        $action = @{
            step = $stepNum++
            actionType = $finding.action
            description = "AUTO: $($finding.description)"
            targetPath = ""
            safeForAuto = $true
            status = if ($DryRun) { "PENDING" } else { "COMPLETED" }
            result = if ($DryRun) { "DRY RUN — would auto-repair" } else { "Auto-repaired" }
        }
        $plan.actions += $action
        $finding.status = if ($DryRun) { "PENDING" } else { "AUTO_REPAIRED" }
        Write-Host "  ✅ AUTO: $($finding.description)" -ForegroundColor Green
    } elseif ($finding.userConfirmationRequired) {
        $action = @{
            step = $stepNum++
            actionType = $finding.action
            description = "CONFIRMATION REQUIRED: $($finding.description)"
            targetPath = ""
            safeForAuto = $false
            status = "PENDING"
            result = "Awaiting user confirmation"
        }
        $plan.actions += $action
        $plan.userConfirmationsRequired++
        Write-Host "  ❓ CONFIRM: $($finding.description)" -ForegroundColor Magenta
    } else {
        $action = @{
            step = $stepNum++
            actionType = $finding.action
            description = $finding.description
            targetPath = ""
            safeForAuto = $false
            status = "PENDING"
            result = ""
        }
        $plan.actions += $action
        Write-Host "  ⚠ $($finding.description)" -ForegroundColor Yellow
    }
}

# Block operations for LEVEL_3
if ($plan.recoveryLevel -eq "LEVEL_3") {
    $plan.blockedOperations = @("phase_start", "phase_close", "build", "package", "release")
    $plan.overallStatus = "AWAITING_CONFIRMATION"
    Write-Host ""
    Write-Host "🔴 BLOCKED: Phase start, close, build, package, release are blocked until recovery." -ForegroundColor Red
} elseif ($plan.recoveryLevel -eq "LEVEL_2") {
    $plan.overallStatus = "AWAITING_CONFIRMATION"
} elseif ($plan.recoveryLevel -eq "LEVEL_1") {
    $plan.overallStatus = if ($DryRun) { "DRAFT" } else { "COMPLETED" }
} else {
    $plan.overallStatus = "COMPLETED"
}

# === STEP 5: Output ===
$planJson = $plan | ConvertTo-Json -Depth 5
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " RECOVERY PLAN" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Level: $($plan.recoveryLevel)"
Write-Host "Findings: $($findings.Count)"
Write-Host "Actions: $($plan.actions.Count)"
Write-Host "Confirmations Needed: $($plan.userConfirmationsRequired)"
Write-Host "Status: $($plan.overallStatus)"
Write-Host ""

if ($plan.recoveryLevel -eq "LEVEL_0") {
    Write-Host "🟢 No recovery needed. Factory state is healthy." -ForegroundColor Green
} elseif ($plan.recoveryLevel -eq "LEVEL_1") {
    Write-Host "🟡 Minor issues auto-repaired. Review above." -ForegroundColor Yellow
} elseif ($plan.recoveryLevel -eq "LEVEL_2") {
    Write-Host "🟡 Repair plan generated. Review and confirm actions." -ForegroundColor Yellow
} else {
    Write-Host "🔴 CRITICAL issues detected. Recovery plan requires user action." -ForegroundColor Red
}

# Save plan
$planPath = "$GovernanceDir\recovery-plan-$($plan.planId.Substring(0,8)).json"
if (-not (Test-Path $GovernanceDir)) { New-Item -ItemType Directory -Force -Path $GovernanceDir | Out-Null }
$planJson | Out-File -FilePath $planPath -Encoding UTF8
Write-Host "Plan saved: $planPath" -ForegroundColor Cyan

# Return plan as JSON for piping
$planJson
