<#
.SYNOPSIS
  Appends a single event line to the current run's run-events.jsonl incrementally.
  Enforces: single runId per file, real-time timestamps, auto-sequence, per-run directory structure.
.DESCRIPTION
  - Reads current-run.json to locate the active run directory.
  - Timestamp is ALWAYS generated at call time (Get-Date), never accepted externally.
  - Sequence is ALWAYS auto-incremented from the last event, never accepted externally.
  - Rejects events with a runId different from the active run's runId.
  - Each call appends exactly ONE line and flushes immediately.
  - Synchronously updates run-state.json lastEventSequence and updatedAt.
.PARAMETER ProjectPath
  Root path of the factory project.
.PARAMETER EventType
  One of the standard event types.
.PARAMETER Stage
  Stage identifier (e.g. stage-5-implementation).
.PARAMETER Status
  pass, fail, in_progress, completed, paused, blocked.
.PARAMETER Summary
  Short human-readable summary.
.PARAMETER EvidencePaths
  Array of relative file paths to evidence artifacts.
.EXAMPLE
  .\append-factory-event.ps1 -ProjectPath "C:\Test\my-project" `
    -EventType "validation_passed" `
    -Stage "stage-6-engineering" `
    -Status "pass" `
    -Summary "npm run build succeeded" `
    -EvidencePaths @(".codex-factory\logs\build.log")
.NOTES
  Safety rules:
  - NEVER accepts timestamp or sequence from caller.
  - NEVER writes to a file that already contains a different runId.
  - Each call appends exactly one line with immediate flush.
  - UTF-8 no BOM output.
  - Sensitive data patterns are rejected.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,

    [Parameter(Mandatory=$true)]
    [ValidateSet(
        "run_started","stage_started","stage_completed",
        "validation_started","validation_passed","validation_failed",
        "defect_found","defect_fixed",
        "factory_backflow_started","factory_backflow_completed",
        "run_completed","run_failed","run_paused",
        "remediation_started","remediation_completed"
    )]
    [string]$EventType,

    [Parameter(Mandatory=$true)]
    [string]$Stage,

    [Parameter(Mandatory=$true)]
    [ValidateSet("pass","fail","in_progress","completed","paused","blocked")]
    [string]$Status,

    [Parameter(Mandatory=$false)]
    [string]$Summary = "",

    [Parameter(Mandatory=$false)]
    [string[]]$EvidencePaths = @()
)

$ErrorActionPreference = "Stop"
$UtilsNoBom = New-Object System.Text.UTF8Encoding($false)

# Resolve active run
$FactoryDir = Join-Path $ProjectPath ".codex-factory"
$CurrentRunFile = Join-Path $FactoryDir "current-run.json"

if (-not (Test-Path $CurrentRunFile)) {
    throw "current-run.json not found at $CurrentRunFile. Initialize the run first."
}

$currentRunRaw = [System.IO.File]::ReadAllBytes($CurrentRunFile)
$currentRunText = if ($currentRunRaw.Length -ge 3 -and $currentRunRaw[0] -eq 0xEF) {
    $UtilsNoBom.GetString($currentRunRaw, 3, $currentRunRaw.Length - 3)
} else {
    $UtilsNoBom.GetString($currentRunRaw)
}
$currentRun = $currentRunText | ConvertFrom-Json
$activeRunId = $currentRun.currentRunId

# Resolve per-run paths
$RunsDir = Join-Path $FactoryDir "runs"
$RunDir = Join-Path $RunsDir $activeRunId
$EventsFile = Join-Path $RunDir "run-events.jsonl"
$StateFile = Join-Path $RunDir "run-state.json"

# Ensure directories exist
if (-not (Test-Path $RunDir)) {
    New-Item -ItemType Directory -Force -Path $RunDir | Out-Null
}

# Determine next sequence number (auto-increment only, never from caller)
$lastSeq = 0
$existingRunId = $null
if (Test-Path $EventsFile) {
    $lines = Get-Content -LiteralPath $EventsFile -Encoding UTF8
    foreach ($line in $lines) {
        $t = $line.Trim()
        if ($t.Length -eq 0) { continue }
        try {
            $evt = $t | ConvertFrom-Json
            $s = [int]$evt.sequence
            if ($s -gt $lastSeq) { $lastSeq = $s }
            if (-not $existingRunId -and $evt.runId) {
                $existingRunId = $evt.runId
            }
        } catch { }
    }
}

# ENFORCE: single runId per events file
if ($existingRunId -and $existingRunId -ne $activeRunId) {
    throw "EVENTS FILE CONTAINS runId '$existingRunId' but active run is '$activeRunId'. One runId per file required."
}

$nextSeq = $lastSeq + 1

# Build event (timestamp ALWAYS from Get-Date, sequence ALWAYS auto-incremented)
$event = [PSCustomObject]@{
    sequence       = $nextSeq
    timestamp      = (Get-Date).ToString("o")
    runId          = $activeRunId
    eventType      = $EventType
    stage          = $Stage
    status         = $Status
    summary        = $Summary
    evidencePaths  = @($EvidencePaths)
}

# Security: reject sensitive patterns
$sensitive = $event | ConvertTo-Json -Compress -Depth 4
if ($sensitive -match '\b(password|secret|api_key)\b') {
    throw "Event contains sensitive data pattern. Refusing to write."
}

# Reject [RECONSTRUCTED] markers in active logs
if ($Summary -match '\[RECONSTRUCTED\]') {
    throw "Cannot write [RECONSTRUCTED] event to active run log. Use archived-reconstructed-runs/ instead."
}

# Append one line with immediate flush
$line = $event | ConvertTo-Json -Compress -Depth 4
$stream = [System.IO.File]::Open($EventsFile, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
$bytes = $UtilsNoBom.GetBytes($line + "`n")
$stream.Write($bytes, 0, $bytes.Length)
$stream.Flush()
$stream.Close()

# Update run-state lastEventSequence and updatedAt
if (Test-Path $StateFile) {
    $raw = [System.IO.File]::ReadAllBytes($StateFile)
    $stateText = if ($raw.Length -ge 3 -and $raw[0] -eq 0xEF -and $raw[1] -eq 0xBB -and $raw[2] -eq 0xBF) {
        $UtilsNoBom.GetString($raw, 3, $raw.Length - 3)
    } else {
        $UtilsNoBom.GetString($raw)
    }
    $state = $stateText | ConvertFrom-Json
    $state.lastEventSequence = $nextSeq
    $state.updatedAt = (Get-Date).ToString("o")
    $newState = $state | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllBytes($StateFile, $UtilsNoBom.GetBytes($newState))
}

Write-Output "Appended event seq=$nextSeq type=$EventType stage=$Stage runId=$activeRunId"
