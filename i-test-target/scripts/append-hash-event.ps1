# Append Hash-Chained Event — SINGLE ENTRY POINT for all RUN_STATE.jsonl writes
# Every production script MUST use this. Direct writes are FORBIDDEN and detectable.
param(
    [Parameter(Mandatory=$true)][string]$RunDir,
    [Parameter(Mandatory=$true)][hashtable]$EventData
)

$ErrorActionPreference = "Stop"
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stateFile = Join-Path $RunDir "RUN_STATE.jsonl"

# Determine seq and previousHash
$prevHash = "GENESIS"
$seq = 1
if (Test-Path $stateFile) {
    $existing = @(Get-Content $stateFile -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 })
    if ($existing.Count -gt 0) {
        # Get actual seq from last event
        try {
            $lastEvent = $existing[-1] | ConvertFrom-Json
            $seq = [int]$lastEvent.seq + 1
            if ($lastEvent.eventHash) {
                $prevHash = $lastEvent.eventHash
            } else {
                throw "Last event seq=$($lastEvent.seq) has no eventHash — chain broken. All events must be hash-chained."
            }
        } catch {
            throw "Failed to parse last event: $_"
        }
    }
}

# Build canonical payload (without hash fields, seq, timestamp)
$timestamp = (Get-Date).ToString("o")
$canonical = [ordered]@{}
foreach ($key in ($EventData.Keys | Sort-Object)) {
    $canonical[$key] = $EventData[$key]
}
# seq and timestamp are ALWAYS added by this script (never from caller)
$canonical["seq"] = $seq
$canonical["timestamp"] = $timestamp
$canonical["previousHash"] = $prevHash

# Compute payloadHash (hash of canonical fields only, without previousHash)
$payloadOnly = [ordered]@{}
foreach ($key in $canonical.Keys) {
    if ($key -ne "previousHash") { $payloadOnly[$key] = $canonical[$key] }
}
$payloadJson = ($payloadOnly | ConvertTo-Json -Compress -Depth 6)
$payloadBytes = [System.Text.Encoding]::UTF8.GetBytes($payloadJson)
$payloadHash = [System.BitConverter]::ToString(
    [System.Security.Cryptography.SHA256]::Create().ComputeHash($payloadBytes)
).Replace("-","").ToLower()

# Compute eventHash (hash of canonical JSON + previousHash)
$fullJson = ($canonical | ConvertTo-Json -Compress -Depth 6)
$fullBytes = [System.Text.Encoding]::UTF8.GetBytes($fullJson + $prevHash)
$eventHash = [System.BitConverter]::ToString(
    [System.Security.Cryptography.SHA256]::Create().ComputeHash($fullBytes)
).Replace("-","").ToLower()

# Build final event
$event = [ordered]@{}
foreach ($key in $canonical.Keys) { $event[$key] = $canonical[$key] }
$event["payloadHash"] = $payloadHash
$event["eventHash"] = $eventHash

# Append to file (single line, immediate flush)
$eventJson = ($event | ConvertTo-Json -Compress -Depth 6)
[System.IO.File]::AppendAllText($stateFile, $eventJson + [Environment]::NewLine, $utf8)

# Output result for the caller's logging
Write-Output (ConvertTo-Json -Compress -Depth 2 @{ status="appended"; seq=$seq; eventHash=$eventHash; event=$EventData.event })
