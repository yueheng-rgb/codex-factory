# verify-run-state-chain.ps1 — Phase 6C-H1
# Verifies RUN_STATE.jsonl hash chain integrity without checking required events.
param(
    [Parameter(Mandatory=$true)][string]$RunDir
)
$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0
$stateFile = Join-Path $RunDir "RUN_STATE.jsonl"

if (-not (Test-Path $stateFile)) {
    [void]$errors.Add("RUN_STATE_NOT_FOUND"); $exitCode = 1
} else {
    $lines = @(Get-Content $stateFile -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 })
    if ($lines.Count -eq 0) {
        [void]$errors.Add("RUN_STATE_EMPTY"); $exitCode = 1
    } else {
        $events = @()
        foreach ($l in $lines) {
            try { $events += ($l | ConvertFrom-Json) } catch { [void]$errors.Add("INVALID_JSON"); $exitCode = 1 }
        }
        [void]$passes.Add("Events: $($events.Count)")
        $prevHash = "GENESIS"
        $chainOk = $true
        for ($idx = 0; $idx -lt $events.Count; $idx++) {
            $evt = $events[$idx]
            if (-not $evt.eventHash) { [void]$errors.Add("MISSING_EVENT_HASH at idx=$idx"); $chainOk = $false; $exitCode = 1; continue }
            if (-not $evt.previousEventHash) { [void]$errors.Add("MISSING_PREVIOUS_HASH at idx=$idx"); $chainOk = $false; $exitCode = 1; continue }
            if ($evt.previousEventHash -ne $prevHash) {
                [void]$errors.Add("CHAIN_BREAK at idx=$idx"); $chainOk = $false; $exitCode = 1
            }
            # Recompute hash
            $canonical = [ordered]@{}
            foreach ($k in ($evt.PSObject.Properties.Name | Where-Object { $_ -ne "eventHash" } | Sort-Object)) { $canonical[$k] = $evt.$k }
            $recomp = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes(($canonical | ConvertTo-Json -Compress)))) -Algorithm SHA256).Hash
            if ($recomp -ne $evt.eventHash) { [void]$errors.Add("HASH_MISMATCH at idx=$idx"); $chainOk = $false; $exitCode = 1 }
            $prevHash = $evt.eventHash
        }
        if ($chainOk) { [void]$passes.Add("Hash chain valid") }
    }
}
$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
@{ verdict=$verdict; timestamp=(Get-Date).ToString("o"); passCount=$passes.Count; failCount=$errors.Count; passes=$passes; errors=$errors } | ConvertTo-Json -Depth 4
exit $exitCode
