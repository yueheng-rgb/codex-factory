# Evidence Hash Chain Verifier v1.0.0
param([string]$LedgerPath = "C:\Codex_App_Factory\outputs\audit-ledger.json")

if (-not (Test-Path $LedgerPath)) {
    [PSCustomObject]@{chain_valid=$false; reason="Ledger not found"} | ConvertTo-Json; return
}

try {
    $ledger = @(Get-Content $LedgerPath -Raw | ConvertFrom-Json)
    $valid = $true; $issues = @()
    
    for ($i = 1; $i -lt $ledger.Count; $i++) {
        $prev = $ledger[$i-1]; $curr = $ledger[$i]
        if ($prev.current_hash -ne $curr.previous_hash) {
            $valid = $false
            $issues += "Break at $($curr.entry_id): prev hash mismatch"
        }
    }
    
    [PSCustomObject]@{
        chain_id = "CHAIN-$(Get-Date -Format 'yyyyMMddHHmmss')"
        chain_valid = $valid
        total_entries = $ledger.Count
        first_entry = if ($ledger.Count -gt 0) { $ledger[0].entry_id } else { "NONE" }
        last_entry = if ($ledger.Count -gt 0) { $ledger[-1].entry_id } else { "NONE" }
        genesis_hash = if ($ledger.Count -gt 0) { $ledger[0].previous_hash } else { "NONE" }
        issues = $issues
    } | ConvertTo-Json -Depth 3
} catch {
    [PSCustomObject]@{chain_valid=$false; error=$_.Exception.Message} | ConvertTo-Json
}
