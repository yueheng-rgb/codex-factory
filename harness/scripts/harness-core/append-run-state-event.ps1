# append-run-state-event.ps1 — Phase 6C-H1
# Appends a hash-chained event to RUN_STATE.jsonl.
param(
    [Parameter(Mandatory=$true)][string]$RunDir,
    [Parameter(Mandatory=$true)][string]$EventType,
    [Parameter(Mandatory=$true)][string]$ActorRole,
    [Parameter(Mandatory=$true)][hashtable]$Payload,
    [string]$RunId = ""
)
$ErrorActionPreference = "Stop"
$stateFile = Join-Path $RunDir "RUN_STATE.jsonl"
$dir = Split-Path $stateFile -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

$existing = @()
$prevHash = "GENESIS"
if (Test-Path $stateFile) {
    $lines = @(Get-Content $stateFile -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 })
    foreach ($l in $lines) {
        try { $existing += ($l | ConvertFrom-Json) } catch {}
    }
    if ($existing.Count -gt 0) { $prevHash = $existing[-1].eventHash }
}

$event = [ordered]@{
    runId = $RunId
    eventType = $EventType
    timestamp = (Get-Date).ToString("o")
    actorRole = $ActorRole
    payload = $Payload
    previousEventHash = $prevHash
}
$canonical = [ordered]@{}
foreach ($k in ($event.Keys | Sort-Object)) { $canonical[$k] = $event[$k] }
$event.eventHash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes(($canonical | ConvertTo-Json -Compress)))) -Algorithm SHA256).Hash

($event | ConvertTo-Json -Compress) | Add-Content $stateFile -Encoding UTF8
Write-Output (ConvertTo-Json -Compress @{ status="APPENDED"; eventType=$EventType; eventHash=$event.eventHash })
