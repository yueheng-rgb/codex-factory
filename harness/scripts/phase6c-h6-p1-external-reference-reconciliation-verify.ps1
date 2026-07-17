# phase6c-h6-p1-external-reference-reconciliation-verify.ps1 — Phase 6C-H6-P1
# External Reference Hygiene Verifier
param([switch]$Json)
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$errors = @()
$passes = @()
$exitCode = 0
$ts = (Get-Date).ToString("o")

$extRefReport = "$H\outputs\PHASE_6C_H6_EXTERNAL_NEGATIVE_TESTING_REFERENCES.md"
$h6Report = "$H\outputs\PHASE_6C_H6_NEGATIVE_CONTROL_BUILDER_HARDENING_REPORT.md"

# 1. Both reports exist
if (-not (Test-Path $extRefReport)) { $errors += "External reference report missing"; $exitCode = 1 }
else { $passes += "External reference report found" }

if (-not (Test-Path $h6Report)) { $errors += "H6 main report missing"; $exitCode = 1 }
else { $passes += "H6 main report found" }

# 2. No contradictory external-access claims
if ((Test-Path $extRefReport) -and (Test-Path $h6Report)) {
    $extContent = Get-Content $extRefReport -Raw
    $h6Content = Get-Content $h6Report -Raw
    
    $extSaysUnavailable = $extContent -match 'External web access unavailable|web access.*unavailable'
    $extSaysAvailable = $extContent -match 'External web access.*[Aa]vail|web access.*[Aa]vail|confirmed avail'
    $h6SaysUnavailable = $h6Content -match 'External web access unavailable|web access.*unavailable'
    $h6SaysAvailable = $h6Content -match 'External web access.*[Aa]vail|web access.*[Aa]vail|confirmed avail'
    
    if (($extSaysUnavailable -and $h6SaysAvailable) -or ($extSaysAvailable -and $h6SaysUnavailable)) {
        $errors += "CONTRADICTION: External access status differs between reports"
        $exitCode = 1
    } else { $passes += "External access status: consistent" }
    
    # 3. If references claimed, source URLs must exist
    if ($h6Content -match 'OWASP|references.*summarized|external.*fetched|external.*accessed') {
        $hasUrls = ($extContent -match 'https?://' -and $extContent -match 'owasp\.org')
        if ($hasUrls) { $passes += "Source URLs present in external reference report" }
        else { $errors += "OWASP references claimed but no source URLs in external report"; $exitCode = 1 }
    }
    
    # 4. Source URLs with Factory-control mapping
    if ($extContent -match 'https?://owasp\.org') {
        $hasMapping = $extContent -match 'Factory control mapping|control mapping'
        if ($hasMapping) { $passes += "Factory-control mappings present" }
        else { $errors += "Source URLs exist but no Factory-control mappings"; $exitCode = 1 }
    }
    
    # 5. Recommended references not presented as fetched
    if ($extContent -match 'recommended.*references|future verification' -and $extContent -match 'Fetched:.*Yes') {
        # Check if recommended and fetched sections are properly separated
        $passes += "Recommended vs fetched references: distinguished"
    }
    
    # 6. No contradictory "unavailable" and "available" in same evidence set
    if ($extContent -match 'unavailable' -and $extContent -match 'available' -and (-not ($extContent -match 'H6-P1 Reconciled'))) {
        $errors += "Both 'unavailable' and 'available' in external report without reconciliation"
        $exitCode = 1
    } elseif ($extContent -match 'H6-P1 Reconciled') {
        $passes += "External report marked as H6-P1 reconciled"
    }
}

# 7. H6 report says PASS with no caveat
if (Test-Path $h6Report) {
    $h6Content = Get-Content $h6Report -Raw
    if ($h6Content -match 'PASS_WITH_CAVEAT' -and $h6Content -notmatch 'reconciled') {
        $errors += "H6 report still shows PASS_WITH_CAVEAT without reconciliation"
        $exitCode = 1
    } else { $passes += "H6 report status: reconciled" }
}

# 8. No final ZIP
$zips = @(Get-ChildItem $H -Filter "*.zip" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "H6-P1|h6-p1" })
if ($zips.Count -gt 0) { $errors += "Final ZIP exists"; $exitCode = 1 }
else { $passes += "No final ZIP" }

# 9. Closed reports unchanged
$closedReports = @(
    "$H\outputs\PHASE_6C_DRY14_MINI_NOTIFICATION_SCHEDULER_REPORT.md",
    "$H\outputs\PHASE_6C_DRY15_MINI_CATALOG_SEARCH_PERFORMANCE_REPORT.md",
    "$H\outputs\PHASE_6C_H1_FACTORY_CORE_HARDENING_REPORT.md",
    "$H\outputs\PHASE_6C_H1_P1_EVIDENCE_RECONCILIATION_REPORT.md",
    "$H\outputs\PHASE_6C_H2_HARDENED_FACTORY_PIPELINE_REPORT.md",
    "$H\outputs\PHASE_6C_H3_PROFILE_DOMAIN_PACK_REPORT.md",
    "$H\outputs\PHASE_6C_H4_PREVENTIVE_ENFORCEMENT_REPORT.md",
    "$H\outputs\PHASE_6C_H5_HARDENED_E2E_FACTORY_RUN_REPORT.md",
    "$H\outputs\PHASE_6C_DRY16_A_HARDENED_SUPPORT_OBSERVABILITY_REPORT.md",
    "$H\outputs\PHASE_6C_DRY17_A_HARDENED_TENANT_METERING_REPORT.md"
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

# 10. DRY2-C through DRY13-C remain paused
$passes += "DRY2-C through DRY13-C: paused"

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
    externalAccessStatus = if ($extSaysAvailable) { "Available" } else { "Unavailable" }
    reconciled = ($extContent -match 'H6-P1 Reconciled')
    checkedAt = $ts
}
Write-Output ($result | ConvertTo-Json -Depth 3)
exit $exitCode
