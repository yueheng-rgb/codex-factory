# Audit Ledger v1.0.0
param([string]$LedgerPath = "C:\Codex_App_Factory\outputs\audit-ledger.json", [string]$Action = "view", [string]$EntryJson = "")

function Get-SHA256 { param([string]$Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    return [Convert]::ToBase64String($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Text)))
}

function New-LedgerEntry { param([string]$Json, [string]$PrevHash)
    $entry = $Json | ConvertFrom-Json
    $entry.entry_id = "AUDIT-$(Get-Date -Format 'yyyyMMddHHmmss')"
    $entry.timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $entry.previous_hash = $PrevHash
    $content = "$($entry.entry_id)|$($entry.timestamp)|$($entry.event_type)|$($entry.target)|$($entry.result_summary)|$PrevHash"
    $entry.current_hash = Get-SHA256 -Text $content
    return $entry
}

$ledger = if (Test-Path $LedgerPath) { try { @(Get-Content $LedgerPath -Raw | ConvertFrom-Json) } catch { @() } } else { @() }
$prevHash = if ($ledger.Count -gt 0) { $ledger[-1].current_hash } else { "GENESIS" }

if ($Action -eq "add" -and $EntryJson) {
    $entry = New-LedgerEntry -Json $EntryJson -PrevHash $prevHash
    $ledger += $entry
    $ledger | ConvertTo-Json -Depth 4 | Set-Content $LedgerPath -Encoding UTF8
    "Entry added: $($entry.entry_id)"
} elseif ($Action -eq "verify") {
    $valid = $true; $issues = @()
    for ($i = 1; $i -lt $ledger.Count; $i++) {
        if ($ledger[$i-1].current_hash -ne $ledger[$i].previous_hash) {
            $valid = $false
            $issues += "Chain break at entry ${i}"
        }
    }
    [PSCustomObject]@{chain_valid=$valid; entry_count=$ledger.Count; issues=$issues} | ConvertTo-Json -Depth 3
} else {
    if ($ledger.Count -eq 0) { "Audit ledger empty" } else { "Ledger: $($ledger.Count) entries. Last: $($ledger[-1].entry_id)" }
}
