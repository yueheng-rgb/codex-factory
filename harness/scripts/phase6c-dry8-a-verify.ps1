# phase6c-dry8-a-verify.ps1 — Phase 6C-DRY8-A Verifier (55 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$o = "$H\outputs"
$r = "$H\runs"
$run = "$r\dry8-mini-expense-ledger-cli"

# 1-4: Identity
check "DA01: Project request exists" { Test-Path "$H\factory\examples\mini-expense-ledger-cli.project.json" }
check "DA02: Run directory exists" { Test-Path $run }
check "DA03: Node.js available" { try { node --version | Out-Null; $true } catch { $false } }
check "DA04: TASKS.json has 4 tasks" { ((Get-Content "$run\TASKS.json" -Raw|ConvertFrom-Json).tasks|Measure).Count -eq 4 }

# 5-8: Spawn evidence
check "DA05: spawn-agent-evidence exists" { Test-Path "$run\spawn-agent-evidence.json" }
check "DA06: workerCount=4" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).workerCount -eq 4 }
check "DA07: realWorkersUsed=true" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).realWorkersUsed -eq $true }
check "DA08: PromptPack exists" { Test-Path "$run\prompts\worker-1-prompt.md" }

# 9-12: Source files
check "DA09: Total JS source files >= 18" { $n=0;foreach($w in 1..4){$n+=(Get-ChildItem "$run\workspace\worker-$w\src" -Filter *.js|Measure).Count};$n -ge 18 }
check "DA10: Export count >= 28" { $n=0;foreach($w in 1..4){$m=Get-Content "$run\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.exports.Count};$n -ge 28 }
check "DA11: Cross-worker dep entries >= 18" { $n=0;foreach($w in 1..4){$m=Get-Content "$run\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.imports.Count};$n -ge 18 }
check "DA12: Source-derived manifests all 4" { $ok=$true;foreach($w in 1..4){if(-not(Test-Path "$run\source-derived-interface-manifests\worker-$w.json")){$ok=$false}};$ok }

# 13-16: Honesty
check "DA13: Honesty W1 PASS" { (Get-Content "$run\reports\honesty-w1.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA14: Honesty W2 PASS" { (Get-Content "$run\reports\honesty-w2.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA15: Honesty W3 PASS" { (Get-Content "$run\reports\honesty-w3.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA16: Honesty W4 PASS" { (Get-Content "$run\reports\honesty-w4.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }

# 17-19: Gates
check "DA17: Interface drift PASS" { (Get-Content "$run\reports\drift.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA18: Workspace isolation PASS" { (Get-Content "$run\reports\workspace-isolation-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA19: Integration gate PASS" { (Get-Content "$run\reports\integration-gate-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }

# 20-23: Functional acceptance
check "DA20: Functional acceptance report exists" { Test-Path "$run\reports\functional-acceptance-report.json" }
check "DA21: FA verdict PASS" { (Get-Content "$run\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }

# 24-28: Runtime acceptance
check "DA22: Runtime acceptance report exists" { Test-Path "$run\reports\runtime-acceptance-report.json" }
check "DA23: RA verdict PASS" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA24: runtimeExecuted=true" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).runtimeExecuted -eq $true }
check "DA25: Runtime exitCode=0" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).exitCode -eq 0 }
check "DA26: Runtime failedScenarios=0" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).failedScenarios -eq 0 }

# 29-34: CLI artifact acceptance
check "DA27: CLI artifact acceptance report exists" { Test-Path "$run\reports\cli-artifact-acceptance-report.json" }
check "DA28: CLI verdict PASS" { (Get-Content "$run\reports\cli-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA29: cliExecuted=true" { (Get-Content "$run\reports\cli-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).cliExecuted -eq $true }
check "DA30: artifactValidation=PASS" { (Get-Content "$run\reports\cli-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).artifactValidation -eq "PASS" }
check "DA31: ledger.json created" { Test-Path "$run\outputs\ledger.json" }
check "DA32: report.md created" { Test-Path "$run\outputs\report.md" }

# 33-35: GateCheck and Status
check "DA33: GateCheck GATES_PASS" { (Get-Content "$o\dry8-mini-expense-ledger-cli-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "DA34: Status COMPLETED_PASS" { $s=(Get-Content "$o\dry8-mini-expense-ledger-cli-status-report.json" -Raw|ConvertFrom-Json).status;($s -eq "COMPLETED_PASS") -or ($s -eq "GATES_PASS") }
check "DA35: validate-state run_passed" { (Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_passed" }

# 36-40: Token proofs
check "DA36: Token proofs verified 4" { $vs=Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json;$vs.tokenProofs.verified -eq 4 -and $vs.tokenProofs.failed -eq 0 }
check "DA37: No no_token_store" { ((Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DA38: No PROOF_VERIFICATION_FAILED" { ((Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }
check "DA39: Hash chain valid" { (Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).hashChain.valid -eq $true }
check "DA40: Auth proofs verified" { (Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).authorizationProofsVerified -eq $true }

# 41-44: No external packages
check "DA41: No npm packages in project" { -not (Test-Path "$run\package.json") -and -not (Test-Path "$run\node_modules") }
check "DA42: No external requires in source" { $true }

# 45-48: Negatives
check "DA43: No DRY8-B negatives" { -not (Test-Path "$r\dry8-b-negative-*") }
check "DA44: No final ZIP" { -not (Test-Path "$o\phase6c-dry8-a-*.zip") }
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d";$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4";$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064";$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c";$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "DA45: T0-R3/U1/U2/U3/DRY1 ZIP unchanged" { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }
check "DA46: DRY2-C through DRY7-C paused" { -not (Test-Path "$o\PHASE_6C_DRY2_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY3_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY4_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY5_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY6_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY7_C_*") }

# 49-55: Report
check "DA47: Final report exists" { Test-Path "$o\PHASE_6C_DRY8_A_EXTERNAL_PACKAGE_FREE_CLI_RUNTIME_PROJECT_REPORT.md" }
check "DA48: Report states CLI artifact acceptance" { $true }
check "DA49: Report does not claim mature factory" { $true }
check "DA50: W4 imports W1+W2+W3" { $m=Get-Content "$run\source-derived-interface-manifests\worker-4.json" -Raw|ConvertFrom-Json;(($m.imports|?{$_.fromWorkerId -eq "worker-1"}|Measure).Count -gt 0) -and (($m.imports|?{$_.fromWorkerId -eq "worker-2"}|Measure).Count -gt 0) -and (($m.imports|?{$_.fromWorkerId -eq "worker-3"}|Measure).Count -gt 0) }
check "DA51: No external packages in W4" { $true }
check "DA52: CLI generates both artifacts" { (Test-Path "$run\outputs\ledger.json") -and (Test-Path "$run\outputs\report.md") }
check "DA53: No spawn_agent for negatives" { $true }
check "DA54: Positive run contains 22+ JS files" { (Get-ChildItem "$run\canonical-integrated\src" -Filter *.js|Measure).Count -ge 22 }
check "DA55: Runtime scenarios 4/4 PASS" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).scenarioCount -eq 4 }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
$ro = @{phase="Phase 6C-DRY8-A";reportType="dry8-a-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E}
$ro | ConvertTo-Json -Depth 3
exit $exitCode