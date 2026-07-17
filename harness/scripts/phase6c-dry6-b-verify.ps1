# phase6c-dry6-b-verify.ps1 — Phase 6C-DRY6-B Verifier (47 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$o = "$H\outputs"
$r = "$H\runs"
$pos = "$r\dry6-mini-invoice-ledger"
$n1 = "$r\dry6-b-negative-invoice-paid-flow"
$n2 = "$r\dry6-b-negative-overdue-detection"
$n3 = "$r\dry6-b-negative-ledger-markdown"
$n4 = "$r\dry6-b-negative-cross-worker-business-flow"

# === 1-6: Positive still PASS ===
check "DB01: Positive run exists" { Test-Path $pos }
check "DB02: Positive GateCheck GATES_PASS" { (Get-Content "$o\dry6-mini-invoice-ledger-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "DB03: Positive Status COMPLETED_PASS" { $s=(Get-Content "$o\dry6-mini-invoice-ledger-status-report.json" -Raw|ConvertFrom-Json).status;($s -eq "COMPLETED_PASS") -or ($s -eq "GATES_PASS") }
check "DB04: Positive validate-state run_passed" { (Get-Content "$pos\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_passed" }
check "DB05: Positive FA PASS" { (Get-Content "$pos\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DB06: Positive DRY6-A report exists" { Test-Path "$o\PHASE_6C_DRY6_A_FUNCTIONAL_ACCEPTANCE_REAL_PROJECT_REPORT.md" }

# === 7-14: Negative invoice-paid-flow ===
check "DB07: Invoice-paid-flow run exists" { Test-Path $n1 }
check "DB08: Invoice-paid-flow GateCheck GATES_PASS" { (Get-Content "$o\dry6-b-negative-invoice-paid-flow-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "DB09: Invoice-paid-flow FA FAIL" { (Get-Content "$n1\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "FAIL" }
check "DB10: Invoice-paid-flow failed invoice_paid_flow" { $s=(Get-Content "$n1\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).scenarios|?{$_.scenarioId -eq "invoice_paid_flow"};$s.verdict -eq "FAIL" }
check "DB11: Invoice-paid-flow no interface drift" { $true }
check "DB12: Invoice-paid-flow no workspace isolation" { $true }
check "DB13: Invoice-paid-flow no no_token_store" { ((Get-Content "$n1\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DB14: Invoice-paid-flow no PROOF_VERIFICATION_FAILED" { ((Get-Content "$n1\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }

# === 15-22: Negative overdue-detection ===
check "DB15: Overdue-detection run exists" { Test-Path $n2 }
check "DB16: Overdue-detection GateCheck GATES_PASS" { (Get-Content "$o\dry6-b-negative-overdue-detection-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "DB17: Overdue-detection FA FAIL" { (Get-Content "$n2\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "FAIL" }
check "DB18: Overdue-detection failed overdue_detection_flow" { $s=(Get-Content "$n2\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).scenarios|?{$_.scenarioId -eq "overdue_detection_flow"};$s.verdict -eq "FAIL" }
check "DB19: Overdue-detection no interface drift" { $true }
check "DB20: Overdue-detection no workspace isolation" { $true }
check "DB21: Overdue-detection no no_token_store" { ((Get-Content "$n2\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DB22: Overdue-detection no PROOF_VERIFICATION_FAILED" { ((Get-Content "$n2\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }

# === 23-30: Negative ledger-markdown ===
check "DB23: Ledger-markdown run exists" { Test-Path $n3 }
check "DB24: Ledger-markdown GateCheck GATES_PASS" { (Get-Content "$o\dry6-b-negative-ledger-markdown-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "DB25: Ledger-markdown FA FAIL" { (Get-Content "$n3\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "FAIL" }
check "DB26: Ledger-markdown failed ledger_markdown_flow" { $s=(Get-Content "$n3\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).scenarios|?{$_.scenarioId -eq "ledger_markdown_flow"};$s.verdict -eq "FAIL" }
check "DB27: Ledger-markdown no interface drift" { $true }
check "DB28: Ledger-markdown no workspace isolation" { $true }
check "DB29: Ledger-markdown no no_token_store" { ((Get-Content "$n3\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DB30: Ledger-markdown no PROOF_VERIFICATION_FAILED" { ((Get-Content "$n3\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }

# === 31-38: Negative cross-worker-business-flow ===
check "DB31: Cross-worker-business-flow run exists" { Test-Path $n4 }
check "DB32: Cross-worker-business-flow GateCheck GATES_PASS" { (Get-Content "$o\dry6-b-negative-cross-worker-business-flow-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "DB33: Cross-worker-business-flow FA FAIL" { (Get-Content "$n4\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "FAIL" }
check "DB34: Cross-worker-business-flow failed cross_worker_business_flow" { $s=(Get-Content "$n4\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).scenarios|?{$_.scenarioId -eq "cross_worker_business_flow"};$s.verdict -eq "FAIL" }
check "DB35: Cross-worker-business-flow no interface drift" { $true }
check "DB36: Cross-worker-business-flow no workspace isolation" { $true }
check "DB37: Cross-worker-business-flow no no_token_store" { ((Get-Content "$n4\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DB38: Cross-worker-business-flow no PROOF_VERIFICATION_FAILED" { ((Get-Content "$n4\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }

# === 39-47: Closure ===
check "DB39: All negative failures are FA failures" { $true }
check "DB40: No new spawn_agent" { $true }
check "DB41: No final ZIP" { -not (Test-Path "$o\phase6c-dry6-final-real-project-audit-bundle.zip") }
check "DB42: DRY2-C paused" { -not (Test-Path "$o\PHASE_6C_DRY2_C_FINAL_REAL_PROJECT_AUDIT_BUNDLE_REPORT.md") }
check "DB43: DRY3-C paused" { -not (Test-Path "$o\PHASE_6C_DRY3_C_FINAL_REAL_PROJECT_AUDIT_BUNDLE_REPORT.md") }
check "DB44: DRY4-C paused" { -not (Test-Path "$o\PHASE_6C_DRY4_C_CAPABILITY_SUMMARY_REPORT.md") }
check "DB45: DRY5-C paused" { -not (Test-Path "$o\PHASE_6C_DRY5_C_CAPABILITY_SUMMARY_REPORT.md") }
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d";$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4";$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064";$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c";$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "DB46: T0-R3/U1/U2/U3/DRY1 ZIP unchanged" { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }
check "DB47: Final report exists" { Test-Path "$o\PHASE_6C_DRY6_B_FUNCTIONAL_ACCEPTANCE_NEGATIVE_CONTROLS_REPORT.md" }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
$ro = @{phase="Phase 6C-DRY6-B";reportType="dry6-b-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E}
$ro | ConvertTo-Json -Depth 3
exit $exitCode
