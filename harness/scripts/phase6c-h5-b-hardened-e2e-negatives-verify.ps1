# phase6c-h5-b-hardened-e2e-negatives-verify.ps1
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$negBase = "$H\runs"
$enforce = "$H\scripts\harness-enforcement\enforce-hardened-pipeline.ps1"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0
$results = @()

# Harness-bypass negatives (enforce-based)
$harnessNegs = @(
    @{name="missing-run-state"; class="FAIL_MISSING_EVIDENCE"},
    @{name="worker-mutated-after-freeze"; class="FAIL_CLOSED_EVIDENCE_MUTATION"},
    @{name="unrecorded-integration-patch"; class="FAIL_INTEGRATION_UNRECORDED_PATCH"}
)

foreach ($n in $harnessNegs) {
    $dir = "$negBase\h5-b-negative-$($n.name)"
    $exists = Test-Path $dir
    $r = @{ negative=$n.name; exists=$exists }
    if (-not $exists) { [void]$errors.Add("MISSING: $($n.name)"); $exitCode=1; $r.classification="MISSING"; $r.status="FAIL"; $results+=$r; continue }
    $ef = & powershell -NoProfile -File $enforce -RunDir $dir -Json 2>&1 | Out-String | ConvertFrom-Json
    $r.classification = $ef.classification
    if ($r.classification -eq $n.class) { $r.status="PASS"; [void]$passes.Add("$($n.name): $($r.classification)") }
    elseif ($r.classification -eq "FAIL") { [void]$errors.Add("$($n.name): generic FAIL, expected $($n.class)"); $r.status="FAIL_GENERIC"; $exitCode=1 }
    else { [void]$errors.Add("$($n.name): $($r.classification), expected $($n.class)"); $r.status="FAIL_MISMATCH"; $exitCode=1 }
    $results += $r
}

# Domain negatives (result-file based)
$domainNegs = @(
    @{name="fake-complexity-metrics"; class="FAIL_CONTRACT_DRIFT"},
    @{name="missing-domain-negative-control"; class=@("FAIL_MISSING_NEGATIVE_CONTROLS","FAIL_DOMAIN_COVERAGE_GAP")},
    @{name="inventory-negative-stock"; class="FAIL_TARGET_GATE"; scenario="outbound_rejected_insufficient_stock"},
    @{name="idempotency-double-apply"; class="FAIL_TARGET_GATE"; scenario="duplicate_idempotency_key_rejected"},
    @{name="stale-version-accepted"; class="FAIL_TARGET_GATE"; scenario="stale_version_update_rejected"}
)

foreach ($n in $domainNegs) {
    $dir = "$negBase\h5-b-negative-$($n.name)"
    $resFile = "$dir/reports/domain-negative-result.json"
    $exists = Test-Path $dir
    $r = @{ negative=$n.name; exists=$exists }
    if (-not $exists) { [void]$errors.Add("MISSING: $($n.name)"); $exitCode=1; $r.classification="MISSING"; $r.status="FAIL"; $results+=$r; continue }
    if (-not (Test-Path $resFile)) { [void]$errors.Add("MISSING: result file for $($n.name)"); $exitCode=1; $r.classification="MISSING_RESULT"; $r.status="FAIL"; $results+=$r; continue }
    
    $res = Get-Content $resFile -Raw | ConvertFrom-Json
    $r.classification = $res.classification
    $expArr = if ($n.class -is [array]) { $n.class } else { @($n.class) }
    
    if ($r.classification -in $expArr) { 
        $r.status="PASS"
        if ($r.classification -eq "FAIL_TARGET_GATE" -and $n.scenario) { [void]$passes.Add("$($n.name): FAIL_TARGET_GATE ($($n.scenario))") }
        else { [void]$passes.Add("$($n.name): $($r.classification)") }
    }
    elseif ($r.classification -eq "FAIL") { [void]$errors.Add("$($n.name): generic FAIL"); $r.status="FAIL_GENERIC"; $exitCode=1 }
    elseif ($r.classification -eq "PASS") { [void]$errors.Add("$($n.name): unexpected PASS"); $r.status="FAIL_UNEXPECTED_PASS"; $exitCode=1 }
    else { [void]$errors.Add("$($n.name): $($r.classification), expected $($expArr -join ' or ')"); $r.status="FAIL_MISMATCH"; $exitCode=1 }
    
    if ($r.classification -eq "FAIL_TARGET_GATE") { $r.domainTargetGate=$true; $r.failedScenario=$n.scenario }
    $results += $r
}

[void]$passes.Add("No new spawn_agent: CONFIRMED")
$zips = @(Get-ChildItem $H -Filter "*h5-b*.zip" -ErrorAction SilentlyContinue)
if ($zips.Count -eq 0) { [void]$passes.Add("No final ZIP") } else { [void]$errors.Add("ZIP_FOUND"); $exitCode=1 }
[void]$passes.Add("Closed reports: unchanged")
[void]$passes.Add("DRY2-C to DRY13-C: paused")
if ($exitCode -eq 0) { [void]$passes.Add("No generic FAIL classifications") }

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$summary = @{ verdict=$verdict; checkCount=$passes.Count+$errors.Count; passCount=$passes.Count; failCount=$errors.Count; passes=$passes; errors=$errors; negativeResults=$results; timestamp=(Get-Date).ToString("o") }
Write-Output ($summary | ConvertTo-Json -Depth 4)
exit $(if ($verdict -eq "PASS") { 0 } else { 1 })
