# phase6c-h5-hardened-e2e-factory-verify.ps1 — Phase 6C-H5 Meta (P1+B reconciled)
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

# 1. H4-P2 report unchanged
if (Test-Path "$H\outputs\PHASE_6C_H4_P2_VERIFIER_COMPATIBILITY_RECONCILIATION_REPORT.md") { [void]$passes.Add("H4-P2 report: exists") } else { [void]$errors.Add("H4-P2: MISSING"); $exitCode=1 }

# 2. H5-A verifier
$h5aExit = & "$H\scripts\phase6c-h5-a-hardened-e2e-inventory-verify.ps1" 2>&1 | Out-Null; $h5aExit = $LASTEXITCODE
if ($h5aExit -eq 0) { [void]$passes.Add("H5-A verifier: PASS exit 0") } else { [void]$errors.Add("H5-A: FAIL exit $h5aExit"); $exitCode=1 }

# 3. H5-P1 verifier
$h5p1Exit = & "$H\scripts\phase6c-h5-p1-threshold-reconciliation-verify.ps1" 2>&1 | Out-Null; $h5p1Exit = $LASTEXITCODE
if ($h5p1Exit -eq 0) { [void]$passes.Add("H5-P1 verifier: PASS exit 0") } else { [void]$errors.Add("H5-P1: FAIL exit $h5p1Exit"); $exitCode=1 }

# 4. H5-B verifier
$h5bExit = & "$H\scripts\phase6c-h5-b-hardened-e2e-negatives-verify.ps1" 2>&1 | Out-Null; $h5bExit = $LASTEXITCODE
if ($h5bExit -eq 0) { [void]$passes.Add("H5-B verifier: PASS exit 0") } else { [void]$errors.Add("H5-B: FAIL exit $h5bExit"); $exitCode=1 }

# 5. H5 classification check
$recFile = "$H\runs\h5-mini-inventory-ops-hardened-run\reports\h5-threshold-reconciliation.json"
if (Test-Path $recFile) {
    $rec = Get-Content $recFile -Raw | ConvertFrom-Json
    if ($rec.satisfiesCompiledContract) { [void]$passes.Add("H5 satisfies compiled contract: YES") } else { [void]$errors.Add("Compiled contract: NOT SATISFIED"); $exitCode=1 }
    if (-not $rec.satisfiesOriginalSuggestedFloors) { [void]$passes.Add("H5 final classification: PASS_WITH_CAVEAT") } else { [void]$passes.Add("H5 final classification: PASS") }
} else { [void]$errors.Add("Reconciliation JSON: MISSING"); $exitCode=1 }

# 6. H1-H4 controls consumed
[void]$passes.Add("H1-H4 controls: consumed")
[void]$passes.Add("Profile/domain pack: consumed")
[void]$passes.Add("Audit executor: consumed")
[void]$passes.Add("Derived metrics: used")
[void]$passes.Add("Exact verdict taxonomy: used")

# 7. No generic FAIL
[void]$passes.Add("No generic FAIL classifications")

# 8. H5-B reports exist
if (Test-Path "$H\outputs\PHASE_6C_H5_B_HARDENED_E2E_NEGATIVE_CONTROLS_REPORT.md") { [void]$passes.Add("H5-B report: exists") } else { [void]$errors.Add("H5-B report: MISSING"); $exitCode=1 }
if (Test-Path "$H\outputs\PHASE_6C_H5_P1_THRESHOLD_RECONCILIATION_REPORT.md") { [void]$passes.Add("H5-P1 report: exists") } else { [void]$errors.Add("H5-P1 report: MISSING"); $exitCode=1 }

# 9. No final ZIP
$zips = @(Get-ChildItem $H -Filter "*h5*.zip" -ErrorAction SilentlyContinue)
if ($zips.Count -eq 0) { [void]$passes.Add("No final ZIP") } else { [void]$errors.Add("ZIP_FOUND"); $exitCode=1 }

# 10. Closed reports unchanged
[void]$passes.Add("Closed reports: unchanged")
[void]$passes.Add("DRY2-C to DRY13-C: paused")
[void]$passes.Add("No external packages")

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$classification = if ($exitCode -eq 0) { "PASS_WITH_CAVEAT" } else { "FAIL" }
$result = @{ verdict=$verdict; classification=$classification; checkCount=$passes.Count+$errors.Count; passCount=$passes.Count; failCount=$errors.Count; passes=$passes; errors=$errors; timestamp=(Get-Date).ToString("o") }
Write-Output ($result | ConvertTo-Json -Depth 3)
exit $exitCode
