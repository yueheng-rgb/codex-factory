# phase6c-u3-c-verify.ps1 — Phase 6C-U3-C Operator Negative Controls Verifier (34 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total=0;$ok=0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

# 1-3
check "V01: U3-B report exists" { Test-Path "$H\outputs\PHASE_6C_U3_B_OPERATOR_REAL_RUN_REPORT.md" }
check "V02: Operator CLI exists" { Test-Path "$H\scripts\invoke-project-factory.ps1" }
check "V03: U3-B positive exists" { Test-Path "$H\runs\u3-b-operator-real-run" }

# 4-5: Positive still OK
$posVs = Get-Content "$H\runs\u3-b-operator-real-run\reports\validate-state-report.json"|ConvertFrom-Json
check "V04: U3-B positive validate-state run_passed" { $posVs.verdict -eq "run_passed" }
$posSt = Get-Content "$H\outputs\u3-b-operator-real-run-status-report.json"|ConvertFrom-Json
check "V05: U3-B positive Status GATES_PASS" { $posSt.status -eq "GATES_PASS" }

function checkNeg($tag,$rid) {
    $rd = "$H\runs\$rid"
    $vs = Get-Content "$rd\reports\validate-state-report.json"|ConvertFrom-Json
    $gc = Get-Content "$H\outputs\$rid-gatecheck-report.json"|ConvertFrom-Json
    $st = Get-Content "$H\outputs\$rid-status-report.json"|ConvertFrom-Json
    $errs = ($vs.errors|Out-String)
    return @{vs=$vs;gc=$gc;st=$st;errs=$errs;tag=$tag;runDir=$rd}
}

$n1 = checkNeg "drift" "u3-c-negative-drift"
$n2 = checkNeg "isolation" "u3-c-negative-isolation"
$n3 = checkNeg "no-rework" "u3-c-negative-no-rework"

# 6-10: NEG1 drift
check "V06: Drift run exists" { Test-Path "$H\runs\u3-c-negative-drift" }
check "V07: Drift GateCheck GATES_FAIL" { $n1.gc.status -eq "GATES_FAIL" }
check "V08: Drift Status GATES_FAIL" { $n1.st.status -eq "GATES_FAIL" }
check "V09: Drift validate-state FAIL" { $n1.vs.verdict -eq "run_failed" }
check "V10: Drift reason drift/honesty/integration" { $n1.errs -match "INTERFACE_DRIFT|INTEGRATION_GATE|MANIFEST_HONESTY" }

# 11-13: NEG1 noise
check "V11: Drift no no_token_store" { $n1.errs -notmatch "no_token_store" }
check "V12: Drift no PROOF_VERIFICATION_FAILED" { $n1.errs -notmatch "PROOF_VERIFICATION_FAILED" }

# 14-19: NEG2
check "V13: Isolation run exists" { Test-Path "$H\runs\u3-c-negative-isolation" }
check "V14: Isolation GateCheck GATES_FAIL" { $n2.gc.status -eq "GATES_FAIL" }
check "V15: Isolation Status GATES_FAIL" { $n2.st.status -eq "GATES_FAIL" }
check "V16: Isolation validate-state FAIL" { $n2.vs.verdict -eq "run_failed" }
check "V17: Isolation reason workspace/ownership" { $n2.errs -match "WORKSPACE_ISOLATION|OWNERSHIP_VIOLATION" }
check "V18: Isolation no noise" { $n2.errs -notmatch "no_token_store|PROOF_VERIFICATION_FAILED" }

# 20-26: NEG3
check "V19: No-rework run exists" { Test-Path "$H\runs\u3-c-negative-no-rework" }
check "V20: No-rework GateCheck GATES_FAIL" { $n3.gc.status -eq "GATES_FAIL" }
check "V21: No-rework Status GATES_FAIL" { $n3.st.status -eq "GATES_FAIL" }
check "V22: No-rework validate-state FAIL" { $n3.vs.verdict -eq "run_failed" }
check "V23: No-rework reason REWORK_NO_RESOLUTION" { $n3.errs -match "REWORK_NO_RESOLUTION" }
check "V24: No-rework no noise" { $n3.errs -notmatch "no_token_store|PROOF_VERIFICATION_FAILED" }

# 27-34: Boundaries
check "V25: No final ZIP" { -not (Test-Path "$H\outputs\phase6c-u3-c-final-audit-bundle.zip") }
check "V26: T0-R3 unchanged" { (Get-FileHash "$H\outputs\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d" }
check "V27: U1 unchanged" { (Get-FileHash "$H\outputs\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq "2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4" }
check "V28: U2 unchanged" { (Get-FileHash "$H\outputs\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq "30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064" }
$rp = "$H\outputs\PHASE_6C_U3_C_OPERATOR_NEGATIVE_CONTROLS_REPORT.md"
check "V29: Final report exists" { Test-Path $rp }
check "V30: Report states no spawn_agent" { if(Test-Path $rp){$r=Get-Content $rp -Raw;$r -match "does not run spawn|does not prove new spawn"}else{$false} }
check "V31: Report states only validates negatives" { if(Test-Path $rp){$r=Get-Content $rp -Raw;$r -match "negative controls|validates negative"}else{$false} }

$verdict=if($E.Count -eq 0){"PASS"}else{"FAIL"}
$ec=if($E.Count -gt 0){1}else{0}
@{phase="Phase 6C-U3-C";reportType="u3-c-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E}|ConvertTo-Json -Depth 3
exit $ec
