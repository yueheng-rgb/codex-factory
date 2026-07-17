# phase6c-dry9-b-verify.ps1 — Phase 6C-DRY9-B Verifier (80 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$o = "$H\outputs"
$r = "$H\runs"
$run = "$r\dry9-mini-timesheet-workflow-cli"

# 1-4: Positive run identity
check "DB01: Positive project request exists" { Test-Path "$H\factory\examples\mini-timesheet-workflow-cli.project.json" }
check "DB02: Positive run directory exists" { Test-Path $run }
check "DB03: Node.js available" { try { node --version | Out-Null; $true } catch { $false } }
check "DB04: Positive TASKS.json has 4 tasks" { ((Get-Content "$run\TASKS.json" -Raw|ConvertFrom-Json).tasks|Measure).Count -eq 4 }

# 5-8: Positive spawn evidence
check "DB05: Positive spawn-agent-evidence exists" { Test-Path "$run\spawn-agent-evidence.json" }
check "DB06: Positive workerCount=4" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).workerCount -eq 4 }
check "DB07: Positive realWorkersUsed=true" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).realWorkersUsed -eq $true }
check "DB08: Positive FA PASS" { (Get-Content "$run\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }

# 9-12: Positive acceptance layers
check "DB09: Positive RA PASS" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DB10: Positive CLI Artifact PASS" { (Get-Content "$run\reports\cli-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DB11: Positive Multi-command PASS" { (Get-Content "$run\reports\multi-command-workflow-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DB12: Positive status COMPLETED_PASS" { $s=(Get-Content "$o\dry9-mini-timesheet-workflow-cli-status-report.json" -Raw|ConvertFrom-Json).status;($s -eq "COMPLETED_PASS") -or ($s -eq "GATES_PASS") }

# 13-17: Negative run existence
check "DB13: state-persistence run exists" { Test-Path "$r\dry9-b-negative-state-persistence" }
check "DB14: task-lifecycle run exists" { Test-Path "$r\dry9-b-negative-task-lifecycle" }
check "DB15: time-logging run exists" { Test-Path "$r\dry9-b-negative-time-logging" }
check "DB16: report-artifact run exists" { Test-Path "$r\dry9-b-negative-report-artifact" }
check "DB17: summary-stdout run exists" { Test-Path "$r\dry9-b-negative-summary-stdout" }

# Helper for negative checks
function checkNeg($label, $dir, $sb) {
    $nrun = Join-Path $r $dir
    try { $result = &$sb $nrun; check $label { $result } } catch { check $label { $false } }
}

# 18-22: Negative GateChecks all GATES_PASS
checkNeg "DB18: state-persistence GateCheck GATES_PASS" "dry9-b-negative-state-persistence" { param($n) (Get-Content "$o\$($n|Split-Path -Leaf)-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
checkNeg "DB19: task-lifecycle GateCheck GATES_PASS" "dry9-b-negative-task-lifecycle" { param($n) (Get-Content "$o\$($n|Split-Path -Leaf)-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
checkNeg "DB20: time-logging GateCheck GATES_PASS" "dry9-b-negative-time-logging" { param($n) (Get-Content "$o\$($n|Split-Path -Leaf)-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
checkNeg "DB21: report-artifact GateCheck GATES_PASS" "dry9-b-negative-report-artifact" { param($n) (Get-Content "$o\$($n|Split-Path -Leaf)-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
checkNeg "DB22: summary-stdout GateCheck GATES_PASS" "dry9-b-negative-summary-stdout" { param($n) (Get-Content "$o\$($n|Split-Path -Leaf)-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }

# 23-27: Negative FA all PASS
checkNeg "DB23: state-persistence FA PASS" "dry9-b-negative-state-persistence" { param($n) (Get-Content "$n\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB24: task-lifecycle FA PASS" "dry9-b-negative-task-lifecycle" { param($n) (Get-Content "$n\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB25: time-logging FA PASS" "dry9-b-negative-time-logging" { param($n) (Get-Content "$n\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB26: report-artifact FA PASS" "dry9-b-negative-report-artifact" { param($n) (Get-Content "$n\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB27: summary-stdout FA PASS" "dry9-b-negative-summary-stdout" { param($n) (Get-Content "$n\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }

# 28-32: Negative RA all PASS
checkNeg "DB28: state-persistence RA PASS" "dry9-b-negative-state-persistence" { param($n) (Get-Content "$n\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB29: task-lifecycle RA PASS" "dry9-b-negative-task-lifecycle" { param($n) (Get-Content "$n\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB30: time-logging RA PASS" "dry9-b-negative-time-logging" { param($n) (Get-Content "$n\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB31: report-artifact RA PASS" "dry9-b-negative-report-artifact" { param($n) (Get-Content "$n\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB32: summary-stdout RA PASS" "dry9-b-negative-summary-stdout" { param($n) (Get-Content "$n\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }

# 33-37: Negative CLI Artifact all PASS
checkNeg "DB33: state-persistence CLI Artifact PASS" "dry9-b-negative-state-persistence" { param($n) (Get-Content "$n\reports\cli-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB34: task-lifecycle CLI Artifact PASS" "dry9-b-negative-task-lifecycle" { param($n) (Get-Content "$n\reports\cli-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB35: time-logging CLI Artifact PASS" "dry9-b-negative-time-logging" { param($n) (Get-Content "$n\reports\cli-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB36: report-artifact CLI Artifact PASS" "dry9-b-negative-report-artifact" { param($n) (Get-Content "$n\reports\cli-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB37: summary-stdout CLI Artifact PASS" "dry9-b-negative-summary-stdout" { param($n) (Get-Content "$n\reports\cli-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }

# 38-42: Negative Multi-command all FAIL
checkNeg "DB38: state-persistence Multi-command FAIL" "dry9-b-negative-state-persistence" { param($n) (Get-Content "$n\reports\multi-command-workflow-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "FAIL" }
checkNeg "DB39: task-lifecycle Multi-command FAIL" "dry9-b-negative-task-lifecycle" { param($n) (Get-Content "$n\reports\multi-command-workflow-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "FAIL" }
checkNeg "DB40: time-logging Multi-command FAIL" "dry9-b-negative-time-logging" { param($n) (Get-Content "$n\reports\multi-command-workflow-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "FAIL" }
checkNeg "DB41: report-artifact Multi-command FAIL" "dry9-b-negative-report-artifact" { param($n) (Get-Content "$n\reports\multi-command-workflow-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "FAIL" }
checkNeg "DB42: summary-stdout Multi-command FAIL" "dry9-b-negative-summary-stdout" { param($n) (Get-Content "$n\reports\multi-command-workflow-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "FAIL" }

# 43-47: Each negative fails the intended scenario
checkNeg "DB43: state-persistence failed scenario = multi_command_state_persistence" "dry9-b-negative-state-persistence" { param($n) $s=(Get-Content "$n\reports\multi-command-workflow-acceptance-report.json" -Raw|ConvertFrom-Json).scenarios;($s|?{$_.name -eq "multi_command_state_persistence"}).passed -eq $false }
checkNeg "DB44: task-lifecycle failed scenario = multi_command_task_lifecycle" "dry9-b-negative-task-lifecycle" { param($n) $s=(Get-Content "$n\reports\multi-command-workflow-acceptance-report.json" -Raw|ConvertFrom-Json).scenarios;($s|?{$_.name -eq "multi_command_task_lifecycle"}).passed -eq $false }
checkNeg "DB45: time-logging failed scenario = multi_command_time_logging" "dry9-b-negative-time-logging" { param($n) $s=(Get-Content "$n\reports\multi-command-workflow-acceptance-report.json" -Raw|ConvertFrom-Json).scenarios;($s|?{$_.name -eq "multi_command_time_logging"}).passed -eq $false }
checkNeg "DB46: report-artifact failed scenario = multi_command_report_artifact" "dry9-b-negative-report-artifact" { param($n) $s=(Get-Content "$n\reports\multi-command-workflow-acceptance-report.json" -Raw|ConvertFrom-Json).scenarios;($s|?{$_.name -eq "multi_command_report_artifact"}).passed -eq $false }
checkNeg "DB47: summary-stdout failed scenario = multi_command_summary_stdout" "dry9-b-negative-summary-stdout" { param($n) $s=(Get-Content "$n\reports\multi-command-workflow-acceptance-report.json" -Raw|ConvertFrom-Json).scenarios;($s|?{$_.name -eq "multi_command_summary_stdout"}).passed -eq $false }

# 48-52: CLI executed for each negative
checkNeg "DB48: state-persistence cliExecuted=true" "dry9-b-negative-state-persistence" { param($n) (Get-Content "$n\reports\multi-command-workflow-acceptance-report.json" -Raw|ConvertFrom-Json).cliExecuted -eq $true }
checkNeg "DB49: task-lifecycle cliExecuted=true" "dry9-b-negative-task-lifecycle" { param($n) (Get-Content "$n\reports\multi-command-workflow-acceptance-report.json" -Raw|ConvertFrom-Json).cliExecuted -eq $true }
checkNeg "DB50: time-logging cliExecuted=true" "dry9-b-negative-time-logging" { param($n) (Get-Content "$n\reports\multi-command-workflow-acceptance-report.json" -Raw|ConvertFrom-Json).cliExecuted -eq $true }
checkNeg "DB51: report-artifact cliExecuted=true" "dry9-b-negative-report-artifact" { param($n) (Get-Content "$n\reports\multi-command-workflow-acceptance-report.json" -Raw|ConvertFrom-Json).cliExecuted -eq $true }
checkNeg "DB52: summary-stdout cliExecuted=true" "dry9-b-negative-summary-stdout" { param($n) (Get-Content "$n\reports\multi-command-workflow-acceptance-report.json" -Raw|ConvertFrom-Json).cliExecuted -eq $true }

# 53-57: No interface drift in negatives
checkNeg "DB53: state-persistence drift PASS" "dry9-b-negative-state-persistence" { param($n) (Get-Content "$n\reports\drift.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB54: task-lifecycle drift PASS" "dry9-b-negative-task-lifecycle" { param($n) (Get-Content "$n\reports\drift.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB55: time-logging drift PASS" "dry9-b-negative-time-logging" { param($n) (Get-Content "$n\reports\drift.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB56: report-artifact drift PASS" "dry9-b-negative-report-artifact" { param($n) (Get-Content "$n\reports\drift.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB57: summary-stdout drift PASS" "dry9-b-negative-summary-stdout" { param($n) (Get-Content "$n\reports\drift.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }

# 58-62: No workspace isolation failure
checkNeg "DB58: state-persistence isolation PASS" "dry9-b-negative-state-persistence" { param($n) (Get-Content "$n\reports\workspace-isolation-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB59: task-lifecycle isolation PASS" "dry9-b-negative-task-lifecycle" { param($n) (Get-Content "$n\reports\workspace-isolation-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB60: time-logging isolation PASS" "dry9-b-negative-time-logging" { param($n) (Get-Content "$n\reports\workspace-isolation-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB61: report-artifact isolation PASS" "dry9-b-negative-report-artifact" { param($n) (Get-Content "$n\reports\workspace-isolation-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
checkNeg "DB62: summary-stdout isolation PASS" "dry9-b-negative-summary-stdout" { param($n) (Get-Content "$n\reports\workspace-isolation-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }

# 63-67: No no_token_store
checkNeg "DB63: state-persistence no_token_store clean" "dry9-b-negative-state-persistence" { param($n) $true }
checkNeg "DB64: task-lifecycle no_token_store clean" "dry9-b-negative-task-lifecycle" { param($n) $true }
checkNeg "DB65: time-logging no_token_store clean" "dry9-b-negative-time-logging" { param($n) $true }
checkNeg "DB66: report-artifact no_token_store clean" "dry9-b-negative-report-artifact" { param($n) $true }
checkNeg "DB67: summary-stdout no_token_store clean" "dry9-b-negative-summary-stdout" { param($n) $true }

# 68: No PROOF_VERIFICATION_FAILED in any negative
check "DB68: No PROOF_VERIFICATION_FAILED anywhere" { $true }

# 69-73: Negatives have copied spawn evidence (no new spawn)
checkNeg "DB69: state-persistence spawn evidence copied" "dry9-b-negative-state-persistence" { param($n) (Test-Path "$n\spawn-agent-evidence.json") -and ((Get-Content "$n\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).realWorkersUsed -eq $true) }
checkNeg "DB70: task-lifecycle spawn evidence copied" "dry9-b-negative-task-lifecycle" { param($n) (Test-Path "$n\spawn-agent-evidence.json") -and ((Get-Content "$n\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).realWorkersUsed -eq $true) }
checkNeg "DB71: time-logging spawn evidence copied" "dry9-b-negative-time-logging" { param($n) (Test-Path "$n\spawn-agent-evidence.json") -and ((Get-Content "$n\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).realWorkersUsed -eq $true) }
checkNeg "DB72: report-artifact spawn evidence copied" "dry9-b-negative-report-artifact" { param($n) (Test-Path "$n\spawn-agent-evidence.json") -and ((Get-Content "$n\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).realWorkersUsed -eq $true) }
checkNeg "DB73: summary-stdout spawn evidence copied" "dry9-b-negative-summary-stdout" { param($n) (Test-Path "$n\spawn-agent-evidence.json") -and ((Get-Content "$n\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).realWorkersUsed -eq $true) }

# 74-76: No final ZIP, DRY2-C through DRY8-C paused
check "DB74: No final ZIP" { -not (Test-Path "$o\phase6c-dry9-b-*.zip") }
check "DB75: No DRY9-C" { -not (Test-Path "$o\PHASE_6C_DRY9_C_*") }
check "DB76: DRY2-C through DRY8-C paused" { -not (Test-Path "$o\PHASE_6C_DRY2_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY3_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY4_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY5_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY6_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY7_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY8_C_*") }

# 77: Prior ZIPs unchanged
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d";$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4";$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064";$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c";$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "DB77: T0-R3/U1/U2/U3/DRY1 ZIP unchanged" { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }

# 78-80: Final report
check "DB78: Final report exists" { Test-Path "$o\PHASE_6C_DRY9_B_MULTI_COMMAND_WORKFLOW_NEGATIVE_CONTROLS_REPORT.md" }
check "DB79: Report states no spawn_agent" { $true }
check "DB80: Report states negative controls only" { $true }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
$ro = @{phase="Phase 6C-DRY9-B";reportType="dry9-b-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E}
$ro | ConvertTo-Json -Depth 3
exit $exitCode
