# Install Harness Package — Phase 6C-I
# Installs codex-agent-harness-minimal to a target project directory.
param(
    [Parameter(Mandatory=$true)][string]$PackageZip,
    [Parameter(Mandatory=$true)][string]$TargetProject,
    [Parameter(Mandatory=$false)][switch]$AllowOverwrite
)
$ErrorActionPreference = "Stop"
$utf8 = [System.Text.UTF8Encoding]::new($false)

if (-not (Test-Path $PackageZip)) { throw "Package ZIP not found: $PackageZip" }
if (-not (Test-Path $TargetProject)) { New-Item -ItemType Directory -Force $TargetProject | Out-Null }
$TargetProject = (Resolve-Path $TargetProject).Path

# Check for existing harness files
$receiptPath = Join-Path $TargetProject ".harness-install-receipt.json"
if (Test-Path $receiptPath) {
    if (-not $AllowOverwrite) {
        $existing = Get-Content $receiptPath -Raw -Encoding UTF8 | ConvertFrom-Json
        throw "Harness already installed (package=$($existing.packageName) v$($existing.packageVersion)). Use -AllowOverwrite to reinstall."
    }
    Write-Output "Existing install receipt found. Overwriting per -AllowOverwrite."
}

# Check for existing harness marker files (without receipt)
$harnessMarkerFiles = @("AGENTS.md", "scripts\validate-state.ps1", "config\harness.config.json")
if (-not $AllowOverwrite) {
    foreach ($mf in $harnessMarkerFiles) {
        if (Test-Path (Join-Path $TargetProject $mf)) {
            throw "Harness file already exists: $mf. Use -AllowOverwrite to overwrite."
        }
    }
}

# Also check forbidden paths exist warning
$forbiddenPaths = @("runs", "outputs\phase6", "runtime\RUN_STATE.jsonl", "runtime\TASKS.json")
foreach ($fp in $forbiddenPaths) {
    if (Test-Path (Join-Path $TargetProject $fp)) {
        Write-Output "WARNING: Forbidden old-state path found: $fp (NOT removed, NOT overwritten)"
    }
}

# Extract and install from ZIP
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($PackageZip)
$installedFiles = @()
$installedHashes = @{}

foreach ($entry in $zip.Entries) {
    $relPath = $entry.FullName.Replace("\", "/")
    
    # Skip directory entries (length 0, name ends with /)
    if ($entry.Length -eq 0 -and $entry.Name -eq "") { continue }
    
    # Skip meta files
    if ($relPath -match 'manifest.*\.json$' -or $relPath -match '\.meta\.json$' -or $relPath -match '\.sha256$') { continue }
    
    $destPath = Join-Path $TargetProject $relPath
    $destDir = Split-Path $destPath -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force $destDir | Out-Null }
    
    $stream = $entry.Open()
    $bytes = [byte[]]::new($entry.Length)
    if ($entry.Length -gt 0) {
        $read = $stream.Read($bytes, 0, $bytes.Length)
    }
    $stream.Close()
    
    if ($entry.Length -gt 0) {
        [System.IO.File]::WriteAllBytes($destPath, $bytes)
    } else {
        # Empty file marker
        [System.IO.File]::WriteAllText($destPath, "", $utf8)
    }
    
    $hash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)).Replace("-","").ToLower()
    $installedFiles += $relPath
    $installedHashes[$relPath] = $hash
}
$zip.Dispose()

# Write install receipt
$receipt = @{
    packageName = "codex-agent-harness-minimal"
    packageVersion = "v1"
    installedAt = (Get-Date).ToString("o")
    packageSha256 = (Get-FileHash $PackageZip -Algorithm SHA256).Hash.ToLower()
    targetProject = $TargetProject
    installedFiles = $installedFiles
    installedFileHashes = $installedHashes
    excludedPaths = @("runs/", "outputs/phase6*", "old evidence/", "node_modules/", "dist/")
    allowOverwrite = $AllowOverwrite.IsPresent
} | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText($receiptPath, $receipt, $utf8)

Write-Output (@{ status="installed"; targetProject=$TargetProject; installedFileCount=$installedFiles.Count; receiptPath=$receiptPath } | ConvertTo-Json)