# Verify Harness Install — Phase 6C-I
param(
    [Parameter(Mandatory=$true)][string]$TargetProject,
    [Parameter(Mandatory=$true)][string]$ManifestPath
)
$ErrorActionPreference = "Continue"
$TargetProject = (Resolve-Path $TargetProject).Path

if (-not (Test-Path $ManifestPath)) { Write-Output '{"status":"FAIL","reason":"MANIFEST_NOT_FOUND"}'; exit 1 }

$manifest = Get-Content $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$errors = @()
$passes = @()
$exitCode = 0

# Build a lookup hashtable from sha256ByFile (handles both PSObject and hashtable)
$hashLookup = @{}
$props = $manifest.sha256ByFile.PSObject.Properties
foreach ($prop in $props) {
    $hashLookup[$prop.Name] = $prop.Value
}

foreach ($filePath in $manifest.includedPaths) {
    # Normalize path: forward slash to backslash for Windows Join-Path
    $normPath = $filePath.Replace("/", "\")
    $fullPath = Join-Path $TargetProject $normPath
    if (-not (Test-Path $fullPath)) {
        $errors += "MISSING: $filePath"
        $exitCode = 1
        continue
    }
    $actualHash = (Get-FileHash $fullPath -Algorithm SHA256).Hash.ToLower()
    $expectedHash = $hashLookup[$filePath]
    if (-not $expectedHash) {
        # Try with backslash normalized key
        $expectedHash = $hashLookup[$normPath]
    }
    if (-not $expectedHash) {
        $errors += "NO_MANIFEST_HASH: $filePath"
        $exitCode = 1
    } elseif ($actualHash -ne $expectedHash) {
        $errors += "HASH_MISMATCH: $filePath (exp=$($expectedHash.Substring(0,12))..., act=$($actualHash.Substring(0,12))...)"
        $exitCode = 1
    } else {
        $passes += "VERIFIED: $filePath"
    }
}

# Check forbidden paths absent
$forbiddenChecks = @("runs", "runtime\RUN_STATE.jsonl", "runtime\TASKS.json")
foreach ($fp in $forbiddenChecks) {
    $checkPath = Join-Path $TargetProject $fp
    if (Test-Path $checkPath) {
        $errors += "FORBIDDEN_PATH_PRESENT: $fp"
        $exitCode = 1
    } else {
        $passes += "FORBIDDEN_ABSENT: $fp"
    }
}

# Receipt
$receiptPath = Join-Path $TargetProject ".harness-install-receipt.json"
if (Test-Path $receiptPath) { $passes += "RECEIPT_FOUND" } else { $errors += "RECEIPT_MISSING"; $exitCode = 1 }

$result = @{
    status = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
    targetProject = $TargetProject
    manifestFileCount = $manifest.fileCount
    verifiedCount = $passes.Count
    errorCount = $errors.Count
    passes = $passes
    errors = $errors
    verifiedAt = (Get-Date).ToString("o")
} | ConvertTo-Json -Depth 4
Write-Output $result
exit $exitCode