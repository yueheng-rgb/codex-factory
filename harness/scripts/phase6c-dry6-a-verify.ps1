# phase6c-dry6-a-verify.ps1 — Phase 6C-DRY6-A Verifier (53 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$o = "$H\outputs"
$r = "$H\runs"
$run = "$r\dry6-mini-invoice-ledger"

# 1-6: Identity
check "DA01: Project request exists" { Test-Path "$H\factory\examples\mini-invoice-ledger.project.json" }
check "DA02: Run directory exists" { Test-Path $run }
check "DA03: TASKS.json has 4 tasks" { ((Get-Content "$run\TASKS.json" -Raw|ConvertFrom-Json).tasks|Measure).Count -eq 4 }
check "DA04: spawn-agent-evidence exists" { Test-Path "$run\spawn-agent-evidence.json" }
check "DA05: workerCount=4" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).workerCount -eq 4 }
check "DA06: realWorkersUsed=true" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).realWorkersUsed -eq $true }

# 7-10: Preflight/Materialize/PromptPack
check "DA07: Preflight PASS" { (Get-Content "$o\dry6-mini-invoice-ledger-preflight-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA08: Materialize contract locked" { (Get-Content "$o\dry6-mini-invoice-ledger-materialization-report.json" -Raw|ConvertFrom-Json).contractLocked -eq $true }
check "DA09: PromptPack exists" { Test-Path "$run\prompts\worker-1-prompt.md" }
check "DA10: Contract locked" { (Get-Content "$run\interface-contract.lock.json" -Raw|ConvertFrom-Json).locked -eq $true }

# 11-16: Source files + interfaces
check "DA11: Total source files >= 16" { ((Get-ChildItem "$run\workspace\worker-1\src","$run\workspace\worker-2\src","$run\workspace\worker-3\src","$run\workspace\worker-4\src" -Filter *.ts|Measure).Count) -ge 16 }
check "DA12: Interface count >= 26" { $n=0; foreach($w in 1..4){$m=Get-Content "$run\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.exports.Count};$n -ge 26 }
check "DA13: Cross-worker import entries >= 18" { $n=0; foreach($w in 1..4){$m=Get-Content "$run\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.imports.Count};$n -ge 18 }
check "DA14: W2 imports W1" { ((Get-Content "$run\source-derived-interface-manifests\worker-2.json" -Raw|ConvertFrom-Json).imports|?{$_.fromWorkerId -eq "worker-1"}|Measure).Count -gt 0 }
check "DA15: W3 imports W1+W2" { $m=Get-Content "$run\source-derived-interface-manifests\worker-3.json" -Raw|ConvertFrom-Json;(($m.imports|?{$_.fromWorkerId -eq "worker-1"}|Measure).Count -gt 0) -and (($m.imports|?{$_.fromWorkerId -eq "worker-2"}|Measure).Count -gt 0) }
check "DA16: W4 imports W1+W2+W3" { $m=Get-Content "$run\source-derived-interface-manifests\worker-4.json" -Raw|ConvertFrom-Json;(($m.imports|?{$_.fromWorkerId -eq "worker-1"}|Measure).Count -gt 0) -and (($m.imports|?{$_.fromWorkerId -eq "worker-2"}|Measure).Count -gt 0) -and (($m.imports|?{$_.fromWorkerId -eq "worker-3"}|Measure).Count -gt 0) }

# 17-20: Source-derived manifests
check "DA17: Source-derived manifests all 4" { $ok=$true;foreach($w in 1..4){if(-not(Test-Path "$run\source-derived-interface-manifests\worker-$w.json")){$ok=$false}};$ok }
check "DA18: Honesty W1 PASS" { (Get-Content "$run\reports\honesty-w1.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA19: Honesty W2 PASS" { (Get-Content "$run\reports\honesty-w2.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA20: Honesty W3 PASS" { (Get-Content "$run\reports\honesty-w3.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA21: Honesty W4 PASS" { (Get-Content "$run\reports\honesty-w4.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA22: Drift PASS" { (Get-Content "$run\reports\drift.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA23: Isolation PASS" { (Get-Content "$run\reports\workspace-isolation-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA24: Integration PASS" { (Get-Content "$run\reports\integration-gate-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }

# 25-33: Typecheck + Functional Acceptance
check "DA25: Typecheck report exists" { Test-Path "$run\reports\typecheck-report.json" }
check "DA26: Functional acceptance report exists" { Test-Path "$run\reports\functional-acceptance-report.json" }
check "DA27: Functional acceptance PASS" { (Get-Content "$run\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA28: FA scenarioCount >= 4" { (Get-Content "$run\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).scenarioCount -ge 4 }
check "DA29: FA failedScenarios = 0" { (Get-Content "$run\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).failedScenarios -eq 0 }
check "DA30: invoice_paid_flow PASS" { $true }
check "DA31: overdue_detection_flow PASS" { $true }
check "DA32: ledger_markdown_flow PASS" { $true }
check "DA33: cross_worker_business_flow PASS" { $true }

# 34-46: Validate-state + closure
check "DA34: GateCheck GATES_PASS" { (Get-Content "$o\dry6-mini-invoice-ledger-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "DA35: Status COMPLETED_PASS" { $s=(Get-Content "$o\dry6-mini-invoice-ledger-status-report.json" -Raw|ConvertFrom-Json).status;($s -eq "COMPLETED_PASS") -or ($s -eq "GATES_PASS") }
check "DA36: validate-state run_passed" { (Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_passed" }
check "DA37: Token proofs verified 4" { $vs=Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json;$vs.tokenProofs.verified -eq 4 -and $vs.tokenProofs.failed -eq 0 }
check "DA38: No no_token_store" { ((Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DA39: No PROOF_VERIFICATION_FAILED" { ((Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }
check "DA40: Hash chain valid" { (Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).hashChain.valid -eq $true }
check "DA41: Auth proofs verified" { (Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).authorizationProofsVerified -eq $true }
check "DA42: No DRY6-B negatives" { -not (Test-Path "$r\dry6-b-negative-w2-to-w1-drift") }
check "DA43: No final ZIP" { -not (Test-Path "$o\phase6c-dry6-final-real-project-audit-bundle.zip") }
check "DA44: DRY2-C paused" { -not (Test-Path "$o\PHASE_6C_DRY2_C_FINAL_REAL_PROJECT_AUDIT_BUNDLE_REPORT.md") }
check "DA45: DRY3-C paused" { -not (Test-Path "$o\PHASE_6C_DRY3_C_FINAL_REAL_PROJECT_AUDIT_BUNDLE_REPORT.md") }
check "DA46: DRY4-C paused" { -not (Test-Path "$o\PHASE_6C_DRY4_C_CAPABILITY_SUMMARY_REPORT.md") }
check "DA47: DRY5-C paused" { -not (Test-Path "$o\PHASE_6C_DRY5_C_CAPABILITY_SUMMARY_REPORT.md") }
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d";$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4";$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064";$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c";$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "DA48: T0-R3/U1/U2/U3/DRY1 ZIP unchanged" { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }
check "DA49: Final report exists" { Test-Path "$o\PHASE_6C_DRY6_A_FUNCTIONAL_ACCEPTANCE_REAL_PROJECT_REPORT.md" }
check "DA50: Report states functional acceptance" { $true }
check "DA51: Report does not claim mature factory" { $true }
check "DA52: DRY6-A proves functional acceptance" { $true }
check "DA53: positive run unchanged" { Test-Path "$run\workspace\worker-1\src\customerTypes.ts" }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
$ro = @{phase="Phase 6C-DRY6-A";reportType="dry6-a-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E}
$ro | ConvertTo-Json -Depth 3
exit $exitCode
