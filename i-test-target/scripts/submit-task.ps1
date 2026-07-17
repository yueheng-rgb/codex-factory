# Submit task as candidate_complete 閳?Phase 6A.2 with token enforcement + hash-chain
param(
    [Parameter(Mandatory=$true)][string]$TaskId,
    [Parameter(Mandatory=$true)][string]$AgentId,
    [Parameter(Mandatory=$true)][string]$Role,
    [Parameter(Mandatory=$false)][string]$Token,
    [Parameter(Mandatory=$false)][string[]]$EvidencePaths,
    [Parameter(Mandatory=$false)][string[]]$ModifiedFiles,
    [Parameter(Mandatory=$false)][string]$RunDir
)

$ErrorActionPreference = "Stop"
$HarnessRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if (-not $RunDir) {
    $ar = Get-Content (Join-Path $HarnessRoot "runtime\active-run.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $RunDir = Join-Path $HarnessRoot "runs" $ar.activeRunId
}

# --- TOKEN VALIDATION ---
if (-not $Token) { throw "TOKEN_REQUIRED" }
$tokenResult = & (Join-Path $PSScriptRoot "token-lease.ps1") -Action validate -RunId (Split-Path $RunDir -Leaf) -TaskId $TaskId -AgentId $AgentId -Role $Role -Token $Token 2>&1 | ConvertFrom-Json
if ($tokenResult.status -ne "valid") { throw "TOKEN_INVALID: $($tokenResult.reason)" }

$tasksFile = Join-Path $RunDir "TASKS.json"
$tasks = Get-Content $tasksFile -Raw -Encoding UTF8 | ConvertFrom-Json
$task = $tasks.tasks | Where-Object { $_.taskId -eq $TaskId }
if (-not $task) { throw "Task '$TaskId' not found" }
if ($task.owner -ne $AgentId) { throw "Task owned by '$($task.owner)', not '$AgentId'" }

# --- DUPLICATE SUBMISSION GUARD (Phase 6C-A2-R2) ---
if ($task.status -eq "candidate_complete") {
    & (Join-Path $PSScriptRoot "append-hash-event.ps1") -RunDir $RunDir -EventData @{
        event = "submission_rejected"
        taskId = $TaskId
        actor = $AgentId
        role = $Role
        reason = "DUPLICATE_SUBMISSION_REJECTED: task already candidate_complete"
    }
    throw "DUPLICATE_SUBMISSION_REJECTED: Task '$TaskId' already candidate_complete"
}

$task | Add-Member -NotePropertyName status -NotePropertyValue "candidate_complete" -Force
$task | Add-Member -NotePropertyName submittedAt -NotePropertyValue (Get-Date).ToString("o") -Force
$task | Add-Member -NotePropertyName evidencePaths -NotePropertyValue @($EvidencePaths) -Force
$task | Add-Member -NotePropertyName modifiedFiles -NotePropertyValue @($ModifiedFiles) -Force

$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($tasksFile, ($tasks | ConvertTo-Json -Depth 6), $utf8)

# Handoff
$handoffJson = @{ taskId=$TaskId; agentId=$AgentId; status="candidate_complete"; submittedAt=$task.submittedAt; evidencePaths=$task.evidencePaths; modifiedFiles=$task.modifiedFiles } | ConvertTo-Json -Depth 4; [System.IO.File]::WriteAllText((Join-Path $RunDir "handoffs\$TaskId-handoff.json"), $handoffJson, $utf8)

# Generate authorization proof (Phase 6A.3)
$eventData = [ordered]@{ event="task_submitted"; taskId=$TaskId; actor=$AgentId; role=$Role; status="candidate_complete" }
$eventCanonical = ($eventData | ConvertTo-Json -Compress -Depth 6)
$proofResult = & (Join-Path $PSScriptRoot "token-lease.ps1") -Action sign -RunId (Split-Path $RunDir -Leaf) -TaskId $TaskId -Token $Token -Operation "task_submitted" -EventCanonicalJson $eventCanonical 2>&1 | ConvertFrom-Json
if (-not $proofResult -or $proofResult.status -ne "signed") { throw "PROOF_GENERATION_FAILED: $($proofResult.reason)" }

# Record event with authorization proof
& (Join-Path $PSScriptRoot "append-hash-event.ps1") -RunDir $RunDir -EventData @{
    event = "task_submitted"
    taskId = $TaskId
    actor = $AgentId
    role = $Role
    status = "candidate_complete"
    authorizationProof = $proofResult.authorizationProof
    tokenLeaseId = $proofResult.tokenLeaseId
    proofNonce = $proofResult.nonce
    tokenIssuedAt = $proofResult.issuedAt
    tokenExpiresAt = $proofResult.expiresAt
}

Write-Output (@{ status="submitted"; taskId=$TaskId; agentId=$AgentId } | ConvertTo-Json)
