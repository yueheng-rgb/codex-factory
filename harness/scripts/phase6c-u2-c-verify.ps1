# phase6c-u2-c-verify.ps1 — Phase 6C-U2-C Negative Controls Verifier (25 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

# 1-3: Prerequisites
check "V01: U2-B final report exists" { Test-Path "$H\outputs\PHASE_6C_U2_B_FACTORY_REAL_RUN_REPORT.md" }
check "V02: U2-B positive run exists" { Test-Path "$H\runs\u2-b-factory-real-run" }

# Read validate-state reports
function getVs($rd) {
    $p = "$rd\reports\validate-state-report.json"
    if (Test-Path $p) { Get-Content $p | ConvertFrom-Json } else { $null }
}
$posVs = getVs "$H\runs\u2-b-factory-real-run"
$neg1Vs = getVs "$H\runs\u2-c-negative-drift"
$neg2Vs = getVs "$H\runs\u2-c-negative-isolation"
$neg3Vs = getVs "$H\runs\u2-c-negative-no-rework"

# 3: U2-B positive still PASS
check "V03: U2-B positive validate-state still PASS" { $posVs -and $posVs.verdict -eq "run_passed" }

# 4-9: Negative drift
check "V04: Negative drift run exists" { Test-Path "$H\runs\u2-c-negative-drift" }
check "V05: Negative drift validate-state FAIL" { $neg1Vs -and $neg1Vs.verdict -eq "run_failed" }
check "V06: Drift reason includes drift/honesty/integration" { 
    $errs = ($neg1Vs.errors | Out-String)
    $errs -match "INTERFACE_DRIFT_FAIL|INTEGRATION_GATE_FAIL|MANIFEST_HONESTY_FAIL"
}
check "V07: Drift evidence includes formatDate/format_date" {
    $src = Get-Content "$H\runs\u2-c-negative-drift\workspace\worker-2\src\service.ts" -Raw
    $src -match "format_date"
}
check "V08: Drift has no no_token_store" { ($neg1Vs.errors | Out-String) -notmatch "no_token_store" }
check "V09: Drift has no PROOF_VERIFICATION_FAILED" { ($neg1Vs.errors | Out-String) -notmatch "PROOF_VERIFICATION_FAILED" }

# 10-14: Negative isolation
check "V10: Negative isolation run exists" { Test-Path "$H\runs\u2-c-negative-isolation" }
check "V11: Negative isolation validate-state FAIL" { $neg2Vs -and $neg2Vs.verdict -eq "run_failed" }
check "V12: Isolation reason includes workspace isolation/ownership" {
    ($neg2Vs.errors | Out-String) -match "WORKSPACE_ISOLATION_FAIL|OWNERSHIP_VIOLATION"
}
check "V13: Isolation has no no_token_store" { ($neg2Vs.errors | Out-String) -notmatch "no_token_store" }
check "V14: Isolation has no PROOF_VERIFICATION_FAILED" { ($neg2Vs.errors | Out-String) -notmatch "PROOF_VERIFICATION_FAILED" }

# 15-19: Negative no-rework
check "V15: Negative no-rework run exists" { Test-Path "$H\runs\u2-c-negative-no-rework" }
check "V16: Negative no-rework validate-state FAIL" { $neg3Vs -and $neg3Vs.verdict -eq "run_failed" }
check "V17: No-rework reason includes REWORK_NO_RESOLUTION" {
    ($neg3Vs.errors | Out-String) -match "REWORK_NO_RESOLUTION"
}
check "V18: No-rework has no no_token_store" { ($neg3Vs.errors | Out-String) -notmatch "no_token_store" }
check "V19: No-rework has no PROOF_VERIFICATION_FAILED" { ($neg3Vs.errors | Out-String) -notmatch "PROOF_VERIFICATION_FAILED" }

# 20-22: Boundaries
check "V20: No final audit ZIP created" { -not (Test-Path "$H\outputs\phase6c-u2-c-final-audit-bundle.zip") }
check "V21: T0-R3 artifact unchanged" {
    $t="$H\outputs\phase6c-t0-r3-final-audit-bundle.zip"
    if(Test-Path $t){(Get-FileHash $t -Algorithm SHA256).Hash.ToLower() -eq "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"}else{$false}
}
check "V22: U1 final ZIP unchanged" {
    $u="$H\outputs\phase6c-u1-final-audit-bundle.zip"
    if(Test-Path $u){(Get-FileHash $u -Algorithm SHA256).Hash.ToLower() -eq "2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4"}else{$false}
}

# 23-25: Report
$reportPath = "$H\outputs\PHASE_6C_U2_C_FACTORY_NEGATIVE_CONTROLS_REPORT.md"
check "V23: Final report exists" { Test-Path $reportPath }
check "V24: Report states no spawn_agent" { 
    if(Test-Path $reportPath){$r=Get-Content $reportPath -Raw;$r -match "does not run spawn_agent|does not prove new spawn"}else{$false}
}
check "V25: Report states only validates negative controls" {
    if(Test-Path $reportPath){$r=Get-Content $reportPath -Raw;$r -match "negative controls|validates negative"}else{$false}
}

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
@{phase="Phase 6C-U2-C";reportType="u2-c-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E} | ConvertTo-Json -Depth 3
exit $exitCode
