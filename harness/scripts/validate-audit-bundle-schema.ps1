# validate-audit-bundle-schema.ps1 — Phase 6C-T0-R1
# Validates an audit bundle (ZIP or staging directory) against AUDIT_BUNDLE_SCHEMA.json.
# Supports -StagingDir for pre-ZIP validation and -BundlePath for post-ZIP validation.
param(
    [Parameter(ParameterSetName="Staging")][string]$StagingDir,
    [Parameter(ParameterSetName="BundlePath")][string]$BundlePath,
    [switch]$Json
)

$ErrorActionPreference = "Continue"
$ScriptsDir = $PSScriptRoot
$HarnessRoot = Resolve-Path (Join-Path $ScriptsDir "..")
$SchemaFile = Join-Path $HarnessRoot "schemas\AUDIT_BUNDLE_SCHEMA.json"

if (-not (Test-Path $SchemaFile)) {
    $result = @{ verdict = "FAIL"; error = "Schema file not found: $SchemaFile"; missing = @(); present = @() }
    if ($Json) { Write-Output ($result | ConvertTo-Json -Depth 4) } else { Write-Output "FAIL: Schema file not found" }
    exit 1
}

$schema = Get-Content $SchemaFile -Raw -Encoding UTF8 | ConvertFrom-Json

# Determine work directory
$workDir = $null
$cleanupDir = $null
if ($BundlePath) {
    if (-not (Test-Path $BundlePath)) {
        $result = @{ verdict = "FAIL"; error = "Bundle not found: $BundlePath"; missing = @(); present = @() }
        if ($Json) { Write-Output ($result | ConvertTo-Json -Depth 4) } else { Write-Output "FAIL: Bundle not found: $BundlePath" }
        exit 1
    }
    $cleanupDir = Join-Path ([System.IO.Path]::GetTempPath()) "schema-validate-$(Get-Random)"
    if (Test-Path $cleanupDir) { Remove-Item -Recurse -Force $cleanupDir }
    Expand-Archive -Path $BundlePath -DestinationPath $cleanupDir -Force
    $workDir = $cleanupDir
} elseif ($StagingDir) {
    if (-not (Test-Path $StagingDir)) {
        $result = @{ verdict = "FAIL"; error = "Staging dir not found: $StagingDir"; missing = @(); present = @() }
        if ($Json) { Write-Output ($result | ConvertTo-Json -Depth 4) } else { Write-Output "FAIL: Staging dir not found: $StagingDir" }
        exit 1
    }
    $workDir = $StagingDir
} else {
    $result = @{ verdict = "FAIL"; error = "Must specify -StagingDir or -BundlePath"; missing = @(); present = @() }
    if ($Json) { Write-Output ($result | ConvertTo-Json -Depth 4) } else { Write-Output "FAIL: Must specify -StagingDir or -BundlePath" }
    exit 1
}

function Get-WorkFiles {
    param([string]$Dir)
    $all = Get-ChildItem $Dir -Recurse -File -ErrorAction SilentlyContinue
    return $all
}
function File-ExistsInWork {
    param([string]$RelPath)
    $absPath = Join-Path $workDir $RelPath
    return (Test-Path $absPath)
}

$missing = [System.Collections.ArrayList]::new()
$present = [System.Collections.ArrayList]::new()
$exitCode = 0

# Check required directories
foreach ($dir in $schema.requiredDirectories) {
    $path = Join-Path $workDir $dir
    if (Test-Path $path) {
        [void]$present.Add("Directory: $dir")
    } else {
        [void]$missing.Add("MISSING_DIR: $dir")
        $exitCode = 1
    }
}

# Check required reports
foreach ($report in $schema.requiredReports) {
    if (File-ExistsInWork $report) {
        [void]$present.Add("Report: $report")
    } else {
        [void]$missing.Add("MISSING_REPORT: $report")
        $exitCode = 1
    }
}

# Check required evidence files
foreach ($ev in $schema.requiredEvidence) {
    if (File-ExistsInWork $ev) {
        [void]$present.Add("Evidence: $ev")
    } else {
        [void]$missing.Add("MISSING_EVIDENCE: $ev")
        $exitCode = 1
    }
}

# Check required bundle root files (wildcard patterns)
$rootFiles = Get-ChildItem $workDir -File -ErrorAction SilentlyContinue
foreach ($pat in $schema.requiredBundleFiles) {
    $found = $false
    foreach ($rf in $rootFiles) {
        if ($rf.Name -like $pat) {
            [void]$present.Add("Bundle file: $($rf.Name) (pattern: $pat)")
            $found = $true
            break
        }
    }
    if (-not $found) {
        [void]$missing.Add("MISSING_BUNDLE_FILE: $pat (searched $($rootFiles.Count) root files)")
        $exitCode = 1
    }
}

# Check no forbidden files at root
foreach ($forbidden in $schema.forbiddenAtRoot) {
    foreach ($rf in $rootFiles) {
        if ($rf.Name -like $forbidden) {
            [void]$missing.Add("FORBIDDEN_AT_ROOT: $($rf.Name)")
            $exitCode = 1
        }
    }
}

# Self-consistency: if this report itself is in the requiredReports, verify it exists
# The schema report is written after validation, so for staging this is pre-checked
# For ZIP, we check what's in the ZIP at time of extraction

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

$result = @{
    schemaVersion = $schema.schemaVersion
    inputMode = if ($BundlePath) { "BundlePath" } else { "StagingDir" }
    inputPath = if ($BundlePath) { $BundlePath } else { $StagingDir }
    timestamp = (Get-Date).ToString("o")
    verdict = $verdict
    totalChecks = ($schema.requiredDirectories.Count + $schema.requiredReports.Count + $schema.requiredEvidence.Count + $schema.requiredBundleFiles.Count + $schema.forbiddenAtRoot.Count)
    missingCount = $missing.Count
    presentCount = $present.Count
    missing = $missing
    present = $present
}

# Cleanup temp dir
if ($cleanupDir -and (Test-Path $cleanupDir)) {
    Remove-Item -Recurse -Force $cleanupDir -ErrorAction SilentlyContinue
}

if ($Json) {
    Write-Output ($result | ConvertTo-Json -Depth 4)
} else {
    Write-Output "Verdict: $verdict"
    Write-Output "Input: $($result.inputMode) = $($result.inputPath)"
    Write-Output "Present: $($present.Count) | Missing: $($missing.Count)"
    foreach ($m in $missing) { Write-Output "  $m" }
}

exit $exitCode
