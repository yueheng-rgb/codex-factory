# verify-integration-patch-ledger.ps1 — Phase 6C-H1
param(
    [Parameter(Mandatory=$true)][string]$LedgerPath,
    [string]$CanonicalSrcPath = ""
)
$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0
if (-not (Test-Path $LedgerPath)) {
    [void]$errors.Add("LEDGER_NOT_FOUND: $LedgerPath"); $exitCode = 1
} else {
    $lines = @(Get-Content $LedgerPath -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 })
    if ($lines.Count -eq 0) { [void]$errors.Add("LEDGER_EMPTY"); $exitCode = 1 }
    else {
        $entries = @()
        foreach ($l in $lines) {
            try { $entries += ($l | ConvertFrom-Json) } catch { [void]$errors.Add("LEDGER_MALFORMED_LINE"); $exitCode = 1 }
        }
        [void]$passes.Add("Ledger entries: $($entries.Count)")
        $prevHash = "GENESIS"
        for ($i = 0; $i -lt $entries.Count; $i++) {
            $e = $entries[$i]
            if ($e.previousPatchEventHash -ne $prevHash) { [void]$errors.Add("LEDGER_CHAIN_BREAK at entry $i"); $exitCode = 1 }
            $canonical = [ordered]@{}
            foreach ($k in ($e.PSObject.Properties.Name | Where-Object { $_ -ne "patchEventHash" } | Sort-Object)) { $canonical[$k] = $e.$k }
            $recomp = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes(($canonical | ConvertTo-Json -Compress)))) -Algorithm SHA256).Hash
            if ($recomp -ne $e.patchEventHash) { [void]$errors.Add("PATCH_HASH_MISMATCH at entry $i"); $exitCode = 1 }
            $prevHash = $e.patchEventHash
        }
        if ($exitCode -eq 0) { [void]$passes.Add("Patch ledger hash chain valid") }
    }
}
$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
@{ verdict=$verdict; timestamp=(Get-Date).ToString("o"); passCount=$passes.Count; failCount=$errors.Count; passes=$passes; errors=$errors } | ConvertTo-Json -Depth 4
exit $exitCode
