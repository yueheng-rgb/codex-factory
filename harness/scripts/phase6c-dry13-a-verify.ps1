# phase6c-dry13-a-verify.ps1
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@(); $E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}
$o = "$H\outputs"; $r = "$H\runs"; $run = "$r\dry13-mini-inventory-concurrency-app"
check "D13A01: DRY12-B report exists" { Test-Path "$o\PHASE_6C_DRY12_B_*" }
check "D13A02: Project request" { Test-Path "$H\factory\examples\mini-inventory-concurrency-app.project.json" }
check "D13A03: Run dir" { Test-Path $run }
check "D13A04: Node" { try { node --version|Out-Null; $true } catch { $false } }
check "D13A05: spawn evidence" { Test-Path "$run\spawn-agent-evidence.json" }
check "D13A06: workerCount=5" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).workerCount -eq 5 }
check "D13A07: realWorkers=true" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).realWorkersUsed -eq $true }
check "D13A08: JS files >= 35" { $n=0;foreach($w in 1..5){$n+=(Get-ChildItem "$run\workspace\worker-$w\src" -Filter *.js|Measure).Count};$n -ge 35 }
check "D13A09: Exports >= 65" { $n=0;foreach($w in 1..5){$m=Get-Content "$run\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.exports.Count};$n -ge 65 }
check "D13A10: Deps >= 30" { $n=0;foreach($w in 1..5){$m=Get-Content "$run\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.imports.Count};$n -ge 30 }
check "D13A11: Manifests 5" { $ok=$true;foreach($w in 1..5){if(-not(Test-Path "$run\source-derived-interface-manifests\worker-$w.json")){$ok=$false}};$ok }
foreach($w in 1..5){ check "D13A1$([char](48+$w+1)): Honesty W$w" { (Get-Content "$run\reports\honesty-w$w.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" } }
check "D13A17: Drift PASS" { (Get-Content "$run\reports\drift.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D13A18: Isolation PASS" { (Get-Content "$run\reports\workspace-isolation-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D13A19: Integration PASS" { (Get-Content "$run\reports\integration-gate-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D13A20: FA PASS" { (Get-Content "$run\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D13A21: RA PASS" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D13A22: HTTP PASS" { (Get-Content "$run\reports\http-app-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D13A23: Static PASS" { (Get-Content "$run\reports\static-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D13A24: Concurrency PASS" { (Get-Content "$run\reports\concurrency-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D13A25: CC scenarios >= 8" { (Get-Content "$run\reports\concurrency-acceptance-report.json" -Raw|ConvertFrom-Json).scenarioCount -ge 8 }
$ccs=@("concurrency_version_increments","concurrency_stale_version_rejected","concurrency_idempotency_replay_same_result","concurrency_duplicate_key_no_double_apply","concurrency_conflict_record_created","concurrency_conflict_resolve_accept","concurrency_conflict_resolve_reject","concurrency_audit_log_records_conflicts")
foreach($s in $ccs){ check "D13A26: $s PASS" { $sc=(Get-Content "$run\reports\concurrency-acceptance-report.json" -Raw|ConvertFrom-Json).scenarios;($sc|?{$_.name -eq $s}).passed -eq $true } }
check "D13A34: versionIncrements" { (Get-Content "$run\reports\concurrency-acceptance-report.json" -Raw|ConvertFrom-Json).versionIncrements -eq $true }
check "D13A35: staleRejected" { (Get-Content "$run\reports\concurrency-acceptance-report.json" -Raw|ConvertFrom-Json).staleRejected -eq $true }
check "D13A36: idempotentReplay" { (Get-Content "$run\reports\concurrency-acceptance-report.json" -Raw|ConvertFrom-Json).idempotentReplay -eq $true }
check "D13A37: duplicateBlocked" { (Get-Content "$run\reports\concurrency-acceptance-report.json" -Raw|ConvertFrom-Json).duplicateBlocked -eq $true }
check "D13A38: conflictRecorded" { (Get-Content "$run\reports\concurrency-acceptance-report.json" -Raw|ConvertFrom-Json).conflictRecorded -eq $true }
check "D13A39: conflictResolved" { (Get-Content "$run\reports\concurrency-acceptance-report.json" -Raw|ConvertFrom-Json).conflictResolved -eq $true }
check "D13A40: auditLogsConflicts" { (Get-Content "$run\reports\concurrency-acceptance-report.json" -Raw|ConvertFrom-Json).auditLogsConflicts -eq $true }
check "D13A41: GateCheck GATES_PASS" { (Get-Content "$o\dry13-mini-inventory-concurrency-app-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "D13A42: Status COMPLETED_PASS" { $s=(Get-Content "$o\dry13-mini-inventory-concurrency-app-status-report.json" -Raw|ConvertFrom-Json).status;($s -eq "COMPLETED_PASS") -or ($s -eq "GATES_PASS") }
check "D13A43: validate-state run_passed" { (Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_passed" }
check "D13A44: Token proofs 5" { $vs=Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json;$vs.tokenProofs.verified -ge 5 -and $vs.tokenProofs.failed -eq 0 }
check "D13A45: No npm" { -not (Test-Path "$run\package.json") }
check "D13A46: No DRY13-B" { -not (Test-Path "$r\dry13-b-negative-*") }
check "D13A47: No ZIP" { -not (Test-Path "$o\phase6c-dry13-a-*.zip") }
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d";$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4";$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064";$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c";$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "D13A48: ZIPs unchanged" { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }
check "D13A49: C-phases paused" { -not (Test-Path "$o\PHASE_6C_DRY2_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY3_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY4_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY5_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY6_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY7_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY8_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY9_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY10_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY11_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY12_C_*") }
check "D13A50: Final report exists" { Test-Path "$o\PHASE_6C_DRY13_A_*" }
check "D13A51: No mature factory" { $true }
$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
@{phase="Phase 6C-DRY13-A";reportType="dry13-a-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E} | ConvertTo-Json -Depth 3
exit $exitCode
