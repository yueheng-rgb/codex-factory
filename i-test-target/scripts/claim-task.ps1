# Claim a task 鈥?Phase 6A.2 with token enforcement + hash-chain events
param(
    [Parameter(Mandatory=$true)][string]$TaskId,
    [Parameter(Mandatory=$true)][string]$AgentId,
    [Parameter(Mandatory=$true)][string]$Role,
    [Parameter(Mandatory=$false)][string]$Token,
    [Parameter(Mandatory=$false)][string]$RunDir
)

$ErrorActionPreference = "Stop"
$HarnessRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if (-not $RunDir) {
    $ar = Get-Content (Join-Path $HarnessRoot "runtime\active-run.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $RunDir = Join-Path $HarnessRoot "runs" $ar.activeRunId
}

# --- TOKEN VALIDATION ---
if (-not $Token) { throw "TOKEN_REQUIRED: claim-task requires -Token" }
$tokenResult = & (Join-Path $PSScriptRoot "token-lease.ps1") -Action validate -RunId (Split-Path $RunDir -Leaf) -TaskId $TaskId -AgentId $AgentId -Role $Role -Token $Token 2>&1 | ConvertFrom-Json
if ($tokenResult.status -ne "valid") { throw "TOKEN_INVALID: $($tokenResult.reason)" }

# --- Check task state ---
$tasksFile = Join-Path $RunDir "TASKS.json"
$tasks = Get-Content $tasksFile -Raw -Encoding UTF8 | ConvertFrom-Json
$task = $tasks.tasks | Where-Object { $_.taskId -eq $TaskId }
if (-not $task) { throw "Task '$TaskId' not found" }
if ($task.status -notin @("ready","pending")) { throw "Task '$TaskId' status is '$($task.status)'" }

# Dependency check
if ($task.dependencies) {
    foreach ($depId in $task.dependencies) {
        $dep = $tasks.tasks | Where-Object { $_.taskId -eq $depId }
        if (-not $dep -or $dep.status -ne "verified") { throw "Dependency '$depId' not verified" }
    }
}

# Path conflict check
$ownership = @{}
$ownerFile = Join-Path $RunDir "OWNERSHIP.json"
if (Test-Path $ownerFile) { $ownership = (Get-Content $ownerFile -Raw -Encoding UTF8 | ConvertFrom-Json).ownership }

$inProgress = $tasks.tasks | Where-Object { $_.status -eq "in_progress" -and $_.owner -ne $AgentId }
foreach ($ipt in $inProgress) {
    foreach ($ap in $task.allowedPaths) {
        foreach ($ip in $ipt.allowedPaths) {
            if ($ap -like $ip -or $ip -like $ap) { throw "Path conflict: '$ap' with '$($ipt.taskId)'" }
        }
    }
}

# Agent not over-allocated
if (($tasks.tasks | Where-Object { $_.status -eq "in_progress" -and $_.owner -eq $AgentId }).Count -gt 0) {
    throw "Agent '$AgentId' already has active task"
}

# Claim
$task | Add-Member -NotePropertyName status -NotePropertyValue "in_progress" -Force
$task | Add-Member -NotePropertyName owner -NotePropertyValue $AgentId -Force
$task | Add-Member -NotePropertyName startedAt -NotePropertyValue (Get-Date).ToString("o") -Force
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($tasksFile, ($tasks | ConvertTo-Json -Depth 6), $utf8)

# Generate authorization proof (Phase 6A.3)
$eventData = [ordered]@{ event="task_claimed"; taskId=$TaskId; actor=$AgentId; role=$Role }
$eventCanonical = ($eventData | ConvertTo-Json -Compress -Depth 6)
$proofResult = & (Join-Path $PSScriptRoot "token-lease.ps1") -Action sign -RunId (Split-Path $RunDir -Leaf) -TaskId $TaskId -Token $Token -Operation "task_claimed" -EventCanonicalJson $eventCanonical 2>&1 | ConvertFrom-Json
if (-not $proofResult -or $proofResult.status -ne "signed") { throw "PROOF_GENERATION_FAILED: $($proofResult.reason)" }

# Record event with authorization proof
& (Join-Path $PSScriptRoot "append-hash-event.ps1") -RunDir $RunDir -EventData @{
    event = "task_claimed"
    taskId = $TaskId
    actor = $AgentId
    role = $Role
    authorizationProof = $proofResult.authorizationProof
    tokenLeaseId = $proofResult.tokenLeaseId
    proofNonce = $proofResult.nonce
    tokenIssuedAt = $proofResult.issuedAt
    tokenExpiresAt = $proofResult.expiresAt
}

Write-Output (@{ status="claimed"; taskId=$TaskId; agentId=$AgentId } | ConvertTo-Json)
