# freeze-worker-output.ps1 — Phase 6C-H1
param(
    [Parameter(Mandatory=$true)][string]$WorkspacePath,
    [Parameter(Mandatory=$true)][string]$OutputPath,
    [string]$RunId = "",
    [int]$WorkerId = 0,
    [string]$WorkerName = ""
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path $WorkspacePath)) { Write-Error "Workspace not found: $WorkspacePath"; exit 1 }
$srcDir = Join-Path $WorkspacePath "src"
$scanResults = [System.Collections.ArrayList]::new()
$totalBytes = 0
if (Test-Path $srcDir) {
    Get-ChildItem $srcDir -File | ForEach-Object {
        $h = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        [void]$scanResults.Add(@{ relativePath = $_.Name; sizeBytes = $_.Length; sha256 = $h })
        $script:totalBytes += $_.Length
    }
}
$sorted = @($scanResults | Sort-Object { $_["relativePath"] })
$manifest = [ordered]@{
    runId = $RunId; workerId = $WorkerId; workerName = $WorkerName
    workspacePath = $WorkspacePath; frozenAt = (Get-Date).ToString("o")
    fileCount = $sorted.Count; totalBytes = $totalBytes; files = $sorted
}
$canonical = [ordered]@{}
foreach ($k in ($manifest.Keys | Sort-Object)) { $canonical[$k] = $manifest[$k] }
$manifest.manifestHash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes(($canonical | ConvertTo-Json -Compress)))) -Algorithm SHA256).Hash
New-Item -ItemType Directory -Force -Path (Split-Path $OutputPath -Parent) | Out-Null
$manifest | ConvertTo-Json -Depth 5 | Set-Content $OutputPath -Encoding UTF8
Write-Output (ConvertTo-Json -Compress @{ status="FROZEN"; workerId=$WorkerId; fileCount=$sorted.Count; manifestHash=$manifest.manifestHash })
