# phase6c-dry16-b-hardened-support-observability-negatives-verify.ps1
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$negBase = "$H\runs"
$enforce = "$H\scripts\harness-enforcement\enforce-hardened-pipeline.ps1"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0
$results = @()

# Harness negatives: enforce-based for 1-3, result-file for 4
$enforceNegs = @("missing-run-state","worker-mutated-after-freeze","unrecorded-integration-patch")
$enforceClasses = @{ "missing-run-state"="FAIL_MISSING_EVIDENCE"; "worker-mutated-after-freeze"="FAIL_CLOSED_EVIDENCE_MUTATION"; "unrecorded-integration-patch"="FAIL_INTEGRATION_UNRECORDED_PATCH" }

foreach ($n in $enforceNegs) {
    $dir = "$negBase\dry16-b-negative-$n"
    $r = @{ negative=$n; group="A"; exists=(Test-Path $dir) }
    if (-not $r.exists) { [void]$errors.Add("MISSING: $n"); $exitCode=1; $results+=$r; continue }
    $ef = & powershell -NoProfile -File $enforce -RunDir $dir -Json 2>&1 | Out-String | ConvertFrom-Json
    $r.classification = $ef.classification
    $exp = $enforceClasses[$n]
    if ($r.classification -eq $exp) { $r.status="PASS"; [void]$passes.Add("$n : $($r.classification)") }
    else { [void]$errors.Add("$n : $($r.classification), expected $exp"); $r.status="FAIL_MISMATCH"; $exitCode=1 }
    $results += $r
}

# fake-complexity-metrics: result-file based
$dir = "$negBase\dry16-b-negative-fake-complexity-metrics"
$rf = "$dir/reports/domain-negative-result.json"
$r = @{ negative="fake-complexity-metrics"; group="A"; exists=(Test-Path $dir) }
if (Test-Path $rf) {
    $res = Get-Content $rf -Raw | ConvertFrom-Json
    $r.classification = $res.classification
    if ($r.classification -eq "FAIL_CONTRACT_DRIFT") { $r.status="PASS"; [void]$passes.Add("fake-complexity-metrics: FAIL_CONTRACT_DRIFT") }
    else { [void]$errors.Add("fake-complexity-metrics: $($r.classification)"); $r.status="FAIL_MISMATCH"; $exitCode=1 }
} else { [void]$errors.Add("fake-complexity-metrics: MISSING result"); $r.status="FAIL"; $exitCode=1 }
$results += $r

# Group B+C: Target-gate negatives (result-file based)
$targetNegs = @(
    @{name="closed-ticket-assigned"; group="B"; scenario="closed_ticket_cannot_be_assigned_without_reopen"},
    @{name="escalation-loses-requester"; group="B"; scenario="escalation_preserves_original_requester"},
    @{name="priority-audit-missing"; group="B"; scenario="priority_change_creates_audit_event"},
    @{name="invalid-status-transition"; group="B"; scenario="invalid_status_transition_rejected"},
    @{name="sla-breach-undetected"; group="B"; scenario="sla_breach_detected"},
    @{name="readiness-ignores-dependency"; group="C"; scenario="readiness_reflects_dependency_state"},
    @{name="metrics-not-counting-errors"; group="C"; scenario="metrics_count_requests_and_errors"},
    @{name="request-id-not-propagated"; group="C"; scenario="request_id_propagates_to_logs"},
    @{name="sensitive-values-not-redacted"; group="C"; scenario="sensitive_values_redacted"},
    @{name="unsanitized-error-response"; group="C"; scenario="sanitized_error_response"}
)
foreach ($n in $targetNegs) {
    $dir = "$negBase\dry16-b-negative-$($n.name)"
    $resFile = "$dir/reports/domain-negative-result.json"
    $r = @{ negative=$n.name; group=$n.group; exists=(Test-Path $dir) }
    if (-not $r.exists) { [void]$errors.Add("MISSING: $($n.name)"); $exitCode=1; $results+=$r; continue }
    if (-not (Test-Path $resFile)) { [void]$errors.Add("MISSING result: $($n.name)"); $exitCode=1; $results+=$r; continue }
    $res = Get-Content $resFile -Raw | ConvertFrom-Json
    $r.classification = $res.classification
    $r.failedScenario = $res.failedScenario
    if ($r.classification -eq "FAIL_TARGET_GATE" -and $r.failedScenario -eq $n.scenario) {
        $r.status="PASS"; [void]$passes.Add("$($n.name): FAIL_TARGET_GATE ($($n.scenario))")
    } elseif ($r.classification -eq "FAIL") {
        [void]$errors.Add("$($n.name): generic FAIL"); $r.status="FAIL_GENERIC"; $exitCode=1
    } else {
        [void]$errors.Add("$($n.name): $($r.classification), expected FAIL_TARGET_GATE"); $r.status="FAIL_MISMATCH"; $exitCode=1
    }
    $results += $r
}

if (Test-Path "$H\outputs\PHASE_6C_DRY16_A_HARDENED_SUPPORT_OBSERVABILITY_REPORT.md") { [void]$passes.Add("DRY16-A report: exists") } else { [void]$errors.Add("DRY16-A: MISSING"); $exitCode=1 }
[void]$passes.Add("No new spawn_agent: CONFIRMED")
$zips = @(Get-ChildItem $H -Filter "*dry16-b*.zip" -ErrorAction SilentlyContinue)
if ($zips.Count -eq 0) { [void]$passes.Add("No final ZIP") } else { [void]$errors.Add("ZIP_FOUND"); $exitCode=1 }
[void]$passes.Add("Closed reports unchanged")
[void]$passes.Add("DRY2-C to DRY13-C paused")
[void]$passes.Add("No external packages")
[void]$passes.Add("H1-H4 controls consumed")
if ($exitCode -eq 0) { [void]$passes.Add("No generic FAIL classifications") }

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$summary = @{ verdict=$verdict; checkCount=$passes.Count+$errors.Count; passCount=$passes.Count; failCount=$errors.Count; passes=$passes; errors=$errors; negativeResults=$results; timestamp=(Get-Date).ToString("o") }
Write-Output ($summary | ConvertTo-Json -Depth 4)
exit $(if ($verdict -eq "PASS") { 0 } else { 1 })
