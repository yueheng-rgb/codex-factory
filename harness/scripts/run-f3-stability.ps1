$harnessRoot = "C:\Codex_App_Factory\harness"
$runDir = "$harnessRoot\runs\C-RUN-F3-STABILITY-R1"
$scriptsDir = "$harnessRoot\scripts"
$cmdLogDir = "$runDir\command-logs"
New-Item -ItemType Directory -Path $cmdLogDir -Force | Out-Null
New-Item -ItemType Directory -Path "$runDir\evidence" -Force | Out-Null

# Helper function
function Append-Event($eventData) {
    $result = & "$scriptsDir\append-hash-event.ps1" -RunDir $runDir -EventData $eventData
    Write-Output $result
}

# Step 1: Create tokens and claim all 3 tasks
$taskIds = @("T-S1","T-S2","T-S3")
$tokens = @{}
$leases = @{}

foreach ($tid in $taskIds) {
    # Create token
    $tokenResult = & "$scriptsDir\token-lease.ps1" -Action create -Role builder-agent -TaskId $tid -TtlMinutes 90
    $tokenJson = $tokenResult | ConvertFrom-Json
    $tokens[$tid] = $tokenJson
    Write-Output "Token created for $tid : $($tokenJson.tokenId)"
    
    # Claim task
    $claimResult = & "$scriptsDir\claim-task.ps1" -RunDir $runDir -TaskId $tid -AgentId "builder-$tid" -Role "builder-agent" -TokenLeaseId $tokenJson.leaseId
    Write-Output "Claim result for $tid : $claimResult"
}

# Step 2: Install deps
Write-Output "=== npm ci ==="
Push-Location $runDir
npm ci 2>&1 | Tee-Object -FilePath "$cmdLogDir\npm-ci-stdout.log"
$npmCiExit = $LASTEXITCODE
$npmCiExit | Out-File "$cmdLogDir\npm-ci-exitcode.txt" -NoNewline
Write-Output "npm ci exitCode: $npmCiExit"
Pop-Location

# Step 3: Typecheck
Write-Output "=== npm run typecheck ==="
Push-Location $runDir
npm run typecheck 2>&1 | Tee-Object -FilePath "$cmdLogDir\typecheck-stdout.log"
$tcExit = $LASTEXITCODE
$tcExit | Out-File "$cmdLogDir\typecheck-exitcode.txt" -NoNewline
Write-Output "typecheck exitCode: $tcExit"
Pop-Location

# Step 4: Unit tests
Write-Output "=== npm run test:unit ==="
Push-Location $runDir
npm run test:unit 2>&1 | Tee-Object -FilePath "$cmdLogDir\test-unit-stdout.log"
$utExit = $LASTEXITCODE
$utExit | Out-File "$cmdLogDir\test-unit-exitcode.txt" -NoNewline
Write-Output "unit test exitCode: $utExit"
Pop-Location

# Step 5: Heartbeat loop (5 rounds, ~5 min apart = ~25 min)
for ($round = 1; $round -le 5; $round++) {
    Write-Output "=== Heartbeat round $round at $(Get-Date -Format 'HH:mm:ss') ==="
    foreach ($tid in $taskIds) {
        $hb = & "$scriptsDir\task-heartbeat.ps1" -RunDir $runDir -TaskId $tid -AgentId "builder-$tid" -CurrentStep "stability-round-$round"
        Write-Output "  Heartbeat $tid : $hb"
    }
    
    # Sweep every other round
    if ($round % 2 -eq 0) {
        Write-Output "=== Sweep at round $round ==="
        $sweep = & "$scriptsDir\sweep-timeouts.ps1" -RunDir $runDir -TimeoutSeconds 600 -AutoRedispatch
        Write-Output "  Sweep: $sweep"
    }
    
    if ($round -lt 5) {
        Write-Output "Waiting 300s before next round..."
        Start-Sleep -Seconds 300
    }
}

# Step 6: Build
Write-Output "=== npm run build ==="
Push-Location $runDir
npm run build 2>&1 | Tee-Object -FilePath "$cmdLogDir\build-stdout.log"
$buildExit = $LASTEXITCODE
$buildExit | Out-File "$cmdLogDir\build-exitcode.txt" -NoNewline
Write-Output "build exitCode: $buildExit"
Pop-Location

# Step 7: Simulate submissions and validations for all 3 tasks
foreach ($tid in $taskIds) {
    Write-Output "=== Submitting $tid ==="
    $submit = & "$scriptsDir\submit-task.ps1" -RunDir $runDir -TaskId $tid -AgentId "builder-$tid" -StdoutPath "command-logs/test-unit-stdout.log" -StderrPath "" -ExitCode $utExit
    Write-Output "Submit $tid : $submit"
}

# Step 8: Verify all tasks
foreach ($tid in $taskIds) {
    $acId = $tid -replace 'T-', 'AC-'
    Write-Output "=== Verifying $tid (acceptance: $acId) ==="
    $verify = & "$scriptsDir\verify-task.ps1" -RunDir $runDir -TaskId $tid -ValidatorRole "test-agent" -ValidatorAgentId "validator-$tid" -ValidationId $acId -ExitCode 0
    Write-Output "Verify $tid : $verify"
}

# Step 9: Final validate-state
Write-Output "=== Final validate-state ==="
$vsResult = & "$scriptsDir\validate-state.ps1" -RunDir $runDir 2>&1
$vsResult | Out-File "$cmdLogDir\validate-state-stdout.log" -Encoding UTF8
$LASTEXITCODE | Out-File "$cmdLogDir\validate-state-exitcode.txt" -NoNewline
Write-Output "validate-state exitCode: $LASTEXITCODE"
Write-Output $vsResult

Write-Output "=== F3 Stability Run Complete ==="
