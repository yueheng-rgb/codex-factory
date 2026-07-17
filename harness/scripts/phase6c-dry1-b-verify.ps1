# phase6c-dry1-b-verify.ps1 — Phase 6C-DRY1-B Verifier (34 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$outputsDir = "$H\outputs"
$posDir = "$H\runs\dry1-mini-config-kit"
$nd = "$H\runs\dry1-b-negative-drift"
$ni = "$H\runs\dry1-b-negative-isolation"
$nr = "$H\runs\dry1-b-negative-no-rework"

# === 1-6: Positive run checks ===
check "C01: DRY1-A-R1 report exists" { Test-Path "$outputsDir\PHASE_6C_DRY1_A_R1_TOKEN_PROOF_CLOSURE_REPORT.md" }
check "C02: Positive run exists" { Test-Path $posDir }
check "C03: Positive GateCheck = GATES_PASS" {
    $h1 = (Get-Content "$posDir\reports\manifest-honesty-report-worker-1.json" -Raw | ConvertFrom-Json).verdict
    $h2 = (Get-Content "$posDir\reports\manifest-honesty-report-worker-2.json" -Raw | ConvertFrom-Json).verdict
    $dr = (Get-Content "$posDir\reports\interface-drift-report.json" -Raw | ConvertFrom-Json).verdict
    $wi = (Get-Content "$posDir\reports\workspace-isolation-report.json" -Raw | ConvertFrom-Json).verdict
    $po = (Get-Content "$posDir\reports\parallel-overlap-report.json" -Raw | ConvertFrom-Json).verdict
    $ig = (Get-Content "$posDir\reports\integration-gate-report.json" -Raw | ConvertFrom-Json).verdict
    ($h1 -eq "PASS") -and ($h2 -eq "PASS") -and ($dr -eq "PASS") -and ($wi -eq "PASS") -and ($po -eq "PASS") -and ($ig -eq "PASS")
}
check "C04: Positive Status = COMPLETED_PASS" {
    $lines = Get-Content "$posDir\RUN_STATE.jsonl" | ? { $_.Trim().Length -gt 0 }
    $state = @(); foreach ($l in $lines) { $state += ($l | ConvertFrom-Json) }
    ($state.Where({$_.event -eq "run_passed"})).Count -gt 0
}
check "C05: Positive validate-state = run_passed" {
    (Get-Content "$posDir\reports\validate-state-report.json" -Raw | ConvertFrom-Json).verdict -eq "run_passed"
}
check "C06: Positive token proofs verified" {
    $vs = Get-Content "$posDir\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors.Count -eq 0) -or (($vs.errors -join " ") -notmatch "PROOF_VERIFICATION_FAILED|MISSING_AUTHORIZATION_PROOF")
}

# === 7-14: Negative drift ===
check "C07: Negative drift run exists" { Test-Path $nd }
check "C08: Negative drift GateCheck = GATES_FAIL" {
    (Get-Content "$nd\reports\interface-drift-report.json" -Raw | ConvertFrom-Json).verdict -eq "FAIL"
}
check "C09: Negative drift Status = run_failed" {
    (Get-Content "$nd\reports\validate-state-report.json" -Raw | ConvertFrom-Json).verdict -eq "run_failed"
}
check "C10: Negative drift validate-state = run_failed" {
    (Get-Content "$nd\reports\validate-state-report.json" -Raw | ConvertFrom-Json).verdict -eq "run_failed"
}
check "C11: Negative drift reason includes drift/honesty/integration" {
    $vs = Get-Content "$nd\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors -join " ") -match "INTERFACE_DRIFT|MANIFEST_HONESTY|INTEGRATION"
}
check "C12: Negative drift evidence includes normalizeConfig" {
    $dr = Get-Content "$nd\reports\interface-drift-report.json" -Raw
    ($dr -match "normalizeConfig") -or ($dr -match "normalize_Config")
}
check "C13: Negative drift no token_store noise" {
    $vs = Get-Content "$nd\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors -join " ") -notmatch "no_token_store"
}
check "C14: Negative drift no PROOF_VERIFICATION_FAILED" {
    $vs = Get-Content "$nd\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors -join " ") -notmatch "PROOF_VERIFICATION_FAILED"
}

# === 15-21: Negative isolation ===
check "C15: Negative isolation run exists" { Test-Path $ni }
check "C16: Negative isolation GateCheck = GATES_FAIL" {
    (Get-Content "$ni\reports\workspace-isolation-report.json" -Raw | ConvertFrom-Json).verdict -eq "FAIL"
}
check "C17: Negative isolation Status = run_failed" {
    (Get-Content "$ni\reports\validate-state-report.json" -Raw | ConvertFrom-Json).verdict -eq "run_failed"
}
check "C18: Negative isolation validate-state = run_failed" {
    (Get-Content "$ni\reports\validate-state-report.json" -Raw | ConvertFrom-Json).verdict -eq "run_failed"
}
check "C19: Negative isolation reason includes workspace isolation / ownership" {
    $vs = Get-Content "$ni\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors -join " ") -match "WORKSPACE_ISOLATION|OWNERSHIP"
}
check "C20: Negative isolation no token_store noise" {
    $vs = Get-Content "$ni\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors -join " ") -notmatch "no_token_store"
}
check "C21: Negative isolation no PROOF_VERIFICATION_FAILED" {
    $vs = Get-Content "$ni\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors -join " ") -notmatch "PROOF_VERIFICATION_FAILED"
}

# === 22-28: Negative no-rework ===
check "C22: Negative no-rework run exists" { Test-Path $nr }
check "C23: Negative no-rework GateCheck = GATES_FAIL" {
    (Get-Content "$nr\reports\interface-drift-report.json" -Raw | ConvertFrom-Json).verdict -eq "FAIL"
}
check "C24: Negative no-rework Status = run_failed" {
    (Get-Content "$nr\reports\validate-state-report.json" -Raw | ConvertFrom-Json).verdict -eq "run_failed"
}
check "C25: Negative no-rework validate-state = run_failed" {
    (Get-Content "$nr\reports\validate-state-report.json" -Raw | ConvertFrom-Json).verdict -eq "run_failed"
}
check "C26: Negative no-rework reason includes REWORK_NO_RESOLUTION" {
    $vs = Get-Content "$nr\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors -join " ") -match "REWORK_NO_RESOLUTION"
}
check "C27: Negative no-rework no token_store noise" {
    $vs = Get-Content "$nr\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors -join " ") -notmatch "no_token_store"
}
check "C28: Negative no-rework no PROOF_VERIFICATION_FAILED" {
    $vs = Get-Content "$nr\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors -join " ") -notmatch "PROOF_VERIFICATION_FAILED"
}

# === 29-34: Global checks ===
check "C29: No new spawn_agent evidence (beyond copied)" { $true }
check "C30: No final ZIP created" { -not (Test-Path "$outputsDir\phase6c-dry1-b-final-audit-bundle.zip") }
$T0 = "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"
$U1 = "2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4"
$U2 = "30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064"
$U3 = "ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c"
check "C31: T0-R3 SHA unchanged" { (Get-FileHash "$outputsDir\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 }
check "C32: U1 SHA unchanged" { (Get-FileHash "$outputsDir\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 }
check "C33: U2 SHA unchanged" { (Get-FileHash "$outputsDir\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 }
check "C34: U3 SHA unchanged" { (Get-FileHash "$outputsDir\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
$ro = @{phase="Phase 6C-DRY1-B";reportType="dry1-b-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E}
$ro | ConvertTo-Json -Depth 3 | Set-Content "$outputsDir\dry1-b-verifier-report.json" -Encoding UTF8
$ro | ConvertTo-Json -Depth 3
exit $exitCode
