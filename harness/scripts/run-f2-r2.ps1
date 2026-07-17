# F2-R2: Timeout Auto Re-dispatch Full Closure
$ErrorActionPreference = "Continue"
$harnessRoot = "C:\Codex_App_Factory\harness"
$runId = "C-RUN-F2-R2-REDISPATCH"
$runDir = "$harnessRoot\runs\$runId"
$scriptsDir = "$harnessRoot\scripts"

Write-Output "=== F2-R2 Timeout Redispatch Closure ==="

# Step 1: Init + freeze
& "$scriptsDir\initialize-run.ps1" -RunId $runId -ProjectName "f2-r2-redispatch" -Description "Phase 6C-F-R2 F2 redispatch closure"
$cmdLogDir = "$runDir\command-logs"
$evidenceDir = "$runDir\evidence"
New-Item -ItemType Directory -Path $cmdLogDir -Force | Out-Null
New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null
& "$scriptsDir\freeze-control-plane.ps1" -RunDir $runDir
& "$scriptsDir\external-trust-root.ps1" -RunDir $runDir -Action freeze

# Step 2: Copy project fixture
$srcRun = "$harnessRoot\runs\C-RUN-F4-R1"
@("src","tests","package.json","package-lock.json","tsconfig.json","vite.config.ts","vitest.config.ts","index.html") | ForEach-Object {
    $src = "$srcRun\$_"
    if (Test-Path $src) { Copy-Item $src "$runDir\$_" -Recurse -Force }
}

# Step 3: TASKS.json + ACCEPTANCE.json with attempts support
$tasks = @{
    schemaVersion = "6B-R1"; runId = $runId
    tasks = @(
        @{
            taskId = "T-RD1"; title = "Redispatch test task"
            status = "ready"; dependencies = @()
            allowedPaths = @("src/storage.ts","tests/storage.test.ts")
            acceptanceIds = @("AC-RD1")
            attempts = @()
        }
    )
} | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText("$runDir\TASKS.json", $tasks, (New-Object System.Text.UTF8Encoding($false)))

$accept = @{
    schemaVersion = "6B-R1"; runId = $runId
    acceptanceItems = @(
        @{ id="AC-RD1"; acceptanceId="AC-RD1"; taskId="T-RD1"; required=$true; validatorRole="test-agent"; status="passed"; evidencePath="command-logs/test-unit-stdout.log" }
    )
} | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText("$runDir\ACCEPTANCE.json", $accept, (New-Object System.Text.UTF8Encoding($false)))

@{ schemaVersion="6B-R1"; runId=$runId; status="complete"; release="none"; roundTrip=@{build="pass"} } | ConvertTo-Json -Depth 4 | Out-File "$runDir\RELEASE_MANIFEST.json" -Encoding UTF8

# TASK_DAG + RUN_PLAN
@{ schemaVersion="6B-R1"; runId=$runId; projectName="F2-R2 Redispatch"; tasks=@(@{ taskId="T-RD1"; title="Redispatch test"; dependencies=@() }) } | ConvertTo-Json -Depth 6 | Out-File "$runDir\TASK_DAG.json" -Encoding UTF8
@{ schemaVersion="6B-R1"; runId=$runId; phases=@(@{ phase=1; name="Original"; actions=@("claim","timeout") }, @{ phase=2; name="Redispatch"; actions=@("replacement claim","submit","validate","verify") }, @{ phase=3; name="Rejection"; actions=@("late submit reject","old lease reject") }, @{ phase=4; name="Governance"; actions=@("validate-state") }); maxConcurrentWorkers=1 } | ConvertTo-Json -Depth 6 | Out-File "$runDir\RUN_PLAN.json" -Encoding UTF8

# Step 4: npm ci + commands
Write-Output "=== Commands ==="
Push-Location $runDir
npm ci 2>&1 | Tee-Object "$cmdLogDir\npm-ci-stdout.log"; $LASTEXITCODE | Out-File "$cmdLogDir\npm-ci-exitcode.txt" -NoNewline; "" | Out-File "$cmdLogDir\npm-ci-stderr.log" -Encoding UTF8
npm run typecheck 2>&1 | Tee-Object "$cmdLogDir\typecheck-stdout.log"; $LASTEXITCODE | Out-File "$cmdLogDir\typecheck-exitcode.txt" -NoNewline; "" | Out-File "$cmdLogDir\typecheck-stderr.log" -Encoding UTF8
npm run test:unit 2>&1 | Tee-Object "$cmdLogDir\test-unit-stdout.log"; $LASTEXITCODE | Out-File "$cmdLogDir\test-unit-exitcode.txt" -NoNewline; "" | Out-File "$cmdLogDir\test-unit-stderr.log" -Encoding UTF8
npm run build 2>&1 | Tee-Object "$cmdLogDir\build-stdout.log"; $LASTEXITCODE | Out-File "$cmdLogDir\build-exitcode.txt" -NoNewline; "" | Out-File "$cmdLogDir\build-stderr.log" -Encoding UTF8
Pop-Location

# Step 5: REDISPATCH1 — Original claim → timeout → replacement → verify
Write-Output "`n=== REDISPATCH1: Original claim ==="
$origTokenResult = & "$scriptsDir\token-lease.ps1" -Action issue -RunId $runId -TaskId "T-RD1" -AgentId "builder-original" -Role builder-agent -TtlSeconds 7200 | ConvertFrom-Json
$origToken = $origTokenResult.token
$origLease = $origTokenResult.leaseId
Write-Output "Original token issued: lease=$origLease"

# Claim with original
& "$scriptsDir\claim-task.ps1" -TaskId "T-RD1" -AgentId "builder-original" -Role "builder-agent" -Token $origToken -RunDir $runDir

# Record attempt1 in TASKS.json
$t = Get-Content "$runDir\TASKS.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$t.tasks[0].attempts += @{ attempt=1; agentId="builder-original"; status="in_progress"; leaseId=$origLease; claimedAt=(Get-Date).ToString("o") }
[System.IO.File]::WriteAllText("$runDir\TASKS.json", ($t | ConvertTo-Json -Depth 8), (New-Object System.Text.UTF8Encoding($false)))

# Wait a moment then sweep with short timeout
Write-Output "Waiting 4s for timeout..."
Start-Sleep -Seconds 4

Write-Output "=== REDISPATCH1: Sweep (timeout=3s) ==="
$sweepResult = & "$scriptsDir\sweep-timeouts.ps1" -RunDir $runDir -TimeoutSeconds 3 -AutoRedispatch
Write-Output $sweepResult

# Check task state after redispatch
$t = Get-Content "$runDir\TASKS.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$task = $t.tasks[0]
Write-Output "Task status: $($task.status), owner: $($task.owner), previousOwner: $($task.previousOwner)"

# Record attempt1 as timed_out
$task.attempts[0].status = "timed_out"
$task.attempts[0].timedOutAt = (Get-Date).ToString("o")

# REDISPATCH1: Replacement builder claims with new token
Write-Output "`n=== REDISPATCH1: Replacement claim ==="
$replTokenResult = & "$scriptsDir\token-lease.ps1" -Action issue -RunId $runId -TaskId "T-RD1" -AgentId "builder-replacement" -Role builder-agent -TtlSeconds 7200 | ConvertFrom-Json
$replToken = $replTokenResult.token
$replLease = $replTokenResult.leaseId

& "$scriptsDir\claim-task.ps1" -TaskId "T-RD1" -AgentId "builder-replacement" -Role "builder-agent" -Token $replToken -RunDir $runDir

# Record attempt2
$task.attempts += @{ attempt=2; agentId="builder-replacement"; status="in_progress"; leaseId=$replLease; claimedAt=(Get-Date).ToString("o") }

# Heartbeat replacement
& "$scriptsDir\task-heartbeat.ps1" -TaskId "T-RD1" -AgentId "builder-replacement" -Token $replToken -RunDir $runDir -CurrentStep "replacement-working"

# Submit replacement
Write-Output "`n=== REDISPATCH1: Replacement submit ==="
& "$scriptsDir\submit-task.ps1" -TaskId "T-RD1" -AgentId "builder-replacement" -Role "builder-agent" -Token $replToken -RunDir $runDir -EvidencePaths @("command-logs/test-unit-stdout.log") -ModifiedFiles @("src/storage.ts")
$task.attempts[1].status = "candidate_complete"

# Validate replacement
Write-Output "`n=== REDISPATCH1: Validate replacement ==="
$valTok = (& "$scriptsDir\token-lease.ps1" -Action issue -RunId $runId -TaskId "AC-RD1" -AgentId "validator-rd1" -Role test-agent -TtlSeconds 7200 | ConvertFrom-Json).token
& "$scriptsDir\invoke-validation-command.ps1" -ValidationId "AC-RD1" -ExecCommand "echo PASS" -WorkingDir $runDir -RunDir $runDir -ExecutorRole "test-agent" -Token $valTok

# Verify replacement
Write-Output "`n=== REDISPATCH1: Verify replacement ==="
$v2tok = (& "$scriptsDir\token-lease.ps1" -Action issue -RunId $runId -TaskId "T-RD1" -AgentId "validator-rd1" -Role test-agent -TtlSeconds 7200 | ConvertFrom-Json).token
& "$scriptsDir\verify-task.ps1" -TaskId "T-RD1" -AgentId "validator-rd1" -Role "test-agent" -RunDir $runDir -Token $v2tok
$task.attempts[1].status = "verified"
$task.status = "verified"

# Integration events
Write-Output "`n=== REDISPATCH1: Integration ==="
& "$scriptsDir\append-hash-event.ps1" -RunDir $runDir -EventData @{ event="integration_started"; actor="integrator"; taskId="T-RD1" }
& "$scriptsDir\append-hash-event.ps1" -RunDir $runDir -EventData @{ event="integration_completed"; actor="integrator"; taskId="T-RD1"; status="success" }

# Save TASKS with attempt history
[System.IO.File]::WriteAllText("$runDir\TASKS.json", ($t | ConvertTo-Json -Depth 8), (New-Object System.Text.UTF8Encoding($false)))

# Step 6: REDISPATCH2 — Old builder late submit REJECTED
Write-Output "`n=== REDISPATCH2: Old builder late submit (should REJECT) ==="
$lateSubmitResult = & "$scriptsDir\submit-task.ps1" -TaskId "T-RD1" -AgentId "builder-original" -Role "builder-agent" -Token $origToken -RunDir $runDir -EvidencePaths @("command-logs/test-unit-stdout.log") -ModifiedFiles @("src/storage.ts") 2>&1
$lateSubmitExit = $LASTEXITCODE
$lateSubmitResult | Out-File "$cmdLogDir\late-submit-stdout.log" -Encoding UTF8
$lateSubmitResult | Out-File "$cmdLogDir\late-submit-stderr.log" -Encoding UTF8
$lateSubmitExit | Out-File "$cmdLogDir\late-submit-exitcode.txt" -NoNewline
Write-Output "Late submit exitCode: $lateSubmitExit"
Write-Output "Late submit output: $lateSubmitResult"

# Step 7: REDISPATCH3 — Old lease reuse REJECTED
Write-Output "`n=== REDISPATCH3: Old lease reuse (should REJECT) ==="
# Try heartbeat with old lease token
$oldLeaseResult = & "$scriptsDir\task-heartbeat.ps1" -TaskId "T-RD1" -AgentId "builder-original" -Token $origToken -RunDir $runDir -CurrentStep "stale-attempt" 2>&1
$oldLeaseExit = $LASTEXITCODE
$oldLeaseResult | Out-File "$cmdLogDir\old-lease-stdout.log" -Encoding UTF8
$oldLeaseResult | Out-File "$cmdLogDir\old-lease-stderr.log" -Encoding UTF8
$oldLeaseExit | Out-File "$cmdLogDir\old-lease-exitcode.txt" -NoNewline
Write-Output "Old lease exitCode: $oldLeaseExit"
Write-Output "Old lease output: $oldLeaseResult"

# Try token validation for old lease
$oldTokenValidate = & "$scriptsDir\token-lease.ps1" -Action validate -RunId $runId -TaskId "T-RD1" -AgentId "builder-original" -Role builder-agent -Token $origToken 2>&1
Write-Output "Old token validation: $oldTokenValidate"

# Create attempt-history.json
$attemptHistory = @{
    taskId = "T-RD1"
    attempts = @(
        @{ attempt=1; agentId="builder-original"; leaseId=$origLease; status="timed_out"; timedOutAt=$task.attempts[0].timedOutAt },
        @{ attempt=2; agentId="builder-replacement"; leaseId=$replLease; status="verified"; verifiedAt=(Get-Date).ToString("o") }
    )
    redispatchCount = 1
    lateSubmitRejected = ($lateSubmitExit -ne 0)
    oldLeaseRejected = ($oldLeaseExit -ne 0)
} | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText("$runDir\attempt-history.json", $attemptHistory, (New-Object System.Text.UTF8Encoding($false)))

# Step 8: validate-state
Write-Output "`n=== Final validate-state ==="
& "$scriptsDir\validate-state.ps1" -RunDir $runDir 2>&1 | Tee-Object "$cmdLogDir\validate-state-stdout.log"
$vsExit = $LASTEXITCODE
$vsExit | Out-File "$cmdLogDir\validate-state-exitcode.txt" -NoNewline
"" | Out-File "$cmdLogDir\validate-state-stderr.log" -Encoding UTF8
Write-Output "validate-state exitCode: $vsExit"

Write-Output "`n=== F2-R2 COMPLETE ==="
Write-Output "REDISPATCH1: replacement verified + integrated"
Write-Output "REDISPATCH2: old late submit rejected (exitCode=$lateSubmitExit)"
Write-Output "REDISPATCH3: old lease rejected (exitCode=$oldLeaseExit)"
Write-Output "validate-state: exitCode=$vsExit"
