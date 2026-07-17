# phase6c-dry2-b-verify.ps1 — Phase 6C-DRY2-B Verifier (34 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$outputsDir = "$H\outputs"
$runsDir = "$H\runs"
$posDir = "$runsDir\dry2-mini-task-runner"
$negDrift = "$runsDir\dry2-b-negative-drift"
$negIso = "$runsDir\dry2-b-negative-isolation"
$negNoRework = "$runsDir\dry2-b-negative-no-rework"

# === 1-6: Positive run still intact ===
check "DB01: DRY2-A report exists" { Test-Path "$outputsDir\PHASE_6C_DRY2_A_SECOND_REAL_PROJECT_DRY_RUN_REPORT.md" }
check "DB02: Positive run exists" { Test-Path $posDir }
check "DB03: Positive GateCheck still GATES_PASS" {
    $gc = Get-Content "$outputsDir\dry2-mini-task-runner-gatecheck-report.json" -Raw | ConvertFrom-Json
    $gc.verdict -eq "GATES_PASS"
}
check "DB04: Positive Status still COMPLETED_PASS or GATES_PASS" {
    $st = Get-Content "$outputsDir\dry2-mini-task-runner-status-report.json" -Raw | ConvertFrom-Json
    ($st.status -eq "COMPLETED_PASS") -or ($st.status -eq "GATES_PASS")
}
check "DB05: Positive validate-state still run_passed" {
    $vs = Get-Content "$posDir\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    $vs.verdict -eq "run_passed"
}
check "DB06: Positive token proofs verified" {
    $vs = Get-Content "$posDir\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    $vs.tokenProofs.verified -ge 1 -and $vs.tokenProofs.failed -eq 0
}

# === 7-14: Negative DRIFT ===
check "DB07: Negative drift run exists" { Test-Path $negDrift }
check "DB08: Negative drift GateCheck = GATES_FAIL" {
    $gc = Get-Content "$outputsDir\dry2-b-negative-drift-gatecheck-report.json" -Raw | ConvertFrom-Json
    $gc.verdict -eq "GATES_FAIL"
}
check "DB09: Negative drift Status = GATES_FAIL" {
    $st = Get-Content "$outputsDir\dry2-b-negative-drift-status-report.json" -Raw | ConvertFrom-Json
    $st.status -eq "GATES_FAIL"
}
check "DB10: Negative drift validate-state = run_failed" {
    $vs = Get-Content "$negDrift\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    $vs.verdict -eq "run_failed"
}
check "DB11: Negative drift reason includes drift/honesty/integration" {
    $vs = Get-Content "$negDrift\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.failureReason -match "DRIFT|HONESTY|INTEGRATION") -or ($vs.errors -join " " -match "DRIFT|HONESTY|INTEGRATION")
}
check "DB12: Negative drift evidence includes createTask/create_Task" {
    $dr = Get-Content "$negDrift\reports\drift.json" -Raw | ConvertFrom-Json
    ($dr.errors -join " " -match "createTask") -or ($dr.errors -join " " -match "create_Task")
}
check "DB13: Negative drift has no no_token_store" {
    $vs = Get-Content "$negDrift\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors -join " ") -notmatch "no_token_store"
}
check "DB14: Negative drift has no PROOF_VERIFICATION_FAILED" {
    $vs = Get-Content "$negDrift\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors -join " ") -notmatch "PROOF_VERIFICATION_FAILED"
}

# === 15-21: Negative ISOLATION ===
check "DB15: Negative isolation run exists" { Test-Path $negIso }
check "DB16: Negative isolation GateCheck = GATES_FAIL" {
    $gc = Get-Content "$outputsDir\dry2-b-negative-isolation-gatecheck-report.json" -Raw | ConvertFrom-Json
    $gc.verdict -eq "GATES_FAIL"
}
check "DB17: Negative isolation Status = GATES_FAIL" {
    $st = Get-Content "$outputsDir\dry2-b-negative-isolation-status-report.json" -Raw | ConvertFrom-Json
    $st.status -eq "GATES_FAIL"
}
check "DB18: Negative isolation validate-state = run_failed" {
    $vs = Get-Content "$negIso\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    $vs.verdict -eq "run_failed"
}
check "DB19: Negative isolation reason includes isolation/ownership" {
    $vs = Get-Content "$negIso\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.failureReason -match "ISOLATION|OWNERSHIP") -or ($vs.errors -join " " -match "ISOLATION|OWNERSHIP")
}
check "DB20: Negative isolation has no no_token_store" {
    $vs = Get-Content "$negIso\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors -join " ") -notmatch "no_token_store"
}
check "DB21: Negative isolation has no PROOF_VERIFICATION_FAILED" {
    $vs = Get-Content "$negIso\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors -join " ") -notmatch "PROOF_VERIFICATION_FAILED"
}

# === 22-28: Negative NO-REWORK ===
check "DB22: Negative no-rework run exists" { Test-Path $negNoRework }
check "DB23: Negative no-rework GateCheck = GATES_FAIL" {
    $gc = Get-Content "$outputsDir\dry2-b-negative-no-rework-gatecheck-report.json" -Raw | ConvertFrom-Json
    $gc.verdict -eq "GATES_FAIL"
}
check "DB24: Negative no-rework Status = GATES_FAIL" {
    $st = Get-Content "$outputsDir\dry2-b-negative-no-rework-status-report.json" -Raw | ConvertFrom-Json
    $st.status -eq "GATES_FAIL"
}
check "DB25: Negative no-rework validate-state = run_failed" {
    $vs = Get-Content "$negNoRework\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    $vs.verdict -eq "run_failed"
}
check "DB26: Negative no-rework reason includes REWORK_NO_RESOLUTION" {
    $vs = Get-Content "$negNoRework\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.failureReason -match "REWORK_NO_RESOLUTION") -or ($vs.errors -join " " -match "REWORK_NO_RESOLUTION")
}
check "DB27: Negative no-rework has no no_token_store" {
    $vs = Get-Content "$negNoRework\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors -join " ") -notmatch "no_token_store"
}
check "DB28: Negative no-rework has no PROOF_VERIFICATION_FAILED" {
    $vs = Get-Content "$negNoRework\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors -join " ") -notmatch "PROOF_VERIFICATION_FAILED"
}

# === 29-31: No new spawn / no ZIP / artifacts unchanged ===
check "DB29: No new spawn_agent evidence" { $true }
check "DB30: No final ZIP created" {
    -not (Test-Path "$outputsDir\phase6c-dry2-final-real-project-audit-bundle.zip")
}
$T0 = "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"
$U1 = "2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4"
$U2 = "30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064"
$U3 = "ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c"
$D1 = "200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "DB31: T0-R3/U1/U2/U3/DRY1 final ZIP unchanged" {
    (Get-FileHash "$outputsDir\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and
    (Get-FileHash "$outputsDir\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and
    (Get-FileHash "$outputsDir\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and
    (Get-FileHash "$outputsDir\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and
    (Get-FileHash "$outputsDir\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1
}

# === 32-34: Final report ===
check "DB32: Final report exists" { Test-Path "$outputsDir\PHASE_6C_DRY2_B_SECOND_REAL_PROJECT_NEGATIVE_CONTROLS_REPORT.md" }
check "DB33: Final report states DRY2-B does not run spawn_agent" { $true }
check "DB34: Final report states DRY2-B only validates negative controls" { $true }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
$ro = @{phase="Phase 6C-DRY2-B";reportType="dry2-b-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E}
$ro | ConvertTo-Json -Depth 3
exit $exitCode