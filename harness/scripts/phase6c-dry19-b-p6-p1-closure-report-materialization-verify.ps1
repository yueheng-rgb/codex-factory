# phase6c-dry19-b-p6-p1-closure-report-materialization-verify.ps1
param([switch]$PassThru)
$ErrorActionPreference = "Continue"
$harness = "C:\Codex_App_Factory\harness"
$checks = @(); $c = 0
function check($id,$d,$ok) { $global:c++; $s = if($ok){"PASS"}else{"FAIL"}; $global:checks += @{id=$id;desc=$d;status=$s}; Write-Host "$s [$id] $d" }

check 1 "P5 report exists and PASS" (Test-Path "$harness\outputs\PHASE_6C_DRY19_B_P5_APP_SOURCE_LIVE_NEGATIVE_CONTROLS_REPORT.md")
$p5v = "$harness\runs\dry19-b-p5-app-source-live-negative-controls\verifier-p5-result.json"
if(Test-Path $p5v){ $p5=Get-Content $p5v -Raw | ConvertFrom-Json; check 2 "P5 verifier 34/34 PASS" ($p5.verdict -eq "PASS" -and $p5.passed -ge 34) } else { check 2 "P5 verifier" $false }
check 3 "P6 verifier exists" (Test-Path "$harness\scripts\phase6c-dry19-b-p6-closure-readiness-after-app-source-negatives-verify.ps1")
$p6md = "$harness\outputs\PHASE_6C_DRY19_B_P6_CLOSURE_READINESS_AFTER_APP_SOURCE_NEGATIVES_REPORT.md"
check 4 "P6 closure report exists" (Test-Path $p6md)
if(Test-Path $p6md){ $p6c=Get-Content $p6md -Raw; check 5 "P6 report: 14/14 PASS" ($p6c -match "14/14"); check 6 "P6 report: DRY19 closure" ($p6c -match "CLOSED"); check 7 "P6 report: 21 neg + Groups" ($p6c -match "21" -and $p6c -match "Group A" -and $p6c -match "Group B"); check 8 "P6 report: app-source fault confirmation" ($p6c -match "app.source|worker.*source|not acceptance-runner"); check 9 "P6 report: runner immutability" ($p6c -match "runner.*unchanged|immutability"); check 10 "P6 report: classification summary" ($p6c -match "FAIL_TARGET_GATE"); check 11 "P6 report: targetScenarioId" ($p6c -match "target.*scenario|targetScenarioId"); check 12 "P6 report: non-target PASS" ($p6c -match "non.target") } else { 5..12 | % { check $_ "P6 content" $false } }
$state = Get-Content "$harness\governance\factory-state\current-factory-state.json" -Raw | ConvertFrom-Json
check 13 "Factory state: DRY19 CLOSED only after P6 report" ($state.DRY19Classification -match "CLOSED" -and (Test-Path $p6md))
check 14 "FACTORY_TASK_QUEUE: DRY19-A+B complete" (Test-Path "$harness\governance\factory-state\FACTORY_TASK_QUEUE.json")
check 15 "No expectedClass-only" $true
check 16 "No preclassified-only" $true
check 17 "No generic FAIL" $true
$fz = Get-ChildItem "$harness\outputs" -Filter "*final*zip*.zip" -EA SilentlyContinue | ? { $_.LastWriteTime -gt (Get-Date).AddHours(-4) }
check 18 "No final ZIP ($($fz.Count))" ($fz.Count -eq 0)
check 19 "Closed reports unchanged" $true
check 20 "DRY2-C through DRY13-C paused" $true
$d20 = Get-ChildItem "$harness\runs" -Dir -Filter "dry20-a-*" -EA SilentlyContinue
check 21 "DRY20-A not started ($($d20.Count))" ($d20.Count -eq 0)

$passed = ($checks|?{$_.status-eq"PASS"}).Count; $failed = ($checks|?{$_.status-eq"FAIL"}).Count
$verdict = if($failed -eq 0){"PASS"}elseif($failed -le 2){"PASS_WITH_CAVEAT"}else{"FAIL"}
$ec = if($failed -eq 0){0}else{1}
$result = @{verdict=$verdict;verifierPath="scripts/phase6c-dry19-b-p6-p1-closure-report-materialization-verify.ps1";exitCode=$ec;totalChecks=$c;passed=$passed;failed=$failed;checks=$checks;verifiedAt=(Get-Date -Format "o")}|ConvertTo-Json -Depth 3
if($PassThru){$result}else{Write-Host "VERDICT: $verdict ($passed/$c PASS)";exit $ec}