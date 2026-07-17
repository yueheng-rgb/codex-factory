# Freeze Control Plane — Records SHA256 of all governance files
# Run after initialization, before Builder starts. Tamper-evident baseline.
# Phase 6B-R5: 14 governance files, rejects empty/missing/outside-root/duplicate.
param(
    [Parameter(Mandatory=$true)][string]$RunDir
)

$ErrorActionPreference = "Stop"

$HarnessRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)

# --- RUN_SEALED CHECK ---
$stateFile = Join-Path $RunDir "RUN_STATE.jsonl"
if (Test-Path $stateFile) {
    $existing = @(Get-Content $stateFile -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 })
    foreach ($line in $existing) {
        try {
            $evt = $line | ConvertFrom-Json
            if ($evt.event -eq "run_sealed") {
                Write-Output (ConvertTo-Json -Compress -Depth 2 @{
                    status = "REJECTED"
                    reason = "RUN_ALREADY_SEALED: run_sealed event exists at seq=$($evt.seq). Cannot re-freeze control plane."
                })
                exit 1
            }
        } catch {}
    }
}

# Check for builder events — refuse to freeze after builder has started work
$builderStarted = $false
if (Test-Path $stateFile) {
    $existing = @(Get-Content $stateFile -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 })
    foreach ($line in $existing) {
        try {
            $evt = $line | ConvertFrom-Json
            if ($evt.event -eq "task_claimed") {
                $builderStarted = $true
                break
            }
        } catch {}
    }
}
if ($builderStarted) {
    Write-Output (ConvertTo-Json -Compress -Depth 2 @{
        status = "REJECTED"
        reason = "BUILDER_ALREADY_STARTED: task_claimed event exists. Cannot freeze control plane after builder has started."
    })
    exit 1
}

# Files that form the control plane — must not change after freeze
$controlPlaneFiles = @(
    @{ path = "config\harness.config.json"; mutable = $false },
    @{ path = "scripts\initialize-run.ps1"; mutable = $false },
    @{ path = "scripts\append-hash-event.ps1"; mutable = $false },
    @{ path = "scripts\token-lease.ps1"; mutable = $false },
    @{ path = "scripts\claim-task.ps1"; mutable = $false },
    @{ path = "scripts\submit-task.ps1"; mutable = $false },
    @{ path = "scripts\invoke-validation-command.ps1"; mutable = $false },
    @{ path = "scripts\freeze-control-plane.ps1"; mutable = $false },
    @{ path = "scripts\validate-control-plane.ps1"; mutable = $false },
    @{ path = "scripts\external-trust-root.ps1"; mutable = $false },
    @{ path = "scripts\validate-evidence.ps1"; mutable = $false },
    @{ path = "scripts\validate-state.ps1"; mutable = $false },
    @{ path = "scripts\validate-delivery-archive.ps1"; mutable = $false },
    @{ path = "scripts\finalize-run.ps1"; mutable = $false }
)

# Run-level files that must be frozen before builder starts
$runControlFiles = @(
    @{ path = "SPEC.md"; mutable = $false; location = "runtime" },
    @{ path = "ACCEPTANCE.json"; mutable = $false; location = "runtime" },
    @{ path = "OWNERSHIP.json"; mutable = $false; location = "runtime" }
)

# Validation: count expected files
$totalExpected = $controlPlaneFiles.Count + $runControlFiles.Count
if ($totalExpected -eq 0) {
    Write-Output (ConvertTo-Json -Compress -Depth 2 @{ status="REJECTED"; reason="NO_CONTROL_PLANE_FILES_DEFINED" })
    exit 1
}

$timestamp = (Get-Date).ToString("o")
$lockFile = Join-Path $RunDir "CONTROL_PLANE_LOCK.json"
$frozenItems = @()
$seenPaths = @{}

# Hash harness-level files
foreach ($item in $controlPlaneFiles) {
    # Reject duplicate paths
    if ($seenPaths.ContainsKey($item.path)) {
        Write-Output (ConvertTo-Json -Compress -Depth 2 @{ status="REJECTED"; reason="DUPLICATE_PATH: $($item.path)" })
        exit 1
    }
    $seenPaths[$item.path] = $true

    $fp = Join-Path $HarnessRoot $item.path
    if (-not (Test-Path $fp)) {
        Write-Output (ConvertTo-Json -Compress -Depth 2 @{ status="REJECTED"; reason="MISSING_FILE: $($item.path)" })
        exit 1
    }
    $bytes = [System.IO.File]::ReadAllBytes($fp)
    # Reject empty files (size 0)
    if ($bytes.Length -eq 0) {
        Write-Output (ConvertTo-Json -Compress -Depth 2 @{ status="REJECTED"; reason="EMPTY_FILE: $($item.path)" })
        exit 1
    }
    $sha = [System.BitConverter]::ToString(
        [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    ).Replace("-","").ToLower()
    $frozenItems += @{
        path = $item.path
        sha256 = $sha
        sizeBytes = $bytes.Length
        mutable = $item.mutable
        status = "frozen"
    }
}

# Hash run-level control files
foreach ($item in $runControlFiles) {
    if ($seenPaths.ContainsKey($item.path)) {
        Write-Output (ConvertTo-Json -Compress -Depth 2 @{ status="REJECTED"; reason="DUPLICATE_PATH: $($item.path)" })
        exit 1
    }
    $seenPaths[$item.path] = $true

    $fp = if ($item.location -eq "runtime") {
        Join-Path $HarnessRoot "runtime\$($item.path)"
    } else {
        Join-Path $RunDir $item.path
    }
    if (-not (Test-Path $fp)) {
        Write-Output (ConvertTo-Json -Compress -Depth 2 @{ status="REJECTED"; reason="MISSING_FILE: $($item.path)" })
        exit 1
    }
    $bytes = [System.IO.File]::ReadAllBytes($fp)
    if ($bytes.Length -eq 0) {
        Write-Output (ConvertTo-Json -Compress -Depth 2 @{ status="REJECTED"; reason="EMPTY_FILE: $($item.path)" })
        exit 1
    }
    $sha = [System.BitConverter]::ToString(
        [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    ).Replace("-","").ToLower()
    $frozenItems += @{
        path = $item.path
        sha256 = $sha
        sizeBytes = $bytes.Length
        mutable = $item.mutable
        status = "frozen"
    }
}

# Final validation: SHA256 must not be empty for any frozen item
foreach ($fi in $frozenItems) {
    if (-not $fi.sha256 -or $fi.sha256.Length -eq 0) {
        Write-Output (ConvertTo-Json -Compress -Depth 2 @{ status="REJECTED"; reason="EMPTY_SHA256: $($fi.path)" })
        exit 1
    }
}

$lock = @{
    schemaVersion = "6B-R5"
    runId = (Split-Path $RunDir -Leaf)
    frozenAt = $timestamp
    harnessRoot = $HarnessRoot
    itemCount = $frozenItems.Count
    items = $frozenItems
} | ConvertTo-Json -Depth 6

$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($lockFile, $lock, $utf8)

Write-Output (@{ status="frozen"; lockFile=$lockFile; itemCount=$frozenItems.Count; totalExpected=$totalExpected } | ConvertTo-Json)
