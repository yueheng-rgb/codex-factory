# phase6c-dry7-a-verify.ps1 — Phase 6C-DRY7-A Verifier
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$o = "$H\outputs"
$r = "$H\runs"
$run = "$r\dry7-mini-booking-engine"

# 1-3: Identity
check "DR7-01: Project request exists" { Test-Path "$H\factory\examples\mini-booking-engine.project.json" }
check "DR7-02: Run directory exists" { Test-Path $run }
check "DR7-03: Node.js available" { try { node --version | Out-Null; $true } catch { $false } }

# 4-6: Spawn evidence
check "DR7-04: spawn-agent-evidence exists" { Test-Path "$run\spawn-agent-evidence.json" }
check "DR7-05: workerCount=4" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).workerCount -eq 4 }
check "DR7-06: realWorkersUsed=true" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).realWorkersUsed -eq $true }

# 7-10: Source files
check "DR7-07: Total JS source files >= 16" { $n=0; foreach($w in 1..4){$n+=(Get-ChildItem "$run\workspace\worker-$w\src" -Filter *.js|Measure).Count};$n -ge 16 }
check "DR7-08: Export count >= 24" { $n=0; foreach($w in 1..4){$m=Get-Content "$run\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.exports.Count};$n -ge 24 }
check "DR7-09: Cross-worker dep entries >= 16" { $n=0; foreach($w in 1..4){$m=Get-Content "$run\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.imports.Count};$n -ge 16 }

# 11-14: Source-derived manifests
check "DR7-10: Source-derived manifests exist for all 4" { $ok=$true;foreach($w in 1..4){if(-not(Test-Path "$run\source-derived-interface-manifests\worker-$w.json")){$ok=$false}};$ok }
check "DR7-11: Manifest honesty W1 PASS" { (Get-Content "$run\reports\honesty-w1.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DR7-12: Manifest honesty W2 PASS" { (Get-Content "$run\reports\honesty-w2.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DR7-13: Manifest honesty W3 PASS" { (Get-Content "$run\reports\honesty-w3.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DR7-14: Manifest honesty W4 PASS" { (Get-Content "$run\reports\honesty-w4.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }

# 15-17: Gates
check "DR7-15: Interface drift PASS" { (Get-Content "$run\reports\drift.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DR7-16: Workspace isolation PASS" { (Get-Content "$run\reports\workspace-isolation-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DR7-17: Integration gate PASS" { (Get-Content "$run\reports\integration-gate-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }

# 18-22: Functional acceptance
check "DR7-18: Functional acceptance report exists" { Test-Path "$run\reports\functional-acceptance-report.json" }
check "DR7-19: Functional acceptance PASS" { (Get-Content "$run\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DR7-20: FA scenarioCount >= 4" { (Get-Content "$run\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).scenarioCount -ge 4 }
check "DR7-21: FA failedScenarios = 0" { (Get-Content "$run\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).failedScenarios -eq 0 }

# 23-28: Runtime acceptance
check "DR7-22: Runtime acceptance report exists" { Test-Path "$run\reports\runtime-acceptance-report.json" }
check "DR7-23: Runtime acceptance PASS" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DR7-24: runtimeExecuted=true" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).runtimeExecuted -eq $true }
check "DR7-25: Runtime exitCode=0" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).exitCode -eq 0 }
check "DR7-26: Runtime scenarioCount >= 4" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).scenarioCount -ge 4 }
check "DR7-27: Runtime failedScenarios=0" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).failedScenarios -eq 0 }

# 29-32: Scenario-level checks
check "DR7-28: booking_creation_runtime PASS" { ((Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).results | ?{$_.name -eq "booking_creation_runtime"}).passed -eq $true }
check "DR7-29: booking_cancellation_runtime PASS" { ((Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).results | ?{$_.name -eq "booking_cancellation_runtime"}).passed -eq $true }
check "DR7-30: conflict_detection_runtime PASS" { ((Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).results | ?{$_.name -eq "conflict_detection_runtime"}).passed -eq $true }
check "DR7-31: report_generation_runtime PASS" { ((Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).results | ?{$_.name -eq "report_generation_runtime"}).passed -eq $true }

# 33-35: GateCheck and Status
check "DR7-32: GateCheck GATES_PASS" { (Get-Content "$o\dry7-mini-booking-engine-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "DR7-33: Status COMPLETED_PASS" { $s=(Get-Content "$o\dry7-mini-booking-engine-status-report.json" -Raw|ConvertFrom-Json).status;($s -eq "COMPLETED_PASS") -or ($s -eq "GATES_PASS") }
check "DR7-34: validate-state run_passed" { (Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_passed" }

# 36-40: Token + hash
check "DR7-35: Token proofs verified for 4" { $vs=Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json;$vs.tokenProofs.verified -eq 4 -and $vs.tokenProofs.failed -eq 0 }
check "DR7-36: No no_token_store" { ((Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DR7-37: No PROOF_VERIFICATION_FAILED" { ((Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }
check "DR7-38: Hash chain valid" { (Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).hashChain.valid -eq $true }
check "DR7-39: Auth proofs verified" { (Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).authorizationProofsVerified -eq $true }

# 41-44: Negatives
check "DR7-40: No DRY7-B negatives" { -not (Test-Path "$r\dry7-b-negative-*") }
check "DR7-41: No final ZIP" { -not (Test-Path "$o\phase6c-dry7-a-*.zip") -and -not (Test-Path "$o\phase6c-dry7-final-*.zip") }
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d";$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4";$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064";$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c";$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "DR7-42: T0-R3/U1/U2/U3/DRY1 ZIP unchanged" { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }
check "DR7-43: DRY2/3/4/5/6-C paused" { -not (Test-Path "$o\PHASE_6C_DRY2_C_FINAL_REAL_PROJECT_AUDIT_BUNDLE_REPORT.md") -and -not (Test-Path "$o\PHASE_6C_DRY3_C_FINAL_REAL_PROJECT_AUDIT_BUNDLE_REPORT.md") -and -not (Test-Path "$o\PHASE_6C_DRY4_C_CAPABILITY_SUMMARY_REPORT.md") -and -not (Test-Path "$o\PHASE_6C_DRY5_C_CAPABILITY_SUMMARY_REPORT.md") -and -not (Test-Path "$o\PHASE_6C_DRY6_C_*") }

# 45: Final report
check "DR7-44: Final report exists" { Test-Path "$o\PHASE_6C_DRY7_A_RUNTIME_EXECUTION_REAL_PROJECT_REPORT.md" }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
$ro = @{phase="Phase 6C-DRY7-A";reportType="dry7-a-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E}
$ro | ConvertTo-Json -Depth 3
exit $exitCode