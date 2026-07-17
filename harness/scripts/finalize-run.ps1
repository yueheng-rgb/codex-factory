# Finalize Run — Sole Terminal Event Writer — Phase 6B-R3
# Only this script may write run_passed or run_failed to RUN_STATE.jsonl.
# It first runs validate-state.ps1 in read-only mode, then checks terminal
# verdict immutability, and only then appends ONE terminal event.
param(
    [Parameter(Mandatory=$true)][string]$RunDir
)

$ErrorActionPreference = "Stop"
$ScriptsDir = $PSScriptRoot
$HarnessRoot = Resolve-Path (Join-Path $ScriptsDir "..")
$stateFile = Join-Path $RunDir "RUN_STATE.jsonl"
$utf8 = New-Object System.Text.UTF8Encoding($false)

# --- 0. Check terminal verdict immutability FIRST ---
if (Test-Path $stateFile) {
    $existing = @(Get-Content $stateFile -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 })
    $parsed = $existing | ForEach-Object {
        try { $_ | ConvertFrom-Json } catch { $null }
    } | Where-Object { $_ -ne $null }

    $terminalEvents = @($parsed | Where-Object { $_.event -in @("run_passed","run_failed") })
    
    if ($terminalEvents.Count -gt 0) {
        $lastTerminal = $terminalEvents[-1]
        $msg = "TERMINAL_VERDICT_ALREADY_EXISTS: A terminal verdict ($($lastTerminal.event)) already exists at seq=$($lastTerminal.seq). Runs are immutable after finalization. Create a new Run."
        Write-Output (ConvertTo-Json -Compress -Depth 3 @{
            status = "REJECTED"
            reason = $msg
            existingVerdict = $lastTerminal.event
            existingSeq = $lastTerminal.seq
        })
        exit 1
    }

    # Also check for multiple terminal events (shouldn't happen with above, but defense in depth)
    $runPassed = @($parsed | Where-Object { $_.event -eq "run_passed" })
    $runFailed = @($parsed | Where-Object { $_.event -eq "run_failed" })
    if (($runPassed.Count + $runFailed.Count) -gt 0) {
        $msg = "TERMINAL_VERDICT_ALREADY_EXISTS: found $($runPassed.Count) run_passed and $($runFailed.Count) run_failed events. Run is already finalized."
        Write-Output (ConvertTo-Json -Compress -Depth 3 @{
            status = "REJECTED"
            reason = $msg
            runPassedCount = $runPassed.Count
            runFailedCount = $runFailed.Count
        })
        exit 1
    }
}

# --- 1. Run validate-state.ps1 in read-only mode ---
$validateScript = Join-Path $ScriptsDir "validate-state.ps1"
$validateOutput = & $validateScript -RunDir $RunDir
$validateResult = $validateOutput | ConvertFrom-Json

if ($validateResult.status -eq "FAIL") {
    $verdict = "run_failed"
} else {
    $verdict = "run_passed"
}

# --- 2. Append the ONE AND ONLY terminal event via hash-chain ---
$appendScript = Join-Path $ScriptsDir "append-hash-event.ps1"
try {
    $appendResult = & $appendScript -RunDir $RunDir -EventData @{
        event = $verdict
        actor = "finalizer"
        totalErrors = $validateResult.errors.Count
        totalPasses = $validateResult.passes.Count
        totalWarnings = $validateResult.warnings.Count
        validatorExitCode = if ($validateResult.status -eq "FAIL") { 1 } else { 0 }
        finalizationTimestamp = (Get-Date).ToString("o")
    }
    $appendParsed = $appendResult | ConvertFrom-Json
    
    # --- 3. Final immutable check: re-validate (read-only) to ensure no tampering ---
    $revalidateOutput = & $validateScript -RunDir $RunDir
    $revalidateResult = $revalidateOutput | ConvertFrom-Json
    
    if ($revalidateResult.status -ne $validateResult.status) {
        Write-Output (ConvertTo-Json -Compress -Depth 4 @{
            status = "REJECTED"
            reason = "POST_FINALIZE_STATE_CHANGE: validate-state result changed after terminal event was written"
            beforeStatus = $validateResult.status
            afterStatus = $revalidateResult.status
        })
        exit 1
    }

    Write-Output (ConvertTo-Json -Compress -Depth 4 @{
        status = "FINALIZED"
        verdict = $verdict
        seq = $appendParsed.seq
        eventHash = $appendParsed.eventHash
        validatorPasses = $validateResult.passes
        validatorErrors = $validateResult.errors
        validatorWarnings = $validateResult.warnings
        revalidationConsistent = $true
    })
    exit 0
    
} catch {
    Write-Output (ConvertTo-Json -Compress -Depth 3 @{
        status = "FAILED"
        reason = "Failed to append terminal event: $_"
    })
    exit 1
}
