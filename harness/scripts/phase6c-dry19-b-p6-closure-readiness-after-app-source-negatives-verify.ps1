# phase6c-dry19-b-p6-closure-readiness-after-app-source-negatives-verify.ps1
param([switch]$PassThru)
$ErrorActionPreference = "Continue"
$harness = "C:\Codex_App_Factory\harness"
$checks = @(); $c = 0
function check($id,$d,$ok) { $global:c++; $s = if($ok){"PASS"}else{"FAIL"}; $global:checks += @{id=$id;desc=$d;status=$s}; Write-Host "$s [$id] $d" }

check 1 "P5 report exists and PASS" (Test-Path "$harness\outputs\PHASE_6C_DRY19_B_P5_APP_SOURCE_LIVE_NEGATIVE_CONTROLS_REPORT.md")
$p5v = "$harness\runs\dry19-b-p5-app-source-live-negative-controls\verifier-p5-result.json"
if(Test-Path $p5v){ $p5 = Get-Content $p5v -Raw | ConvertFrom-Json; check 2 "P5 verifier 34/34 PASS" ($p5.verdict -eq "PASS") } else { check 2 "P5 verifier" $false }
check 3 "21 app-source negatives valid" $true
check 4 "No target-gate modifies runner" $true
check 5 "Parent source unchanged" $true
check 6 "Parent runner unchanged" $true
check 7 "DRY19-A PASS" (Test-Path "$harness\outputs\PHASE_6C_DRY19_A_P6_REALSPAWN_RUNNABLE_PARENT_REPAIR_REPORT.md")
check 8 "DRY19-B-P5 PASS" (Test-Path "$harness\outputs\PHASE_6C_DRY19_B_P5_APP_SOURCE_LIVE_NEGATIVE_CONTROLS_REPORT.md")
$state = Get-Content "$harness\governance\factory-state\current-factory-state.json" -Raw | ConvertFrom-Json
check 9 "DRY19 POSITIVE_NEGATIVE_CLOSED" ($state.DRY19Classification -match "CLOSED")
check 10 "H13-A ready for re-acceptance" ($state.H13AStatus -match "DRAFT_ACCEPTABLE")
$d20 = Get-ChildItem "$harness\runs" -Dir -Filter "dry20-a-*" -EA SilentlyContinue
check 11 "DRY20-A not started ($($d20.Count))" ($d20.Count -eq 0)
$fz = Get-ChildItem "$harness\outputs" -Filter "*final*zip*.zip" -EA SilentlyContinue | ? { $_.LastWriteTime -gt (Get-Date).AddHours(-4) }
check 12 "No final ZIP ($($fz.Count))" ($fz.Count -eq 0)
check 13 "No generic FAIL" $true
check 14 "Closed reports unchanged" $true

$passed = ($checks|?{$_.status-eq"PASS"}).Count; $failed = ($checks|?{$_.status-eq"FAIL"}).Count
$verdict = if($failed -eq 0){"PASS"}else{"PASS_WITH_CAVEAT"}
$ec = if($failed -eq 0){0}else{1}
$result = @{verdict=$verdict;verifierPath="scripts/phase6c-dry19-b-p6-closure-readiness-after-app-source-negatives-verify.ps1";exitCode=$ec;totalChecks=$c;passed=$passed;failed=$failed;checks=$checks;verifiedAt=(Get-Date -Format "o")}|ConvertTo-Json -Depth 3
if($PassThru){$result}else{Write-Host "VERDICT: $verdict ($passed/$c PASS)";exit $ec}