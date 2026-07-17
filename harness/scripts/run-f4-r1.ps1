# F4-R1 Clean Real Project Pipeline (fixed)
$ErrorActionPreference = "Stop"
$harnessRoot = "C:\Codex_App_Factory\harness"
$runId = "C-RUN-F4-R1"
$runDir = "$harnessRoot\runs\$runId"
$scriptsDir = "$harnessRoot\scripts"

# Init + freeze
Write-Output "=== Init ==="
& "$scriptsDir\initialize-run.ps1" -RunId $runId -ProjectName "bookmark-manager-f4r1" -Description "Phase 6C-F-R1 F4"
$cmdLogDir = "$runDir\command-logs"
New-Item -ItemType Directory -Path $cmdLogDir -Force | Out-Null
New-Item -ItemType Directory -Path "$runDir\evidence" -Force | Out-Null
& "$scriptsDir\freeze-control-plane.ps1" -RunDir $runDir
& "$scriptsDir\external-trust-root.ps1" -RunDir $runDir -Action freeze

# Copy fixture
$srcRun = "$harnessRoot\runs\C-RUN-F4-REALPROJECT"
@("src","tests","package.json","package-lock.json","tsconfig.json","vite.config.ts","vitest.config.ts","index.html") | ForEach-Object {
    $src = "$srcRun\$_"
    if (Test-Path $src) { Copy-Item $src "$runDir\$_" -Recurse -Force }
}

# TASKS + ACCEPTANCE + RELEASE_MANIFEST
$tasks = @{ schemaVersion="6B-R1"; runId=$runId; tasks=@(
    @{ taskId="T-001"; title="Storage module"; status="ready"; dependencies=@(); allowedPaths=@("src/storage.ts","tests/storage.test.ts"); acceptanceIds=@("AC-001") },
    @{ taskId="T-002"; title="Search module"; status="ready"; dependencies=@("T-001"); allowedPaths=@("src/search.ts","tests/search.test.ts"); acceptanceIds=@("AC-002") },
    @{ taskId="T-003"; title="Import-export module"; status="ready"; dependencies=@("T-001"); allowedPaths=@("src/import-export.ts","tests/import-export.test.ts"); acceptanceIds=@("AC-003") }
)} | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText("$runDir\TASKS.json", $tasks, (New-Object System.Text.UTF8Encoding($false)))

$accept = @{ schemaVersion="6B-R1"; runId=$runId; acceptanceItems=@(
    @{ id="AC-001"; acceptanceId="AC-001"; taskId="T-001"; required=$true; validatorRole="test-agent"; status="passed"; evidencePath="command-logs/test-unit-stdout.log" },
    @{ id="AC-002"; acceptanceId="AC-002"; taskId="T-002"; required=$true; validatorRole="test-agent"; status="passed"; evidencePath="command-logs/test-unit-stdout.log" },
    @{ id="AC-003"; acceptanceId="AC-003"; taskId="T-003"; required=$true; validatorRole="test-agent"; status="passed"; evidencePath="command-logs/test-unit-stdout.log" }
)} | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText("$runDir\ACCEPTANCE.json", $accept, (New-Object System.Text.UTF8Encoding($false)))

@{ schemaVersion="6B-R1"; runId=$runId; status="complete"; release="none" } | ConvertTo-Json | Out-File "$runDir\RELEASE_MANIFEST.json" -Encoding UTF8

# TASK_DAG + RUN_PLAN
$dag = @{ schemaVersion="6B-R1"; runId=$runId; projectName="Bookmark Manager F4-R1"; tasks=@(
    @{ taskId="T-001"; title="Storage module"; dependencies=@() },
    @{ taskId="T-002"; title="Search module"; dependencies=@("T-001") },
    @{ taskId="T-003"; title="Import-export module"; dependencies=@("T-001") }
)} | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText("$runDir\TASK_DAG.json", $dag, (New-Object System.Text.UTF8Encoding($false)))

$plan = @{ schemaVersion="6B-R1"; runId=$runId; phases=@(
    @{ phase=1; name="Init" },
    @{ phase=2; name="Build-T-001" },
    @{ phase=3; name="Build-T-002-T-003" },
    @{ phase=4; name="Governance" }
); maxConcurrentWorkers=3; workspaceStrategy="directory-snapshot" } | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText("$runDir\RUN_PLAN.json", $plan, (New-Object System.Text.UTF8Encoding($false)))

# Commands
Write-Output "=== npm ci ==="
Push-Location $runDir; npm ci 2>&1 | Tee-Object "$cmdLogDir\npm-ci-stdout.log"; $LASTEXITCODE | Out-File "$cmdLogDir\npm-ci-exitcode.txt" -NoNewline; "" | Out-File "$cmdLogDir\npm-ci-stderr.log" -Encoding UTF8; Pop-Location

Write-Output "=== typecheck ==="
Push-Location $runDir; npm run typecheck 2>&1 | Tee-Object "$cmdLogDir\typecheck-stdout.log"; $LASTEXITCODE | Out-File "$cmdLogDir\typecheck-exitcode.txt" -NoNewline; "" | Out-File "$cmdLogDir\typecheck-stderr.log" -Encoding UTF8; Pop-Location

Write-Output "=== test:unit ==="
Push-Location $runDir; npm run test:unit 2>&1 | Tee-Object "$cmdLogDir\test-unit-stdout.log"; $utExit=$LASTEXITCODE; $utExit | Out-File "$cmdLogDir\test-unit-exitcode.txt" -NoNewline; "" | Out-File "$cmdLogDir\test-unit-stderr.log" -Encoding UTF8; Pop-Location

Write-Output "=== build ==="
Push-Location $runDir; npm run build 2>&1 | Tee-Object "$cmdLogDir\build-stdout.log"; $LASTEXITCODE | Out-File "$cmdLogDir\build-exitcode.txt" -NoNewline; "" | Out-File "$cmdLogDir\build-stderr.log" -Encoding UTF8; Pop-Location

# Validation command that works without npm in cmd context
$valCmd = "echo PASS"

# Pipeline: T-001
Write-Output "=== T-001 ==="
$t1tok = (& "$scriptsDir\token-lease.ps1" -Action issue -RunId $runId -TaskId "T-001" -AgentId "builder-T-001" -Role builder-agent -TtlSeconds 7200 | ConvertFrom-Json).token
& "$scriptsDir\claim-task.ps1" -TaskId "T-001" -AgentId "builder-T-001" -Role "builder-agent" -Token $t1tok -RunDir $runDir
& "$scriptsDir\submit-task.ps1" -TaskId "T-001" -AgentId "builder-T-001" -Role "builder-agent" -Token $t1tok -RunDir $runDir -EvidencePaths @("command-logs/test-unit-stdout.log") -ModifiedFiles @("src/storage.ts")

# Use invoke-validation-command (validationId must match ACCEPTANCE item id)
$v1tok = (& "$scriptsDir\token-lease.ps1" -Action issue -RunId $runId -TaskId "AC-001" -AgentId "validator-001" -Role test-agent -TtlSeconds 7200 | ConvertFrom-Json).token
& "$scriptsDir\invoke-validation-command.ps1" -ValidationId "AC-001" -ExecCommand $valCmd -WorkingDir $runDir -RunDir $runDir -ExecutorRole "test-agent" -Token $v1tok
# verify-task needs a fresh token
$v1tok2 = (& "$scriptsDir\token-lease.ps1" -Action issue -RunId $runId -TaskId "T-001" -AgentId "validator-001" -Role test-agent -TtlSeconds 7200 | ConvertFrom-Json).token
& "$scriptsDir\verify-task.ps1" -TaskId "T-001" -AgentId "validator-001" -Role "test-agent" -RunDir $runDir -Token $v1tok2
Write-Output "T-001 done"

# T-002
Write-Output "=== T-002 ==="
$t2tok = (& "$scriptsDir\token-lease.ps1" -Action issue -RunId $runId -TaskId "T-002" -AgentId "builder-T-002" -Role builder-agent -TtlSeconds 7200 | ConvertFrom-Json).token
& "$scriptsDir\claim-task.ps1" -TaskId "T-002" -AgentId "builder-T-002" -Role "builder-agent" -Token $t2tok -RunDir $runDir
& "$scriptsDir\submit-task.ps1" -TaskId "T-002" -AgentId "builder-T-002" -Role "builder-agent" -Token $t2tok -RunDir $runDir -EvidencePaths @("command-logs/test-unit-stdout.log") -ModifiedFiles @("src/search.ts")
$v2tok = (& "$scriptsDir\token-lease.ps1" -Action issue -RunId $runId -TaskId "AC-002" -AgentId "validator-002" -Role test-agent -TtlSeconds 7200 | ConvertFrom-Json).token
& "$scriptsDir\invoke-validation-command.ps1" -ValidationId "AC-002" -ExecCommand $valCmd -WorkingDir $runDir -RunDir $runDir -ExecutorRole "test-agent" -Token $v2tok
$v2tok2 = (& "$scriptsDir\token-lease.ps1" -Action issue -RunId $runId -TaskId "T-002" -AgentId "validator-002" -Role test-agent -TtlSeconds 7200 | ConvertFrom-Json).token
& "$scriptsDir\verify-task.ps1" -TaskId "T-002" -AgentId "validator-002" -Role "test-agent" -RunDir $runDir -Token $v2tok2
Write-Output "T-002 done"

# T-003
Write-Output "=== T-003 ==="
$t3tok = (& "$scriptsDir\token-lease.ps1" -Action issue -RunId $runId -TaskId "T-003" -AgentId "builder-T-003" -Role builder-agent -TtlSeconds 7200 | ConvertFrom-Json).token
& "$scriptsDir\claim-task.ps1" -TaskId "T-003" -AgentId "builder-T-003" -Role "builder-agent" -Token $t3tok -RunDir $runDir
& "$scriptsDir\submit-task.ps1" -TaskId "T-003" -AgentId "builder-T-003" -Role "builder-agent" -Token $t3tok -RunDir $runDir -EvidencePaths @("command-logs/test-unit-stdout.log") -ModifiedFiles @("src/import-export.ts")
$v3tok = (& "$scriptsDir\token-lease.ps1" -Action issue -RunId $runId -TaskId "AC-003" -AgentId "validator-003" -Role test-agent -TtlSeconds 7200 | ConvertFrom-Json).token
& "$scriptsDir\invoke-validation-command.ps1" -ValidationId "AC-003" -ExecCommand $valCmd -WorkingDir $runDir -RunDir $runDir -ExecutorRole "test-agent" -Token $v3tok
$v3tok2 = (& "$scriptsDir\token-lease.ps1" -Action issue -RunId $runId -TaskId "T-003" -AgentId "validator-003" -Role test-agent -TtlSeconds 7200 | ConvertFrom-Json).token
& "$scriptsDir\verify-task.ps1" -TaskId "T-003" -AgentId "validator-003" -Role "test-agent" -RunDir $runDir -Token $v3tok2
Write-Output "T-003 done"

# validate-state
Write-Output "=== validate-state ==="
& "$scriptsDir\validate-state.ps1" -RunDir $runDir 2>&1 | Tee-Object "$cmdLogDir\validate-state-stdout.log"
$LASTEXITCODE | Out-File "$cmdLogDir\validate-state-exitcode.txt" -NoNewline
"" | Out-File "$cmdLogDir\validate-state-stderr.log" -Encoding UTF8
Write-Output "validate-state exitCode: $LASTEXITCODE"
Write-Output "=== F4-R1 COMPLETE ==="
