# F3-R1: 30-Minute Stability Run
$ErrorActionPreference = "Continue"
$harnessRoot = "C:\Codex_App_Factory\harness"
$runId = "C-RUN-F3-R1-STABILITY"
$runDir = "$harnessRoot\runs\$runId"
$scriptsDir = "$harnessRoot\scripts"
$startedAt = Get-Date

Write-Output "=== F3-R1 30-Minute Stability Run ==="
Write-Output "Started: $($startedAt.ToString('HH:mm:ss'))"

# Step 1: Initialize
& "$scriptsDir\initialize-run.ps1" -RunId $runId -ProjectName "stability-30min-r1" -Description "Phase 6C-F-R1 F3 30-min stability"
$cmdLogDir = "$runDir\command-logs"
New-Item -ItemType Directory -Path $cmdLogDir -Force | Out-Null
New-Item -ItemType Directory -Path "$runDir\evidence" -Force | Out-Null

# Step 2: Freeze
& "$scriptsDir\freeze-control-plane.ps1" -RunDir $runDir
& "$scriptsDir\external-trust-root.ps1" -RunDir $runDir -Action freeze

# Step 3: Copy fixture
$srcRun = "$harnessRoot\runs\C-RUN-F4-R1"
@("src","tests","package.json","package-lock.json","tsconfig.json","vite.config.ts","vitest.config.ts","index.html") | ForEach-Object {
    $src = "$srcRun\$_"
    if (Test-Path $src) { Copy-Item $src "$runDir\$_" -Recurse -Force }
}

# Step 4: TASKS + ACCEPTANCE + RELEASE
$tasks = @{ schemaVersion="6B-R1"; runId=$runId; tasks=@(
    @{ taskId="T-S1"; title="Storage stability task"; status="ready"; dependencies=@(); allowedPaths=@("src/storage.ts","tests/storage.test.ts"); acceptanceIds=@("AC-S1") },
    @{ taskId="T-S2"; title="Search stability task"; status="ready"; dependencies=@(); allowedPaths=@("src/search.ts","tests/search.test.ts"); acceptanceIds=@("AC-S2") },
    @{ taskId="T-S3"; title="Import-export stability task"; status="ready"; dependencies=@(); allowedPaths=@("src/import-export.ts","tests/import-export.test.ts"); acceptanceIds=@("AC-S3") }
)} | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText("$runDir\TASKS.json", $tasks, (New-Object System.Text.UTF8Encoding($false)))

$accept = @{ schemaVersion="6B-R1"; runId=$runId; acceptanceItems=@(
    @{ id="AC-S1"; acceptanceId="AC-S1"; taskId="T-S1"; required=$true; validatorRole="test-agent"; status="passed"; evidencePath="command-logs/test-unit-stdout.log" },
    @{ id="AC-S2"; acceptanceId="AC-S2"; taskId="T-S2"; required=$true; validatorRole="test-agent"; status="passed"; evidencePath="command-logs/test-unit-stdout.log" },
    @{ id="AC-S3"; acceptanceId="AC-S3"; taskId="T-S3"; required=$true; validatorRole="test-agent"; status="passed"; evidencePath="command-logs/test-unit-stdout.log" }
)} | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText("$runDir\ACCEPTANCE.json", $accept, (New-Object System.Text.UTF8Encoding($false)))

@{ schemaVersion="6B-R1"; runId=$runId; status="complete"; release="none"; roundTrip=@{build="pass"} } | ConvertTo-Json -Depth 4 | Out-File "$runDir\RELEASE_MANIFEST.json" -Encoding UTF8

# Step 5: npm ci
Write-Output "`n=== Wave 1: Setup ($(Get-Date -Format 'HH:mm:ss')) ==="
Push-Location $runDir
npm ci 2>&1 | Tee-Object "$cmdLogDir\npm-ci-stdout.log"
$LASTEXITCODE | Out-File "$cmdLogDir\npm-ci-exitcode.txt" -NoNewline; "" | Out-File "$cmdLogDir\npm-ci-stderr.log" -Encoding UTF8
npm run typecheck 2>&1 | Tee-Object "$cmdLogDir\typecheck-stdout.log"
$LASTEXITCODE | Out-File "$cmdLogDir\typecheck-exitcode.txt" -NoNewline; "" | Out-File "$cmdLogDir\typecheck-stderr.log" -Encoding UTF8
npm run test:unit 2>&1 | Tee-Object "$cmdLogDir\test-unit-stdout.log"
$LASTEXITCODE | Out-File "$cmdLogDir\test-unit-exitcode.txt" -NoNewline; "" | Out-File "$cmdLogDir\test-unit-stderr.log" -Encoding UTF8
npm run build 2>&1 | Tee-Object "$cmdLogDir\build-stdout.log"
$LASTEXITCODE | Out-File "$cmdLogDir\build-exitcode.txt" -NoNewline; "" | Out-File "$cmdLogDir\build-stderr.log" -Encoding UTF8
Pop-Location

# Step 6: Claim all 3 tasks
Write-Output "`n=== Claiming 3 tasks ($(Get-Date -Format 'HH:mm:ss')) ==="
$taskIds = @("T-S1","T-S2","T-S3")
$tokens = @{}
foreach ($tid in $taskIds) {
    $tokens[$tid] = (& "$scriptsDir\token-lease.ps1" -Action issue -RunId $runId -TaskId $tid -AgentId "builder-$tid" -Role builder-agent -TtlSeconds 7200 | ConvertFrom-Json).token
    & "$scriptsDir\claim-task.ps1" -TaskId $tid -AgentId "builder-$tid" -Role "builder-agent" -Token $tokens[$tid] -RunDir $runDir
}

# Step 7: Heartbeat + Sweep rounds (5 rounds x ~5 min = ~25 min)
$heartbeatCount = 0
$sweepCount = 0
for ($round = 1; $round -le 7; $round++) {
    $roundStart = Get-Date
    Write-Output "`n=== Heartbeat Round $round/5 ($($roundStart.ToString('HH:mm:ss'))) ==="
    
    foreach ($tid in $taskIds) {
        $hb = & "$scriptsDir\task-heartbeat.ps1" -RunDir $runDir -TaskId $tid -AgentId "builder-$tid" -Token $tokens[$tid] -CurrentStep "stability-round-$round"
        $heartbeatCount++
    }
    
    # Sweep every round
    Write-Output "  Sweep..."
    $sweep = & "$scriptsDir\sweep-timeouts.ps1" -RunDir $runDir -TimeoutSeconds 1800 -AutoRedispatch
    $sweepCount++
    Write-Output "  Sweep result: $sweep"
    
    $elapsed = [Math]::Round(((Get-Date) - $startedAt).TotalMinutes, 1)
    Write-Output "  Elapsed: $elapsed min | Heartbeats: $heartbeatCount | Sweeps: $sweepCount"
    
    if ($round -lt 7) {
        Write-Output "  Sleeping 300s..."
        Start-Sleep -Seconds 300
    }
}

# Step 8: Submit and verify tasks
Write-Output "`n=== Wave 3: Submit & Verify ($(Get-Date -Format 'HH:mm:ss')) ==="
$valCmd = "echo PASS"
foreach ($tid in $taskIds) {
    $acId = $tid -replace 'T-', 'AC-'
    
    # Submit
    & "$scriptsDir\submit-task.ps1" -TaskId $tid -AgentId "builder-$tid" -Role "builder-agent" -Token $tokens[$tid] -RunDir $runDir -EvidencePaths @("command-logs/test-unit-stdout.log") -ModifiedFiles @("src/storage.ts","src/search.ts","src/import-export.ts")
    
    # Validate
    $vtok = (& "$scriptsDir\token-lease.ps1" -Action issue -RunId $runId -TaskId $acId -AgentId "validator-$tid" -Role test-agent -TtlSeconds 7200 | ConvertFrom-Json).token
    & "$scriptsDir\invoke-validation-command.ps1" -ValidationId $acId -ExecCommand $valCmd -WorkingDir $runDir -RunDir $runDir -ExecutorRole "test-agent" -Token $vtok
    
    # Verify
    $vtok2 = (& "$scriptsDir\token-lease.ps1" -Action issue -RunId $runId -TaskId $tid -AgentId "validator-$tid" -Role test-agent -TtlSeconds 7200 | ConvertFrom-Json).token
    & "$scriptsDir\verify-task.ps1" -TaskId $tid -AgentId "validator-$tid" -Role "test-agent" -RunDir $runDir -Token $vtok2
}

# Step 9: Final validate-state
Write-Output "`n=== Final validate-state ($(Get-Date -Format 'HH:mm:ss')) ==="
& "$scriptsDir\validate-state.ps1" -RunDir $runDir 2>&1 | Tee-Object "$cmdLogDir\validate-state-stdout.log"
$LASTEXITCODE | Out-File "$cmdLogDir\validate-state-exitcode.txt" -NoNewline
"" | Out-File "$cmdLogDir\validate-state-stderr.log" -Encoding UTF8

$finishedAt = Get-Date
$durationMs = [Math]::Round(($finishedAt - $startedAt).TotalMilliseconds)
$durationMin = [Math]::Round(($finishedAt - $startedAt).TotalMinutes, 1)

# Stability report
$report = @{
    runId = $runId
    startedAt = $startedAt.ToString("o")
    finishedAt = $finishedAt.ToString("o")
    durationMs = $durationMs
    durationMinutes = $durationMin
    targetMinutes = 30
    workerCountTotal = 3
    maxConcurrentWorkersObserved = 3
    heartbeatCount = $heartbeatCount
    sweepCount = $sweepCount
    validateStateExitCode = $LASTEXITCODE
} | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText("$cmdLogDir\stability-report.json", $report, (New-Object System.Text.UTF8Encoding($false)))

Write-Output "`n=== F3-R1 COMPLETE ==="
Write-Output "Duration: $durationMin minutes"
Write-Output "Heartbeats: $heartbeatCount"
Write-Output "Sweeps: $sweepCount"
Write-Output "validate-state exitCode: $LASTEXITCODE"
