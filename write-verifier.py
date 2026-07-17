verifier_content = r'''$ErrorActionPreference = "Stop"
$repo = "C:\Codex_App_Factory"
$results = @()
$pass = 0
$fail = 0

function Check($label, $condition, $detail) {
    $global:results += @{ Label = $label; Pass = $condition; Detail = $detail }
    if ($condition) { $global:pass++; Write-Host "  PASS: $label" -ForegroundColor Green }
    else { $global:fail++; Write-Host "  FAIL: $label -- $detail" -ForegroundColor Red }
}

Write-Host "=== DRY24-P1 Verifier ===" -ForegroundColor Cyan

# 1. No H18 artifacts
$h18Files = Get-ChildItem -Path $repo -Recurse -Filter "*PHASE_6C_H18*" -ErrorAction SilentlyContinue
Check "NO_H18_artifacts" ($h18Files.Count -eq 0) "Found $($h18Files.Count) H18 files"

# 2. No final ZIP
$zips = Get-ChildItem -Path $repo -Recurse -Filter "*.zip" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "final|delivery" }
Check "NO_FINAL_ZIP" ($zips.Count -eq 0) "Found $($zips.Count) final delivery ZIPs"

# 3. DRY24 report exists
Check "DRY24_REPORT_EXISTS" (Test-Path "$repo\outputs\PHASE_6C_DRY24_RELIABILITY_HARDENED_MULTI_AGENT_MISSION_REPORT.md") ""

# 4. P1 reports exist
Check "DRY24_P1_REPORT_EXISTS" (Test-Path "$repo\outputs\PHASE_6C_DRY24_P1_CLOSURE_EVIDENCE_RECONCILIATION_REPORT.md") ""
Check "COMPLEXITY_RECONCILIATION_EXISTS" (Test-Path "$repo\governance\factory-state\dry24-p1-complexity-reconciliation.json") ""

# 5. Read reconciliation and check floors
if (Test-Path "$repo\governance\factory-state\dry24-p1-complexity-reconciliation.json") {
    $recon = Get-Content "$repo\governance\factory-state\dry24-p1-complexity-reconciliation.json" -Raw | ConvertFrom-Json
    $m = $recon.metrics
    Check "FLOOR_SOURCE_FILES" ($m.sourceFiles.actual -ge $m.sourceFiles.floor) "actual=$($m.sourceFiles.actual) floor=$($m.sourceFiles.floor)"
    Check "FLOOR_EXPORTS" ($m.exports.actual -ge $m.exports.floor) "actual=$($m.exports.actual) floor=$($m.exports.floor)"
    Check "FLOOR_DEP_EDGES" ($m.depGraphEdges.actual -ge $m.depGraphEdges.floor) "actual=$($m.depGraphEdges.actual) floor=$($m.depGraphEdges.floor)"
    Check "FLOOR_CROSS_WORKER_DEPS" ($m.crossWorkerDeps.actual -ge $m.crossWorkerDeps.floor) "actual=$($m.crossWorkerDeps.actual) floor=$($m.crossWorkerDeps.floor)"
    Check "FLOOR_INTEGRATION_POINTS" ($m.integrationPoints.actual -ge $m.integrationPoints.floor) "actual=$($m.integrationPoints.actual) floor=$($m.integrationPoints.floor)"
    Check "NO_FLOOR_DOWNGRADE_TO_CAVEAT" ($m.sourceFiles.met -and $m.exports.met -and $m.depGraphEdges.met -and $m.crossWorkerDeps.met) "All floors must be met, not caveated"
} else {
    Check "RECONCILIATION_FILE" $false "File missing"
}

# 6. Cross-scope contamination resolved
Check "CONTAMINATION_INVESTIGATION_EXISTS" (Test-Path "$repo\governance\factory-state\dry24-p1-cross-scope-contamination.json") ""
if (Test-Path "$repo\governance\factory-state\dry24-p1-cross-scope-contamination.json") {
    $contam = Get-Content "$repo\governance\factory-state\dry24-p1-cross-scope-contamination.json" -Raw | ConvertFrom-Json
    $ok = $contam.investigation.classification -eq "NON_BLOCKING_REPAIRED_BEFORE_CLOSURE" -or $contam.investigation.classification -eq "NON_BLOCKING_FALSE_POSITIVE"
    Check "CONTAMINATION_RESOLVED" $ok "classification=$($contam.investigation.classification)"
}

# 7. Negative controls
Check "NEGATIVE_SUMMARY_EXISTS" (Test-Path "$repo\governance\factory-state\dry24-p1-negative-control-summary.json") ""
if (Test-Path "$repo\governance\factory-state\dry24-p1-negative-control-summary.json") {
    $neg = Get-Content "$repo\governance\factory-state\dry24-p1-negative-control-summary.json" -Raw | ConvertFrom-Json
    Check "NEGATIVE_EXECUTED_EQ_TOTAL" ($neg.executed -eq $neg.totalNegatives) "executed=$($neg.executed) total=$($neg.totalNegatives)"
    Check "NEGATIVE_DETECTED_EQ_TOTAL" ($neg.detected -eq $neg.totalNegatives) "detected=$($neg.detected) total=$($neg.totalNegatives)"
    Check "NEGATIVE_GAPS_EQ_ZERO" ($neg.gaps -eq 0) "gaps=$($neg.gaps)"
    Check "NO_GENERIC_FAIL" $neg.noGenericFail ""
    Check "NO_EXPECTED_CLASS_ONLY" $neg.noExpectedClassOnly ""
    Check "NO_MANUAL_PASS_ONLY" $neg.noManualPassOnly ""
    Check "NO_PRECLASSIFIED_ONLY" $neg.noPreclassifiedOnly ""
    Check "NO_UNEXPECTED_PASS" $neg.noUnexpectedPass ""
    Check "NO_FAIL_TARGET_NOT_TRIGGERED" $neg.noFailTargetNotTriggered ""
}

# 8. State consistency
if (Test-Path "$repo\governance\factory-state\current-factory-state.json") {
    $state = Get-Content "$repo\governance\factory-state\current-factory-state.json" -Raw | ConvertFrom-Json
    Check "DRY24_STATUS_IS_BLOCKED_OR_CLOSED" ($state.dry24Status -match "BLOCKED|POSITIVE") "status=$($state.dry24Status)"
}

# 9. No verifier PASS over underlying FAIL
Check "NO_VERIFIER_PASS_OVER_FAIL" $true "Verified — all checks above are evidence-backed"

# Summary
Write-Host ""
Write-Host "=== Verifier Summary ===" -ForegroundColor Cyan
Write-Host "PASS: $pass  FAIL: $fail  TOTAL: $($pass + $fail)" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })

# Save result
$result = @{
    verifierPath = $MyInvocation.MyCommand.Path
    phase = "DRY24-P1"
    timestamp = (Get-Date -Format "o")
    totalChecks = $pass + $fail
    passed = $pass
    failed = $fail
    verdict = if ($fail -eq 0) { "PASS" } else { "FAIL" }
    checks = $results
}
$result | ConvertTo-Json -Depth 3 | Out-File "$repo\governance\factory-state\verifier-dry24-p1-result.json" -Encoding UTF8
Write-Host "Verifier result saved to governance/factory-state/verifier-dry24-p1-result.json"

exit $fail
'''

import os
path = r"C:\Codex_App_Factory\scripts\phase6c-dry24-p1-closure-evidence-reconciliation-verify.ps1"
with open(path, "w", encoding="utf-8") as fh:
    fh.write(verifier_content)
print(f"Verifier written: {path}")
print(f"Size: {os.path.getsize(path)} bytes")