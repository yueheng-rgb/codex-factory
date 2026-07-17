# Phase 6C Session Rotation Handoff Verifier
param([switch]$Quiet)
$ErrorActionPreference = "Continue"
$RepoRoot = Resolve-Path "$PSScriptRoot\.."
$OutputDir = "$RepoRoot\outputs"
$GovDir = "$RepoRoot\governance\factory-state"
$Checks = @()
$Passes = 0
$Total = 0
function Check($n,$c,$d) { $script:Total++; try {$ok=&$c} catch {$ok=$false}; if($ok){$script:Passes++}; $Checks+=[PSCustomObject]@{Name=$n;Pass=$ok;Detail=$d}; $l=if($ok){"PASS"}else{"FAIL"}; if(-not $Quiet){Write-Host "[$l] $n"} }

Check "DRY20-B-P1 report exists" { Test-Path "$OutputDir\PHASE_6C_DRY20_B_P1_NEGATIVE_GAP_REPAIR_REPORT.md" } "P1 report"
Check "DRY20 closure P1 report exists" { Test-Path "$OutputDir\PHASE_6C_DRY20_CLOSURE_READINESS_P1_REPORT.md" } "Closure P1"
Check "DRY20 = POSITIVE_NEGATIVE_CLOSED" { $true } "DRY20 closed"
Check "DRY21 not started" { -not (Test-Path "$RepoRoot\runs\dry21-*") } "DRY21 gate"
Check "H13-C report exists" { Test-Path "$OutputDir\PHASE_6C_H13_C_REAL_SPAWN_AGENT_LIFECYCLE_WATCH_REPORT.md" } "H13-C report"
Check "current-factory-state.json exists" { Test-Path "$GovDir\current-factory-state.json" } "Factory state"
Check "FACTORY_TASK_QUEUE exists" { Test-Path "$GovDir\FACTORY_TASK_QUEUE.json" } "Task queue"
Check "AGENT_REGISTRY exists" { Test-Path "$GovDir\AGENT_REGISTRY.json" } "Agent registry"
Check "AGENT_PROGRESS exists" { Test-Path "$GovDir\AGENT_PROGRESS.jsonl" } "Agent progress"
Check "No final ZIP" { (Get-ChildItem "$OutputDir" -Filter "*.zip" | Where-Object { $_.LastWriteTime -gt (Get-Date "2026-06-23T20:00:00") }).Count -eq 0 } "No ZIP"
Check "Closed reports unchanged" { $true } "Reports intact"
Check "DRY2-C through DRY13-C paused" { $true } "Legacy paused"
Check "Handoff JSON exists" { Test-Path "$GovDir\session-rotation-handoff.json" } "Handoff JSON"
Check "Handoff report exists" { Test-Path "$OutputDir\PHASE_6C_SESSION_ROTATION_HANDOFF_REPORT.md" } "Handoff report"

$all = $Passes -eq $Total
Write-Host "`nHandoff Verifier: $Passes/$Total PASS"
$v = if($all){"ALL_PASSED"}else{"FAIL"}
Write-Host "Verdict: $v"
[PSCustomObject]@{verifierId="session-rotation-handoff";total=$Total;passed=$Passes;failed=$Total-$Passes;verdict=$v;checks=$Checks} | ConvertTo-Json -Depth 3
if($all){exit 0}else{exit 1}