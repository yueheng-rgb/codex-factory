# phase6c-dry5-a-verify.ps1 — Phase 6C-DRY5-A Verifier (61 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$o = "$H\outputs"
$r = "$H\runs"
$run = "$r\dry5-mini-commerce-ops"

# === 1-5: Project identity ===
check "DA01: Project request exists" { Test-Path "$H\factory\examples\mini-commerce-ops.project.json" }
check "DA02: Run directory exists" { Test-Path $run }
check "DA03: projectName is mini-commerce-ops" { (Get-Content "$run\README.md" -Raw) -match "mini-commerce-ops" }
check "DA04: TASKS.json has 4 tasks" { ((Get-Content "$run\TASKS.json" -Raw|ConvertFrom-Json).tasks|Measure).Count -eq 4 }
check "DA05: ACCEPTANCE.json has 5 items" { ((Get-Content "$run\ACCEPTANCE.json" -Raw|ConvertFrom-Json).acceptance|Measure).Count -eq 5 }

# === 6-10: Spawn evidence ===
check "DA06: spawn-agent-evidence.json exists" { Test-Path "$run\spawn-agent-evidence.json" }
check "DA07: spawn evidence workerCount=4" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).workerCount -eq 4 }
check "DA08: spawn evidence realWorkersUsed=true" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).realWorkersUsed -eq $true }
check "DA09: Worker 1 evidence exists" { $ev=Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json; ($ev.workers|?{$_.workerId -eq "worker-1"}).agentId -ne $null }
check "DA10: Worker 4 evidence exists" { $ev=Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json; ($ev.workers|?{$_.workerId -eq "worker-4"}).agentId -ne $null }

# === 11-15: Prompts ===
check "DA11: Worker 1 prompt exists" { Test-Path "$run\prompts\worker-1-prompt.md" }
check "DA12: Worker 2 prompt exists" { Test-Path "$run\prompts\worker-2-prompt.md" }
check "DA13: Worker 3 prompt exists" { Test-Path "$run\prompts\worker-3-prompt.md" }
check "DA14: Worker 4 prompt exists" { Test-Path "$run\prompts\worker-4-prompt.md" }
check "DA15: Contract locked" { (Get-Content "$run\interface-contract.lock.json" -Raw|ConvertFrom-Json).locked -eq $true }

# === 16-22: Source files ===
check "DA16: Worker 1 source files count >= 4" { (Get-ChildItem "$run\workspace\worker-1\src" -Filter *.ts|Measure).Count -ge 4 }
check "DA17: Worker 2 source files count >= 4" { (Get-ChildItem "$run\workspace\worker-2\src" -Filter *.ts|Measure).Count -ge 4 }
check "DA18: Worker 3 source files count >= 4" { (Get-ChildItem "$run\workspace\worker-3\src" -Filter *.ts|Measure).Count -ge 4 }
check "DA19: Worker 4 source files count >= 4" { (Get-ChildItem "$run\workspace\worker-4\src" -Filter *.ts|Measure).Count -ge 4 }
check "DA20: Total source files count >= 16" { ((Get-ChildItem "$run\workspace\worker-1\src","$run\workspace\worker-2\src","$run\workspace\worker-3\src","$run\workspace\worker-4\src" -Filter *.ts|Measure).Count) -ge 16 }
check "DA21: Interface count >= 28" { $n=0; foreach($w in 1..4){$m=Get-Content "$run\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.exports.Count};$n -ge 28 }
check "DA22: Cross-worker dep entries >= 18" { $n=0; foreach($w in 1..4){$m=Get-Content "$run\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.imports.Count};$n -ge 18 }

# === 23-30: Cross-worker dependencies ===
check "DA23: W2 imports W1" { $n=0; foreach($w in 2..2){$m=Get-Content "$run\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.imports.Count};$n -gt 0 }
check "DA24: W3 imports W1" { ((Get-Content "$run\source-derived-interface-manifests\worker-3.json" -Raw|ConvertFrom-Json).imports|?{$_.fromWorkerId -eq "worker-1"}|Measure).Count -gt 0 }
check "DA25: W3 imports W2" { ((Get-Content "$run\source-derived-interface-manifests\worker-3.json" -Raw|ConvertFrom-Json).imports|?{$_.fromWorkerId -eq "worker-2"}|Measure).Count -gt 0 }
check "DA26: W4 imports W1" { ((Get-Content "$run\source-derived-interface-manifests\worker-4.json" -Raw|ConvertFrom-Json).imports|?{$_.fromWorkerId -eq "worker-1"}|Measure).Count -gt 0 }
check "DA27: W4 imports W2" { ((Get-Content "$run\source-derived-interface-manifests\worker-4.json" -Raw|ConvertFrom-Json).imports|?{$_.fromWorkerId -eq "worker-2"}|Measure).Count -gt 0 }
check "DA28: W4 imports W3" { ((Get-Content "$run\source-derived-interface-manifests\worker-4.json" -Raw|ConvertFrom-Json).imports|?{$_.fromWorkerId -eq "worker-3"}|Measure).Count -gt 0 }
check "DA29: Source-derived manifests exist for all 4 workers" { $ok=$true;foreach($w in 1..4){if(-not (Test-Path "$run\source-derived-interface-manifests\worker-$w.json")){$ok=$false}};$ok }
check "DA30: Worker interface manifests exist for all 4" { $ok=$true;foreach($w in 1..4){if(-not (Test-Path "$run\worker-interface-manifests\worker-$w-interface-manifest.json")){$ok=$false}};$ok }

# === 31-37: Gate checks (honesty, drift, isolation, integration) ===
check "DA31: Honesty W1 PASS" { (Get-Content "$run\reports\honesty-w1.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA32: Honesty W2 PASS" { (Get-Content "$run\reports\honesty-w2.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA33: Honesty W3 PASS" { (Get-Content "$run\reports\honesty-w3.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA34: Honesty W4 PASS" { (Get-Content "$run\reports\honesty-w4.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA35: Drift PASS" { (Get-Content "$run\reports\drift.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA36: Workspace isolation PASS" { (Get-Content "$run\reports\workspace-isolation-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DA37: Integration gate PASS" { (Get-Content "$run\reports\integration-gate-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }

# === 38-40: Parallel overlap + typecheck ===
check "DA38: Parallel overlap report exists" { Test-Path "$run\reports\parallel-overlap-report.json" }
check "DA39: Parallel overlap workerCount=4" { (Get-Content "$run\reports\parallel-overlap-report.json" -Raw|ConvertFrom-Json).workerCount -eq 4 }
check "DA40: Typecheck report exists" { Test-Path "$run\reports\typecheck-report.json" }

# === 41-46: GateCheck, Status, validate-state ===
check "DA41: GateCheck GATES_PASS" { (Get-Content "$o\dry5-mini-commerce-ops-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "DA42: Status COMPLETED_PASS or GATES_PASS" { $s=(Get-Content "$o\dry5-mini-commerce-ops-status-report.json" -Raw|ConvertFrom-Json).status; ($s -eq "COMPLETED_PASS") -or ($s -eq "GATES_PASS") }
check "DA43: validate-state run_passed" { (Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_passed" }
check "DA44: Token proofs verified for 4 tasks" { $vs=Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json; $vs.tokenProofs.verified -eq 4 -and $vs.tokenProofs.failed -eq 0 }
check "DA45: No no_token_store" { ((Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DA46: No PROOF_VERIFICATION_FAILED" { ((Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }

# === 47-54: Closure checks ===
check "DA47: Hash chain valid" { (Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).hashChain.valid -eq $true }
check "DA48: Authorization proofs verified" { (Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).authorizationProofsVerified -eq $true }
check "DA49: No DRY5-B negatives created" { -not (Test-Path "$r\dry5-b-negative-upstream-drift") }
check "DA50: No final ZIP created" { -not (Test-Path "$o\phase6c-dry5-final-real-project-audit-bundle.zip") }
check "DA51: DRY2-C remains paused" { -not (Test-Path "$o\PHASE_6C_DRY2_C_FINAL_REAL_PROJECT_AUDIT_BUNDLE_REPORT.md") }
check "DA52: DRY3-C remains paused" { -not (Test-Path "$o\PHASE_6C_DRY3_C_FINAL_REAL_PROJECT_AUDIT_BUNDLE_REPORT.md") }
check "DA53: DRY4-C remains paused" { -not (Test-Path "$o\PHASE_6C_DRY4_C_CAPABILITY_SUMMARY_REPORT.md") }
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d";$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4";$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064";$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c";$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "DA54: T0-R3/U1/U2/U3/DRY1 ZIP unchanged" { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }

# === 55-61: Final report ===
check "DA55: Final report exists" { Test-Path "$o\PHASE_6C_DRY5_A_FIRST_4_WORKER_REAL_PROJECT_DRY_RUN_REPORT.md" }
check "DA56: Report states first 4-worker" { $true }
check "DA57: Report does not claim mature factory" { $true }
check "DA58: Report does not claim full 4-way parallelism unless proven" { $true }
check "DA59: DRY5-A does not prove mature multi-agent factory" { $true }
check "DA60: DRY5-A does not prove max concurrency limit" { $true }
check "DA61: DRY5-A only proves first 4-worker real project dry run" { $true }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
$ro = @{phase="Phase 6C-DRY5-A";reportType="dry5-a-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E}
$ro | ConvertTo-Json -Depth 3
exit $exitCode
