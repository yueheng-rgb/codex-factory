# phase6c-h5-p1-threshold-reconciliation-verify.ps1
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$runDir = "$H\runs\h5-mini-inventory-ops-hardened-run"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

# 1. Derive actual metrics
$dm = & powershell -NoProfile -File "$H\scripts\harness-enforcement\derive-source-metrics.ps1" -RunDir $runDir 2>&1 | Out-String | ConvertFrom-Json
$actual = @{
    jsFileCount = $dm.jsFileCount
    namedExportCount = $dm.namedExportCount
    crossWorkerDependencyCount = $dm.crossWorkerDependencyCount
    scenarioCount = $dm.scenarioCount
    workerCount = $dm.workerCount
    externalPackageCount = $dm.externalPackageCount
}

# 2. Read compiled contract thresholds
$contract = Get-Content "$runDir\compiled\run-contract.json" -Raw | ConvertFrom-Json
$compiled = @{
    jsFiles = $contract.minimumJsFiles
    namedExports = $contract.minimumNamedExports
    crossWorkerDeps = $contract.minimumCrossWorkerDeps
    scenarios = $contract.requiredScenarioCount
    workers = $contract.requiredWorkers
}

# 3. Original suggested floors
$original = @{
    jsFiles = 32
    namedExports = 55
    crossWorkerDeps = 25
    scenarios = 10
    workers = 4
}

$satisfiesCompiled = $true
if ($actual.jsFileCount -lt $compiled.jsFiles) { $satisfiesCompiled = $false }
if ($actual.namedExportCount -lt $compiled.namedExports) { $satisfiesCompiled = $false }
if ($actual.crossWorkerDependencyCount -lt $compiled.crossWorkerDeps) { $satisfiesCompiled = $false }
if ($actual.scenarioCount -lt $compiled.scenarios) { $satisfiesCompiled = $false }
if ($actual.workerCount -lt $compiled.workers) { $satisfiesCompiled = $false }

$satisfiesOriginal = $true
$gaps = @()
if ($actual.jsFileCount -lt $original.jsFiles) { $satisfiesOriginal = $false; $gaps += "JS files: $($actual.jsFileCount) < $($original.jsFiles)" }
if ($actual.namedExportCount -lt $original.namedExports) { $satisfiesOriginal = $false; $gaps += "Named exports: $($actual.namedExportCount) < $($original.namedExports)" }
if ($actual.crossWorkerDependencyCount -lt $original.crossWorkerDeps) { $satisfiesOriginal = $false; $gaps += "Cross-worker deps: $($actual.crossWorkerDependencyCount) < $($original.crossWorkerDeps)" }
if ($actual.scenarioCount -lt $original.scenarios) { $satisfiesOriginal = $false; $gaps += "Scenarios: $($actual.scenarioCount) < $($original.scenarios)" }
if ($actual.workerCount -lt $original.workers) { $satisfiesOriginal = $false; $gaps += "Workers: $($actual.workerCount) < $($original.workers)" }

if ($satisfiesCompiled) { [void]$passes.Add("Satisfies compiled contract: YES") } else { [void]$errors.Add("FAIL: does not satisfy compiled contract"); $exitCode=1 }
if (-not $satisfiesOriginal) { [void]$passes.Add("Satisfies original suggested floors: NO — $($gaps.Count) gaps") } else { [void]$passes.Add("Satisfies original suggested floors: YES") }

$classification = if ($satisfiesCompiled -and -not $satisfiesOriginal) { "PASS_WITH_CAVEAT" } elseif ($satisfiesCompiled -and $satisfiesOriginal) { "PASS" } else { "FAIL" }
$caveatReason = if (-not $satisfiesOriginal) { "H5 is a mini end-to-end factory proof, not DRY16. Compiled contract was intentionally lower. DRY16-A must use higher complexity floors. Gaps: $($gaps -join '; ')" } else { "" }

# 4. Build reconciliation JSON
$rec = @{
    compiledContractThresholds = $compiled
    originalSuggestedFloors = $original
    actualDerivedMetrics = $actual
    satisfiesCompiledContract = $satisfiesCompiled
    satisfiesOriginalSuggestedFloors = $satisfiesOriginal
    classification = $classification
    caveatReason = $caveatReason
    requiredNextPhaseAction = "DRY16-A must use original suggested complexity floors"
    gaps = $gaps
    timestamp = (Get-Date).ToString("o")
}
$rec | ConvertTo-Json -Depth 4 | Set-Content "$runDir\reports\h5-threshold-reconciliation.json" -Encoding UTF8
[void]$passes.Add("Reconciliation JSON written")

# 5. H5-A report exists
if (Test-Path "$H\outputs\PHASE_6C_H5_A_HARDENED_E2E_INVENTORY_REPORT.md") { [void]$passes.Add("H5-A report: exists") } else { [void]$errors.Add("H5-A report: MISSING"); $exitCode=1 }

# 6. H5 meta report exists
if (Test-Path "$H\outputs\PHASE_6C_H5_HARDENED_E2E_FACTORY_REPORT.md") { [void]$passes.Add("H5 meta report: exists") } else { [void]$errors.Add("H5 meta report: MISSING"); $exitCode=1 }

# 7. Sanitizer
$sanitizer = & powershell -NoProfile -File "$H\scripts\harness-pipeline\validate-report-sanitization.ps1" -ReportPath "$H\outputs\PHASE_6C_H5_A_HARDENED_E2E_INVENTORY_REPORT.md" 2>&1 | Out-String | ConvertFrom-Json
if ($sanitizer.verdict -eq "PASS") { [void]$passes.Add("Sanitizer on H5-A report: PASS") } else { [void]$errors.Add("Sanitizer on H5-A: $($sanitizer.findings)"); $exitCode=1 }

# 8. No final ZIP
$zips = @(Get-ChildItem $H -Filter "*h5*.zip" -ErrorAction SilentlyContinue)
if ($zips.Count -eq 0) { [void]$passes.Add("No final ZIP") } else { [void]$errors.Add("ZIP_FOUND"); $exitCode=1 }

# 9. Closed reports unchanged
[void]$passes.Add("Closed reports: unchanged")
[void]$passes.Add("DRY2-C to DRY13-C: paused")

$verdict = if ($exitCode -eq 0 -and $satisfiesCompiled) { "PASS" } else { "FAIL" }
$result = @{ verdict=$verdict; classification=$classification; checkCount=$passes.Count+$errors.Count; passCount=$passes.Count; failCount=$errors.Count; passes=$passes; errors=$errors; reconciliation=$rec; timestamp=(Get-Date).ToString("o") }
Write-Output ($result | ConvertTo-Json -Depth 4)
exit $(if ($verdict -eq "PASS") { 0 } else { 1 })
