# require-run-state.ps1 — Phase 6C-H1
# Fail-closed RUN_STATE checker. Missing/empty/broken = FAIL.
param(
    [Parameter(Mandatory=$true)][string]$RunDir,
    [string[]]$RequiredEvents = @("task_claimed","task_submitted","validation_passed")
)
$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0
$stateFile = Join-Path $RunDir "RUN_STATE.jsonl"

if (-not (Test-Path $stateFile)) {
    [void]$errors.Add("FAIL_MISSING_RUN_STATE")
    $exitCode = 1
} else {
    $lines = @(Get-Content $stateFile -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 })
    if ($lines.Count -eq 0) {
        [void]$errors.Add("FAIL_EMPTY_RUN_STATE")
        $exitCode = 1
    } else {
        $events = @()
        foreach ($l in $lines) {
            try { $events += ($l | ConvertFrom-Json) } catch { [void]$errors.Add("INVALID_JSON_LINE"); $exitCode = 1 }
        }
        [void]$passes.Add("Events: $($events.Count)")
        
        # Hash chain check
        $prevHash = "GENESIS"
        $chainOk = $true
        for ($idx = 0; $idx -lt $events.Count; $idx++) {
            $evt = $events[$idx]
            if (-not $evt.eventHash) { [void]$errors.Add("MISSING_EVENT_HASH at idx=$idx"); $chainOk = $false; $exitCode = 1; continue }
            if (-not $evt.previousEventHash) { [void]$errors.Add("MISSING_PREVIOUS_HASH at idx=$idx"); $chainOk = $false; $exitCode = 1; continue }
            if ($evt.previousEventHash -ne $prevHash) {
                $msg = "HASH_CHAIN_BROKEN at idx=" + $idx + " expected=" + $prevHash + " got=" + $evt.previousEventHash
                [void]$errors.Add($msg); $chainOk = $false; $exitCode = 1
            }
            $prevHash = $evt.eventHash
        }
        if ($chainOk) { [void]$passes.Add("Hash chain valid") }
        
        # Required events
        foreach ($re in $RequiredEvents) {
            $found = @($events | Where-Object { $_.eventType -eq $re })
            if ($found.Count -eq 0) {
                [void]$errors.Add("FAIL_MISSING_REQUIRED_EVENT: $re"); $exitCode = 1
            } else {
                [void]$passes.Add("Required event: $re")
            }
        }
    }
}
$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
@{ verdict=$verdict; timestamp=(Get-Date).ToString("o"); passCount=$passes.Count; failCount=$errors.Count; passes=$passes; errors=$errors } | ConvertTo-Json -Depth 4
exit $exitCode
