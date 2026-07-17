# phase6c-u0-d-verify.ps1 — Phase 6C-U0-D Umbrella Verifier
# Verifies real contract-enforced two-Worker run.
param([switch]$JsonOnly)

$ErrorActionPreference = "Continue"
$HarnessRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

Write-Output "=== Phase 6C-U0-D Umbrella Verifier ==="

$posDir = "$HarnessRoot\runs\phase6c-u0-d-real"
$negDir = "$HarnessRoot\runs\phase6c-u0-d-negative"

# --- 1. U0-C-R1 final report ---
if (Test-Path "$HarnessRoot\outputs\PHASE_6C_U0_C_R1_FINAL_REPORT.md") { [void]$passes.Add("U0-C-R1 report exists") }
else { [void]$errors.Add("MISSING_U0C_R1_REPORT"); $exitCode = 1 }

# --- 2-5. Real run + spawn evidence ---
if (Test-Path $posDir) { [void]$passes.Add("Real run exists") } else { [void]$errors.Add("MISSING_REAL_RUN"); $exitCode = 1 }
$sev = Get-Content "$posDir\spawn-agent-evidence.json" -Raw | ConvertFrom-Json
if ($sev.realWorkersUsed -eq $true) { [void]$passes.Add("realWorkersUsed=true") } else { [void]$errors.Add("NOT_REAL_WORKERS"); $exitCode = 1 }
if ($sev.workerCount -eq 2) { [void]$passes.Add("workerCount=2") } else { [void]$errors.Add("WRONG_WORKER_COUNT"); $exitCode = 1 }

# --- 6-7. Worker workspaces ---
if (Test-Path "$posDir\workspace\worker-1\src\utils.ts") { [void]$passes.Add("Worker 1 workspace: utils.ts") } else { [void]$errors.Add("W1_NO_UTILS"); $exitCode = 1 }
if (Test-Path "$posDir\workspace\worker-2\src\app.ts") { [void]$passes.Add("Worker 2 workspace: app.ts") } else { [void]$errors.Add("W2_NO_APP"); $exitCode = 1 }

# --- 8-9. Contract lock ---
$contract = Get-Content "$posDir\interface-contract.lock.json" -Raw | ConvertFrom-Json
if ($contract.locked -eq $true) { [void]$passes.Add("Contract locked=true") } else { [void]$errors.Add("CONTRACT_NOT_LOCKED"); $exitCode = 1 }

# --- 10-16. Manifests and source-derived ---
if (Test-Path "$posDir\worker-interface-manifests\worker-1-interface-manifest.json") { [void]$passes.Add("Worker manifests exist") }
$sdm1 = Get-Content "$posDir\source-derived-interface-manifests\worker-1.json" -Raw | ConvertFrom-Json
$sdm2 = Get-Content "$posDir\source-derived-interface-manifests\worker-2.json" -Raw | ConvertFrom-Json
$hasExports = @($sdm1.exports | ? { $_.name -eq "formatDate" }).Count -gt 0 -and @($sdm1.exports | ? { $_.name -eq "makeRunLabel" }).Count -gt 0
$hasImports = @($sdm2.imports | ? { $_.name -eq "formatDate" }).Count -gt 0 -and @($sdm2.imports | ? { $_.name -eq "makeRunLabel" }).Count -gt 0
$hasBuildSummary = @($sdm2.exports | ? { $_.name -eq "buildSummary" }).Count -gt 0
if ($hasExports) { [void]$passes.Add("W1 source exports: formatDate+makeRunLabel") } else { [void]$errors.Add("W1_MISSING_EXPORTS"); $exitCode = 1 }
if ($hasImports) { [void]$passes.Add("W2 source imports: formatDate+makeRunLabel") } else { [void]$errors.Add("W2_MISSING_IMPORTS"); $exitCode = 1 }
if ($hasBuildSummary) { [void]$passes.Add("W2 source exports: buildSummary") } else { [void]$errors.Add("W2_MISSING_EXPORT"); $exitCode = 1 }

# --- 17-23. Honesty, drift, integration ---
$h1 = Get-Content "$posDir\reports\manifest-honesty-report-worker-1.json" -Raw | ConvertFrom-Json
$h2 = Get-Content "$posDir\reports\manifest-honesty-report-worker-2.json" -Raw | ConvertFrom-Json
$drift = Get-Content "$posDir\reports\interface-drift-report.json" -Raw | ConvertFrom-Json
$gate = Get-Content "$posDir\reports\integration-gate-report.json" -Raw | ConvertFrom-Json
if ($h1.verdict -eq "PASS" -and $h2.verdict -eq "PASS") { [void]$passes.Add("Honesty: both PASS") } else { [void]$errors.Add("HONESTY_FAIL"); $exitCode = 1 }
if ($drift.verdict -eq "PASS" -and $drift.driftCount -eq 0) { [void]$passes.Add("Drift: PASS count=0") } else { [void]$errors.Add("DRIFT_FAIL"); $exitCode = 1 }
if ($gate.verdict -eq "PASS") { [void]$passes.Add("Integration gate: PASS") } else { [void]$errors.Add("GATE_FAIL"); $exitCode = 1 }

# --- 24-28. Positive validate-state ---
$posVS = & (Join-Path $HarnessRoot "scripts\validate-state.ps1") -RunDir $posDir 2>&1 | Out-String
$posVSJson = $null
try { $j=$posVS.IndexOf('{'); if ($j -ge 0) { $posVSJson = $posVS.Substring($j) | ConvertFrom-Json } } catch {}
if ($posVSJson -and $posVSJson.verdict -eq "run_passed") { [void]$passes.Add("Positive validate-state: run_passed") } else { [void]$errors.Add("POS_VS_FAIL"); $exitCode = 1 }
if ($posVS -notmatch "no_token_store") { [void]$passes.Add("Positive: no no_token_store") } else { [void]$errors.Add("POS_TOKEN_STORE"); $exitCode = 1 }
if ($posVS -notmatch "PROOF_VERIFICATION_FAILED") { [void]$passes.Add("Positive: no PROOF_VERIFICATION_FAILED") } else { [void]$errors.Add("POS_PROOF_FAIL"); $exitCode = 1 }

# --- 29-34. Negative control ---
if (Test-Path $negDir) { [void]$passes.Add("Negative run exists") } else { [void]$errors.Add("MISSING_NEG"); $exitCode = 1 }
$negVS = & (Join-Path $HarnessRoot "scripts\validate-state.ps1") -RunDir $negDir 2>&1 | Out-String
$negVSJson = $null
try { $j=$negVS.IndexOf('{'); if ($j -ge 0) { $negVSJson = $negVS.Substring($j) | ConvertFrom-Json } } catch {}
if ($negVSJson -and $negVSJson.verdict -eq "run_failed") { [void]$passes.Add("Negative: run_failed") } else { [void]$errors.Add("NEG_VS_NOT_FAIL"); $exitCode = 1 }
if ($negVS -match "MANIFEST_HONESTY_FAIL" -or $negVS -match "INTERFACE_DRIFT") { [void]$passes.Add("Negative: honesty/drift failure present") } else { [void]$errors.Add("NEG_WRONG_REASON"); $exitCode = 1 }
if ($negVS -match "INTERFACE_DRIFT_REPORT_FAIL" -and $negVS -match "MANIFEST_HONESTY_FAIL") { [void]$passes.Add("Negative: drift+honesty failure evidence") } else { [void]$errors.Add("NEG_NO_DRIFT_HONESTY_EVIDENCE"); $exitCode = 1 }
if ($negVS -notmatch "no_token_store") { [void]$passes.Add("Negative: no no_token_store") } else { [void]$errors.Add("NEG_TOKEN_STORE"); $exitCode = 1 }

# --- 35-37. Final report ---
$frPath = "$HarnessRoot\outputs\PHASE_6C_U0_D_FINAL_REPORT.md"
if (Test-Path $frPath) { [void]$passes.Add("Final report exists") } else { [void]$errors.Add("MISSING_FINAL_REPORT"); $exitCode = 1 }

# --- 38. T0-R3 unchanged ---
$t0r3Zip = "$HarnessRoot\outputs\phase6c-t0-r3-final-audit-bundle.zip"
$t0r3Hash = "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"
if (Test-Path $t0r3Zip) {
    if ((Get-FileHash $t0r3Zip -Algorithm SHA256).Hash.ToLower() -eq $t0r3Hash) { [void]$passes.Add("T0-R3 unchanged") }
    else { [void]$errors.Add("T0_R3_MODIFIED"); $exitCode = 1 }
}

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{ phase="Phase 6C-U0-D"; tool="phase6c-u0-d-verify"; verdict=$verdict; errorCount=$errors.Count; passCount=$passes.Count; errors=$errors; passes=$passes; timestamp=(Get-Date).ToString("o") }
if ($JsonOnly) { Write-Output ($result|ConvertTo-Json -Depth 4) }
else {
    Write-Output "`n=== U0-D VERDICT: $verdict ==="
    Write-Output "Errors: $($errors.Count) | Passes: $($passes.Count)"
    foreach ($p in $passes) { Write-Output "  [PASS] $p" }
    foreach ($e in $errors) { Write-Output "  [FAIL] $e" }
}
exit $exitCode