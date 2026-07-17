# validate-final-zip-self-consistency.ps1 — Phase 6C-T0-R1
# Validates the final ZIP for self-consistency: integrity, layout, and report consistency.
param(
    [Parameter(Mandatory=$true)][string]$ZipPath,
    [switch]$Json
)

$ErrorActionPreference = "Continue"
$ScriptsDir = $PSScriptRoot
$HarnessRoot = Resolve-Path (Join-Path $ScriptsDir "..")

$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

if (-not (Test-Path $ZipPath)) {
    [void]$errors.Add("ZIP_NOT_FOUND: $ZipPath")
    $result = @{ verdict = "FAIL"; errors = $errors; passes = $passes; timestamp = (Get-Date).ToString("o") }
    if ($Json) { Write-Output ($result | ConvertTo-Json -Depth 4) } else { Write-Output "FAIL: ZIP not found" }
    exit 1
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = $null
try {
    $archive = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
} catch {
    [void]$errors.Add("ZIP_CANNOT_OPEN: $_")
    $result = @{ verdict = "FAIL"; errors = $errors; passes = $passes; timestamp = (Get-Date).ToString("o"); entryCount = 0 }
    if ($Json) { Write-Output ($result | ConvertTo-Json -Depth 4) } else { Write-Output "FAIL: Cannot open ZIP" }
    exit 1
}

$allEntries = $archive.Entries
$entryCount = $allEntries.Count
[void]$passes.Add("ZIP openable: $entryCount entries")

# Root entries = no path separator (neither / nor \)
$rootEntries = @($allEntries | Where-Object { $_.FullName -notmatch '[/\\]' -and $_.Name.Length -gt 0 })
$rootJsonCount = 0
$rootPS1Count = 0
$hasSha256sums = $false
$hasFinalReport = $false

foreach ($entry in $rootEntries) {
    $n = $entry.Name
    if ($n -like "*.json") { $rootJsonCount++ }
    if ($n -like "*.ps1") { $rootPS1Count++ }
    if ($n -eq "SHA256SUMS.txt") { $hasSha256sums = $true }
    if ($n -like "PHASE_*_FINAL_REPORT.md") { $hasFinalReport = $true }
}

if ($rootJsonCount -eq 0) { [void]$passes.Add("No JSON at root") } else { [void]$errors.Add("JSON_AT_ROOT: $rootJsonCount file(s)"); $exitCode = 1 }
if ($rootPS1Count -eq 0) { [void]$passes.Add("No PS1 at root") } else { [void]$errors.Add("PS1_AT_ROOT: $rootPS1Count file(s)"); $exitCode = 1 }
if ($hasSha256sums) { [void]$passes.Add("SHA256SUMS.txt at root") } else { [void]$errors.Add("MISSING_SHA256SUMS"); $exitCode = 1 }
if ($hasFinalReport) { [void]$passes.Add("Final report at root") } else { [void]$errors.Add("MISSING_FINAL_REPORT"); $exitCode = 1 }

# Check required directories using both / and \ separators
$requiredDirs = @("docs","scripts","tests","reports","command-logs")
$dirSeen = @{}
foreach ($entry in $allEntries) {
    $parts = $entry.FullName -split '[/\\]'
    if ($parts.Count -ge 1 -and $parts[0].Length -gt 0) {
        $dirSeen[$parts[0]] = $true
    }
}
foreach ($rd in $requiredDirs) {
    if ($dirSeen.ContainsKey($rd)) { [void]$passes.Add("Directory: $rd") }
    else { [void]$errors.Add("MISSING_DIR: $rd"); $exitCode = 1 }
}

# Check SHA256SUMS
$shaEntry = @($allEntries | Where-Object { $_.FullName -eq "SHA256SUMS.txt" })[0]
$shaRecordCount = 0
if ($shaEntry) {
    $reader = New-Object System.IO.StreamReader($shaEntry.Open())
    $shaContent = $reader.ReadToEnd()
    $reader.Close()
    $shaLines = @($shaContent -split "`n" | Where-Object { $_.Trim().Length -gt 0 })
    $shaRecordCount = $shaLines.Count
    [void]$passes.Add("SHA256SUMS records: $shaRecordCount")

    $zeroHashCount = 0
    foreach ($l in $shaLines) {
        $parts = $l -split '\s+', 2
        if ($parts[0].Trim() -eq "0000000000000000000000000000000000000000000000000000000000000000") { $zeroHashCount++ }
    }
    if ($zeroHashCount -eq 0) { [void]$passes.Add("No zero hashes in SHA256SUMS") } else { [void]$errors.Add("ZERO_HASHES: $zeroHashCount entries"); $exitCode = 1 }

    # Check no self-SHA256 in internal reports
    $mdEntries = @($allEntries | Where-Object { $_.Name -like "*.md" -and $_.FullName -notmatch 'tests' })
    $selfRefFound = $false
    foreach ($md in $mdEntries) {
        try {
            $r = New-Object System.IO.StreamReader($md.Open())
            $text = $r.ReadToEnd()
            $r.Close()
            if ($text -match "ZIP SHA256|Final ZIP SHA256|bundle.*SHA256.*\s*[:=]\s*[a-f0-9]{64}") {
                if ($text -notmatch "external sidecar metadata") { $selfRefFound = $true }
            }
        } catch {}
    }
    if (-not $selfRefFound) { [void]$passes.Add("No ZIP self-SHA256 in internal reports") } else { [void]$errors.Add("SELF_REFERENCE: Internal report contains ZIP SHA256"); $exitCode = 1 }
} else {
    [void]$errors.Add("SHA256SUMS entry missing"); $exitCode = 1
}

# Check critical reports
$criticalReports = @(
    "reports/audit-bundle-schema-validation-report.json",
    "reports/bundle-layout-report.json",
    "reports/sha256sums-validation-report.json"
)
foreach ($cr in $criticalReports) {
    $found = $false
    foreach ($entry in $allEntries) {
        if ($entry.FullName -replace '\\', '/' -eq $cr) { $found = $true; break }
    }
    if ($found) { [void]$passes.Add("Report: $cr") } else { [void]$errors.Add("MISSING_REPORT: $cr"); $exitCode = 1 }
}

# Verify schema report says PASS
$schemaRepEntry = @($allEntries | Where-Object { ($_.FullName -replace '\\', '/') -eq "reports/audit-bundle-schema-validation-report.json" })[0]
if ($schemaRepEntry) {
    try {
        $r = New-Object System.IO.StreamReader($schemaRepEntry.Open())
        $repJson = $r.ReadToEnd()
        $r.Close()
        $repObj = $repJson | ConvertFrom-Json
        if ($repObj.verdict -eq "PASS") {
            [void]$passes.Add("Schema validation report verdict: PASS")
        } else {
            [void]$errors.Add("SCHEMA_VALIDATOR_REPORT_FAIL: verdict=$($repObj.verdict)")
            $exitCode = 1
        }
    } catch { [void]$errors.Add("Cannot parse schema validation report"); $exitCode = 1 }
}

# Verify SHA report consistency
$shaRepEntry = @($allEntries | Where-Object { ($_.FullName -replace '\\', '/') -eq "reports/sha256sums-validation-report.json" })[0]
if ($shaRepEntry) {
    try {
        $r = New-Object System.IO.StreamReader($shaRepEntry.Open())
        $repJson = $r.ReadToEnd()
        $r.Close()
        $repObj = $repJson | ConvertFrom-Json
        if ($repObj.verdict -eq "PASS" -and $repObj.mismatchCount -eq 0) {
            [void]$passes.Add("SHA report: PASS, 0 mismatches")
        } elseif ($repObj.mismatchCount -eq 0) {
            [void]$passes.Add("SHA report: $($repObj.verdict) but 0 mismatches")
        } else {
            [void]$errors.Add("SHA_REPORT_FAIL: mismatches=$($repObj.mismatchCount)")
            $exitCode = 1
        }
        if ($shaRecordCount -gt 0 -and $repObj.checkedEntries) {
            if ($shaRecordCount -eq $repObj.checkedEntries) {
                [void]$passes.Add("SHA record count consistent: $shaRecordCount = checkedEntries")
            } else {
                [void]$errors.Add("SHA_RECORD_DRIFT: SHA256SUMS=$shaRecordCount checkedEntries=$($repObj.checkedEntries)")
                $exitCode = 1
            }
        }
    } catch { [void]$errors.Add("Cannot parse SHA report"); $exitCode = 1 }
}

$archive.Dispose()

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

$result = @{
    phase = "6C-T0-R1"
    zipPath = $ZipPath
    timestamp = (Get-Date).ToString("o")
    verdict = $verdict
    entryCount = $entryCount
    shaRecordCount = $shaRecordCount
    errorCount = $errors.Count
    passCount = $passes.Count
    errors = $errors
    passes = $passes
}

if ($Json) {
    Write-Output ($result | ConvertTo-Json -Depth 4)
} else {
    Write-Output "=== Final ZIP Self-Consistency ==="
    Write-Output "Verdict: $verdict"
    Write-Output "Entries: $entryCount | Errors: $($errors.Count)"
    foreach ($p in $passes) { Write-Output "  PASS: $p" }
    foreach ($e in $errors) { Write-Output "  FAIL: $e" }
}

exit $exitCode
