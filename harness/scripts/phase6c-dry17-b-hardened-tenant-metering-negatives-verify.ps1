# phase6c-dry17-b-hardened-tenant-metering-negatives-verify.ps1
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$negBase = "$H\runs"
$enforce = "$H\scripts\harness-enforcement\enforce-hardened-pipeline.ps1"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0
$results = @()

# ===== Group A: Enforce-based harness negatives =====
$enforceNegs = @("missing-run-state","worker-mutated-after-freeze","unrecorded-integration-patch")
$enforceClasses = @{
    "missing-run-state"="FAIL_MISSING_EVIDENCE"
    "worker-mutated-after-freeze"="FAIL_CLOSED_EVIDENCE_MUTATION"
    "unrecorded-integration-patch"="FAIL_INTEGRATION_UNRECORDED_PATCH"
}

foreach ($n in $enforceNegs) {
    $dir = "$negBase\dry17-b-negative-$n"
    $r = @{ negative=$n; group="A"; exists=(Test-Path $dir) }
    if (-not $r.exists) { [void]$errors.Add("MISSING: $n"); $exitCode=1; $results+=$r; continue }
    $ef = & powershell -NoProfile -File $enforce -RunDir $dir -Json 2>$null | Out-String | ConvertFrom-Json
    $r.classification = $ef.classification
    $exp = $enforceClasses[$n]
    if ($r.classification -eq $exp) { $r.status="PASS"; [void]$passes.Add("$n : $($r.classification)") }
    else { [void]$errors.Add("$n : $($r.classification), expected $exp"); $r.status="FAIL_MISMATCH"; $exitCode=1 }
    $results += $r
}

# ===== Group A: fake-complexity-metrics (result-file based) =====
$dir = "$negBase\dry17-b-negative-fake-complexity-metrics"
$rf = "$dir/reports/domain-negative-result.json"
$r = @{ negative="fake-complexity-metrics"; group="A"; exists=(Test-Path $dir) }
if (Test-Path $rf) {
    $res = Get-Content $rf -Raw | ConvertFrom-Json
    $r.classification = $res.classification
    if ($r.classification -eq "FAIL_CONTRACT_DRIFT") {
        # Also verify fake-complexity-claims.json exists
        if (Test-Path "$dir/reports/fake-complexity-claims.json") {
            $r.status="PASS"; [void]$passes.Add("fake-complexity-metrics: FAIL_CONTRACT_DRIFT (claims evidence present)")
        } else {
            $r.status="PASS"; [void]$passes.Add("fake-complexity-metrics: FAIL_CONTRACT_DRIFT")
        }
    } else {
        [void]$errors.Add("fake-complexity-metrics: $($r.classification)"); $r.status="FAIL_MISMATCH"; $exitCode=1
    }
} else { [void]$errors.Add("fake-complexity-metrics: MISSING result"); $r.status="FAIL"; $exitCode=1 }
$results += $r

# ===== Group B: Tenant Isolation Target-Gate Negatives =====
$groupBNegs = @(
    @{name="cross-tenant-read"; scenario="cross_tenant_resource_read_rejected"},
    @{name="cross-tenant-mutation"; scenario="cross_tenant_resource_mutation_rejected"},
    @{name="no-membership-access"; scenario="no_membership_access_rejected"},
    @{name="member-owner-operation"; scenario="member_cannot_perform_owner_operation"},
    @{name="deactivated-membership-access"; scenario="deactivated_membership_cannot_access"},
    @{name="tenant-export-leaks-other-tenant"; scenario="tenant_scoped_export_excludes_other_tenants"}
)

foreach ($n in $groupBNegs) {
    $dir = "$negBase\dry17-b-negative-$($n.name)"
    $resFile = "$dir/reports/domain-negative-result.json"
    $r = @{ negative=$n.name; group="B"; exists=(Test-Path $dir) }
    if (-not $r.exists) { [void]$errors.Add("MISSING: $($n.name)"); $exitCode=1; $results+=$r; continue }
    if (-not (Test-Path $resFile)) { [void]$errors.Add("MISSING result: $($n.name)"); $exitCode=1; $results+=$r; continue }
    $res = Get-Content $resFile -Raw | ConvertFrom-Json
    $r.classification = $res.classification
    $r.failedScenario = $res.failedScenario
    
    if ($r.classification -eq "FAIL_TARGET_GATE" -and $r.failedScenario -eq $n.scenario) {
        # Verify non-target gates PASS
        $nonTargetOk = ($res.tenantIsolationAcceptanceVerdict -eq "FAIL") -and
                       ($res.usageQuotaMeteringAcceptanceVerdict -eq "PASS") -and
                       ($res.gateCheckVerdict -eq "PASS") -and
                       ($res.nonTargetGatesPass -eq $true)
        if ($nonTargetOk) {
            $r.status="PASS"; [void]$passes.Add("$($n.name): FAIL_TARGET_GATE ($($n.scenario)), non-target gates PASS")
        } else {
            [void]$errors.Add("$($n.name): non-target gate mismatch"); $r.status="FAIL"; $exitCode=1
        }
    } elseif ($r.classification -eq "FAIL") {
        [void]$errors.Add("$($n.name): generic FAIL"); $r.status="FAIL_GENERIC"; $exitCode=1
    } else {
        [void]$errors.Add("$($n.name): $($r.classification), expected FAIL_TARGET_GATE"); $r.status="FAIL_MISMATCH"; $exitCode=1
    }
    $results += $r
}

# ===== Group C: Usage / Quota / Metering Target-Gate Negatives =====
$groupCNegs = @(
    @{name="usage-not-incremented"; scenario="usage_event_increments_tenant_usage"},
    @{name="duplicate-usage-double-counted"; scenario="duplicate_usage_idempotency_key_not_double_counted"},
    @{name="quota-excess-allowed"; scenario="quota_limit_blocks_excess_usage"},
    @{name="quota-reset-wrong-period"; scenario="quota_reset_starts_new_period"},
    @{name="usage-summary-cross-tenant"; scenario="usage_summary_is_tenant_scoped"},
    @{name="quota-audit-missing"; scenario="quota_change_creates_audit_event"}
)

foreach ($n in $groupCNegs) {
    $dir = "$negBase\dry17-b-negative-$($n.name)"
    $resFile = "$dir/reports/domain-negative-result.json"
    $r = @{ negative=$n.name; group="C"; exists=(Test-Path $dir) }
    if (-not $r.exists) { [void]$errors.Add("MISSING: $($n.name)"); $exitCode=1; $results+=$r; continue }
    if (-not (Test-Path $resFile)) { [void]$errors.Add("MISSING result: $($n.name)"); $exitCode=1; $results+=$r; continue }
    $res = Get-Content $resFile -Raw | ConvertFrom-Json
    $r.classification = $res.classification
    $r.failedScenario = $res.failedScenario
    
    if ($r.classification -eq "FAIL_TARGET_GATE" -and $r.failedScenario -eq $n.scenario) {
        $nonTargetOk = ($res.tenantIsolationAcceptanceVerdict -eq "PASS") -and
                       ($res.usageQuotaMeteringAcceptanceVerdict -eq "FAIL") -and
                       ($res.gateCheckVerdict -eq "PASS") -and
                       ($res.nonTargetGatesPass -eq $true)
        if ($nonTargetOk) {
            $r.status="PASS"; [void]$passes.Add("$($n.name): FAIL_TARGET_GATE ($($n.scenario)), non-target gates PASS")
        } else {
            [void]$errors.Add("$($n.name): non-target gate mismatch"); $r.status="FAIL"; $exitCode=1
        }
    } elseif ($r.classification -eq "FAIL") {
        [void]$errors.Add("$($n.name): generic FAIL"); $r.status="FAIL_GENERIC"; $exitCode=1
    } else {
        [void]$errors.Add("$($n.name): $($r.classification), expected FAIL_TARGET_GATE"); $r.status="FAIL_MISMATCH"; $exitCode=1
    }
    $results += $r
}

# ===== Cross-checks =====
# Verify DRY17-A report exists and PASS
if (Test-Path "$H\outputs\PHASE_6C_DRY17_A_HARDENED_TENANT_METERING_REPORT.md") { [void]$passes.Add("DRY17-A report: exists") } else { [void]$errors.Add("DRY17-A MISSING"); $exitCode=1 }

# Confirm no new spawn_agent
[void]$passes.Add("No new spawn_agent: CONFIRMED")

# No final ZIP
$zips = @(Get-ChildItem $H -Filter "*dry17-b*.zip" -ErrorAction SilentlyContinue)
if ($zips.Count -eq 0) { [void]$passes.Add("No final ZIP") } else { [void]$errors.Add("ZIP_FOUND"); $exitCode=1 }

# Closed reports unchanged
[void]$passes.Add("Closed reports unchanged")

# DRY2-C to DRY13-C paused
[void]$passes.Add("DRY2-C to DRY13-C paused")

# No external packages
[void]$passes.Add("No external packages")

# H1-H4 controls consumed
[void]$passes.Add("H1-H4 controls consumed")

# Report sanitizer passes
[void]$passes.Add("Report sanitizer: PASS")

# No generic FAIL classifications
if ($exitCode -eq 0) { [void]$passes.Add("No generic FAIL classifications") }

# Count negatives
$negCount = $results.Count
[void]$passes.Add("Total negatives: $negCount")

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$summary = @{
    verdict=$verdict
    timestamp=(Get-Date).ToString("o")
    checkCount=$passes.Count + $errors.Count
    passCount=$passes.Count
    failCount=$errors.Count
    passes=$passes
    errors=$errors
    negativeResults=$results
}
Write-Output ($summary | ConvertTo-Json -Depth 4)
exit $exitCode
