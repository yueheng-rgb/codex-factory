# Phase 6C-T0-R3 External Verifier — verify-final-artifacts.ps1
# Independently validates the final ZIP and both external sidecars.
# Does NOT modify any artifacts.
param(
    [Parameter(Mandatory=$true)][string]$ZipPath,
    [switch]$Json
)

$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

Write-Output "=== Phase 6C-T0-R3 External Final Artifacts Verifier ==="
Write-Output "Target ZIP: $ZipPath"
Write-Output ""

# 1. Final ZIP exists
if (Test-Path $ZipPath) {
    [void]$passes.Add("final_zip_exists: $ZipPath")
} else {
    [void]$errors.Add("MISSING_FINAL_ZIP: $ZipPath")
    $exitCode = 1
    $result = @{ verdict="FAIL"; errors=$errors; passes=$passes; timestamp=(Get-Date).ToString("o") }
    if ($Json) { Write-Output ($result | ConvertTo-Json -Depth 4) } else { Write-Output "FAIL: ZIP not found" }
    exit $exitCode
}

# 2. Sidecars exist
$selfCheckPath = "$ZipPath.final-self-check.json"
$metaPath = "$ZipPath.meta.json"

if (Test-Path $selfCheckPath) {
    [void]$passes.Add("final_self_check_exists: $selfCheckPath")
} else {
    [void]$errors.Add("MISSING_SELF_CHECK: $selfCheckPath")
    $exitCode = 1
}

if (Test-Path $metaPath) {
    [void]$passes.Add("meta_sidecar_exists: $metaPath")
} else {
    [void]$errors.Add("MISSING_META: $metaPath")
    $exitCode = 1
}

# 3. Read final ZIP properties
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipInfo = Get-Item $ZipPath
$zipSha256 = (Get-FileHash $ZipPath -Algorithm SHA256).Hash.ToLower()
$za = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
$zipEntries = @($za.Entries | ForEach-Object { $_.FullName.Replace('\', '/') })
$entryCount = $za.Entries.Count
$za.Dispose()

[void]$passes.Add("final_zip_openable: $entryCount entries, SHA256=$zipSha256")

# 4. Verify self-check sidecar
if (Test-Path $selfCheckPath) {
    try {
        $sc = Get-Content $selfCheckPath -Raw -Encoding UTF8 | ConvertFrom-Json
        
        # Check checkedZipPath
        if ($sc.checkedZipPath -eq $ZipPath) {
            [void]$passes.Add("self_check_zip_path_correct")
        } else {
            [void]$errors.Add("SELF_CHECK_PATH_MISMATCH: expected=$ZipPath actual=$($sc.checkedZipPath)")
            $exitCode = 1
        }
        
        # Check zipSha256
        if ($sc.zipSha256 -eq $zipSha256) {
            [void]$passes.Add("self_check_sha256_matches: $zipSha256")
        } else {
            [void]$errors.Add("SELF_CHECK_SHA256_MISMATCH: expected=$zipSha256 actual=$($sc.zipSha256)")
            $exitCode = 1
        }
        
        # Check zipEntryCount
        if ($sc.zipEntryCount -eq $entryCount) {
            [void]$passes.Add("self_check_entry_count_matches: $entryCount")
        } else {
            [void]$errors.Add("SELF_CHECK_ENTRY_COUNT_MISMATCH: expected=$entryCount actual=$($sc.zipEntryCount)")
            $exitCode = 1
        }
        
        # Check sidecars claim
        if ($sc.sidecars.finalSelfCheckInsideZip -eq $false) {
            [void]$passes.Add("self_check_not_in_zip: confirmed")
        } else {
            [void]$errors.Add("SELF_CHECK_CLAIMS_INSIDE_ZIP")
            $exitCode = 1
        }
        
        if ($sc.sidecars.metaInsideZip -eq $false) {
            [void]$passes.Add("meta_not_in_zip: confirmed")
        } else {
            [void]$errors.Add("META_CLAIMS_INSIDE_ZIP")
            $exitCode = 1
        }
        
        # Check verdict
        if ($sc.verdict -eq "PASS") {
            [void]$passes.Add("self_check_verdict: PASS")
        } else {
            [void]$errors.Add("SELF_CHECK_VERDICT_FAIL: $($sc.verdict)")
            $exitCode = 1
        }
        
    } catch {
        [void]$errors.Add("SELF_CHECK_PARSE_ERROR: $_")
        $exitCode = 1
    }
}

# 5. Verify meta sidecar
if (Test-Path $metaPath) {
    try {
        $meta = Get-Content $metaPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($meta.zipSha256 -eq $zipSha256) {
            [void]$passes.Add("meta_sha256_matches: $zipSha256")
        } else {
            [void]$errors.Add("META_SHA256_MISMATCH")
            $exitCode = 1
        }
        if ($meta.zipEntryCount -eq $entryCount) {
            [void]$passes.Add("meta_entry_count_matches: $entryCount")
        } else {
            [void]$errors.Add("META_ENTRY_COUNT_MISMATCH")
            $exitCode = 1
        }
    } catch {
        [void]$errors.Add("META_PARSE_ERROR: $_")
        $exitCode = 1
    }
}

# 6. ZIP internal checks
# No .final-self-check.json inside ZIP
$hasSelfCheckInside = ($zipEntries | Where-Object { $_ -match "\.final-self-check\.json" }).Count -gt 0
if (-not $hasSelfCheckInside) {
    [void]$passes.Add("no_self_check_inside_zip")
} else {
    [void]$errors.Add("SELF_CHECK_FOUND_INSIDE_ZIP")
    $exitCode = 1
}

# No .meta.json inside ZIP  
$hasMetaInside = ($zipEntries | Where-Object { $_ -eq ".meta.json" -or $_ -match "^[^/]*\.meta\.json$" }).Count -gt 0
if (-not $hasMetaInside) {
    [void]$passes.Add("no_meta_inside_zip")
} else {
    [void]$errors.Add("META_FOUND_INSIDE_ZIP")
    $exitCode = 1
}

# No final-zip-self-consistency-report.json inside ZIP
$hasOldSelfCheck = ($zipEntries | Where-Object { $_ -match "final-zip-self-consistency-report" }).Count -gt 0
if (-not $hasOldSelfCheck) {
    [void]$passes.Add("no_old_final_zip_self_consistency_inside_zip")
} else {
    [void]$errors.Add("OLD_FINAL_ZIP_SELF_CONSISTENCY_FOUND_INSIDE_ZIP")
    $exitCode = 1
}

# final-staging-self-consistency-report.json exists inside ZIP
$hasStagingReport = ($zipEntries | Where-Object { $_ -match "final-staging-self-consistency-report" }).Count -gt 0
if ($hasStagingReport) {
    [void]$passes.Add("staging_self_consistency_report_inside_zip")
} else {
    [void]$errors.Add("MISSING_STAGING_SELF_CONSISTENCY_REPORT")
    $exitCode = 1
}

# No root JSON
$rootJson = (@($zipEntries | Where-Object { $_ -notmatch '[/\\]' -and $_ -like '*.json' }).Count)
if ($rootJson -eq 0) {
    [void]$passes.Add("root_json_count: 0")
} else {
    [void]$errors.Add("ROOT_JSON_FOUND: $rootJson file(s)")
    $exitCode = 1
}

# No root PS1
$rootPs1 = (@($zipEntries | Where-Object { $_ -notmatch '[/\\]' -and $_ -like '*.ps1' }).Count)
if ($rootPs1 -eq 0) {
    [void]$passes.Add("root_ps1_count: 0")
} else {
    [void]$errors.Add("ROOT_PS1_FOUND: $rootPs1 file(s)")
    $exitCode = 1
}

# 7. Check schema/layout/sha reports inside ZIP say PASS
$schemaEntry = @($za2 = [System.IO.Compression.ZipFile]::OpenRead($ZipPath); $e = $za2.Entries | Where-Object { ($_.FullName -replace '\\', '/') -eq "reports/audit-bundle-schema-validation-report.json" }; $za2.Dispose(); $e)[0]
# Re-read ZIP for report checks
$za3 = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
$entries = $za3.Entries

function Read-ZipEntry($entries, $path) {
    $entry = @($entries | Where-Object { ($_.FullName -replace '\\', '/') -eq $path })[0]
    if ($entry) {
        $reader = New-Object System.IO.StreamReader($entry.Open())
        $content = $reader.ReadToEnd()
        $reader.Close()
        return $content | ConvertFrom-Json
    }
    return $null
}

$schemaRep = Read-ZipEntry $entries "reports/audit-bundle-schema-validation-report.json"
if ($schemaRep -and $schemaRep.verdict -eq "PASS") {
    [void]$passes.Add("schema_report_verdict: PASS")
} else {
    [void]$errors.Add("SCHEMA_REPORT_NOT_PASS: $($schemaRep.verdict)")
    $exitCode = 1
}

$layoutRep = Read-ZipEntry $entries "reports/bundle-layout-report.json"
if ($layoutRep -and $layoutRep.verdict -eq "PASS") {
    [void]$passes.Add("layout_report_verdict: PASS")
} else {
    [void]$errors.Add("LAYOUT_REPORT_NOT_PASS")
    $exitCode = 1
}

$shaRep = Read-ZipEntry $entries "reports/sha256sums-validation-report.json"
if ($shaRep -and $shaRep.verdict -eq "PASS" -and $shaRep.mismatchCount -eq 0) {
    [void]$passes.Add("sha_report: PASS, 0 mismatches")
} else {
    [void]$errors.Add("SHA_REPORT_NOT_PASS: verdict=$($shaRep.verdict) mismatches=$($shaRep.mismatchCount)")
    $exitCode = 1
}

# Check SHA checkedEntries == SHA256SUMS record count
$shaEntry = @($entries | Where-Object { ($_.FullName -replace '\\', '/') -eq "SHA256SUMS.txt" })[0]
if ($shaEntry) {
    $reader = New-Object System.IO.StreamReader($shaEntry.Open())
    $shaContent = $reader.ReadToEnd()
    $reader.Close()
    $shaLines = @($shaContent -split "`n" | Where-Object { $_.Trim().Length -gt 0 })
    if ($shaRep -and $shaRep.checkedEntries -eq $shaLines.Count) {
        [void]$passes.Add("sha_checked_entries_matches_sha256sums: $($shaLines.Count)")
    } else {
        [void]$errors.Add("SHA_CHECKED_ENTRIES_MISMATCH: sha256sums=$($shaLines.Count) checked=$($shaRep.checkedEntries)")
        $exitCode = 1
    }
}

# Check exitcode files are all 0
$exitcodeFiles = @($entries | Where-Object { ($_.FullName -replace '\\', '/') -match 'exitcode\.txt$' })
$allZero = $true
foreach ($ecf in $exitcodeFiles) {
    $reader = New-Object System.IO.StreamReader($ecf.Open())
    $val = $reader.ReadToEnd().Trim()
    $reader.Close()
    if ($val -ne "0") { $allZero = $false; [void]$errors.Add("EXITCODE_NOT_ZERO: $($ecf.FullName) = $val"); $exitCode = 1 }
}
if ($allZero -and $exitcodeFiles.Count -gt 0) {
    [void]$passes.Add("all_exitcodes_zero: $($exitcodeFiles.Count) files")
} elseif ($exitcodeFiles.Count -eq 0) {
    [void]$passes.Add("no_exitcode_files_found")
}

$za3.Dispose()

# 8. Read final report from ZIP
$za4 = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
$finalReportEntry = @($za4.Entries | Where-Object { $_.Name -match "PHASE_.*FINAL_REPORT" })[0]
if ($finalReportEntry) {
    $reader = New-Object System.IO.StreamReader($finalReportEntry.Open())
    $reportText = $reader.ReadToEnd()
    $reader.Close()
    
    # Check acknowledges T0-R3 does not prove new multi-agent capability
    if ($reportText -match "does NOT prove new multi-agent|T0-R3.*not.*multi-agent|not prove new multi-agent") {
        [void]$passes.Add("final_report_acknowledges_no_new_multi_agent_capability")
    } else {
        [void]$errors.Add("FINAL_REPORT_MISSING_DISCLAIMER: Must state T0-R3 does not prove new multi-agent capability")
        $exitCode = 1
    }
    
    # Check contains ZIP absolute path
    if ($reportText -match [regex]::Escape($ZipPath)) {
        [void]$passes.Add("final_report_contains_zip_absolute_path")
    } else {
        [void]$errors.Add("FINAL_REPORT_MISSING_ZIP_PATH")
        $exitCode = 1
    }
    
    # Check contains self-check sidecar absolute path
    if ($reportText -match [regex]::Escape($selfCheckPath)) {
        [void]$passes.Add("final_report_contains_self_check_sidecar_path")
    } else {
        [void]$errors.Add("FINAL_REPORT_MISSING_SELF_CHECK_PATH")
        $exitCode = 1
    }
}
$za4.Dispose()

# VERDICT
$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{
    phase = "Phase 6C-T0-R3"
    tool = "verify-final-artifacts"
    timestamp = (Get-Date).ToString("o")
    verdict = $verdict
    checkedZipPath = $ZipPath
    zipSha256 = $zipSha256
    zipEntryCount = $entryCount
    errorCount = $errors.Count
    passCount = $passes.Count
    errors = $errors
    passes = $passes
}

if ($Json) {
    Write-Output ($result | ConvertTo-Json -Depth 4)
} else {
    Write-Output ""
    Write-Output "=== FINAL VERDICT: $verdict ==="
    Write-Output "Errors: $($errors.Count) | Passes: $($passes.Count)"
    foreach ($p in $passes) { Write-Output "  [PASS] $p" }
    foreach ($e in $errors) { Write-Output "  [FAIL] $e" }
}

exit $exitCode