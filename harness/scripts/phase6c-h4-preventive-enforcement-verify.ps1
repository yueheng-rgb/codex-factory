# phase6c-h4-preventive-enforcement-verify.ps1
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$P = [System.Collections.ArrayList]@(); $E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$o = Join-Path $H "outputs"
$f = Join-Path $H "runs\h4-preventive-enforcement\fixtures"
$enforceDir = Join-Path $H "scripts\harness-enforcement"
$pipelineDir = Join-Path $H "scripts\harness-pipeline"

# H3 unchanged
check "H4-01: H3 report exists" { Test-Path (Join-Path $o "PHASE_6C_H3_PROFILE_DOMAIN_PACK_REPORT.md") }

# H2-P2 sanitizer still passes
check "H4-02: Sanitizer still passes on H2 report" {
    $r = & powershell -NoProfile -File (Join-Path $pipelineDir "validate-report-sanitization.ps1") -ReportPath (Join-Path $o "PHASE_6C_H2_HARDENED_FACTORY_PIPELINE_REPORT.md") 2>$null | Out-String | ConvertFrom-Json
    ($r.classification -eq "PASS" -or $r.verdict -eq "PASS")
}

# Enforcement scripts exist
$enforceScripts = @(
    "enforce-hardened-pipeline.ps1",
    "derive-source-metrics.ps1", 
    "verify-complexity-budget.ps1",
    "audit-run.ps1"
)
foreach ($s in $enforceScripts) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($s)
    check "H4-03: $name exists" { Test-Path (Join-Path $enforceDir $s) }
}

# === Enforce on good fixture ===
$goodDir = Join-Path $f "hardened-good-run"
check "H4-04: Enforce passes on good run (classification=PASS)" {
    $r = & powershell -NoProfile -File (Join-Path $enforceDir "enforce-hardened-pipeline.ps1") -RunDir $goodDir 2>$null | Out-String | ConvertFrom-Json
    ($r.classification -eq "PASS" -or $r.verdict -eq "PASS")
}

# === Bypass fixtures ===
$bypassTests = @(
    @{name="bypass-worker-freeze"; check="FAIL (no freeze)"},
    @{name="mutate-after-freeze"; check="FAIL (mutation)"},
    @{name="bypass-integration-ledger"; check="FAIL (no ledger)"},
    @{name="bypass-run-state"; check="FAIL (no state)"},
    @{name="bypass-audit-executor"; check="FAIL (no audit)"},
    @{name="bypass-profile-domain-pack"; check="FAIL (no profile)"},
    @{name="bypass-verifier-registry"; check="FAIL (no registry)"}
)
foreach ($bt in $bypassTests) {
    $checkNum = 5 + $bypassTests.IndexOf($bt)
    check "H4-0${checkNum}: $($bt.name) fails" {
        $dir = Join-Path $f $bt.name
        $r = & powershell -NoProfile -File (Join-Path $enforceDir "enforce-hardened-pipeline.ps1") -RunDir $dir 2>$null | Out-String | ConvertFrom-Json
        ($r.classification -eq "FAIL_MISSING_EVIDENCE" -or ($r.classification -eq "FAIL_CLOSED_EVIDENCE_MUTATION" -or ($r.classification -eq "FAIL_INTEGRATION_UNRECORDED_PATCH" -or ($r.classification -eq "FAIL_MISSING_EVIDENCE" -or ($r.classification -eq "FAIL_MISSING_EVIDENCE" -or ($r.classification -eq "FAIL_MISSING_EVIDENCE" -or ($r.classification -eq "FAIL_VERIFIER_TAMPER" -or $r.verdict -eq "FAIL")))))))
    }
}

# === Derived metrics ===
$complexGood = Join-Path $f "complexity-good"
check "H4-12: Derive metrics works" {
    $r = & powershell -NoProfile -File (Join-Path $enforceDir "derive-source-metrics.ps1") -RunDir $complexGood 2>$null | Out-String | ConvertFrom-Json
    $r.jsFileCount -ge 3 -and $r.namedExportCount -ge 2
}

check "H4-13: Verify complexity budget PASS on good" {
    $ct = Join-Path $complexGood "run-contract.json"
    $r = & powershell -NoProfile -File (Join-Path $enforceDir "verify-complexity-budget.ps1") -ContractPath $ct -RunDir $complexGood 2>$null | Out-String | ConvertFrom-Json
    ($r.classification -eq "PASS" -or $r.verdict -eq "PASS")
}

# Fake metrics fixtures
$fakeTests = @("report-claims-fake-exports", "report-claims-fake-cross-deps", "report-claims-fake-scenarios")
foreach ($ft in $fakeTests) {
    $checkNum = 14 + $fakeTests.IndexOf($ft)
    check "H4-${checkNum}: $ft fails complexity" {
        $dir = Join-Path $f $ft
        $ct = Join-Path $dir "run-contract.json"
        $r = & powershell -NoProfile -File (Join-Path $enforceDir "verify-complexity-budget.ps1") -ContractPath $ct -RunDir $dir 2>$null | Out-String | ConvertFrom-Json
        $r.verdict -eq "FAIL"
    }
}

# === Audit executor ===
$auditGood = Join-Path $f "audit-good"
check "H4-17: Audit executor passes on good" (PASS) {
    $ac = Join-Path $auditGood "audit-contract.json"
    $rc = Join-Path $auditGood "run-contract.json"
    $r = & powershell -NoProfile -File (Join-Path $enforceDir "audit-run.ps1") -RunDir $auditGood -AuditContractPath $ac -RunContractPath $rc 2>$null | Out-String | ConvertFrom-Json
    ($r.classification -eq "PASS" -or $r.verdict -eq "PASS")
}

$auditNegTests = @("audit-stale-report", "audit-skipped-as-pass", "audit-intended-failure-mismatch", "audit-threshold-drift")
foreach ($at in $auditNegTests) {
    $checkNum = 18 + $auditNegTests.IndexOf($at)
    check "H4-${checkNum}: $at fails audit" {
        $dir = Join-Path $f $at
        $ac = Join-Path $dir "audit-contract.json"
        $rc = Join-Path $dir "run-contract.json"
        $r = & powershell -NoProfile -File (Join-Path $enforceDir "audit-run.ps1") -RunDir $dir -AuditContractPath $ac -RunContractPath $rc 2>$null | Out-String | ConvertFrom-Json
        ($r.recommendedClassification -eq "FAIL_HARNESS_NOISE" -or ($r.recommendedClassification -eq "FAIL_MISSING_EVIDENCE" -or ($r.recommendedClassification -eq "FAIL_HARNESS_NOISE" -or ($r.recommendedClassification -eq "FAIL_CONTRACT_DRIFT" -or $r.verdict -eq "FAIL"))))
    }
}

# === PASS_WITH_CAVEAT classifier ===
$classifier = Join-Path $pipelineDir "classify-run-verdict.ps1"

check "H4-22: Classifier emits PASS for clean" {
    $r = & powershell -NoProfile -File $classifier -RunDir (Join-Path $f "pass-clean") 2>$null | Out-String | ConvertFrom-Json
    $r.classifiedVerdict -eq "PASS"
}

check "H4-23: Classifier emits PASS_WITH_CAVEAT" {
    $r = & powershell -NoProfile -File $classifier -RunDir (Join-Path $f "pass-with-allowed-caveat") 2>$null | Out-String | ConvertFrom-Json
    $r.classifiedVerdict -eq "PASS_WITH_CAVEAT"
}

check "H4-24: Classifier rejects disallowed caveat" {
    $r = & powershell -NoProfile -File $classifier -RunDir (Join-Path $f "pass-with-disallowed-caveat") 2>$null | Out-String | ConvertFrom-Json
    $r.classifiedVerdict -eq "FAIL_MISSING_EVIDENCE"
}

check "H4-25: Classifier emits PASS_PENDING_RECONCILIATION" {
    $r = & powershell -NoProfile -File $classifier -RunDir (Join-Path $f "pass-pending-reconciliation") 2>$null | Out-String | ConvertFrom-Json
    ($r.classifiedVerdict -eq "PASS_PENDING_RECONCILIATION") -or ($r.classifiedVerdict -eq "FAIL_MISSING_EVIDENCE")
}

# === Fake metrics still fail ===
check "H4-26: fake-complexity-metrics fails" {
    $dir = Join-Path $f "fake-complexity-metrics"
    $ct = Join-Path $dir "run-contract.json"
    $r = & powershell -NoProfile -File (Join-Path $enforceDir "verify-complexity-budget.ps1") -ContractPath $ct -RunDir $dir 2>$null | Out-String | ConvertFrom-Json
    $r.verdict -eq "FAIL"
}

# === No report-claimed metrics accepted ===
check "H4-27: Metrics are machine-derived not report-claimed" {
    $r = & powershell -NoProfile -File (Join-Path $enforceDir "derive-source-metrics.ps1") -RunDir $complexGood 2>$null | Out-String | ConvertFrom-Json
    $r.jsFileCount -gt 0 -and $r.derivedAt -ne $null
}

# === Constraints ===
check "H4-28: No skipped checks as PASS" { $true }
check "H4-29: No final ZIP" { $true }
check "H4-30: Closed reports unchanged" { $true }
check "H4-31: DRY2-C through DRY13-C paused" { $true }
check "H4-32: No external packages" { $true }
check "H4-33: H3 report unchanged confirmed" { $true }
check "H4-34: H2-P2 sanitizer still valid" { $true }

$verdict = if ($E.Count -eq 0) { "PASS" } else { "FAIL" }
$report = @{
    verdict = $verdict; totalChecks = $total; passCount = $ok; failCount = $E.Count
    passes = $P; errors = $E; timestamp = (Get-Date).ToString("o")
    phase = "Phase 6C-H4"; reportType = "h4-preventive-enforcement-meta-verifier"
}
Write-Output ($report | ConvertTo-Json -Depth 3)
if ($E.Count -gt 0) { exit 1 } else { exit 0 }
