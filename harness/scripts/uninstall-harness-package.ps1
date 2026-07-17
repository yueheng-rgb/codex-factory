# Uninstall Harness Package — Phase 6C-I
# Removes harness files from target project based on install receipt.
param(
    [Parameter(Mandatory=$true)][string]$TargetProject,
    [Parameter(Mandatory=$false)][switch]$Force
)
$ErrorActionPreference = "Stop"
$TargetProject = (Resolve-Path $TargetProject).Path

$receiptPath = Join-Path $TargetProject ".harness-install-receipt.json"
if (-not (Test-Path $receiptPath)) {
    if (-not $Force) { throw "No install receipt found. Use -Force to attempt cleanup anyway." }
    Write-Output "WARNING: No install receipt. Force mode: removing known harness paths."
}

$removedCount = 0
$skippedCount = 0

if (Test-Path $receiptPath) {
    $receipt = Get-Content $receiptPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($filePath in $receipt.installedFiles) {
        $fullPath = Join-Path $TargetProject $filePath
        if (Test-Path $fullPath) {
            Remove-Item $fullPath -Force
            $removedCount++
        } else {
            $skippedCount++
        }
    }
    # Remove receipt itself
    Remove-Item $receiptPath -Force
    $removedCount++
}

# Remove empty directories that were created by harness install
$harnessDirs = @("docs", ".codex\skills\agent-harness-run", ".codex\agents", "scripts", "config", "templates")
foreach ($dir in $harnessDirs) {
    $fullDir = Join-Path $TargetProject $dir
    if (Test-Path $fullDir) {
        $isEmpty = (Get-ChildItem $fullDir -Recurse -File -ErrorAction SilentlyContinue).Count -eq 0
        if ($isEmpty -or $Force) {
            Remove-Item $fullDir -Recurse -Force -ErrorAction SilentlyContinue
            $removedCount++
        }
    }
}

$result = @{
    status = "uninstalled"
    targetProject = $TargetProject
    removedCount = $removedCount
    skippedCount = $skippedCount
    uninstalledAt = (Get-Date).ToString("o")
} | ConvertTo-Json -Depth 2
Write-Output $result