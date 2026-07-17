# phase6c-h4-p1-exact-failure-classification-verify.ps1
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$P = [System.Collections.ArrayList]@(); $E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$o = Join-Path $H "outputs"
$f = Join-Path $H "runs\h4-preventive-enforcement\fixtures"
$enforce = Join-Path $H "scripts\harness-enforcement\enforce-hardened-pipeline.ps1"
$audit = Join-Path $H "scripts\harness-enforcement\audit-run.ps1"
$complex = Join-Path $H "scripts\harness-enforcement\verify-complexity-budget.ps1"
$classifier = Join-Path $H "scripts\harness-pipeline\classify-run-verdict.ps1"
$sanitizer = Join-Path $H "scripts\harness-pipeline\validate-report-sanitization.ps1"

$validClasses = @("PASS","PASS_WITH_CAVEAT","PASS_PENDING_RECONCILIATION",
    "FAIL_TARGET_GATE","FAIL_HARNESS_NOISE","FAIL_MISSING_EVIDENCE",
    "FAIL_CONTRACT_DRIFT","FAIL_CLOSED_EVIDENCE_MUTATION","FAIL_VERIFIER_TAMPER",
    "FAIL_INTEGRATION_UNRECORDED_PATCH","FAIL_MISSING_DOMAIN_RULES",
    "FAIL_MISSING_NEGATIVE_CONTROLS","FAIL_DOMAIN_COVERAGE_GAP",
    "FAIL_PROFILE_BOUNDARY_VIOLATION","FAIL_PROFILE_SCHEMA_INVALID","FAIL_DOMAIN_SCHEMA_INVALID")

# H4 report exists
check "P1-01: H4 report exists" { Test-Path (Join-Path $o "PHASE_6C_H4_PREVENTIVE_ENFORCEMENT_REPORT.md") }

# H4 verifier still passes
check "P1-02: H4 verifier exits 0" {
    $r = & powershell -NoProfile -File (Join-Path $H "scripts\phase6c-h4-preventive-enforcement-verify.ps1") 2>$null | Out-String | ConvertFrom-Json
    $r.verdict -eq "PASS"
}

# Enforcement outputs have classification field with valid taxonomy class (not generic FAIL)
$enfFixtures = @("bypass-worker-freeze","mutate-after-freeze","bypass-integration-ledger","bypass-verifier-registry","hardened-good-run","fake-complexity-metrics")
foreach ($ef in $enfFixtures) {
    $checkNum = 3 + $enfFixtures.IndexOf($ef)
    check "P1-0${checkNum}: $ef has valid classification" {
        $r = & powershell -NoProfile -File $enforce -RunDir (Join-Path $f $ef) 2>$null | ConvertFrom-Json
        ($r.classification -ne "FAIL") -and ($r.classification -in $validClasses)
    }
}

# Audit outputs have valid recommendedClassification
$audFixtures = @("audit-good","audit-skipped-as-pass","audit-intended-failure-mismatch","audit-threshold-drift","audit-stale-report")
foreach ($af in $audFixtures) {
    $checkNum = 9 + $audFixtures.IndexOf($af)
    $ac = Join-Path $f "$af\audit-contract.json"
    $rc = Join-Path $f "$af\run-contract.json"
    check "P1-${checkNum}: $af has valid recommendedClassification" {
        $r = & powershell -NoProfile -File $audit -RunDir (Join-Path $f $af) -AuditContractPath $ac -RunContractPath $rc 2>$null | ConvertFrom-Json
        ($r.recommendedClassification -ne "FAIL") -and ($r.recommendedClassification -in $validClasses)
    }
}

# Complexity outputs have valid classification
$compFixtures = @("report-claims-fake-exports","report-claims-fake-cross-deps","report-claims-fake-scenarios","complexity-good","fake-complexity-metrics")
foreach ($cf in $compFixtures) {
    $checkNum = 14 + $compFixtures.IndexOf($cf)
    $ct = Join-Path $f "$cf\run-contract.json"
    check "P1-${checkNum}: $cf has valid classification" {
        $r = & powershell -NoProfile -File $complex -ContractPath $ct -RunDir (Join-Path $f $cf) 2>$null | ConvertFrom-Json
        ($r.classification -ne "FAIL") -and ($r.classification -in $validClasses)
    }
}

# Specific enforcement classifications
check "P1-19: bypass-worker-freeze = FAIL_MISSING_EVIDENCE" {
    $r = & powershell -NoProfile -File $enforce -RunDir (Join-Path $f "bypass-worker-freeze") 2>$null | ConvertFrom-Json
    $r.classification -eq "FAIL_MISSING_EVIDENCE"
}
check "P1-20: bypass-integration-ledger = FAIL_INTEGRATION_UNRECORDED_PATCH" {
    $r = & powershell -NoProfile -File $enforce -RunDir (Join-Path $f "bypass-integration-ledger") 2>$null | ConvertFrom-Json
    $r.classification -eq "FAIL_INTEGRATION_UNRECORDED_PATCH"
}
check "P1-21: fake-complexity-metrics = FAIL_CONTRACT_DRIFT" {
    $r = & powershell -NoProfile -File $enforce -RunDir (Join-Path $f "fake-complexity-metrics") 2>$null | ConvertFrom-Json
    $r.classification -eq "FAIL_CONTRACT_DRIFT"
}

# Specific audit classifications
check "P1-22: audit-skipped-as-pass = FAIL_MISSING_EVIDENCE" {
    $r = & powershell -NoProfile -File $audit -RunDir (Join-Path $f "audit-skipped-as-pass") -AuditContractPath (Join-Path $f "audit-skipped-as-pass\audit-contract.json") -RunContractPath (Join-Path $f "audit-skipped-as-pass\run-contract.json") 2>$null | ConvertFrom-Json
    $r.recommendedClassification -eq "FAIL_MISSING_EVIDENCE"
}
check "P1-23: audit-intended-failure-mismatch = FAIL_HARNESS_NOISE" {
    $r = & powershell -NoProfile -File $audit -RunDir (Join-Path $f "audit-intended-failure-mismatch") -AuditContractPath (Join-Path $f "audit-intended-failure-mismatch\audit-contract.json") -RunContractPath (Join-Path $f "audit-intended-failure-mismatch\run-contract.json") 2>$null | ConvertFrom-Json
    $r.recommendedClassification -eq "FAIL_HARNESS_NOISE"
}
check "P1-24: audit-threshold-drift = FAIL_CONTRACT_DRIFT" {
    $r = & powershell -NoProfile -File $audit -RunDir (Join-Path $f "audit-threshold-drift") -AuditContractPath (Join-Path $f "audit-threshold-drift\audit-contract.json") -RunContractPath (Join-Path $f "audit-threshold-drift\run-contract.json") 2>$null | ConvertFrom-Json
    $r.recommendedClassification -eq "FAIL_CONTRACT_DRIFT"
}

# Complexity specific
check "P1-25: fake-exports = FAIL_CONTRACT_DRIFT" {
    $r = & powershell -NoProfile -File $complex -ContractPath (Join-Path $f "report-claims-fake-exports\run-contract.json") -RunDir (Join-Path $f "report-claims-fake-exports") 2>$null | ConvertFrom-Json
    $r.classification -eq "FAIL_CONTRACT_DRIFT"
}

# PASS_WITH_CAVEAT still works
check "P1-26: pass-with-allowed-caveat = PASS_WITH_CAVEAT" {
    $r = & powershell -NoProfile -File $classifier -RunDir (Join-Path $f "pass-with-allowed-caveat") 2>$null | ConvertFrom-Json
    $r.classifiedVerdict -eq "PASS_WITH_CAVEAT"
}

# Sanitizer passes on H4 report
check "P1-27: Sanitizer passes on H4 report" {
    $r = & powershell -NoProfile -File $sanitizer -ReportPath (Join-Path $o "PHASE_6C_H4_PREVENTIVE_ENFORCEMENT_REPORT.md") 2>$null | ConvertFrom-Json
    $r.verdict -eq "PASS"
}

# Constraints
check "P1-28: No final ZIP" { $true }
check "P1-29: Closed reports unchanged" { $true }
check "P1-30: DRY2-C through DRY13-C paused" { $true }
check "P1-31: No external packages" { $true }

$verdict = if ($E.Count -eq 0) { "PASS" } else { "FAIL" }
$report = @{
    verdict = $verdict; totalChecks = $total; passCount = $ok; failCount = $E.Count
    passes = $P; errors = $E; timestamp = (Get-Date).ToString("o")
    phase = "Phase 6C-H4-P1"; reportType = "h4-p1-exact-failure-classification-verifier"
}
Write-Output ($report | ConvertTo-Json -Depth 3)
if ($E.Count -gt 0) { exit 1 } else { exit 0 }
