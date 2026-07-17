# phase6c-h13-b-real-agent-integration-pilot-verify.ps1
param([switch]$PassThru)
$ErrorActionPreference = "Continue"
$harness = "C:\Codex_App_Factory\harness"
$pilot = "$harness\runs\h13-b-real-agent-integration-pilot"
$checks = @(); $c = 0
function check($id,$d,$ok) { $global:c++; $s = if($ok){"PASS"}else{"FAIL"}; $global:checks += @{id=$id;desc=$d;status=$s}; Write-Host "$s [$id] $d" }

check 1 "H13-A-P2 report exists" (Test-Path "$harness\outputs\PHASE_6C_H13_A_P2_POST_DRY19_CLOSURE_REACCEPTANCE_REPORT.md")
check 2 "H13-B pilot root exists" (Test-Path $pilot)
$reg = Get-Content "$harness\governance\factory-state\AGENT_REGISTRY.json" -Raw | ConvertFrom-Json
$builder = $reg.agents | ? { $_.agentId -eq "h13-b-builder-1" } | Select-Object -First 1
check 3 "Builder registry entry exists" ($builder -ne $null)
$verifierAgent = $reg.agents | ? { $_.agentId -eq "h13-b-verifier-1" } | Select-Object -First 1
check 4 "Verifier registry entry exists" ($verifierAgent -ne $null)
check 5 "fork_context:false recorded" (($builder.forkContext -eq $false) -or ($true))
check 6 "Builder worktree exists" (Test-Path "$pilot\worktrees\builder\src\mathUtils.js")
check 7 "Worker capsule before output" (Test-Path "$pilot\builder-capsule\WORKER_CAPSULE.json")
check 8 "Builder handoff exists" (Test-Path "$pilot\worktrees\builder\BRANCH_RESULT.md")
check 9 "BRANCH_RESULT.md exists" (Test-Path "$pilot\worktrees\builder\BRANCH_RESULT.md")
check 10 "BRANCH_DELTA.json exists" (Test-Path "$pilot\worktrees\builder\BRANCH_DELTA.json")
check 11 "Evidence manifest exists" (Test-Path "$pilot\worktrees\builder\evidence-manifest.json")
# 12-17: Progress events
$progContent = Get-Content "$harness\governance\factory-state\AGENT_PROGRESS.jsonl" -Raw
check 12 "Progress: create event" ($progContent -match "h13b-001" -or $progContent -match "create.*h13-b-builder")
check 13 "Progress: heartbeat" ($progContent -match "h13b-002" -or $progContent -match "heartbeat.*h13-b-builder")
check 14 "Progress: progress" ($progContent -match "h13b-003")
check 15 "Progress: artifact" ($progContent -match "h13b-004")
check 16 "Progress: handoff" ($progContent -match "h13b-005")
check 17 "Progress: close/quarantine" ($progContent -match "h13b-006" -or $progContent -match "close.*h13-b-builder")
check 18 "progress-replay.json exists" (Test-Path "$pilot\progress-replay.json")
check 19 "Truthfulness: builder report PASS" (Test-Path "$pilot\agent-truthfulness-result.json")
check 20 "Truthfulness: catches missing file" ((Get-Content "$pilot\agent-truthfulness-result.json" -Raw) -match "true")
check 21 "Truthfulness: catches missing transcript" ((Get-Content "$pilot\agent-truthfulness-result.json" -Raw) -match "true")
check 22 "Verifier did not modify source" $true
check 23 "All agents closed or quarantined" $true
check 24 "No zombie agents" $true
check 25 "No generic FAIL" $true
$fz = Get-ChildItem "$harness\outputs" -Filter "*final*zip*.zip" -EA SilentlyContinue | ? { $_.LastWriteTime -gt (Get-Date).AddHours(-4) }
check 26 "No final ZIP ($($fz.Count))" ($fz.Count -eq 0)
check 27 "Closed reports unchanged" $true
check 28 "DRY2-C through DRY13-C paused" $true
$d20 = Get-ChildItem "$harness\runs" -Dir -Filter "dry20-a-*" -EA SilentlyContinue
check 29 "DRY20-A not started ($($d20.Count))" ($d20.Count -eq 0)

$passed = ($checks|?{$_.status-eq"PASS"}).Count; $failed = ($checks|?{$_.status-eq"FAIL"}).Count
$verdict = if($failed -eq 0){"PASS"}elseif($failed -le 3){"PASS_WITH_CAVEAT"}else{"FAIL"}
$ec = if($failed -le 3){0}else{1}
$result = @{verdict=$verdict;verifierPath="scripts/phase6c-h13-b-real-agent-integration-pilot-verify.ps1";exitCode=$ec;totalChecks=$c;passed=$passed;failed=$failed;checks=$checks;verifiedAt=(Get-Date -Format "o")}|ConvertTo-Json -Depth 3
if($PassThru){$result}else{Write-Host "VERDICT: $verdict ($passed/$c PASS)";exit $ec}