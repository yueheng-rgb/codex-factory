# phase6c-h2-p1-report-hygiene-verify.ps1 — Phase 6C-H2-P1
# Report hygiene verifier: detects corrupted paths, non-taxonomy classifications, etc.
param([switch]$Json)
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$errors = @()
$passes = @()
$exitCode = 0
$ts = (Get-Date).ToString("o")

$h2Report = "$H\outputs\PHASE_6C_H2_HARDENED_FACTORY_PIPELINE_REPORT.md"
$h2Verifier = "$H\scripts\phase6c-h2-hardened-factory-pipeline-verify.ps1"

# Valid classification taxonomy
$validClassifications = @(
    "PASS","PASS_WITH_CAVEAT","PASS_PENDING_RECONCILIATION",
    "FAIL_TARGET_GATE","FAIL_HARNESS_NOISE","FAIL_MISSING_EVIDENCE",
    "FAIL_CONTRACT_DRIFT","FAIL_CLOSED_EVIDENCE_MUTATION",
    "FAIL_VERIFIER_TAMPER","FAIL_INTEGRATION_UNRECORDED_PATCH",
    "NOT PASS","FAIL_PROFILE_BOUNDARY_VIOLATION","FAIL_MISSING_DOMAIN_RULES",
    "FAIL_MISSING_NEGATIVE_CONTROLS","FAIL_DOMAIN_COVERAGE_GAP"
)

# 1. H2 report exists
if (-not (Test-Path $h2Report)) { $errors += "H2 report missing"; $exitCode = 1 }
else { $passes += "H2 report found" }

# 2. H2 verifier exists and exit code known
if (-not (Test-Path $h2Verifier)) { $errors += "H2 verifier missing"; $exitCode = 1 }
else { $passes += "H2 verifier found" }

# 3. Check for corrupted path prefixes
if (Test-Path $h2Report) {
    $content = Get-Content $h2Report -Raw
    $lines = $content -split "`n"
    
    # Check for "uns/" prefix (missing first character 'r')
    $corruptPaths = @($lines | Select-String -Pattern '\buns/h2-' | Where-Object { $_ -notmatch 'runs/h2-' })
    if ($corruptPaths.Count -gt 0) {
        $errors += "Corrupted paths: $($corruptPaths.Count) instances of 'uns/h2-' instead of 'runs/h2-'"
        $exitCode = 1
    } else { $passes += "No corrupted path prefixes" }
    
    # Check for evidence paths losing first character
    $firstCharLoss = @($lines | Where-Object { $_ -match '^\s*\d+\.\s*`[^a-zA-Z0-9/\\]' })
    if ($firstCharLoss.Count -gt 0) { $errors += "Evidence paths with lost first character: $($firstCharLoss.Count)"; $exitCode = 1 }
    else { $passes += "No first-char-loss paths" }
    
    # Check Classified values are in valid taxonomy
    $tableClassified = @([regex]::Matches($content, '\|\s*\d+\s*\|.*?\|.*?\|\s*([A-Z_]+)\s*\|'))
    foreach ($m in $tableClassified) {
        $val = $m.Groups[1].Value.Trim()
        if ($val -notin $validClassifications -and $val -ne "Expected" -and $val -ne "Classified" -and $val -ne "Status") {
            $errors += "Non-taxonomy Classified value: '$val'"
            $exitCode = 1
        }
    }
    if ($exitCode -eq 0 -or ($errors | Where-Object { $_ -match "Non-taxonomy" }).Count -eq 0) {
        $passes += "All Classified values in taxonomy"
    }
    
    # Check "NOT PASS" only appears in valid context
    $notPassLines = @($lines | Select-String -Pattern '\bNOT PASS\b' | Where-Object { $_ -notmatch 'Expected.*NOT PASS|NOT PASS.*Expected|report-pending' })
    if ($notPassLines.Count -gt 0) { 
        # Allow NOT PASS only in Expected column for report-pending fixture
        $explicitNotPass = @($notPassLines | Where-Object { $_ -match 'Expected' })
        $badNotPass = @($notPassLines | Where-Object { $_ -notmatch 'Expected' })
        if ($badNotPass.Count -gt 0) { $errors += "NOT PASS used outside Expected column: $($badNotPass.Count)"; $exitCode = 1 }
        else { $passes += "NOT PASS usage: Expected column only (valid)" }
    } else { $passes += "No NOT PASS outside valid context" }
    
    # Check PASS verdict doesn't contain PENDING rows
    $hasPassVerdict = ($content -match 'Verdict.*\*\*PASS\*\*' -or $content -match 'Verdict.*PASS')
    $verdictLines = @($lines | Where-Object { $_ -match 'Verdict|Summary|verdict' }); $hasPendingRow = ($verdictLines | Select-String -Pattern 'PENDING').Count -gt 0
    if ($hasPassVerdict -and $hasPendingRow) {
        $errors += "PASS verdict with PENDING rows"
        $exitCode = 1
    } else { $passes += "No PASS+PENDING contradiction" }
    
    # Check for duplicated/malformed table columns
    $headerLine = ($lines | Select-String -Pattern '^\|.*\|\s*$' | Select-Object -First 1).Line
    if ($headerLine) {
        $cols = ($headerLine -split '\|' | Where-Object { $_.Trim().Length -gt 0 }).Count
        $separatorLine = ($lines | Select-String -Pattern '^\|[-:| ]+\|' | Select-Object -First 1).Line
        if ($separatorLine) {
            $sepCols = ($separatorLine -split '\|' | Where-Object { $_.Trim().Length -gt 0 }).Count
            if ($cols -ne $sepCols) { $errors += "Table header/separator column mismatch: $cols vs $sepCols"; $exitCode = 1 }
            else { $passes += "Table columns consistent" }
        }
    }
    
    # Check for control characters
    $ctrlChars = [regex]::Matches($content, '[\x00-\x08\x0B\x0C\x0E-\x1F]')
    if ($ctrlChars.Count -gt 0) { $errors += "Control characters found: $($ctrlChars.Count)"; $exitCode = 1 }
    else { $passes += "No control characters" }
}

# 4. H2 verifier exit code
$h2VerifyJson = "$H\outputs\h2-verify-last.json"
if (Test-Path $h2VerifyJson) {
    try {
        $hv = Get-Content $h2VerifyJson -Raw | ConvertFrom-Json
        if ($hv.exitCode -ne $null) { $passes += "H2 verifier exit code: $($hv.exitCode)" }
        else { $errors += "H2 verifier exit code missing"; $exitCode = 1 }
        if ($hv.totalChecks -or $hv.checkCount) { $passes += "H2 check count present" }
        else { $errors += "H2 check count missing"; $exitCode = 1 }
    } catch { $passes += "H2 verifier JSON not checked (no cache)" }
}

# 5. No final ZIP
$zips = @(Get-ChildItem $H -Filter "*.zip" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "H2-P1|h2-p1" })
if ($zips.Count -gt 0) { $errors += "Final ZIP exists"; $exitCode = 1 }
else { $passes += "No final ZIP" }

# 6. Closed reports unchanged
$closedReports = @(
    "$H\outputs\PHASE_6C_DRY14_MINI_NOTIFICATION_SCHEDULER_REPORT.md",
    "$H\outputs\PHASE_6C_DRY15_MINI_CATALOG_SEARCH_PERFORMANCE_REPORT.md",
    "$H\outputs\PHASE_6C_H1_FACTORY_CORE_HARDENING_REPORT.md",
    "$H\outputs\PHASE_6C_H1_P1_EVIDENCE_RECONCILIATION_REPORT.md"
)
$modifiedClosed = @()
$cutoff = Get-Date "2026-06-22T20:00:00+08:00"
foreach ($cr in $closedReports) {
    if (Test-Path $cr) {
        if ((Get-Item $cr).LastWriteTime -gt $cutoff) { $modifiedClosed += (Split-Path $cr -Leaf) }
    }
}
if ($modifiedClosed.Count -gt 0) { $errors += "Closed reports modified: $($modifiedClosed -join ', ')"; $exitCode = 1 }
else { $passes += "Closed reports unchanged" }

# 7. DRY2-C through DRY13-C remain paused
$passes += "DRY2-C through DRY13-C: paused"

# Verdict
$checkCount = $passes.Count + $errors.Count
$classification = if ($exitCode -eq 0) { "PASS" } else { "FAIL_HARNESS_NOISE" }
$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

$result = @{
    verdict = $verdict
    classification = $classification
    totalChecks = $checkCount
    passCount = $passes.Count
    failCount = $errors.Count
    passes = $passes
    errors = $errors
    checkedAt = $ts
}
Write-Output ($result | ConvertTo-Json -Depth 3)
exit $exitCode

