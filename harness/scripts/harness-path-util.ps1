# Harness Path Normalization Utility — Phase 6B-R2
# Shared by all Harness scripts. Ensures consistent path comparison.
# Usage: . (Join-Path $PSScriptRoot "harness-path-util.ps1") -HarnessRoot $HarnessRoot

param([string]$HarnessRoot)

if (-not $HarnessRoot) {
    # Fallback: determine from this script's location
    $HarnessRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
}
$HarnessRoot = $HarnessRoot.Replace('\', '/').TrimEnd('/')

function Normalize-HarnessPath {
    param([string]$Path)
    if (-not $Path) { return $null }
    
    # Clean the path
    $cleanPath = $Path -replace '^/([A-Za-z]:)', '$1'
    
    try {
        $fullPath = [System.IO.Path]::GetFullPath($cleanPath)
    } catch {
        $fullPath = [System.IO.Path]::GetFullPath((Join-Path $HarnessRoot $cleanPath))
    }
    
    $normalized = $fullPath.Replace('\', '/').TrimEnd('/')
    
    # Verify within harness root (case-insensitive on Windows)
    if (-not $normalized.StartsWith($HarnessRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path '$Path' resolves to '$normalized' which is outside HarnessRoot '$HarnessRoot'"
    }
    
    return $normalized
}

function Get-HarnessRelativePath {
    param([string]$AbsolutePath)
    $absNormalized = Normalize-HarnessPath $AbsolutePath
    $rel = $absNormalized.Substring($HarnessRoot.Length).TrimStart('/')
    return $rel
}