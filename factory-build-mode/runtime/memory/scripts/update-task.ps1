# update-task.ps1 — Update task status in task-graph.json
param([Parameter(Mandatory)]$ProjectPath, [Parameter(Mandatory)]$TaskId, [Parameter(Mandatory)]$Status, $Agent="")

$cfDir = Join-Path $ProjectPath ".codex-factory"
$tgPath = Join-Path $cfDir "task-graph.json"
if (-not (Test-Path $tgPath)) { Write-Error "task-graph.json not found."; exit 1 }

$tg = Get-Content $tgPath -Raw | ConvertFrom-Json
$validStatuses = @("PENDING","IN_PROGRESS","COMPLETED","BLOCKED")
if ($Status -notin $validStatuses) { Write-Error "Invalid status: $Status. Valid: $($validStatuses -join ', ')"; exit 2 }

$task = $tg.tasks | Where-Object { $_.id -eq $TaskId }
if (-not $task) { Write-Error "Task $TaskId not found in task-graph.json"; exit 3 }

# Conflict: only 1 task IN_PROGRESS at a time
if ($Status -eq "IN_PROGRESS") {
    $inProgress = $tg.tasks | Where-Object { $_.status -eq "IN_PROGRESS" -and $_.id -ne $TaskId }
    if ($inProgress) { Write-Warning "Conflict: task(s) already IN_PROGRESS: $($inProgress.id -join ', ')" }
}

$task.status = $Status
if ($Status -eq "COMPLETED") { $task.completedAt = (Get-Date).ToString("o") }
if ($Agent) { $task.agentAssigned = $Agent }

$tg.completedTasks = ($tg.tasks | Where-Object { $_.status -eq "COMPLETED" }).Count
$tg.updatedAt = (Get-Date).ToString("o")

$tg | ConvertTo-Json -Depth 6 | Out-File $tgPath -Encoding UTF8
Write-Host "Task $TaskId -> $Status | Completed: $($tg.completedTasks)/$($tg.totalTasks)"
@{status="ok";taskId=$TaskId;newStatus=$Status;completedTasks=$tg.completedTasks} | ConvertTo-Json

