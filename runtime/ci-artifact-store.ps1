
# Codex Factory v2.1 - CI Artifact Store Runtime (Function Library)
$script:_CI_storeDir = $null
$script:_CI_RunId = $null
$script:_CI_artifactCounter = 0

function Initialize-CIArtifactStore {
  param(
    [Parameter(Mandatory=$true)]
    [string]$RunIdParam,
    [Parameter(Mandatory=$false)]
    [string]$StoreRoot
  )
  if (-not $StoreRoot) { $StoreRoot = Join-Path $PSScriptRoot "..\artifacts" }
  $script:_CI_RunId = $RunIdParam
  $script:_CI_storeDir = Join-Path $StoreRoot $RunIdParam
  New-Item -ItemType Directory -Force -Path $script:_CI_storeDir | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $script:_CI_storeDir "stdout") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $script:_CI_storeDir "stderr") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $script:_CI_storeDir "reports") | Out-Null
  $script:_CI_artifactCounter = 0
  Write-Host "[CI-STORE] Initialized: $script:_CI_storeDir" -ForegroundColor Green
}

function Get-NextArtifactId {
  $script:_CI_artifactCounter++
  return ("ART-{0:D4}" -f $script:_CI_artifactCounter)
}

function Get-Timestamp {
  return (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffK")
}

function Get-DirectorySnapshot {
  param([string]$Path)
  $files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch "node_modules|\.git|artifacts|dist|\.codex-factory" } |
    Sort-Object FullName |
    ForEach-Object { "{0}|{1}" -f $_.FullName.Replace($Path, "").TrimStart("\"), $_.Length }
  $content = $files -join "`n"
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $hashBytes = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($content))
  $hash = -join ($hashBytes | ForEach-Object { $_.ToString("x2") })
  $sha.Dispose()
  return @{ hash = $hash; files_count = $files.Count; captured_at = Get-Timestamp }
}

function Invoke-CICommand {
  param(
    [Parameter(Mandatory=$true)] [string]$Command,
    [Parameter(Mandatory=$true)] [string]$WorkingDirectory,
    [string]$ProjectName = "",
    [string]$ProjectType = "other",
    [string[]]$Tags = @(),
    [int]$TimeoutMs = 60000,
    [string]$Notes = ""
  )
  if (-not $script:_CI_storeDir) { throw "CI Artifact Store not initialized." }

  $artifactId = Get-NextArtifactId
  $startedAt = Get-Timestamp
  $stdoutFile = Join-Path $script:_CI_storeDir "stdout\$artifactId.stdout.txt"
  $stderrFile = Join-Path $script:_CI_storeDir "stderr\$artifactId.stderr.txt"

  Write-Host "[CI-ARTIFACT] $artifactId : $Command" -ForegroundColor Cyan
  Write-Host "  DIR: $WorkingDirectory" -ForegroundColor DarkGray

  $startSw = [System.Diagnostics.Stopwatch]::StartNew()
  $prevLocation = Get-Location
  try {
    Set-Location $WorkingDirectory
    $output = Invoke-Expression $Command 2>&1
    $exitCode = $LASTEXITCODE
    $stdoutLines = @()
    $stderrLines = @()
    foreach ($line in $output) {
      if ($line -is [System.Management.Automation.ErrorRecord]) {
        $stderrLines += $line.Exception.Message
      } else {
        $stdoutLines += $line.ToString()
      }
    }
    $stdoutText = $stdoutLines -join "`n"
    $stderrText = $stderrLines -join "`n"
    if (-not $stdoutText) { $stdoutText = "(no output)" }
    if (-not $stderrText) { $stderrText = "(no stderr)" }
  } catch {
    $stdoutText = "(execution failed: $($_.Exception.Message))"
    $stderrText = $_.Exception.ToString()
    $exitCode = 1
  }
  Set-Location $prevLocation
  $startSw.Stop()
  $duration = $startSw.ElapsedMilliseconds
  $finishedAt = Get-Timestamp

  $stdoutText | Out-File -FilePath $stdoutFile -Encoding utf8
  $stderrText | Out-File -FilePath $stderrFile -Encoding utf8

  $clean = ($stdoutText + "`n" + $stderrText) -replace '\x1b\[[0-9;]*m', ''
  $testCounts = @{}
  if ($clean -match 'Tests\s+(\d+)\s+passed.*?\((\d+)\)') {
    $testCounts.passed = [int]$Matches[1]; $testCounts.total = [int]$Matches[2]; $testCounts.failed = 0
  } elseif ($clean -match 'Tests.*?(\d+)\s+passed') {
    $testCounts.passed = [int]$Matches[1]; $testCounts.total = [int]$Matches[1]; $testCounts.failed = 0
  }
  if ($clean -match '(\d+)\s+failed') { $testCounts.failed = [int]$Matches[1] }

  $summaryLimit = [Math]::Min(500, $stdoutText.Length)
  $artifact = [PSCustomObject]@{
    artifact_id = $artifactId; run_id = $script:_CI_RunId; command = $Command
    working_directory = $WorkingDirectory; started_at = $startedAt; finished_at = $finishedAt
    duration_ms = $duration; exit_code = $exitCode
    stdout_file = "stdout/$artifactId.stdout.txt"; stderr_file = "stderr/$artifactId.stderr.txt"
    stdout_summary = $stdoutText.Substring(0, $summaryLimit)
    stderr_summary = $stderrText.Substring(0, [Math]::Min(500, $stderrText.Length))
    test_counts = $testCounts; project_type = $ProjectType
    project_name = $(if ($ProjectName) { $ProjectName } else { Split-Path $WorkingDirectory -Leaf })
    tags = $Tags; notes = $Notes
  }

  $color = if ($exitCode -eq 0) { "Green" } else { "Red" }
  Write-Host "  -> exit=$exitCode duration=$duration ms" -ForegroundColor $color
  if ($testCounts.Count -gt 0 -and $testCounts.total -gt 0) {
    $tc = if ($testCounts.failed -gt 0) { "Red" } else { "Green" }
    Write-Host "  -> tests: $($testCounts.passed)/$($testCounts.total) passed" -ForegroundColor $tc
  }
  return $artifact
}

function Export-CIArtifactStoreIndex {
  param(
    [Parameter(Mandatory=$true)] [array]$Artifacts,
    [string]$FactoryRoot = "C:\Codex_App_Factory",
    [string]$RunDescription = ""
  )
  if (-not $script:_CI_storeDir) { throw "CI Artifact Store not initialized." }

  $cleanArtifacts = $Artifacts | Where-Object { $_ -ne $null -and $_.artifact_id }
  $passed = ($cleanArtifacts | Where-Object { $_.exit_code -eq 0 }).Count
  $failed = ($cleanArtifacts | Where-Object { $_.exit_code -ne 0 -and $_.exit_code -ne -1 }).Count
  $skipped = ($cleanArtifacts | Where-Object { $_.exit_code -eq -1 }).Count

  $totalTests = 0; $totalPassed = 0; $totalFailed = 0
  foreach ($a in $cleanArtifacts) {
    if ($a.test_counts -and $a.test_counts.total) {
      $totalTests += $a.test_counts.total
      if ($a.test_counts.passed) { $totalPassed += $a.test_counts.passed }
      if ($a.test_counts.failed) { $totalFailed += $a.test_counts.failed }
    }
  }

  $snapshot = Get-DirectorySnapshot -Path $FactoryRoot

  $trace = @{}
  foreach ($a in $cleanArtifacts) {
    if ($a.test_counts -and $a.test_counts.total) {
      $trace["$($a.project_name): $($a.test_counts.passed)/$($a.test_counts.total) PASS"] = @($a.artifact_id)
    } elseif ($a.project_type -eq "engine") {
      $trace["engine:$($a.project_name)"] = @($a.artifact_id)
    } else {
      $trace["$($a.project_name): exit=$($a.exit_code)"] = @($a.artifact_id)
    }
  }

  $index = [PSCustomObject]@{
    store_version = "2.1.0"; created_at = Get-Timestamp; run_id = $script:_CI_RunId
    run_description = $RunDescription; factory_version = "2.1.0"
    total_artifacts = $cleanArtifacts.Count; passed = $passed; failed = $failed; skipped = $skipped
    total_tests = $totalTests; total_tests_passed = $totalPassed; total_tests_failed = $totalFailed
    directory_snapshot = $snapshot; artifacts = @($cleanArtifacts)
    audit_ledger_entries = @(); traceability_matrix = $trace
  }

  $indexFile = Join-Path $script:_CI_storeDir "artifact-store-index.json"
  $index | ConvertTo-Json -Depth 6 | Out-File -FilePath $indexFile -Encoding utf8
  Write-Host "[CI-STORE] Index: $indexFile" -ForegroundColor Green
  Write-Host "[CI-STORE] $($cleanArtifacts.Count) artifacts, $passed PASS, $failed FAIL, $skipped SKIP, $totalPassed/$totalTests tests" -ForegroundColor Green
  return $index
}

