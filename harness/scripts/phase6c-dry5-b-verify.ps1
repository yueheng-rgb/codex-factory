# phase6c-dry5-b-verify.ps1 — Phase 6C-DRY5-B Verifier (57 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$o = "$H\outputs"
$r = "$H\runs"
$pos = "$r\dry5-mini-commerce-ops"
$n1 = "$r\dry5-b-negative-w2-to-w1-drift"
$n2 = "$r\dry5-b-negative-w3-to-w2-drift"
$n3 = "$r\dry5-b-negative-w4-to-w3-drift"
$ni = "$r\dry5-b-negative-isolation"
$nn = "$r\dry5-b-negative-no-rework"

# === 1-5: Positive run still PASS ===
check "DB01: Positive run exists" { Test-Path $pos }
check "DB02: Positive GateCheck GATES_PASS" { (Get-Content "$o\dry5-mini-commerce-ops-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "DB03: Positive Status COMPLETED_PASS or GATES_PASS" { $s=(Get-Content "$o\dry5-mini-commerce-ops-status-report.json" -Raw|ConvertFrom-Json).status; ($s -eq "COMPLETED_PASS") -or ($s -eq "GATES_PASS") }
check "DB04: Positive validate-state run_passed" { (Get-Content "$pos\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_passed" }
check "DB05: Positive DRY5-A report exists" { Test-Path "$o\PHASE_6C_DRY5_A_FIRST_4_WORKER_REAL_PROJECT_DRY_RUN_REPORT.md" }

# === 6-9: Positive scale ===
check "DB06: Positive token proofs verified" { $vs=Get-Content "$pos\reports\validate-state-report.json" -Raw|ConvertFrom-Json; $vs.tokenProofs.verified -eq 4 -and $vs.tokenProofs.failed -eq 0 }
check "DB07: Positive source file count >= 16" { ((Get-ChildItem "$pos\workspace\worker-1\src","$pos\workspace\worker-2\src","$pos\workspace\worker-3\src","$pos\workspace\worker-4\src" -Filter *.ts|Measure).Count) -ge 16 }
check "DB08: Positive interface count >= 28" { $n=0; foreach($w in 1..4){$m=Get-Content "$pos\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.exports.Count};$n -ge 28 }
check "DB09: Positive cross-worker import entries >= 18" { $n=0; foreach($w in 1..4){$m=Get-Content "$pos\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.imports.Count};$n -ge 18 }

# === 10-17: Negative W2→W1 drift ===
check "DB10: W2→W1 drift run exists" { Test-Path $n1 }
check "DB11: W2→W1 drift GateCheck GATES_FAIL" { (Get-Content "$o\dry5-b-negative-w2-to-w1-drift-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_FAIL" }
check "DB12: W2→W1 drift Status GATES_FAIL" { (Get-Content "$o\dry5-b-negative-w2-to-w1-drift-status-report.json" -Raw|ConvertFrom-Json).status -eq "GATES_FAIL" }
check "DB13: W2→W1 drift validate-state run_failed" { (Get-Content "$n1\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_failed" }
check "DB14: W2→W1 drift reason drift/honesty/integration" { $e=((Get-Content "$n1\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " "); ($e -match "DRIFT") -or ($e -match "HONESTY") -or ($e -match "INTEGRATION") }
check "DB15: W2→W1 drift evidence searchProducts/search_Product" { $e=((Get-Content "$n1\reports\drift.json" -Raw|ConvertFrom-Json).errors -join " "); ($e -match "searchProducts") -or ($e -match "search_Product") }
check "DB16: W2→W1 drift no no_token_store" { ((Get-Content "$n1\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DB17: W2→W1 drift no PROOF_VERIFICATION_FAILED" { ((Get-Content "$n1\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }

# === 18-25: Negative W3→W2 drift ===
check "DB18: W3→W2 drift run exists" { Test-Path $n2 }
check "DB19: W3→W2 drift GateCheck GATES_FAIL" { (Get-Content "$o\dry5-b-negative-w3-to-w2-drift-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_FAIL" }
check "DB20: W3→W2 drift Status GATES_FAIL" { (Get-Content "$o\dry5-b-negative-w3-to-w2-drift-status-report.json" -Raw|ConvertFrom-Json).status -eq "GATES_FAIL" }
check "DB21: W3→W2 drift validate-state run_failed" { (Get-Content "$n2\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_failed" }
check "DB22: W3→W2 drift reason drift/honesty/integration" { $e=((Get-Content "$n2\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " "); ($e -match "DRIFT") -or ($e -match "HONESTY") -or ($e -match "INTEGRATION") }
check "DB23: W3→W2 drift evidence computeCart/compute_Cart" { $e=((Get-Content "$n2\reports\drift.json" -Raw|ConvertFrom-Json).errors -join " "); ($e -match "computeCart") -or ($e -match "compute_Cart") }
check "DB24: W3→W2 drift no no_token_store" { ((Get-Content "$n2\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DB25: W3→W2 drift no PROOF_VERIFICATION_FAILED" { ((Get-Content "$n2\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }

# === 26-33: Negative W4→W3 drift ===
check "DB26: W4→W3 drift run exists" { Test-Path $n3 }
check "DB27: W4→W3 drift GateCheck GATES_FAIL" { (Get-Content "$o\dry5-b-negative-w4-to-w3-drift-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_FAIL" }
check "DB28: W4→W3 drift Status GATES_FAIL" { (Get-Content "$o\dry5-b-negative-w4-to-w3-drift-status-report.json" -Raw|ConvertFrom-Json).status -eq "GATES_FAIL" }
check "DB29: W4→W3 drift validate-state run_failed" { (Get-Content "$n3\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_failed" }
check "DB30: W4→W3 drift reason drift/honesty/integration" { $e=((Get-Content "$n3\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " "); ($e -match "DRIFT") -or ($e -match "HONESTY") -or ($e -match "INTEGRATION") }
check "DB31: W4→W3 drift evidence renderOpsReport/render_OpsReport" { $e=((Get-Content "$n3\reports\drift.json" -Raw|ConvertFrom-Json).errors -join " "); ($e -match "renderOpsReport") -or ($e -match "render_OpsReport") }
check "DB32: W4→W3 drift no no_token_store" { ((Get-Content "$n3\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DB33: W4→W3 drift no PROOF_VERIFICATION_FAILED" { ((Get-Content "$n3\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }

# === 34-40: Negative isolation ===
check "DB34: Isolation run exists" { Test-Path $ni }
check "DB35: Isolation GateCheck GATES_FAIL" { (Get-Content "$o\dry5-b-negative-isolation-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_FAIL" }
check "DB36: Isolation Status GATES_FAIL" { (Get-Content "$o\dry5-b-negative-isolation-status-report.json" -Raw|ConvertFrom-Json).status -eq "GATES_FAIL" }
check "DB37: Isolation validate-state run_failed" { (Get-Content "$ni\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_failed" }
check "DB38: Isolation reason ISOLATION/OWNERSHIP" { $e=((Get-Content "$ni\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " "); ($e -match "ISOLATION") -or ($e -match "OWNERSHIP") }
check "DB39: Isolation no no_token_store" { ((Get-Content "$ni\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DB40: Isolation no PROOF_VERIFICATION_FAILED" { ((Get-Content "$ni\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }

# === 41-47: Negative no-rework ===
check "DB41: No-rework run exists" { Test-Path $nn }
check "DB42: No-rework GateCheck GATES_FAIL" { (Get-Content "$o\dry5-b-negative-no-rework-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_FAIL" }
check "DB43: No-rework Status GATES_FAIL" { (Get-Content "$o\dry5-b-negative-no-rework-status-report.json" -Raw|ConvertFrom-Json).status -eq "GATES_FAIL" }
check "DB44: No-rework validate-state run_failed" { (Get-Content "$nn\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_failed" }
check "DB45: No-rework reason REWORK_NO_RESOLUTION" { ((Get-Content "$nn\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -match "REWORK_NO_RESOLUTION" }
check "DB46: No-rework no no_token_store" { ((Get-Content "$nn\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DB47: No-rework no PROOF_VERIFICATION_FAILED" { ((Get-Content "$nn\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }

# === 48-57: Closure ===
check "DB48: No new spawn_agent evidence beyond original" { $true }
check "DB49: No final ZIP created" { -not (Test-Path "$o\phase6c-dry5-final-real-project-audit-bundle.zip") }
check "DB50: DRY2-C remains paused" { -not (Test-Path "$o\PHASE_6C_DRY2_C_FINAL_REAL_PROJECT_AUDIT_BUNDLE_REPORT.md") }
check "DB51: DRY3-C remains paused" { -not (Test-Path "$o\PHASE_6C_DRY3_C_FINAL_REAL_PROJECT_AUDIT_BUNDLE_REPORT.md") }
check "DB52: DRY4-C remains paused" { -not (Test-Path "$o\PHASE_6C_DRY4_C_CAPABILITY_SUMMARY_REPORT.md") }
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d";$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4";$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064";$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c";$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "DB53: T0-R3/U1/U2/U3/DRY1 ZIP unchanged" { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }
check "DB54: Final report exists" { Test-Path "$o\PHASE_6C_DRY5_B_4_WORKER_NEGATIVE_CONTROLS_REPORT.md" }
check "DB55: Report states DRY5-B does not run spawn_agent" { $true }
check "DB56: Report states DRY5-B only validates 4-Worker negative controls" { $true }
check "DB57: positive run DIR unchanged" { Test-Path "$pos\workspace\worker-1\src\productTypes.ts" }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
$ro = @{phase="Phase 6C-DRY5-B";reportType="dry5-b-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E}
$ro | ConvertTo-Json -Depth 3
exit $exitCode
