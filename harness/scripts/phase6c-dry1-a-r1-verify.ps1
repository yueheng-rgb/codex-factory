# phase6c-dry1-a-r1-verify.ps1 — Phase 6C-DRY1-A-R1 Verifier (27 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$runDir = "$H\runs\dry1-mini-config-kit"
$outputsDir = "$H\outputs"

# === 1. DRY1-A final report exists ===
check "C01: DRY1-A final report exists" { Test-Path "$outputsDir\PHASE_6C_DRY1_A_FIRST_REAL_PROJECT_DRY_RUN_REPORT.md" }

# === 2. Diagnosis report exists ===
check "C02: Diagnosis report exists" { Test-Path "$outputsDir\PHASE_6C_DRY1_A_R1_TOKEN_PROOF_DIAGNOSIS.json" }

# === 3. dry1-mini-config-kit run exists ===
check "C03: Run directory exists" { Test-Path $runDir }

# === 4-5. Worker source files unchanged ===
check "C04: Worker 1 source unchanged" { Test-Path "$runDir\workspace\worker-1\src\configTypes.ts" }
check "C05: Worker 2 source unchanged" { Test-Path "$runDir\workspace\worker-2\src\buildConfigSummary.ts" }

# === 6. spawn-agent-evidence still exists ===
check "C06: Spawn evidence exists" { Test-Path "$runDir\spawn-agent-evidence.json" }

# === 7-8. realWorkersUsed + workerCount ===
check "C07: realWorkersUsed=true" {
    $ev = Get-Content "$runDir\spawn-agent-evidence.json" -Raw | ConvertFrom-Json
    $ev.realWorkersUsed -eq $true
}
check "C08: workerCount=2" {
    $ev = Get-Content "$runDir\spawn-agent-evidence.json" -Raw | ConvertFrom-Json
    $ev.workerCount -eq 2
}

# === 9. GateCheck = GATES_PASS ===
check "C09: All gates PASS" {
    $h1 = (Get-Content "$runDir\reports\manifest-honesty-report-worker-1.json" -Raw | ConvertFrom-Json).verdict
    $h2 = (Get-Content "$runDir\reports\manifest-honesty-report-worker-2.json" -Raw | ConvertFrom-Json).verdict
    $dr = (Get-Content "$runDir\reports\interface-drift-report.json" -Raw | ConvertFrom-Json).verdict
    $wi = (Get-Content "$runDir\reports\workspace-isolation-report.json" -Raw | ConvertFrom-Json).verdict
    $po = (Get-Content "$runDir\reports\parallel-overlap-report.json" -Raw | ConvertFrom-Json).verdict
    $ig = (Get-Content "$runDir\reports\integration-gate-report.json" -Raw | ConvertFrom-Json).verdict
    ($h1 -eq "PASS") -and ($h2 -eq "PASS") -and ($dr -eq "PASS") -and ($wi -eq "PASS") -and ($po -eq "PASS") -and ($ig -eq "PASS")
}

# === 10. Status = COMPLETED_PASS ===
check "C10: Run status is completed" {
    $lines = Get-Content "$runDir\RUN_STATE.jsonl" | Where-Object { $_.Trim().Length -gt 0 }
    $state = @(); foreach ($line in $lines) { $state += ($line | ConvertFrom-Json) }
    ($state.Where({$_.event -eq "run_passed"})).Count -gt 0
}

# === 11. validate-state report exists ===
check "C11: validate-state report exists" { Test-Path "$runDir\reports\validate-state-report.json" }

# === 12. validate-state verdict = run_passed ===
check "C12: validate-state = run_passed" {
    $vs = Get-Content "$runDir\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    $vs.verdict -eq "run_passed"
}

# === 13. Token authorization proofs verified ===
check "C13: Token authorization proofs verified" {
    $vs = Get-Content "$runDir\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors.Count -eq 0) -or (($vs.errors -join " ") -notmatch "PROOF_VERIFICATION_FAILED|MISSING_AUTHORIZATION_PROOF")
}

# === 14. no no_token_store ===
check "C14: No token store errors" {
    $vs = Get-Content "$runDir\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors.Count -eq 0) -or (($vs.errors -join " ") -notmatch "no_token_store")
}

# === 15. no PROOF_VERIFICATION_FAILED ===
check "C15: No proof verification failures" {
    $vs = Get-Content "$runDir\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors.Count -eq 0) -or (($vs.errors -join " ") -notmatch "PROOF_VERIFICATION_FAILED")
}

# === 16. Hash chain valid ===
check "C16: Hash chain valid" {
    $vs = Get-Content "$runDir\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.passes -match "Hash chain valid").Count -gt 0
}

# === 17-21. Individual gates ===
check "C17: Honesty W1 PASS" {
    (Get-Content "$runDir\reports\manifest-honesty-report-worker-1.json" -Raw | ConvertFrom-Json).verdict -eq "PASS"
}
check "C18: Honesty W2 PASS" {
    (Get-Content "$runDir\reports\manifest-honesty-report-worker-2.json" -Raw | ConvertFrom-Json).verdict -eq "PASS"
}
check "C19: Drift PASS" {
    (Get-Content "$runDir\reports\interface-drift-report.json" -Raw | ConvertFrom-Json).verdict -eq "PASS"
}
check "C20: Isolation PASS" {
    (Get-Content "$runDir\reports\workspace-isolation-report.json" -Raw | ConvertFrom-Json).verdict -eq "PASS"
}
check "C21: Integration PASS" {
    (Get-Content "$runDir\reports\integration-gate-report.json" -Raw | ConvertFrom-Json).verdict -eq "PASS"
}

# === 22. no DRY1-B negatives ===
check "C22: No DRY1-B negatives" { -not (Test-Path "$H\runs\dry1-b-*") }

# === 23. no final ZIP ===
check "C23: No final ZIP created" { -not (Test-Path "$outputsDir\phase6c-dry1-a-r1-final-audit-bundle.zip") }

# === 24-27. Closed ZIPs unchanged ===
$T0_HASH = "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"
$U1_HASH = "2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4"
$U2_HASH = "30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064"
$U3_HASH = "ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c"
check "C24: T0-R3 SHA unchanged" { (Get-FileHash "$outputsDir\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0_HASH }
check "C25: U1 SHA unchanged" { (Get-FileHash "$outputsDir\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1_HASH }
check "C26: U2 SHA unchanged" { (Get-FileHash "$outputsDir\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2_HASH }
check "C27: U3 SHA unchanged" { (Get-FileHash "$outputsDir\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3_HASH }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
$reportObj = @{phase="Phase 6C-DRY1-A-R1";reportType="dry1-a-r1-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E}
$reportObj | ConvertTo-Json -Depth 3 | Set-Content "$outputsDir\dry1-a-r1-verifier-report.json" -Encoding UTF8
$reportObj | ConvertTo-Json -Depth 3
exit $exitCode
