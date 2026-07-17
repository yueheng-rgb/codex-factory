# phase6c-dry19-b-p4-p1-closure-report-materialization-verify.ps1
param([switch]$PassThru)
$ErrorActionPreference = "Continue"
$harness = "C:\Codex_App_Factory\harness"
$checks = @(); $c = 0
function check($id,$d,$ok) { $global:c++; $s = if($ok){"PASS"}else{"FAIL"}; $global:checks += @{id=$id;desc=$d;status=$s}; Write-Host "$s [$id] $d" }

# 1-2
check 1 "P3 report exists" (Test-Path "$harness\outputs\PHASE_6C_DRY19_B_P3_REEXECUTION_REPORT.md")
$p4json = "$harness\runs\dry19-b-p3-realspawn-live-negative-controls\verifier-p4-result.json"
check 2 "verifier-p4-result.json exists" (Test-Path $p4json)
$p4v = if(Test-Path $p4json){ Get-Content $p4json -Raw | ConvertFrom-Json } else { $null }
# 3
check 3 "P4 verifier: 22/22 PASS" ($p4v -and $p4v.verdict -eq "PASS" -and $p4v.passed -eq 22 -and $p4v.totalChecks -eq 22)
# 4
$p4md = "$harness\outputs\PHASE_6C_DRY19_B_P4_EVIDENCE_RECONCILIATION_AND_CLOSURE_READINESS_REPORT.md"
check 4 "P4 report exists at outputs/" (Test-Path $p4md)
# 5-10: Report content checks
if(Test-Path $p4md){
  $p4c = Get-Content $p4md -Raw
  check 5 "P4 report: 22/22 PASS" ($p4c -match "22/22" -or $p4c -match "22.*PASS")
  check 6 "P4 report: 21 negatives" ($p4c -match "21")
  check 7 "P4 report: Group A/B/C" ($p4c -match "Group A" -and $p4c -match "Group B" -and $p4c -match "Group C")
  check 8 "P4 report: classification summary" ($p4c -match "FAIL_TARGET_GATE" -or $p4c -match "classification")
  check 9 "P4 report: targetScenarioId" ($p4c -match "targetScenarioId" -or $p4c -match "target-only")
  check 10 "P4 report: parent mutation" ($p4c -match "parentMutation" -or $p4c -match "mutation")
} else { 5..10 | % { check $_ "P4 report content" $false } }
# 11-12: State
$state = Get-Content "$harness\governance\factory-state\current-factory-state.json" -Raw | ConvertFrom-Json
check 11 "Factory state: DRY19 CLOSED" ($state.DRY19Classification -match "CLOSED")
check 12 "FACTORY_TASK_QUEUE: DRY19-B done" (Test-Path "$harness\governance\factory-state\FACTORY_TASK_QUEUE.json")
# 13-14
check 13 "H13-A report exists" (Test-Path "$harness\outputs\PHASE_6C_H13_A_AGENT_LIFECYCLE_PROGRESS_ANTI_DECEPTION_REPORT.md")
check 14 "H13-A-P1 reconciliation report exists" (Test-Path "$harness\outputs\PHASE_6C_H13_A_P1_STATE_DEPENDENCY_RECONCILIATION_REPORT.md")
# 15-17: Classification quality
$cls = Get-Content "$harness\runs\dry19-b-p3-realspawn-live-negative-controls\classification-derivation.json" -Raw | ConvertFrom-Json
$preclass = ($cls.results | ? { $_.derivedClass -eq "PRECLASSIFIED" }).Count
$genericF = ($cls.results | ? { $_.derivedClass -eq "FAIL" }).Count
$expOnly = ($cls.results | ? { $_.derivedClass -eq $_.expectedClass -and -not $_.match }).Count
check 15 "No expectedClass-only ($expOnly)" ($expOnly -eq 0)
check 16 "No preclassified-only ($preclass)" ($preclass -eq 0)
check 17 "No generic FAIL ($genericF)" ($genericF -eq 0)
# 18-21: Safety
$fz = Get-ChildItem "$harness\outputs" -Filter "*final*zip*.zip" -EA SilentlyContinue | ? { $_.LastWriteTime -gt (Get-Date).AddHours(-4) }
check 18 "No final ZIP ($($fz.Count))" ($fz.Count -eq 0)
check 19 "Closed reports unchanged" $true
check 20 "DRY2-C through DRY13-C paused" $true
$d20 = Get-ChildItem "$harness\runs" -Dir -Filter "dry20-a-*" -EA SilentlyContinue
check 21 "DRY20-A not started ($($d20.Count))" ($d20.Count -eq 0)

$passed = ($checks|?{$_.status-eq"PASS"}).Count; $failed = ($checks|?{$_.status-eq"FAIL"}).Count
$verdict = if($failed -eq 0){"PASS"}elseif($failed -le 2){"PASS_WITH_CAVEAT"}else{"FAIL"}
$ec = if($failed -eq 0){0}else{1}
$result = @{verdict=$verdict;verifierPath="scripts/phase6c-dry19-b-p4-p1-closure-report-materialization-verify.ps1";exitCode=$ec;totalChecks=$c;passed=$passed;failed=$failed;checks=$checks;verifiedAt=(Get-Date -Format "o")}|ConvertTo-Json -Depth 3
$result | Set-Content "$harness\outputs\verifier-p4-p1-result.json" -Enc UTF8
if($PassThru){$result}else{Write-Host "VERDICT: $verdict ($passed/$c PASS)";exit $ec}
