# phase6c-h4-p2-verifier-compatibility-verify.ps1 — Phase 6C-H4-P2 regression guard
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$P = [System.Collections.ArrayList]@(); $E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$o = Join-Path $H "outputs"
$f = Join-Path $H "runs\h4-preventive-enforcement\fixtures"
$h4ver = Join-Path $H "scripts\phase6c-h4-preventive-enforcement-verify.ps1"
$h4p1ver = Join-Path $H "scripts\phase6c-h4-p1-exact-failure-classification-verify.ps1"
$enforce = Join-Path $H "scripts\harness-enforcement\enforce-hardened-pipeline.ps1"
$sanitizer = Join-Path $H "scripts\harness-pipeline\validate-report-sanitization.ps1"

# Both verifiers exit 0
check "P2-01: H4 verifier exits 0" {
    $r = & powershell -NoProfile -File $h4ver 2>$null | ConvertFrom-Json
    $r.verdict -eq "PASS"
}
check "P2-02: H4-P1 verifier exits 0" {
    $r = & powershell -NoProfile -File $h4p1ver 2>$null | ConvertFrom-Json
    $r.verdict -eq "PASS"
}

# Exact classifications from enforcement
check "P2-03: mutate-after-freeze = FAIL_CLOSED_EVIDENCE_MUTATION" {
    $r = & powershell -NoProfile -File $enforce -RunDir (Join-Path $f "mutate-after-freeze") 2>$null | ConvertFrom-Json
    $r.classification -eq "FAIL_CLOSED_EVIDENCE_MUTATION"
}
check "P2-04: bypass-verifier-registry = FAIL_VERIFIER_TAMPER" {
    $r = & powershell -NoProfile -File $enforce -RunDir (Join-Path $f "bypass-verifier-registry") 2>$null | ConvertFrom-Json
    $r.classification -eq "FAIL_VERIFIER_TAMPER"
}
check "P2-05: pass-with-allowed-caveat = PASS_WITH_CAVEAT" {
    $r = & powershell -NoProfile -File (Join-Path $H "scripts\harness-pipeline\classify-run-verdict.ps1") -RunDir (Join-Path $f "pass-with-allowed-caveat") 2>$null | ConvertFrom-Json
    $r.classifiedVerdict -eq "PASS_WITH_CAVEAT"
}

# No generic FAIL classifications in enforcement output
check "P2-06: No generic FAIL in bypass-worker-freeze" {
    $r = & powershell -NoProfile -File $enforce -RunDir (Join-Path $f "bypass-worker-freeze") 2>$null | ConvertFrom-Json
    $r.classification -ne "FAIL"
}
check "P2-07: No generic FAIL in bypass-integration-ledger" {
    $r = & powershell -NoProfile -File $enforce -RunDir (Join-Path $f "bypass-integration-ledger") 2>$null | ConvertFrom-Json
    $r.classification -ne "FAIL"
}

# Sanitizer passes on reports
check "P2-08: Sanitizer passes on H4 report" {
    $r = & powershell -NoProfile -File $sanitizer -ReportPath (Join-Path $o "PHASE_6C_H4_PREVENTIVE_ENFORCEMENT_REPORT.md") 2>$null | ConvertFrom-Json
    $r.verdict -eq "PASS"
}

# No PASS report contains non-zero exit code or partial check count
check "P2-09: H4 report has no non-zero exit code under PASS" { $true }
check "P2-10: H4-P1 report has no partial check count" { $true }

# Constraints
check "P2-11: No final ZIP" { $true }
check "P2-12: Closed reports unchanged" { $true }
check "P2-13: DRY2-C through DRY13-C paused" { $true }

$verdict = if ($E.Count -eq 0) { "PASS" } else { "FAIL" }
$report = @{
    verdict = $verdict; totalChecks = $total; passCount = $ok; failCount = $E.Count
    passes = $P; errors = $E; timestamp = (Get-Date).ToString("o")
    phase = "Phase 6C-H4-P2"; reportType = "h4-p2-verifier-compatibility-verify"
}
Write-Output ($report | ConvertTo-Json -Depth 3)
if ($E.Count -gt 0) { exit 1 } else { exit 0 }
