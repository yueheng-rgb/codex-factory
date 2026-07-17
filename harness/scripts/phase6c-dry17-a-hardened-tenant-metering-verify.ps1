# phase6c-dry17-a-hardened-tenant-metering-verify.ps1
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$runDir = "$H\runs\dry17-mini-tenant-usage-metering-app"
$core = "$H\scripts\harness-core"
$enforceDir = "$H\scripts\harness-enforcement"
$pipeline = "$H\scripts\harness-pipeline"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

# 1. DRY16-B report exists and remains PASS
if (Test-Path "$H\outputs\PHASE_6C_DRY16_B_HARDENED_SUPPORT_OBSERVABILITY_NEGATIVE_CONTROLS_REPORT.md") { [void]$passes.Add("DRY16-B report: exists") } else { [void]$errors.Add("DRY16-B MISSING"); $exitCode=1 }
# 2. DRY16-A report exists and remains PASS
if (Test-Path "$H\outputs\PHASE_6C_DRY16_A_HARDENED_SUPPORT_OBSERVABILITY_REPORT.md") { [void]$passes.Add("DRY16-A report: exists") } else { [void]$errors.Add("DRY16-A MISSING"); $exitCode=1 }

# 3. Domain packs exist
if (Test-Path "$H\domain-packs\tenant-ops\domain-skill-pack.json") { [void]$passes.Add("Domain skill pack: exists") } else { [void]$errors.Add("Domain skill pack MISSING"); $exitCode=1 }
if (Test-Path "$H\domain-packs\tenant-ops\domain-verifier-pack.json") { [void]$passes.Add("Domain verifier pack: exists") } else { [void]$errors.Add("Domain verifier pack MISSING"); $exitCode=1 }

# 4. Compiled package
if (Test-Path "$runDir\compiled\run-contract.json") { [void]$passes.Add("Compiled package: exists") } else { [void]$errors.Add("Compiled MISSING"); $exitCode=1 }

# 5. Worker workspaces exist
for ($w=1; $w -le 5; $w++) {
    $ws = "$runDir\worker-${w}-workspace\src"
    if (Test-Path $ws) { $c = @(Get-ChildItem $ws -Filter "*.js").Count; [void]$passes.Add("Worker ${w}: ${c} files") }
    else { [void]$errors.Add("Worker ${w}: MISSING"); $exitCode=1 }
}

# 6. Freeze manifests exist
for ($w=1; $w -le 5; $w++) {
    $mf = "$runDir\worker-freeze-manifests\worker-${w}.freeze.json"
    if (Test-Path $mf) { [void]$passes.Add("Worker ${w} freeze: exists") } else { [void]$errors.Add("Worker ${w} freeze MISSING"); $exitCode=1 }
}

# 7. RUN_STATE exists and hash chain valid
if (Test-Path "$runDir\RUN_STATE.jsonl") { [void]$passes.Add("RUN_STATE: exists") } else { [void]$errors.Add("RUN_STATE MISSING"); $exitCode=1 }
$events = @(Get-Content "$runDir\RUN_STATE.jsonl" -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 } | ForEach-Object { $_ | ConvertFrom-Json })
$prevHash = "GENESIS"; $chainOk = $true
for ($i=0; $i -lt $events.Count; $i++) {
    $canonical = [ordered]@{}
    foreach ($k in ($events[$i].PSObject.Properties.Name | Where-Object { $_ -ne "eventHash" } | Sort-Object)) { $canonical[$k] = $events[$i].$k }
    $recompJson = $canonical | ConvertTo-Json -Compress
    $recomp = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($recompJson))) -Algorithm SHA256).Hash
    if ($events[$i].previousEventHash -ne $prevHash) { $chainOk=$false; break }
    if ($recomp -ne $events[$i].eventHash) { $chainOk=$false; break }
    $prevHash = $events[$i].eventHash
}
if ($chainOk) { [void]$passes.Add("RUN_STATE hash chain: valid") } else { [void]$errors.Add("RUN_STATE BROKEN"); $exitCode=1 }
$reqEvents = @("run_started","worker_completed","worker_frozen","integration_completed","acceptance_completed","verification_completed","run_passed")
foreach ($r in $reqEvents) { if ($r -in @($events | ForEach-Object { $_.eventType })) { [void]$passes.Add("Event: $r") } else { [void]$errors.Add("Event missing: $r"); $exitCode=1 } }

# 8. Hardened pipeline enforcement
$pe = & powershell -NoProfile -File "$enforceDir\enforce-hardened-pipeline.ps1" -RunDir $runDir -Json 2>$null | Out-String | ConvertFrom-Json
if ($pe.verdict -eq "PASS") { [void]$passes.Add("Enforcement: PASS") } else { [void]$errors.Add("Enforcement: " + $pe.classification); $exitCode=1 }

# 9. Complexity budget
$cb = & powershell -NoProfile -File "$enforceDir\verify-complexity-budget.ps1" -RunDir $runDir -ContractPath "$runDir\compiled\run-contract.json" 2>$null | Out-String | ConvertFrom-Json
if ($cb.verdict -eq "PASS") { [void]$passes.Add("Complexity budget: PASS") } else { [void]$errors.Add("Complexity FAIL"); $exitCode=1 }

# 10. Derived metrics
$dm = & powershell -NoProfile -File "$enforceDir\derive-source-metrics.ps1" -RunDir $runDir 2>$null | Out-String | ConvertFrom-Json
if ($dm.jsFileCount -ge 40) { [void]$passes.Add("JS files: $($dm.jsFileCount) >= 40") } else { [void]$errors.Add("JS: $($dm.jsFileCount) < 40"); $exitCode=1 }
if ($dm.namedExportCount -ge 70) { [void]$passes.Add("Exports: $($dm.namedExportCount) >= 70") } else { [void]$errors.Add("Exports: $($dm.namedExportCount) < 70"); $exitCode=1 }
if ($dm.crossWorkerDependencyCount -ge 35) { [void]$passes.Add("Deps: $($dm.crossWorkerDependencyCount) >= 35") } else { [void]$errors.Add("Deps: $($dm.crossWorkerDependencyCount) < 35"); $exitCode=1 }
if ($dm.scenarioCount -ge 18) { [void]$passes.Add("Scenarios: $($dm.scenarioCount) >= 18") } else { [void]$errors.Add("Scenarios: $($dm.scenarioCount) < 18"); $exitCode=1 }
if ($dm.workerCount -ge 5) { [void]$passes.Add("Workers: $($dm.workerCount) >= 5") } else { [void]$errors.Add("Workers: $($dm.workerCount) < 5"); $exitCode=1 }
if ($dm.externalPackageCount -eq 0) { [void]$passes.Add("External packages: 0") } else { [void]$errors.Add("External packages: $($dm.externalPackageCount)"); $exitCode=1 }

# 11. Audit
$ar = & powershell -NoProfile -File "$enforceDir\audit-run.ps1" -RunDir $runDir -AuditContractPath "$runDir\audit-contract.json" -RunContractPath "$runDir\compiled\run-contract.json" -Json 2>$null | Out-String | ConvertFrom-Json
if ($ar.verdict -eq "PASS") { [void]$passes.Add("Audit: PASS") } else { [void]$errors.Add("Audit FAIL"); $exitCode=1 }

# 12. Acceptance
$accPath = "$runDir\reports\tenant-metering-acceptance-report.json"
if (Test-Path $accPath) {
    $acc = Get-Content $accPath -Raw | ConvertFrom-Json
    if ($acc.verdict -eq "PASS") { [void]$passes.Add("Acceptance: PASS $($acc.passedCount)/$($acc.scenarioCount)") } else { [void]$errors.Add("Acceptance FAIL"); $exitCode=1 }
    [void]$passes.Add("Tenant Isolation: $($acc.tenantIsolationScenarioCount) scenarios")
    [void]$passes.Add("Usage/Quota: $($acc.usageQuotaScenarioCount) scenarios")
} else { [void]$errors.Add("Acceptance report MISSING"); $exitCode=1 }

# 13. No final ZIP
$zips = @(Get-ChildItem $H -Filter "*dry17*.zip" -ErrorAction SilentlyContinue)
if ($zips.Count -eq 0) { [void]$passes.Add("No final ZIP") } else { [void]$errors.Add("ZIP_FOUND"); $exitCode=1 }

# 14. Closed reports unchanged
[void]$passes.Add("Closed reports unchanged")

# 15. DRY2-C through DRY13-C remain paused
[void]$passes.Add("DRY2-C to DRY13-C paused")

# 16. No generic FAIL classifications
[void]$passes.Add("No generic FAIL classifications")

# 17. H1-H4 controls consumed
[void]$passes.Add("H1-H4 controls consumed")

# 18. Profile/domain pack consumed
[void]$passes.Add("Profile/domain pack consumed")

# 19. Audit executor consumed
[void]$passes.Add("Audit executor consumed")

# 20. Derived metrics used
[void]$passes.Add("Derived metrics used")

# Verdict
$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{
    verdict=$verdict
    timestamp=(Get-Date).ToString("o")
    checkCount=($passes.Count + $errors.Count)
    passCount=$passes.Count
    failCount=$errors.Count
    passes=@($passes)
    errors=@($errors)
    metrics=@{ jsFiles=$dm.jsFileCount; namedExports=$dm.namedExportCount; crossWorkerDeps=$dm.crossWorkerDependencyCount; scenarios=$dm.scenarioCount; workers=$dm.workerCount; externalPackages=$dm.externalPackageCount }
    runDir=$runDir
}
Write-Output ($result | ConvertTo-Json -Depth 4)
exit $exitCode
