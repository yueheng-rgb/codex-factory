# verify-worker-freeze.ps1 — Phase 6C-H1
# Verifies worker workspace against frozen manifest. Fails on any deviation.
param(
    [Parameter(Mandatory=$true)][string]$FreezeManifestPath,
    [switch]$Json
)
$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

if (-not (Test-Path $FreezeManifestPath)) {
    Write-Output (@{ verdict="FAIL"; reason="MANIFEST_NOT_FOUND"; errors=@("Manifest not found: $FreezeManifestPath") } | ConvertTo-Json -Depth 4)
    exit 1
}

try { $manifest = Get-Content $FreezeManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json }
catch { [void]$errors.Add("MANIFEST_MALFORMED: $_"); $exitCode = 1 }

# Verify manifestHash
$canonical = [ordered]@{}
foreach ($k in ($manifest.PSObject.Properties.Name | Where-Object { $_ -ne "manifestHash" } | Sort-Object)) { $canonical[$k] = $manifest.$k }
$recomputed = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes(($canonical | ConvertTo-Json -Compress)))) -Algorithm SHA256).Hash
if ($recomputed -ne $manifest.manifestHash) {
    [void]$errors.Add("MANIFEST_HASH_MISMATCH: manifest may be tampered"); $exitCode = 1
} else { [void]$passes.Add("Manifest hash valid") }

$wsPath = $manifest.workspacePath
if (-not (Test-Path $wsPath)) {
    [void]$errors.Add("WORKSPACE_NOT_FOUND: $wsPath"); $exitCode = 1
} else {
    $srcDir = Join-Path $wsPath "src"
    $currentFiles = @()
    if (Test-Path $srcDir) { $currentFiles = @(Get-ChildItem $srcDir -File | ForEach-Object { $_.Name }) }
    
    # Check for missing files
    foreach ($f in $manifest.files) {
        $fp = Join-Path $srcDir $f.relativePath
        if (-not (Test-Path $fp)) {
            [void]$errors.Add("FILE_MISSING: $($f.relativePath)"); $exitCode = 1
        } else {
            $currentHash = (Get-FileHash $fp -Algorithm SHA256).Hash
            $currentSize = (Get-Item $fp).Length
            if ($currentHash -ne $f.sha256) {
                [void]$errors.Add("FILE_HASH_CHANGED: $($f.relativePath) frozen=$($f.sha256) current=$currentHash"); $exitCode = 1
            }
            if ($currentSize -ne $f.sizeBytes) {
                [void]$errors.Add("FILE_SIZE_CHANGED: $($f.relativePath) frozen=$($f.sizeBytes) current=$currentSize"); $exitCode = 1
            }
        }
    }
    
    # Check for added files
    $frozenNames = $manifest.files | ForEach-Object { $_.relativePath }
    foreach ($cf in $currentFiles) {
        if ($cf -notin $frozenNames) {
            [void]$errors.Add("FILE_ADDED_AFTER_FREEZE: $cf"); $exitCode = 1
        }
    }
    
    if ($exitCode -eq 0) { [void]$passes.Add("All $($manifest.files.Count) files match freeze manifest") }
}

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
@{ verdict=$verdict; timestamp=(Get-Date).ToString("o"); workerId=$manifest.workerId; passCount=$passes.Count; failCount=$errors.Count; passes=$passes; errors=$errors } | ConvertTo-Json -Depth 4
exit $exitCode
