# Task Heartbeat — Update liveness timestamp for in_progress task
param(
    [Parameter(Mandatory=$true)][string]$TaskId,
    [Parameter(Mandatory=$true)][string]$AgentId,
    [Parameter(Mandatory=$true)][string]$Token,
    [Parameter(Mandatory=$false)][string]$RunDir,
    [Parameter(Mandatory=$false)][string]$CurrentStep = "heartbeat"
)

$ErrorActionPreference = "Stop"
$HarnessRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if (-not $RunDir) {
    $ar = Get-Content (Join-Path $HarnessRoot "runtime\active-run.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $RunDir = Join-Path $HarnessRoot "runs" $ar.activeRunId
}

# Validate token (must be active, not expired)
$tokenResult = & (Join-Path $PSScriptRoot "token-lease.ps1") -Action validate -RunId (Split-Path $RunDir -Leaf) -TaskId $TaskId -AgentId $AgentId -Role "builder-agent" -Token $Token 2>&1 | ConvertFrom-Json
if ($tokenResult.status -ne "valid") {
    & (Join-Path $PSScriptRoot "append-hash-event.ps1") -RunDir $RunDir -EventData @{
        event = "heartbeat_rejected"
        taskId = $TaskId; agentId = $AgentId
        reason = "TOKEN_INVALID: $($tokenResult.reason)"
    }
    throw "HEARTBEAT_REJECTED: Token invalid ($($tokenResult.reason))"
}

# Check task is in_progress
$tasksFile = Join-Path $RunDir "TASKS.json"
$tasks = Get-Content $tasksFile -Raw -Encoding UTF8 | ConvertFrom-Json
$task = $tasks.tasks | Where-Object { $_.taskId -eq $TaskId }
if (-not $task) { throw "Task '$TaskId' not found" }
if ($task.owner -ne $AgentId) { throw "Task owned by '$($task.owner)', not '$AgentId'" }
if ($task.status -ne "in_progress") { throw "Task status is '$($task.status)', not in_progress" }

# Update heartbeat timestamp
$task | Add-Member -NotePropertyName lastHeartbeatAt -NotePropertyValue (Get-Date).ToString("o") -Force
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($tasksFile, ($tasks | ConvertTo-Json -Depth 6), $utf8)

# Record heartbeat event
& (Join-Path $PSScriptRoot "append-hash-event.ps1") -RunDir $RunDir -EventData @{
    event = "task_heartbeat"
    taskId = $TaskId; agentId = $AgentId
    currentStep = $CurrentStep
    leaseId = $tokenResult.tokenLeaseId
}

Write-Output (@{ status="heartbeat"; taskId=$TaskId; agentId=$AgentId; timestamp=(Get-Date).ToString("o") } | ConvertTo-Json)