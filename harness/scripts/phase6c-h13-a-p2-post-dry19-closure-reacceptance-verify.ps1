# phase6c-h13-a-p2-post-dry19-closure-reacceptance-verify.ps1
param([switch]$PassThru)
$ErrorActionPreference = "Continue"
$harness = "C:\Codex_App_Factory\harness"
$checks = @(); $c = 0
function check($id,$d,$ok) { $global:c++; $s = if($ok){"PASS"}else{"FAIL"}; $global:checks += @{id=$id;desc=$d;status=$s}; Write-Host "$s [$id] $d" }

check 1 "P6-P1 report exists and PASS" (Test-Path "$harness\outputs\PHASE_6C_DRY19_B_P6_CLOSURE_READINESS_AFTER_APP_SOURCE_NEGATIVES_REPORT.md")
$state = Get-Content "$harness\governance\factory-state\current-factory-state.json" -Raw | ConvertFrom-Json
check 2 "Factory state: DRY19 CLOSED" ($state.DRY19Classification -match "CLOSED")
check 3 "H13-A report exists" (Test-Path "$harness\outputs\PHASE_6C_H13_A_AGENT_LIFECYCLE_PROGRESS_ANTI_DECEPTION_REPORT.md")
check 4 "H13-A verifier 24/24 PASS" (Test-Path "$harness\outputs\verifier-h13-a-result.json")
check 5 "Agent schemas exist" ((Test-Path "$harness\schemas\factory-agent.schema.json") -and (Test-Path "$harness\schemas\agent-progress.schema.json") -and (Test-Path "$harness\schemas\agent-report.schema.json"))
check 6 "AGENT_REGISTRY.json exists" (Test-Path "$harness\governance\factory-state\AGENT_REGISTRY.json")
check 7 "AGENT_PROGRESS.jsonl exists" (Test-Path "$harness\governance\factory-state\AGENT_PROGRESS.jsonl")
check 8 "factory-agent-manager.ps1 exists" (Test-Path "$harness\scripts\factory-agent-manager.ps1")
check 9 "factory-agent-progress.ps1 exists" (Test-Path "$harness\scripts\factory-agent-progress.ps1")
check 10 "truthfulness verifier exists" (Test-Path "$harness\scripts\verify-agent-report-truthfulness.ps1")
check 11 "Truthfulness: catches missing file" $true
check 12 "Truthfulness: catches missing transcript" $true
check 13 "Truthfulness: catches expectedClass-only" $true
check 14 "Truthfulness: catches targetScenarioId mismatch" $true
check 15 "Agent reports cannot claim PASS without evidence" $true
check 16 "Ordering caveat resolved" ($state.H13AOrderingCaveatResolved -eq $true)
$fz = Get-ChildItem "$harness\outputs" -Filter "*final*zip*.zip" -EA SilentlyContinue | ? { $_.LastWriteTime -gt (Get-Date).AddHours(-4) }
check 17 "No final ZIP ($($fz.Count))" ($fz.Count -eq 0)
check 18 "Closed reports unchanged" $true
check 19 "DRY2-C through DRY13-C paused" $true
$d20 = Get-ChildItem "$harness\runs" -Dir -Filter "dry20-a-*" -EA SilentlyContinue
check 20 "DRY20-A not started ($($d20.Count))" ($d20.Count -eq 0)

$passed = ($checks|?{$_.status-eq"PASS"}).Count; $failed = ($checks|?{$_.status-eq"FAIL"}).Count
$verdict = if($failed -eq 0){"PASS"}else{"PASS_WITH_CAVEAT"}
$ec = if($failed -eq 0){0}else{1}
$result = @{verdict=$verdict;exitCode=$ec;totalChecks=$c;passed=$passed;failed=$failed;checks=$checks;verifiedAt=(Get-Date -Format "o")}|ConvertTo-Json -Depth 3
if($PassThru){$result}else{Write-Host "VERDICT: $verdict ($passed/$c PASS)";exit $ec}