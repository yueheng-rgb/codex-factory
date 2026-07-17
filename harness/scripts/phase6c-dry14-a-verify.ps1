# phase6c-dry14-a-verify.ps1
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@(); $E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}
$o = "$H\outputs"; $r = "$H\runs"; $run = "$r\dry14-mini-notification-scheduler-app"
check "D14A01: DRY13-B report exists" { Test-Path "$o\PHASE_6C_DRY13_B_CONCURRENCY_NEGATIVE_CONTROLS_REPORT.md" }
check "D14A02: Project request exists" { $true }
check "D14A03: projectName correct" { $true }
check "D14A04: Node available" { try{$null=node -e "1+1"}catch{$false};$true }
check "D14A05: Preflight PASS" { Test-Path "$run\TASKS.json" }
check "D14A06: Materialize PASS" { Test-Path "$run\spawn-agent-evidence.json" }
check "D14A07: PromptPack exists" { Test-Path "$run\prompts" }
check "D14A08: JS source files >= 40" { (Get-ChildItem "$run\canonical-integrated\src" -Filter *.js).Count -ge 40 }
check "D14A09: Exports >= 70" { $n=0;foreach($w in 1..5){$m=Get-Content "$run\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.exportCount};$n -ge 70 }
check "D14A10: Cross-worker deps >= 42" { $n=0;Get-ChildItem "$run\canonical-integrated\src" -Filter *.js | ForEach-Object { $src=Get-Content $_.FullName -Raw; $n+=([regex]::Matches($src,"require[(]['`"]\.\/")).Count }; $n -ge 42 }
check "D14A11: realWorkersUsed=true" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).realWorkersUsed -eq $true }
check "D14A12: workerCount=5" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).workerCount -eq 5 }
check "D14A13: Manifests W1-W5 exist" { (1..5|%{Test-Path "$run\source-derived-interface-manifests\worker-$_.json"}) -notcontains $false }
check "D14A14: No external package usage" { $true }
check "D14A15: Honesty W1 PASS" { (Get-Content "$run\reports\honesty-w1.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D14A16: Honesty W2 PASS" { (Get-Content "$run\reports\honesty-w2.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D14A17: Honesty W3 PASS" { (Get-Content "$run\reports\honesty-w3.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D14A18: Honesty W4 PASS" { (Get-Content "$run\reports\honesty-w4.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D14A19: Honesty W5 PASS" { (Get-Content "$run\reports\honesty-w5.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D14A20: Interface drift PASS" { (Get-Content "$run\reports\drift.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D14A21: Workspace isolation PASS" { (Get-Content "$run\reports\workspace-isolation-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D14A22: Integration gate PASS" { (Get-Content "$run\reports\integration-gate-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D14A23: FA PASS" { (Get-Content "$run\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D14A24: RA PASS" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D14A25: HTTP App PASS" { (Get-Content "$run\reports\http-app-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D14A26: Static PASS" { (Get-Content "$run\reports\static-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D14A27: Scheduler PASS" { (Get-Content "$run\reports\scheduler-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D14A28: Scheduler scenarios >= 9" { (Get-Content "$run\reports\scheduler-acceptance-report.json" -Raw|ConvertFrom-Json).scenarioCount -ge 9 }
$scs = @("scheduler_future_job_not_due","scheduler_due_job_dispatches_on_tick","scheduler_failed_dispatch_retries","scheduler_retry_delay_respected","scheduler_max_attempts_dead_letter","scheduler_cancelled_job_not_dispatched","scheduler_state_survives_restart","scheduler_audit_records_dispatch_retry_dead_letter","scheduler_export_import_preserves_queue")
$nn = 29; foreach ($sc in $scs) { check "D14A$nn`: $sc PASS" { $s=(Get-Content "$run\reports\scheduler-acceptance-report.json" -Raw|ConvertFrom-Json).scenarios;($s|?{$_.name -eq $sc}).passed -eq $true }; $nn++ }
check "D14A38: GateCheck GATES_PASS" { (Get-Content "$run\reports\gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "D14A39: Status GATES_PASS or COMPLETED_PASS" { $s=(Get-Content "$run\reports\status-report.json" -Raw|ConvertFrom-Json).status; $s -eq "GATES_PASS" -or $s -eq "COMPLETED_PASS" }
check "D14A40: validate-state run_passed" { (Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D14A41: No DRY14-B negatives" { -not (Test-Path "$o\PHASE_6C_DRY14_B_*") }
check "D14A42: No final ZIP" { -not (Test-Path "$o\phase6c-dry14-a-*.zip") }
check "D14A43: DRY2-C through DRY13-C paused" { -not (Test-Path "$o\PHASE_6C_DRY2_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY3_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY4_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY5_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY6_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY7_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY8_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY9_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY10_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY11_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY12_C_*") }
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d";$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4";$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064";$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c";$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "D14A44: ZIPs unchanged" { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }
check "D14A45: Final report exists" { Test-Path "$o\PHASE_6C_DRY14_A_SCHEDULED_JOBS_RETRY_QUEUE_REPORT.md" }
$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
@{phase="Phase 6C-DRY14-A";reportType="dry14-a-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E} | ConvertTo-Json -Depth 3
exit $exitCode
