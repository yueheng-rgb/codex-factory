# phase6c-h2-p2-raw-report-sanitizer-verify.ps1 — Phase 6C-H2-P2
# Meta verifier for the raw report sanitizer hardening.
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@(); $E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$o = "$H\outputs"
$pipeline = "$H\scripts\harness-pipeline"
$sanitizer = "$pipeline\validate-report-sanitization.ps1"
$negatives = "$H\runs\h2-hardened-factory-pipeline\sanitizer-negatives"

# === Sanitizer existence ===
check "H2P2-01: Sanitizer exists" { Test-Path $sanitizer }

# === Sanitizer PASS on clean reports ===
check "H2P2-02: Sanitizer PASS on H2 report" {
    $r = & powershell -NoProfile -File $sanitizer -ReportPath "$o\PHASE_6C_H2_HARDENED_FACTORY_PIPELINE_REPORT.md" 2>&1 | Out-String | ConvertFrom-Json
    $r.verdict -eq "PASS"
}

check "H2P2-03: Sanitizer PASS on H2-P1 report" {
    $r = & powershell -NoProfile -File $sanitizer -ReportPath "$o\PHASE_6C_H2_P1_TAMPER_CLASSIFICATION_REPORT.md" 2>&1 | Out-String | ConvertFrom-Json
    $r.verdict -eq "PASS"
}

# === Sanitizer FAIL on negative fixtures ===
check "H2P2-04: Sanitizer FAIL on control chars" {
    $r = & powershell -NoProfile -File $sanitizer -ReportPath "$negatives\control-chars\report-with-null.md" 2>&1 | Out-String | ConvertFrom-Json
    $r.verdict -eq "FAIL"
}

check "H2P2-05: Sanitizer FAIL on corrupted path" {
    $r = & powershell -NoProfile -File $sanitizer -ReportPath "$negatives\corrupted-path\report.md" 2>&1 | Out-String | ConvertFrom-Json
    $r.verdict -eq "FAIL"
}

check "H2P2-06: Sanitizer FAIL on broken words" {
    $r = & powershell -NoProfile -File $sanitizer -ReportPath "$negatives\broken-words\report.md" 2>&1 | Out-String | ConvertFrom-Json
    $r.verdict -eq "FAIL"
}

check "H2P2-07: Sanitizer FAIL on PASS-with-PENDING" {
    $r = & powershell -NoProfile -File $sanitizer -ReportPath "$negatives\pass-with-pending\report.md" 2>&1 | Out-String | ConvertFrom-Json
    $r.verdict -eq "FAIL"
}

# === H2-P1 taxonomy still fixed ===
check "H2P2-08: Verifier-tampered Classified = FAIL_VERIFIER_TAMPER" {
    $report = Get-Content "$o\PHASE_6C_H2_P1_TAMPER_CLASSIFICATION_REPORT.md" -Raw
    $report -match 'verifier-tampered.*FAIL_VERIFIER_TAMPER.*FAIL_VERIFIER_TAMPER.*PASS'
}

# === H2 verifiers still pass ===
check "H2P2-09: H2 meta verifier exits 0" {
    $r = & powershell -NoProfile -File "$H\scripts\phase6c-h2-hardened-factory-pipeline-verify.ps1" 2>&1 | Out-String | ConvertFrom-Json
    $r.verdict -eq "PASS"
}

check "H2P2-10: H2-P1 hygiene verifier exits 0" {
    $r = & powershell -NoProfile -File "$H\scripts\phase6c-h2-p1-report-hygiene-verify.ps1" 2>&1 | Out-String | ConvertFrom-Json
    $r.verdict -eq "PASS"
}

# === No final ZIP ===
check "H2P2-11: No final ZIP" { -not (Test-Path "$o\phase6c-h2-p2-*.zip") }

# === Closed reports unchanged ===
$closed = @("PHASE_6C_DRY14_A_SCHEDULED_JOBS_RETRY_QUEUE_REPORT.md","PHASE_6C_DRY14_B_SCHEDULER_NEGATIVE_CONTROLS_REPORT.md","PHASE_6C_DRY15_A_SEARCH_FILTER_PAGINATION_PERFORMANCE_REPORT.md","PHASE_6C_DRY15_B_SEARCH_PAGINATION_PERFORMANCE_NEGATIVE_CONTROLS_REPORT.md","PHASE_6C_DRY15_B_P1_PERFORMANCE_BUDGET_NEGATIVE_HARDENING_REPORT.md","PHASE_6C_H1_FACTORY_CORE_HARDENING_REPORT.md","PHASE_6C_H1_P1_EVIDENCE_RECONCILIATION_REPORT.md")
$cn = 11
foreach ($cr in $closed) {
    $cn++
    $short = $cr.Substring(9, [Math]::Min(15,$cr.Length-13))
    check "H2P2-$cn`: Closed $short" { Test-Path "$o\$cr" }
}

# === DRY2-C through DRY13-C paused ===
check "H2P2-19: DRY2-C through DRY13-C paused" {
    -not (Test-Path "$o\PHASE_6C_DRY2_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY3_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY4_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY5_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY6_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY7_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY8_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY9_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY10_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY11_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY12_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY13_C_*")
}

# === H2-P2 report exists ===
check "H2P2-20: H2-P2 report exists" { Test-Path "$o\PHASE_6C_H2_P2_RAW_REPORT_SANITIZER_REPORT.md" }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
@{phase="Phase 6C-H2-P2";reportType="h2-p2-raw-report-sanitizer-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E} | ConvertTo-Json -Depth 3
exit $exitCode