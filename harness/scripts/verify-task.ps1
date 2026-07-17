# Verify Task — Test Agent task verification with authorization proof
# Phase 6B-R5: Only Test Agent can verify. Must sync TASKS.json AND event.
param(
    [Parameter(Mandatory=$true)][string]$TaskId,
    [Parameter(Mandatory=$true)][string]$AgentId,
    [Parameter(Mandatory=$true)][string]$Role,
    [Parameter(Mandatory=$true)][string]$Token,
    [Parameter(Mandatory=$false)][string]$RunDir
)

$ErrorActionPreference = "Stop"
$HarnessRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if (-not $RunDir) {
    $ar = Get-Content (Join-Path $HarnessRoot "runtime\active-run.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $RunDir = Join-Path $HarnessRoot "runs" $ar.activeRunId
}

$RunId = Split-Path $RunDir -Leaf

# --- 1. TOKEN VALIDATION: must be test-agent with task_verified operation ---
if (-not $Token) { throw "TOKEN_REQUIRED: verify-task requires -Token" }
$tokenResult = & (Join-Path $PSScriptRoot "token-lease.ps1") -Action validate -RunId $RunId -TaskId $TaskId -AgentId $AgentId -Role $Role -Token $Token 2>&1 | ConvertFrom-Json
if ($tokenResult.status -ne "valid") { throw "TOKEN_INVALID: $($tokenResult.reason)" }
if ($Role -ne "test-agent") { throw "ROLE_REJECTED: Only test-agent can verify tasks. Got: $Role" }

# --- 2. Check task status is candidate_complete ---
$tasksFile = Join-Path $RunDir "TASKS.json"
if (-not (Test-Path $tasksFile)) { throw "TASKS.json not found" }
$tasks = Get-Content $tasksFile -Raw -Encoding UTF8 | ConvertFrom-Json
$task = $tasks.tasks | Where-Object { $_.taskId -eq $TaskId }
if (-not $task) { throw "Task '$TaskId' not found in TASKS.json" }
if ($task.status -ne "candidate_complete") { throw "Task '$TaskId' status is '$($task.status)', not candidate_complete" }

# --- 3. Verify all required acceptance items are PASS ---
$acceptFile = Join-Path $RunDir "ACCEPTANCE.json"
if (-not (Test-Path $acceptFile)) { throw "ACCEPTANCE.json not found" }
$accept = Get-Content $acceptFile -Raw -Encoding UTF8 | ConvertFrom-Json
$taskAcceptanceIds = @($task.acceptanceIds)
if ($taskAcceptanceIds.Count -eq 0) { throw "Task '$TaskId' has no acceptanceIds" }

foreach ($acId in $taskAcceptanceIds) {
    $acItem = $accept.acceptanceItems | Where-Object { $_.id -eq $acId }
    if (-not $acItem) { throw "Acceptance item '$acId' not found in ACCEPTANCE.json" }
    if (-not $acItem.required) { continue }
    
    $acStatus = $acItem.status
    $evidenceDir = Join-Path $RunDir "evidence"
    
    if ($acItem.evidencePath -and (Test-Path (Join-Path $RunDir $acItem.evidencePath))) {
        $ep = Join-Path $RunDir $acItem.evidencePath
        try {
            $ev = Get-Content $ep -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($ev.failedCount -and [int]$ev.failedCount -gt 0) { $acStatus = "failed" }
            elseif ($ev.totalTests -and $ev.passedTests -and [int]$ev.passedTests -lt [int]$ev.totalTests) { $acStatus = "failed" }
            elseif ($ev.failures -and @($ev.failures).Count -gt 0) { $acStatus = "failed" }
            elseif ($ev.exitCode -and [int]$ev.exitCode -ne 0) { $acStatus = "failed" }
        } catch {}
    }
    
    $acResultFile = Join-Path $evidenceDir "$acId-result.json"
    if (Test-Path $acResultFile) {
        try {
            $vr = Get-Content $acResultFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($vr.status -and $vr.status -ne "passed") { $acStatus = "failed" }
            if ($vr.exitCode -and [int]$vr.exitCode -ne 0) { $acStatus = "failed" }
        } catch {}
    }
    
    if ($acStatus -ne "pass" -and $acStatus -ne "passed") {
        throw "Acceptance '$acId' has not passed (status=$acStatus). All required acceptance must be PASS before task verification."
    }
}

# --- 3.5. Emit validation_started / validation_passed events per acceptance item ---
# Phase 6C-H-R1 v2: Each required acceptance item must have validation lifecycle events
# with authorization proofs that validate-state.ps1 can verify.
# CRITICAL: timestamp is NOT included in the canonical JSON for signing because
# validate-state.ps1 strips timestamp during proof verification.
foreach ($acId in $taskAcceptanceIds) {
    $acItem = $accept.acceptanceItems | Where-Object { $_.id -eq $acId }
    if (-not $acItem -or -not $acItem.required) { continue }

    # validation_started
    $vsEventData = [ordered]@{ event = "validation_started"; taskId = $TaskId; validationId = $acId; actor = $AgentId; role = $Role }
    $vsCanonical = ($vsEventData | ConvertTo-Json -Compress -Depth 6)
    $vsProof = & (Join-Path $PSScriptRoot "token-lease.ps1") -Action sign -RunId $RunId -TaskId $TaskId -Token $Token -Operation "validation_started" -EventCanonicalJson $vsCanonical 2>&1 | ConvertFrom-Json
    if (-not $vsProof -or $vsProof.status -ne "signed") { throw "PROOF_GENERATION_FAILED (validation_started): $($vsProof.reason)" }

    & (Join-Path $PSScriptRoot "append-hash-event.ps1") -RunDir $RunDir -EventData @{
        event = "validation_started"
        taskId = $TaskId
        validationId = $acId
        actor = $AgentId
        role = $Role
        authorizationProof = $vsProof.authorizationProof
        tokenLeaseId = $vsProof.tokenLeaseId
        proofNonce = $vsProof.nonce
        tokenIssuedAt = $vsProof.issuedAt
        tokenExpiresAt = $vsProof.expiresAt
    }

    # validation_passed
    $vpEventData = [ordered]@{ event = "validation_passed"; taskId = $TaskId; validationId = $acId; actor = $AgentId; role = $Role }
    $vpCanonical = ($vpEventData | ConvertTo-Json -Compress -Depth 6)
    $vpProof = & (Join-Path $PSScriptRoot "token-lease.ps1") -Action sign -RunId $RunId -TaskId $TaskId -Token $Token -Operation "validation_passed" -EventCanonicalJson $vpCanonical 2>&1 | ConvertFrom-Json
    if (-not $vpProof -or $vpProof.status -ne "signed") { throw "PROOF_GENERATION_FAILED (validation_passed): $($vpProof.reason)" }

    & (Join-Path $PSScriptRoot "append-hash-event.ps1") -RunDir $RunDir -EventData @{
        event = "validation_passed"
        taskId = $TaskId
        validationId = $acId
        actor = $AgentId
        role = $Role
        authorizationProof = $vpProof.authorizationProof
        tokenLeaseId = $vpProof.tokenLeaseId
        proofNonce = $vpProof.nonce
        tokenIssuedAt = $vpProof.issuedAt
        tokenExpiresAt = $vpProof.expiresAt
    }
}

# --- 4. Update TASKS.json: status → verified ---
$task | Add-Member -NotePropertyName status -NotePropertyValue "verified" -Force
$task | Add-Member -NotePropertyName verifiedAt -NotePropertyValue (Get-Date).ToString("o") -Force
$task | Add-Member -NotePropertyName verifiedBy -NotePropertyValue $AgentId -Force
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($tasksFile, ($tasks | ConvertTo-Json -Depth 6), $utf8)

# --- 5. Generate authorization proof ---
$eventData = [ordered]@{ event="task_verified"; taskId=$TaskId; actor=$AgentId; role=$Role }
$eventCanonical = ($eventData | ConvertTo-Json -Compress -Depth 6)
$proofResult = & (Join-Path $PSScriptRoot "token-lease.ps1") -Action sign -RunId $RunId -TaskId $TaskId -Token $Token -Operation "task_verified" -EventCanonicalJson $eventCanonical 2>&1 | ConvertFrom-Json
if (-not $proofResult -or $proofResult.status -ne "signed") { throw "PROOF_GENERATION_FAILED: $($proofResult.reason)" }

# --- 6. Append hash-chained event ---
$appendResult = & (Join-Path $PSScriptRoot "append-hash-event.ps1") -RunDir $RunDir -EventData @{
    event = "task_verified"
    taskId = $TaskId
    actor = $AgentId
    role = $Role
    authorizationProof = $proofResult.authorizationProof
    tokenLeaseId = $proofResult.tokenLeaseId
    proofNonce = $proofResult.nonce
    tokenIssuedAt = $proofResult.issuedAt
    tokenExpiresAt = $proofResult.expiresAt
}

Write-Output (@{ status="verified"; taskId=$TaskId; agentId=$AgentId } | ConvertTo-Json)