# phase6c-u1-b-verify.ps1 — Phase 6C-U1-B Real 2-Worker Contract Run Verifier (40 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$R = Join-Path $H "runs\u1-r1"
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l, $sb) { $script:total++; try { if (& $sb) { [void]$script:P.Add($l); $script:ok++ } else { [void]$script:E.Add("$l-FAIL") } } catch { [void]$script:E.Add("$l-ERROR: $_") } }

$spawn = if (Test-Path "$R\spawn-agent-evidence.json") { Get-Content "$R\spawn-agent-evidence.json" | ConvertFrom-Json } else { $null }
$sdm1 = if (Test-Path "$R\source-derived-interface-manifests\worker-1.json") { Get-Content "$R\source-derived-interface-manifests\worker-1.json" | ConvertFrom-Json } else { $null }
$sdm2 = if (Test-Path "$R\source-derived-interface-manifests\worker-2.json") { Get-Content "$R\source-derived-interface-manifests\worker-2.json" | ConvertFrom-Json } else { $null }
$h1 = if (Test-Path "$R\reports\manifest-honesty-report-worker-1.json") { Get-Content "$R\reports\manifest-honesty-report-worker-1.json" | ConvertFrom-Json } else { $null }
$h2 = if (Test-Path "$R\reports\manifest-honesty-report-worker-2.json") { Get-Content "$R\reports\manifest-honesty-report-worker-2.json" | ConvertFrom-Json } else { $null }
$drift = if (Test-Path "$R\reports\interface-drift-report.json") { Get-Content "$R\reports\interface-drift-report.json" | ConvertFrom-Json } else { $null }
$iso = if (Test-Path "$R\reports\workspace-isolation-report.json") { Get-Content "$R\reports\workspace-isolation-report.json" | ConvertFrom-Json } else { $null }
$ov = if (Test-Path "$R\reports\parallel-overlap-report.json") { Get-Content "$R\reports\parallel-overlap-report.json" | ConvertFrom-Json } else { $null }
$ig = if (Test-Path "$R\reports\integration-gate-report.json") { Get-Content "$R\reports\integration-gate-report.json" | ConvertFrom-Json } else { $null }
$vsOut = & "$H\scripts\validate-state.ps1" -RunDir $R 2>&1 | Out-String
$vs = try { $vsOut | ConvertFrom-Json } catch { $null }

# 1-2: Run infra
check "V01: U1-A report exists" { Test-Path "$H\outputs\PHASE_6C_U1_A_MATERIALIZATION_REPORT.md" }
check "V02: runs/u1-r1/ exists" { Test-Path $R }

# 3-5: Spawn evidence
check "V03: spawn-agent-evidence exists" { $spawn -ne $null }
check "V04: realWorkersUsed=true" { $spawn.realWorkersUsed -eq $true }
check "V05: workerCount=2" { $spawn.workerCount -eq 2 }

# 6-9: Worker outputs
check "V06: Worker 1 src/utils.ts exists" { (Test-Path "$R\workspace\worker-1\src\utils.ts") -and ((Get-Item "$R\workspace\worker-1\src\utils.ts").Length -gt 50) }
check "V07: Worker 2 src/app.ts exists" { (Test-Path "$R\workspace\worker-2\src\app.ts") -and ((Get-Item "$R\workspace\worker-2\src\app.ts").Length -gt 50) }
check "V08: Worker 1 manifest exists" { Test-Path "$R\worker-interface-manifests\worker-1-interface-manifest.json" }
check "V09: Worker 2 manifest exists" { Test-Path "$R\worker-interface-manifests\worker-2-interface-manifest.json" }

# 10-11: Source-derived manifests
check "V10: SDM worker-1 exists" { $sdm1 -ne $null }
check "V11: SDM worker-2 exists" { $sdm2 -ne $null }

# 12-18: Source-derived content
$w1Exports = if ($sdm1) { ($sdm1.exports | ForEach-Object { $_.name }) -join "," } else { "" }
$w2Imports = if ($sdm2) { ($sdm2.imports | ForEach-Object { $_.name }) -join "," } else { "" }
$w2Exports = if ($sdm2) { ($sdm2.exports | ForEach-Object { $_.name }) -join "," } else { "" }
check "V12: SDM w1 exports formatDate" { $w1Exports -match "formatDate" }
check "V13: SDM w1 exports makeRunLabel" { $w1Exports -match "makeRunLabel" }
check "V14: SDM w1 exports validateRunId" { $w1Exports -match "validateRunId" }
check "V15: SDM w2 imports formatDate" { $w2Imports -match "formatDate" }
check "V16: SDM w2 imports makeRunLabel" { $w2Imports -match "makeRunLabel" }
check "V17: SDM w2 exports buildSummary" { $w2Exports -match "buildSummary" }
check "V18: SDM w2 exports buildAuditLine" { $w2Exports -match "buildAuditLine" }

# 19-28: Gate reports
check "V19: Honesty w1 PASS" { $h1 -and $h1.verdict -eq "PASS" }
check "V20: Honesty w1 mismatchCount=0" { $h1 -and $h1.mismatches.Count -eq 0 }
check "V21: Honesty w2 PASS" { $h2 -and $h2.verdict -eq "PASS" }
check "V22: Honesty w2 mismatchCount=0" { $h2 -and $h2.mismatches.Count -eq 0 }
check "V23: Drift PASS" { $drift -and $drift.verdict -eq "PASS" }
check "V24: Drift count=0" { $drift -and $drift.driftCount -eq 0 }
check "V25: Isolation PASS" { $iso -and $iso.verdict -eq "PASS" }
check "V26: Overlap PASS" { $ov -and $ov.verdict -eq "PASS" }
check "V27: Overlap exists" { $ov -and $ov.overlap.exists -eq $true }
check "V28: overlapSeconds>0" { $ov -and $ov.overlap.overlapSeconds -gt 0 }

# 29-33: Integration + validate-state
check "V29: Integration gate PASS" { $ig -and $ig.verdict -eq "PASS" }
check "V30: validate-state verdict=run_passed" { $vs -and $vs.verdict -eq "run_passed" }
check "V31: No no_token_store" { $vsOut -notmatch "no_token_store" }
check "V32: No PROOF_VERIFICATION_FAILED" { $vsOut -notmatch "PROOF_VERIFICATION_FAILED" }
check "V33: Authorization proofs verified" { $vsOut -match "Authorization proofs:" }

# 34-35: Artifact integrity
check "V34: T0-R3 ZIP unchanged" {
    $zip = "$H\outputs\phase6c-t0-r3-final-audit-bundle.zip"
    if (Test-Path $zip) { (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower() -eq "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d" } else { $false }
}
check "V35: U0-D/E/F runs exist" { (Test-Path "$H\runs\phase6c-u0-d-real") -and (Test-Path "$H\runs\phase6c-u0-e-real-parallel") -and (Test-Path "$H\runs\phase6c-u0-f-rework") }

# 36-40: Boundaries
check "V36: Final report exists" { Test-Path "$H\outputs\PHASE_6C_U1_B_REAL_RUN_REPORT.md" }
$report = if (Test-Path "$H\outputs\PHASE_6C_U1_B_REAL_RUN_REPORT.md") { Get-Content "$H\outputs\PHASE_6C_U1_B_REAL_RUN_REPORT.md" -Raw } else { "" }
check "V37: Report states one real run only" { $report -match "one real|real two-Worker|real 2-Worker" }
check "V38: Report does not claim mature factory" { $report -match "does not prove mature" }
check "V39: No U1-C directories" { -not (Test-Path "$H\runs\u1-r1-negative") -and -not (Test-Path "$H\runs\phase6c-u1-c") }
check "V40: No U1-D ZIP" { -not (Test-Path "$H\outputs\phase6c-u1-final-audit-bundle") }

$verdict = if ($E.Count -eq 0) { "PASS" } else { "FAIL" }
$exitCode = if ($E.Count -gt 0) { 1 } else { 0 }
@{ phase="Phase 6C-U1-B"; reportType="u1-b-verifier"; verdict=$verdict; timestamp=(Get-Date).ToString("o"); totalChecks=$total; passCount=$ok; failCount=$E.Count; passes=$P; errors=$E } | ConvertTo-Json -Depth 3
exit $exitCode