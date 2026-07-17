# phase6c-u1-c-verify.ps1 — Phase 6C-U1-C Negative Controls Verifier (25 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$VS = Join-Path $H "scripts\validate-state.ps1"
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l, $sb) { $script:total++; try { if (& $sb) { [void]$script:P.Add($l); $script:ok++ } else { [void]$script:E.Add("$l-FAIL") } } catch { [void]$script:E.Add("$l-ERROR: $_") } }

function runVs($dir) { $o = & $script:VS -RunDir $dir 2>&1 | Out-String; try { $o | ConvertFrom-Json } catch { $null } }
function vsStr($dir) { & $script:VS -RunDir $dir 2>&1 | Out-String }

$posVs = vsStr "$H\runs\u1-r1"
$posV = runVs "$H\runs\u1-r1"
$negDV = runVs "$H\runs\u1-r1-negative-drift"; $negDS = vsStr "$H\runs\u1-r1-negative-drift"
$negIV = runVs "$H\runs\u1-r1-negative-isolation"; $negIS = vsStr "$H\runs\u1-r1-negative-isolation"
$negRV = runVs "$H\runs\u1-r1-negative-no-rework"; $negRS = vsStr "$H\runs\u1-r1-negative-no-rework"

# 1-3: U1-B positive still valid
check "V01: U1-B report exists" { Test-Path "$H\outputs\PHASE_6C_U1_B_REAL_RUN_REPORT.md" }
check "V02: U1-B positive run exists" { Test-Path "$H\runs\u1-r1" }
check "V03: U1-B validate-state still PASS" { $posV.verdict -eq "run_passed" }

# 4-9: Negative drift
check "V04: Negative drift run exists" { Test-Path "$H\runs\u1-r1-negative-drift" }
check "V05: Negative drift run_failed" { $negDV.verdict -eq "run_failed" }
check "V06: Drift failure: honesty/drift" { ($negDV.errors -join " ") -match "MANIFEST_HONESTY_FAIL|INTERFACE_DRIFT_FAIL" }
check "V07: Drift: formatDate/format_date evidence" { (Get-Content "$H\runs\u1-r1-negative-drift\reports\manifest-honesty-report-worker-2.json" -Raw) -match "formatDate|format_date" }
check "V08: Drift: no no_token_store" { $negDS -notmatch "no_token_store" }
check "V09: Drift: no PROOF_VERIFICATION_FAILED" { $negDS -notmatch "PROOF_VERIFICATION_FAILED" }

# 10-14: Negative isolation
check "V10: Negative isolation run exists" { Test-Path "$H\runs\u1-r1-negative-isolation" }
check "V11: Negative isolation run_failed" { $negIV.verdict -eq "run_failed" }
check "V12: Isolation failure: workspace/ownership" { ($negIV.errors -join " ") -match "WORKSPACE_ISOLATION_FAIL|OWNERSHIP_VIOLATION" }
check "V13: Isolation: no no_token_store" { $negIS -notmatch "no_token_store" }
check "V14: Isolation: no PROOF_VERIFICATION_FAILED" { $negIS -notmatch "PROOF_VERIFICATION_FAILED" }

# 15-19: Negative no-rework
check "V15: Negative no-rework run exists" { Test-Path "$H\runs\u1-r1-negative-no-rework" }
check "V16: Negative no-rework run_failed" { $negRV.verdict -eq "run_failed" }
check "V17: No-rework failure: REWORK_NO_RESOLUTION" { ($negRV.errors -join " ") -match "REWORK_NO_RESOLUTION" }
check "V18: No-rework: no no_token_store" { $negRS -notmatch "no_token_store" }
check "V19: No-rework: no PROOF_VERIFICATION_FAILED" { $negRS -notmatch "PROOF_VERIFICATION_FAILED" }

# 20-25: Boundaries
check "V20: No U1-D ZIP" { -not (Test-Path "$H\outputs\phase6c-u1-final-audit-bundle") }
check "V21: T0-R3 ZIP unchanged" {
    $zip = "$H\outputs\phase6c-t0-r3-final-audit-bundle.zip"
    if (Test-Path $zip) { (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower() -eq "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d" } else { $false }
}
check "V22: U0-D/E/F runs exist" { (Test-Path "$H\runs\phase6c-u0-d-real") -and (Test-Path "$H\runs\phase6c-u0-e-real-parallel") -and (Test-Path "$H\runs\phase6c-u0-f-rework") }
check "V23: Final report exists" { Test-Path "$H\outputs\PHASE_6C_U1_C_NEGATIVE_CONTROLS_REPORT.md" }
$report = if (Test-Path "$H\outputs\PHASE_6C_U1_C_NEGATIVE_CONTROLS_REPORT.md") { Get-Content "$H\outputs\PHASE_6C_U1_C_NEGATIVE_CONTROLS_REPORT.md" -Raw } else { "" }
check "V24: Report: no new spawn_agent claim" { $report -match "does not prove new spawn_agent|does not run new spawn_agent" }
check "V25: Report: validates negatives only" { $report -match "validates negative controls|negative controls for" }

$verdict = if ($E.Count -eq 0) { "PASS" } else { "FAIL" }
$exitCode = if ($E.Count -gt 0) { 1 } else { 0 }
@{ phase="Phase 6C-U1-C"; reportType="u1-c-verifier"; verdict=$verdict; timestamp=(Get-Date).ToString("o"); totalChecks=$total; passCount=$ok; failCount=$E.Count; passes=$P; errors=$E } | ConvertTo-Json -Depth 3
exit $exitCode