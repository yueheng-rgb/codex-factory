# validate-sha256sums.ps1 - Phase 6C-P
# Validates SHA256SUMS.txt with detailed report.
# Self-excludes SHA256SUMS.txt and sha256sums-validation-report.json.
param(
    [Parameter(Mandatory=$true)][string]$BundleDir,
    [switch]$Json
)

$ErrorActionPreference = "Continue"
$shaFile = Join-Path $BundleDir "SHA256SUMS.txt"
$reportFile = "sha256sums-validation-report.json"

if (-not (Test-Path $shaFile)) {
    $report = @{
        schemaVersion = "6C-P"
        bundleDir = $BundleDir
        timestamp = (Get-Date).ToString("o")
        verdict = "FAIL"
        error = "SHA256SUMS.txt not found"
        checkedEntries = 0
        matchedEntries = 0
        mismatchCount = 0
        absolutePathCount = 0
        mismatches = @()
        absolutePaths = @()
        relativePathsOnly = $false
        selfExcluded = $false
        hashReportExcluded = $false
    }
    if ($Json) { Write-Output ($report | ConvertTo-Json -Depth 4) }
    else { Write-Output "FAIL: SHA256SUMS.txt not found" }
    exit 1
}

$lines = Get-Content $shaFile -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 }
$selfExcluded = $true
$hashReportExcluded = $true
$checkedEntries = 0
$matchedEntries = 0
$mismatchCount = 0
$absolutePathCount = 0
$mismatches = @()
$absolutePaths = @()

foreach ($line in $lines) {
    $parts = $line -split '\s+', 2
    if ($parts.Count -lt 2) { continue }
    $expectedHash = $parts[0].Trim().ToLower()
    $relPath = $parts[1].Trim()

    # Check for absolute paths
    if ($relPath -match '^[A-Za-z]:\\' -or $relPath -match '^/') {
        $absolutePathCount++
        $absolutePaths += $relPath
        continue
    }

    $checkedEntries++

    # Self-exclusion checks
    if ($relPath -eq "SHA256SUMS.txt") { $selfExcluded = $false; continue }
    if ($relPath -match "sha256sums-validation-report\.json") { $hashReportExcluded = $false; continue }

    # Verify hash
    $fullPath = Join-Path $BundleDir $relPath
    if (-not (Test-Path $fullPath)) {
        $mismatchCount++
        $mismatches += @{ path=$relPath; reason="FILE_NOT_FOUND" }
        continue
    }

    try {
        $actualHash = (Get-FileHash -Path $fullPath -Algorithm SHA256).Hash.ToLower()
        if ($actualHash -eq $expectedHash) {
            $matchedEntries++
        } else {
            $mismatchCount++
            $mismatches += @{ path=$relPath; expected=$expectedHash; actual=$actualHash; reason="HASH_MISMATCH" }
        }
    } catch {
        $mismatchCount++
        $mismatches += @{ path=$relPath; reason="HASH_ERROR: $_" }
    }
}

$verdict = if ($mismatchCount -eq 0 -and $absolutePathCount -eq 0 -and $selfExcluded -and $hashReportExcluded) { "PASS" } else { "FAIL" }

$report = @{
    schemaVersion = "6C-P"
    bundleDir = $BundleDir
    timestamp = (Get-Date).ToString("o")
    verdict = $verdict
    relativePathsOnly = ($absolutePathCount -eq 0)
    selfExcluded = $selfExcluded
    hashReportExcluded = $hashReportExcluded
    checkedEntries = $checkedEntries
    matchedEntries = $matchedEntries
    mismatchCount = $mismatchCount
    absolutePathCount = $absolutePathCount
    mismatches = $mismatches
    absolutePaths = $absolutePaths
}

if ($Json) {
    Write-Output ($report | ConvertTo-Json -Depth 4)
} else {
    Write-Output "=== SHA256SUMS Validation ==="
    Write-Output "Verdict: $verdict"
    Write-Output "Checked: $checkedEntries | Matched: $matchedEntries | Mismatch: $mismatchCount | AbsolutePaths: $absolutePathCount"
    Write-Output "SelfExcluded: $selfExcluded | HashReportExcluded: $hashReportExcluded"
    foreach ($m in $mismatches) { Write-Output "  [MISMATCH] $($m.path): $($m.reason)" }
    foreach ($ap in $absolutePaths) { Write-Output "  [ABSOLUTE] $ap" }
}

if ($verdict -eq "FAIL") { exit 1 } else { exit 0 }
