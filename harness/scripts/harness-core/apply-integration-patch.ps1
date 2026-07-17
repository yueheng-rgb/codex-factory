# apply-integration-patch.ps1 — Phase 6C-H1
param(
    [Parameter(Mandatory=$true)][string]$LedgerPath,
    [Parameter(Mandatory=$true)][string]$RunId,
    [Parameter(Mandatory=$true)][string]$Reason,
    [Parameter(Mandatory=$true)][string[]]$AffectedFiles,
    [Parameter(Mandatory=$true)][string]$Operation,
    [string]$SourceWorker = "",
    [string]$BeforeHash = "",
    [string]$AfterHash = ""
)
$ErrorActionPreference = "Stop"
$ts = (Get-Date).ToString("o")
$dir = Split-Path $LedgerPath -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
$existing = @()
if (Test-Path $LedgerPath) { $existing = @(Get-Content $LedgerPath -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 } | ForEach-Object { $_ | ConvertFrom-Json }) }
$prevHash = if ($existing.Count -gt 0) { $existing[-1].patchEventHash } else { "GENESIS" }
$patchId = "PATCH-$($existing.Count + 1)-$(Get-Date -Format 'yyyyMMddHHmmss')"
$patch = [ordered]@{
    runId=$RunId; patchId=$patchId; timestamp=$ts; actorRole="Integrator"
    reason=$Reason; affectedFiles=@($AffectedFiles); beforeHash=$BeforeHash
    afterHash=$AfterHash; operation=$Operation; sourceWorker=$SourceWorker
    previousPatchEventHash=$prevHash
}
$canonical = [ordered]@{}
foreach ($k in ($patch.Keys | Sort-Object)) { $canonical[$k] = $patch[$k] }
$patch.patchEventHash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes(($canonical | ConvertTo-Json -Compress)))) -Algorithm SHA256).Hash
($patch | ConvertTo-Json -Compress) | Add-Content $LedgerPath -Encoding UTF8
Write-Output (ConvertTo-Json -Compress @{ status="RECORDED"; patchId=$patchId; patchEventHash=$patch.patchEventHash })
