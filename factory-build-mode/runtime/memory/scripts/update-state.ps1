# update-state.ps1 — Update project-state.json stage and metadata
param([Parameter(Mandatory)]$ProjectPath, [Parameter(Mandatory)]$Stage, $Mode="", $Action="", $Actor="update-state.ps1")

$cfDir = Join-Path $ProjectPath ".codex-factory"
$statePath = Join-Path $cfDir "project-state.json"
if (-not (Test-Path $statePath)) { Write-Error "project-state.json not found. Run init-memory.ps1 first."; exit 1 }

$state = Get-Content $statePath -Raw | ConvertFrom-Json
$validStages = @("INTAKE","CLASSIFY","ROUTE","BLUEPRINT","TASK_GRAPH","BUILD","DIAGNOSTIC_GATE","REPAIR","DELIVER","BLOCKED")
if ($Stage -notin $validStages) { Write-Error "Invalid stage: $Stage. Valid: $($validStages -join ', ')"; exit 2 }

$now = (Get-Date).ToString("o")
$state.currentStage = $Stage
$state.stages.$Stage = "COMPLETED"
$state.lastAction = if ($Action) { $Action } else { "stage-updated-to-$Stage" }
$state.lastActionTimestamp = $now
$state.updatedAt = $now
$state.updatedBy = $Actor
$state.sessionCount += 1
if ($Mode) { $state.selectedMode = $Mode }

$state | ConvertTo-Json -Depth 4 | Out-File $statePath -Encoding UTF8
Write-Host "State updated: stage=$Stage, mode=$(if($Mode){$Mode}else{'unchanged'}), action=$($state.lastAction)"
@{status="ok";stage=$Stage;updatedAt=$now} | ConvertTo-Json
