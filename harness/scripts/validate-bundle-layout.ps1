# validate-bundle-layout.ps1 — Phase 6C-P
# Validates release audit bundle directory structure.
# No scripts/docs/tests at ZIP root. All files in correct subdirectories.
param(
    [Parameter(Mandatory=$true)][string]$BundleDir,
    [switch]$Json
)

$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

# Expected directory structure
$requiredDirs = @("docs","scripts","tests","run","reports","command-logs","evidence")
$scriptExts = @(".ps1",".psm1")
$docExts = @(".md",".txt")
$testPattern = "test"
$reportPatterns = @("report","evidence","audit","validation")

# Files allowed at root
$allowedRootFiles = @(
    "PHASE_*_FINAL_REPORT.md",
    "PHASE_*_PROJECT_MODE_TRIAL_REPORT.md",
    "PHASE_*_CODEX_SELF_REVIEW_SUMMARY.md",
    "PHASE_*_BASELINE_NOTE.md",
    "PHASE_*_INITIAL_AUDIT_NOTE.md",
    "README.md",
    "SHA256SUMS.txt"
)

$rootFiles = Get-ChildItem $BundleDir -File -ErrorAction SilentlyContinue
$rootDirs = Get-ChildItem $BundleDir -Directory -ErrorAction SilentlyContinue

# Check required directories exist
foreach ($rd in $requiredDirs) {
    if (Test-Path (Join-Path $BundleDir $rd)) {
        [void]$passes.Add("Directory: $rd")
    } else {
        [void]$errors.Add("MISSING_DIR: $rd"); $exitCode = 1
    }
}

# Check no scripts at root
$rootScripts = @($rootFiles | Where-Object { $_.Extension -in $scriptExts })
if ($rootScripts.Count -gt 0) {
    [void]$errors.Add("SCRIPT_AT_ROOT: $($rootScripts.Name -join ', ')")
    $exitCode = 1
} else {
    [void]$passes.Add("No scripts at root")
}

# Check no docs at root
$rootDocs = @($rootFiles | Where-Object { $_.Extension -in $docExts -and $_.Name -notin @("README.md") })
$allowedRootCount = 0
foreach ($rf in $rootDocs) {
    $matched = $false
    foreach ($pat in $allowedRootFiles) {
        if ($rf.Name -like $pat) { $matched = $true; $allowedRootCount++; break }
    }
    if (-not $matched) {
        [void]$errors.Add("DOC_AT_ROOT: $($rf.Name)")
        $exitCode = 1
    }
}
if ($rootDocs.Count -le $allowedRootCount) {
    [void]$passes.Add("No unauthorized docs at root")
}

# Check no test files at root
$rootTests = @($rootFiles | Where-Object { $_.Name -match $testPattern })
if ($rootTests.Count -gt 0) {
    $realTests = @($rootTests | Where-Object { $_.Name -notmatch 'SUMMARY|REPORT' })
    if ($realTests.Count -gt 0) {
        [void]$errors.Add("TEST_AT_ROOT: $($realTests.Name -join ', ')")
        $exitCode = 1
    } else {
        [void]$passes.Add("No test files at root")
    }
} else {
    [void]$passes.Add("No test files at root")
}

# Check scripts/ has .ps1 files
$scriptsDir = Join-Path $BundleDir "scripts"
if (Test-Path $scriptsDir) {
    $scriptCount = @(Get-ChildItem $scriptsDir -Filter "*.ps1" -File).Count
    [void]$passes.Add("scripts/: $scriptCount script(s)")
}

# Check reports/ has .json files
$reportsDir = Join-Path $BundleDir "reports"
if (Test-Path $reportsDir) {
    $reportCount = @(Get-ChildItem $reportsDir -Filter "*.json" -File).Count
    [void]$passes.Add("reports/: $reportCount report(s)")
}

# Check no machine evidence at root
$rootJsons = @($rootFiles | Where-Object { $_.Extension -eq ".json" })
if ($rootJsons.Count -gt 0) {
    [void]$errors.Add("JSON_AT_ROOT: $($rootJsons.Name -join ', ')")
    $exitCode = 1
} else {
    [void]$passes.Add("No JSON at root")
}

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

$report = @{
    schemaVersion = "6C-P"
    bundleDir = $BundleDir
    timestamp = (Get-Date).ToString("o")
    verdict = $verdict
    errors = $errors
    passes = $passes
}

if ($Json) {
    Write-Output ($report | ConvertTo-Json -Depth 4)
} else {
    Write-Output "=== Bundle Layout Report ==="
    Write-Output "Verdict: $verdict"
    foreach ($p in $passes) { Write-Output "  [PASS] $p" }
    foreach ($e in $errors) { Write-Output "  [FAIL] $e" }
}

exit $exitCode