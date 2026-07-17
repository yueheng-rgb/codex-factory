# Codex Factory V3.1 — Execution Runner (Path Bug Fixed v3)
# External Execution Platform RC -> CI/Remote RC
# Usage: powershell -File runtime/execution-runner.ps1 -TaskId "TASK-001" -Command "npm test" -WorkDir "testbeds/products-api" -RunnerType "sandbox"

param(
    [Parameter(Mandatory=$true)] [string]$TaskId,
    [Parameter(Mandatory=$true)] [string]$Command,
    [string]$WorkDir = ".",
    [string]$RunnerType = "sandbox",
    [string]$RunId = $null,
    [switch]$DryRun,
    [switch]$Json
)

if (-not $RunId) { $RunId = "RUN-" + (Get-Date -Format "yyyyMMdd-HHmmss") + "-" + (Get-Random -Minimum 1000 -Maximum 9999) }

$started = Get-Date
$RepoRoot = (Get-Location).Path

# Snapshot preflight
$snapshotOk = $true
if (Test-Path "$RepoRoot/outputs/V2_9/V2_9_IMMUTABLE_SNAPSHOT_MANIFEST.json") {
    powershell -File "$RepoRoot/runtime/snapshot-verifier.ps1" 2>&1 | Out-Null
    $snapshotOk = ($LASTEXITCODE -eq 0)
}

# Resolve all paths as ABSOLUTE upfront to avoid double-nesting bug
$wsDirAbs = "$RepoRoot\workspaces\runs\$RunId"
$artifactsDirAbs = "$RepoRoot\artifacts\runs\$RunId"
$stdoutPathAbs = "$wsDirAbs\stdout.log"
$stderrPathAbs = "$wsDirAbs\stderr.log"
$runRecordPathAbs = "$artifactsDirAbs\run-record.json"

$result = @{
    run_id = $RunId
    task_id = $TaskId
    runner_type = $RunnerType
    working_directory = $WorkDir
    command = $Command
    command_redacted = $Command -replace '(sk-[A-Za-z0-9]+|api_key=[A-Za-z0-9]+|token=[A-Za-z0-9]+)','***REDACTED***'
    started_at = $started.ToString("o")
    finished_at = $null
    exit_code = $null
    stdout_path = $stdoutPathAbs
    stderr_path = $stderrPathAbs
    artifact_paths = @()
    environment_snapshot = @{}
    secret_policy_result = "NOT_CHECKED"
    snapshot_verified = $snapshotOk
    final_status = "PENDING"
    non_claims = @(
        "This is a V3.1 CI/Remote RC runner, NOT a production cloud platform",
        "Isolation is directory-level, NOT VM/container-level",
        "Sandbox mode is simulated via workspace copy, NOT kernel isolation",
        "Do NOT use for production deployment or sensitive data"
    )
}

if ($DryRun) {
    $result.runner_type = "dry_run"
    $result.final_status = "PLAN_ONLY"
    $result.finished_at = (Get-Date).ToString("o")
    if ($Json) { $result | ConvertTo-Json -Depth 4 } else { Write-Output "DRY RUN PLAN: $Command in $WorkDir" }
    return
}

# Create workspace and artifact directories
New-Item -ItemType Directory -Path $wsDirAbs -Force | Out-Null
New-Item -ItemType Directory -Path $artifactsDirAbs -Force | Out-Null

# Copy task files to isolated workspace (sandbox mode)
if ($RunnerType -eq "sandbox") {
    $srcAbs = "$RepoRoot\$WorkDir"
    # Copy everything including node_modules for full isolation
    Copy-Item "$srcAbs\*" "$wsDirAbs\" -Recurse -Force -ErrorAction SilentlyContinue
    $result.environment_snapshot.workspace_copy = "$WorkDir -> workspaces/runs/$RunId"
} else {
    $result.working_directory = $WorkDir
}

# Capture env snapshot
$result.environment_snapshot.node_version = (node --version 2>$null) -replace "`n|`r",""
$result.environment_snapshot.npm_version = (npm --version 2>$null) -replace "`n|`r",""
$result.environment_snapshot.os = "$env:OS $env:PROCESSOR_ARCHITECTURE"
$result.environment_snapshot.cwd = $RepoRoot

# Execute command — paths already absolute, safe to Push-Location
try {
    $execWorkDir = if ($RunnerType -eq "sandbox") { $wsDirAbs } else { (Resolve-Path "$RepoRoot\$WorkDir").Path }
    Push-Location $execWorkDir
    
    $output = Invoke-Expression $Command 2>&1
    $result.exit_code = $LASTEXITCODE
    $result.finished_at = (Get-Date).ToString("o")
    
    $stdoutContent = $output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }
    $stderrContent = $output | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }
    
    $stdoutContent | Out-File -Encoding utf8 -LiteralPath $stdoutPathAbs
    $stderrContent | Out-File -Encoding utf8 -LiteralPath $stderrPathAbs
    
    if ($result.exit_code -eq 0) { $result.final_status = "PASS" }
    elseif ($result.exit_code -eq 999) { $result.final_status = "BLOCKED" }
    else { $result.final_status = "FAIL" }
    
    Pop-Location
} catch {
    $result.exit_code = 1
    $result.final_status = "FAIL"
    $result.finished_at = (Get-Date).ToString("o")
    $_ | Out-File -Encoding utf8 -LiteralPath $stderrPathAbs
}

# Capture artifacts using absolute paths
$result.artifact_paths = @($stdoutPathAbs, $stderrPathAbs)

# Save run record using absolute path
$result | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 -LiteralPath $runRecordPathAbs

if ($Json) {
    $result | ConvertTo-Json -Depth 5
} else {
    Write-Output "Run: $RunId | Task: $TaskId | Status: $($result.final_status) | Exit: $($result.exit_code)"
}