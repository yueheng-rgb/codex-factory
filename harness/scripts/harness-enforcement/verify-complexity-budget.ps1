# verify-complexity-budget.ps1 — Phase 6C-H4
# Compares derived metrics against run contract thresholds.
param(
    [Parameter(Mandatory=$true)][string]$ContractPath,
    [Parameter(Mandatory=$true)][string]$RunDir,
    [string]$ReportPath = "",
    [switch]$Json
)
$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

$H = "C:\Codex_App_Factory\harness"
$enforcement = "$H\scripts\harness-enforcement"

# Load contract
if (-not (Test-Path $ContractPath)) { Write-Output '{"verdict":"FAIL","reason":"CONTRACT_NOT_FOUND"}'; exit 1 }
try { $contract = Get-Content $ContractPath -Raw | ConvertFrom-Json } catch { Write-Output '{"verdict":"FAIL","reason":"CONTRACT_MALFORMED"}'; exit 1 }

# Derive metrics
$derive = & powershell -NoProfile -File "$enforcement\derive-source-metrics.ps1" -RunDir $RunDir 2>&1 | Out-String | ConvertFrom-Json

# Check each threshold
$thresholds = @(
    @{name="jsFileCount"; contractField="minimumJsFiles"},
    @{name="namedExportCount"; contractField="minimumNamedExports"},
    @{name="crossWorkerDependencyCount"; contractField="minimumCrossWorkerDeps"},
    @{name="scenarioCount"; contractField="requiredScenarioCount"},
    @{name="workerCount"; contractField="requiredWorkers"},
    @{name="taskCount"; contractField="requiredTasks"}
)

foreach ($t in $thresholds) {
    $contractVal = $contract.$($t.contractField)
    $derivedVal = $derive.$($t.name)
    if ($contractVal -and $derivedVal) {
        if ($derivedVal -lt $contractVal) {
            [void]$errors.Add("THRESHOLD_DRIFT: $($t.name)=$derivedVal < contract=$contractVal")
            $exitCode = 1
        } else {
            [void]$passes.Add("$($t.name): $derivedVal >= $contractVal")
        }
    } elseif ($contractVal -and -not $derivedVal) {
        [void]$errors.Add("MISSING_DERIVED: $($t.name) not derivable, contract=$contractVal")
        $exitCode = 1
    }
}

# Check report claims match derived if report provided
if ($ReportPath -and (Test-Path $ReportPath)) {
    try {
        $reportContent = Get-Content $ReportPath -Raw
        if ($reportContent -match "JS files.*?(\d+)" -and $derive.jsFileCount) {
            $claimed = [int]$Matches[1]
            if ($claimed -ne $derive.jsFileCount) {
                [void]$errors.Add("REPORT_CLAIM_MISMATCH: JS files claimed=$claimed derived=$($derive.jsFileCount)")
            }
        }
    } catch {}
}

$classification = if ($exitCode -eq 0) { "PASS" } else { "FAIL_CONTRACT_DRIFT" }

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{
    verdict = $verdict
    classification = $classification
    derived = $derive
    derivedJsFileCount = $derive.jsFileCount
    derivedNamedExportCount = $derive.namedExportCount
    derivedCrossWorkerDependencyCount = $derive.crossWorkerDependencyCount
    derivedScenarioCount = $derive.scenarioCount
    contract = $contract
    claimedJsFileCount = $contract.minimumJsFiles
    claimedNamedExportCount = $contract.minimumNamedExports
    claimedCrossWorkerDependencyCount = $contract.minimumCrossWorkerDeps
    claimedScenarioCount = $contract.requiredScenarioCount
    passes = $passes
    errors = $errors
    checkedAt = (Get-Date).ToString("o")
}
Write-Output ($result | ConvertTo-Json -Depth 3)
exit $exitCode
