# read-memory.ps1 — Read and summarize .codex-factory/ state
param([Parameter(Mandatory)]$ProjectPath, [switch]$Json)

$cfDir = Join-Path $ProjectPath ".codex-factory"
if (-not (Test-Path $cfDir)) { Write-Error ".codex-factory/ not found at $cfDir"; exit 1 }

$summary = @{projectPath=$ProjectPath;cfDir=$cfDir;files=@{}}

$statePath = Join-Path $cfDir "project-state.json"
if (Test-Path $statePath) {
    $state = Get-Content $statePath -Raw | ConvertFrom-Json
    $summary.state = @{projectId=$state.projectId;currentStage=$state.currentStage;selectedMode=$state.selectedMode;complexityLevel=$state.complexityLevel;agentCount=$state.agentCount;lastAction=$state.lastAction;sessionCount=$state.sessionCount;updatedAt=$state.updatedAt}
}

$tgPath = Join-Path $cfDir "task-graph.json"
if (Test-Path $tgPath) {
    $tg = Get-Content $tgPath -Raw | ConvertFrom-Json
    $summary.taskGraph = @{totalTasks=$tg.totalTasks;completedTasks=$tg.completedTasks;pending=($tg.tasks|Where-Object{$_.status-eq"PENDING"}).Count;inProgress=($tg.tasks|Where-Object{$_.status-eq"IN_PROGRESS"}).Count;blocked=($tg.tasks|Where-Object{$_.status-eq"BLOCKED"}).Count}
}

$arPath = Join-Path $cfDir "active-risks.json"
if (Test-Path $arPath) {
    $ar = Get-Content $arPath -Raw | ConvertFrom-Json
    $activeRisks = $ar.risks | Where-Object { $_.status -eq "ACTIVE" }
    $summary.risks = @{total=$ar.risks.Count;active=$activeRisks.Count;critical=($activeRisks|Where-Object{$_.severity-eq"CRITICAL"}).Count}
}

$vhPath = Join-Path $cfDir "verifier-history.json"
if (Test-Path $vhPath) {
    $vh = Get-Content $vhPath -Raw | ConvertFrom-Json
    $summary.verifierHistory = @{totalRuns=$vh.entries.Count;lastResult=if($vh.entries.Count -gt 0){$vh.entries[-1].result}else{"N/A"}}
}

$dlPath = Join-Path $cfDir "decision-log.jsonl"
if (Test-Path $dlPath) {
    $lines = (Get-Content $dlPath | Where-Object { $_.Trim() -ne "" }).Count
    $summary.decisions = @{totalEntries=$lines}
}

if ($Json) { $summary | ConvertTo-Json -Depth 4 }
else {
    Write-Host "=== .codex-factory/ State Summary ==="
    Write-Host "Project: $($summary.state.projectId)"
    Write-Host "Stage: $($summary.state.currentStage) | Mode: $($summary.state.selectedMode) | Complexity: $($summary.state.complexityLevel)"
    Write-Host "Tasks: $($summary.taskGraph.completedTasks)/$($summary.taskGraph.totalTasks) done | $($summary.taskGraph.pending) pending | $($summary.taskGraph.inProgress) in-progress | $($summary.taskGraph.blocked) blocked"
    Write-Host "Risks: $($summary.risks.active) active ($($summary.risks.critical) critical) of $($summary.risks.total) total"
    Write-Host "Verifier: $($summary.verifierHistory.totalRuns) runs, last: $($summary.verifierHistory.lastResult)"
    Write-Host "Decisions: $($summary.decisions.totalEntries) entries"
    Write-Host "Last Update: $($summary.state.updatedAt)"
}
