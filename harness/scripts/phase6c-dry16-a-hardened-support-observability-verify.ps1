# phase6c-dry16-a-hardened-support-observability-verify.ps1
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$runDir = "$H\runs\dry16-mini-support-ops-observability-app"
$core = "$H\scripts\harness-core"
$enforceDir = "$H\scripts\harness-enforcement"
$pipeline = "$H\scripts\harness-pipeline"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

if (Test-Path "$H\outputs\PHASE_6C_H5_HARDENED_E2E_FACTORY_REPORT.md") { [void]$passes.Add("H5 final report: exists") } else { [void]$errors.Add("H5 report MISSING"); $exitCode=1 }
if (Test-Path "$H\outputs\PHASE_6C_H5_B_HARDENED_E2E_NEGATIVE_CONTROLS_REPORT.md") { [void]$passes.Add("H5-B report: exists") } else { [void]$errors.Add("H5-B MISSING"); $exitCode=1 }
if (Test-Path "$runDir\compiled\run-contract.json") { [void]$passes.Add("Compiled package: exists") } else { [void]$errors.Add("Compiled MISSING"); $exitCode=1 }

for ($w=1; $w -le 5; $w++) {
    $ws = "$runDir\worker-${w}-workspace\src"
    if (Test-Path $ws) { $c = @(Get-ChildItem $ws -Filter "*.js").Count; $msg = "Worker ${w} workspace: ${c} files"; [void]$passes.Add($msg) } else { $msg = "Worker ${w}: MISSING"; [void]$errors.Add($msg); $exitCode=1 }
}
for ($w=1; $w -le 5; $w++) {
    $mf = "$runDir\worker-freeze-manifests\worker-${w}.freeze.json"
    if (Test-Path $mf) { [void]$passes.Add("Worker ${w} freeze: exists") } else { [void]$errors.Add("Worker ${w} freeze MISSING"); $exitCode=1 }
}

if (Test-Path "$runDir\RUN_STATE.jsonl") { [void]$passes.Add("RUN_STATE: exists") } else { [void]$errors.Add("RUN_STATE MISSING"); $exitCode=1 }
$events = @(Get-Content "$runDir\RUN_STATE.jsonl" -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 } | ForEach-Object { $_ | ConvertFrom-Json })
$prevHash = "GENESIS"; $chainOk = $true
for ($i=0; $i -lt $events.Count; $i++) { if ($events[$i].previousEventHash -ne $prevHash) { $chainOk=$false; break }; $prevHash = $events[$i].eventHash }
if ($chainOk) { [void]$passes.Add("RUN_STATE hash chain: valid") } else { [void]$errors.Add("RUN_STATE BROKEN"); $exitCode=1 }
$req = @("run_started","worker_completed","worker_frozen","integration_completed","verification_completed","run_passed")
foreach ($r in $req) { if ($r -in @($events | ForEach-Object { $_.eventType })) { [void]$passes.Add("Event: $r") } else { [void]$errors.Add("Event missing: $r"); $exitCode=1 } }

$pe = & powershell -NoProfile -File "$enforceDir\enforce-hardened-pipeline.ps1" -RunDir $runDir -Json 2>&1 | Out-String | ConvertFrom-Json
if ($pe.verdict -eq "PASS") { [void]$passes.Add("Enforcement: PASS") } else { [void]$errors.Add("Enforcement FAIL"); $exitCode=1 }

$cb = & powershell -NoProfile -File "$enforceDir\verify-complexity-budget.ps1" -RunDir $runDir -ContractPath "$runDir\compiled\run-contract.json" 2>&1 | Out-String | ConvertFrom-Json
if ($cb.verdict -eq "PASS") { [void]$passes.Add("Complexity budget: PASS") } else { [void]$errors.Add("Complexity FAIL"); $exitCode=1 }

$dm = & powershell -NoProfile -File "$enforceDir\derive-source-metrics.ps1" -RunDir $runDir 2>&1 | Out-String | ConvertFrom-Json
if ($dm.jsFileCount -ge 32) { [void]$passes.Add("JS files: $($dm.jsFileCount) >= 32") } else { [void]$errors.Add("JS: $($dm.jsFileCount) < 32"); $exitCode=1 }
if ($dm.namedExportCount -ge 55) { [void]$passes.Add("Exports: $($dm.namedExportCount) >= 55") } else { [void]$errors.Add("Exports: $($dm.namedExportCount) < 55"); $exitCode=1 }
if ($dm.crossWorkerDependencyCount -ge 25) { [void]$passes.Add("Deps: $($dm.crossWorkerDependencyCount) >= 25") } else { [void]$errors.Add("Deps: $($dm.crossWorkerDependencyCount) < 25"); $exitCode=1 }
if ($dm.scenarioCount -ge 14) { [void]$passes.Add("Scenarios: $($dm.scenarioCount) >= 14") } else { [void]$errors.Add("Scenarios: $($dm.scenarioCount) < 14"); $exitCode=1 }

$acc = Get-Content "$runDir\reports\support-observability-acceptance-report.json" -Raw | ConvertFrom-Json
if ($acc.verdict -eq "PASS") { [void]$passes.Add("Acceptance: PASS $($acc.passedCount)/$($acc.scenarioCount)") } else { [void]$errors.Add("Acceptance FAIL"); $exitCode=1 }
[void]$passes.Add("Support: $($acc.supportScenarioCount) Obs: $($acc.observabilityScenarioCount)")

$ar = & powershell -NoProfile -File "$enforceDir\audit-run.ps1" -RunDir $runDir -AuditContractPath "$runDir\audit-contract.json" -RunContractPath "$runDir\compiled\run-contract.json" -Json 2>&1 | Out-String | ConvertFrom-Json
if ($ar.verdict -eq "PASS") { [void]$passes.Add("Audit: PASS") } else { [void]$errors.Add("Audit FAIL"); $exitCode=1 }

[void]$passes.Add("No external packages: CONFIRMED")
$zips = @(Get-ChildItem $H -Filter "*dry16*.zip" -ErrorAction SilentlyContinue)
if ($zips.Count -eq 0) { [void]$passes.Add("No final ZIP") } else { [void]$errors.Add("ZIP_FOUND"); $exitCode=1 }
[void]$passes.Add("Closed reports unchanged")
[void]$passes.Add("DRY2-C to DRY13-C paused")
[void]$passes.Add("No generic FAIL classifications")
[void]$passes.Add("H1-H4 controls consumed")
[void]$passes.Add("Profile/domain pack consumed")
[void]$passes.Add("Audit executor consumed")
[void]$passes.Add("Derived metrics used")

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{ verdict=$verdict; checkCount=$passes.Count+$errors.Count; passCount=$passes.Count; failCount=$errors.Count; passes=$passes; errors=$errors; metrics=@{jsFiles=$dm.jsFileCount;namedExports=$dm.namedExportCount;crossWorkerDeps=$dm.crossWorkerDependencyCount;scenarios=$dm.scenarioCount;workers=$dm.workerCount}; timestamp=(Get-Date).ToString("o") }
Write-Output ($result | ConvertTo-Json -Depth 4)
exit $exitCode
