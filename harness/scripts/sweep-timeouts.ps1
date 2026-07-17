# Sweep Timeouts — Detect and mark stale in_progress tasks
param(
    [Parameter(Mandatory=$true)][string]$RunDir,
    [Parameter(Mandatory=$false)][int]$TimeoutSeconds = 120,
    [Parameter(Mandatory=$false)][switch]$AutoRedispatch
)

$ErrorActionPreference = "Continue"
$ScriptsDir = $PSScriptRoot
$tasksFile = Join-Path $RunDir "TASKS.json"
$utf8 = New-Object System.Text.UTF8Encoding($false)

if (-not (Test-Path $tasksFile)) {
    Write-Output (@{ status="FAIL"; reason="TASKS.json not found" } | ConvertTo-Json)
    exit 1
}

$tasks = Get-Content $tasksFile -Raw -Encoding UTF8 | ConvertFrom-Json
$inProgress = @($tasks.tasks | Where-Object { $_.status -eq "in_progress" })
$now = Get-Date
$timedOut = @()
$stillActive = @()

foreach ($task in $inProgress) {
    if (-not $task.lastHeartbeatAt) {
        if ($task.startedAt) {
            $started = [DateTime]::Parse($task.startedAt)
            $elapsed = ($now - $started).TotalSeconds
            if ($elapsed -gt $TimeoutSeconds) {
                $timedOut += @{ taskId=$task.taskId; reason="no_heartbeat"; elapsedSeconds=[Math]::Round($elapsed,0); lastHeartbeatAt=$null }
                $task.status = "timed_out"
                $task | Add-Member -NotePropertyName timedOutAt -NotePropertyValue $now.ToString("o") -Force
                $task | Add-Member -NotePropertyName timeoutReason -NotePropertyValue "No heartbeat within ${TimeoutSeconds}s" -Force
                
                & (Join-Path $ScriptsDir "append-hash-event.ps1") -RunDir $RunDir -EventData @{
                    event = "task_timed_out"
                    taskId = $task.taskId
                    reason = "no_heartbeat"
                    timeoutSeconds = $TimeoutSeconds
                    elapsedSeconds = [Math]::Round($elapsed,0)
                }

                # Auto re-dispatch
                if ($AutoRedispatch) {
                    $task | Add-Member -NotePropertyName previousOwner -NotePropertyValue $task.owner -Force
                    $rc = if ($task.redispatchCount) { [int]$task.redispatchCount + 1 } else { 1 }
                    $task | Add-Member -NotePropertyName redispatchCount -NotePropertyValue $rc -Force
                    $task.owner = "redispatch-$(Get-Date -Format 'HHmmss')"
                    $task.status = "ready"
                    $task.PSObject.Properties.Remove('startedAt')
                    $task.PSObject.Properties.Remove('lastHeartbeatAt')
                    $task.PSObject.Properties.Remove('timedOutAt')
                    $task.PSObject.Properties.Remove('timeoutReason')
                    & (Join-Path $ScriptsDir "append-hash-event.ps1") -RunDir $RunDir -EventData @{
                        event = "task_redispatch"
                        taskId = $task.taskId
                        previousOwner = $task.previousOwner
                        newOwner = $task.owner
                        redispatchCount = $rc
                        reason = "timeout_auto_redispatch"
                    }
                }
            } else {
                $stillActive += @{ taskId=$task.taskId; reason="within_timeout"; elapsedSeconds=[Math]::Round($elapsed,0) }
            }
        }
    } else {
        $lastHb = [DateTime]::Parse($task.lastHeartbeatAt)
        $elapsed = ($now - $lastHb).TotalSeconds
        if ($elapsed -gt $TimeoutSeconds) {
            $timedOut += @{ taskId=$task.taskId; reason="heartbeat_expired"; elapsedSeconds=[Math]::Round($elapsed,0); lastHeartbeatAt=$task.lastHeartbeatAt }
            $task.status = "timed_out"
            $task | Add-Member -NotePropertyName timedOutAt -NotePropertyValue $now.ToString("o") -Force
            $task | Add-Member -NotePropertyName timeoutReason -NotePropertyValue "Last heartbeat ${elapsed}s ago, threshold ${TimeoutSeconds}s" -Force
            & (Join-Path $ScriptsDir "append-hash-event.ps1") -RunDir $RunDir -EventData @{
                event = "task_timed_out"
                taskId = $task.taskId
                reason = "heartbeat_expired"
                timeoutSeconds = $TimeoutSeconds
                elapsedSeconds = [Math]::Round($elapsed,0)
                lastHeartbeatAt = $task.lastHeartbeatAt
            }

            # Auto re-dispatch
            if ($AutoRedispatch) {
                $task | Add-Member -NotePropertyName previousOwner -NotePropertyValue $task.owner -Force
                $rc = if ($task.redispatchCount) { [int]$task.redispatchCount + 1 } else { 1 }
                $task | Add-Member -NotePropertyName redispatchCount -NotePropertyValue $rc -Force
                $task.owner = "redispatch-$(Get-Date -Format 'HHmmss')"
                $task.status = "ready"
                $task.PSObject.Properties.Remove('startedAt')
                $task.PSObject.Properties.Remove('lastHeartbeatAt')
                $task.PSObject.Properties.Remove('timedOutAt')
                $task.PSObject.Properties.Remove('timeoutReason')
                & (Join-Path $ScriptsDir "append-hash-event.ps1") -RunDir $RunDir -EventData @{
                    event = "task_redispatch"
                    taskId = $task.taskId
                    previousOwner = $task.previousOwner
                    newOwner = $task.owner
                    redispatchCount = $rc
                    reason = "timeout_auto_redispatch"
                }
            }
        } else {
            $stillActive += @{ taskId=$task.taskId; reason="heartbeat_recent"; elapsedSeconds=[Math]::Round($elapsed,0); lastHeartbeatAt=$task.lastHeartbeatAt }
        }
    }
}

[System.IO.File]::WriteAllText($tasksFile, ($tasks | ConvertTo-Json -Depth 6), $utf8)

$result = @{
    status = if ($timedOut.Count -gt 0) { "TIMED_OUT_FOUND" } else { "ALL_ACTIVE" }
    totalInProgress = $inProgress.Count
    timedOutCount = $timedOut.Count
    stillActiveCount = $stillActive.Count
    timedOut = $timedOut
    stillActive = $stillActive
    sweepTimestamp = $now.ToString("o")
    timeoutSeconds = $TimeoutSeconds
    autoRedispatch = $AutoRedispatch.IsPresent
} | ConvertTo-Json -Depth 6

Write-Output $result
if ($timedOut.Count -gt 0) { exit 1 } else { exit 0 }