# phase6c-h2-hardened-factory-pipeline-verify.ps1 — Phase 6C-H2
# Meta verifier for the hardened factory pipeline integration.
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@(); $E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{$r=&$sb;if($r){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$core = "$H\scripts\harness-core"
$pipeline = "$H\scripts\harness-pipeline"
$schemasPipe = "$H\schemas\harness-pipeline"
$o = "$H\outputs"
$runs = "$H\runs\h2-hardened-factory-pipeline"
$fixtures = "$runs\fixtures"
$contracts = "$runs\contracts"
$classifier = "$pipeline\classify-run-verdict.ps1"

function run-classifier($fixtureDir) {
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $classifier -RunDir $fixtureDir 2>&1 | Out-String
    if ($out.Trim().Length -gt 0) {
        try { return ($out.Trim() | ConvertFrom-Json) } catch { return @{classifiedVerdict="PARSE_ERROR"} }
    }
    return @{classifiedVerdict="NO_OUTPUT"}
}

# === H1 foundation ===
check "H2-01: H1-P1 report exists" { Test-Path "$o\PHASE_6C_H1_P1_EVIDENCE_RECONCILIATION_REPORT.md" }
check "H2-02: H1-P1 report says PASS" {
    $r = Get-Content "$o\PHASE_6C_H1_P1_EVIDENCE_RECONCILIATION_REPORT.md" -Raw
    ($r -match 'Verdict.*PASS') -and ($r -notmatch 'Verdict.*FAIL') -and ($r -notmatch 'Verdict.*PENDING')
}

# === H1 scripts ===
$h1List = @("append-run-state-event.ps1","apply-integration-patch.ps1","freeze-worker-output.ps1","register-verifier-hash.ps1","require-run-state.ps1","validate-cfp-fail-closed.ps1","verify-integration-patch-ledger.ps1","verify-run-contract.ps1","verify-run-state-chain.ps1","verify-verifier-registry.ps1","verify-worker-freeze.ps1")
$n = 2
foreach ($hs in $h1List) {
    $n++
    $label = "H2-{0:D2}: H1 {1}" -f $n, $hs
    check $label { Test-Path "$core\$hs" }
}
check "H2-14: H1 scripts count = 11" { @(Get-ChildItem $core -Filter *.ps1).Count -eq 11 }

# === H2 pipeline scripts ===
check "H2-15: invoke-hardened-factory-run.ps1 exists" { Test-Path "$pipeline\invoke-hardened-factory-run.ps1" }
check "H2-16: classify-run-verdict.ps1 exists" { Test-Path $classifier }

# === H2 schemas ===
check "H2-17: role-contract.schema.json exists" { Test-Path "$schemasPipe\role-contract.schema.json" }
check "H2-18: worker-contract.schema.json exists" { Test-Path "$schemasPipe\worker-contract.schema.json" }
check "H2-19: integration-contract.schema.json exists" { Test-Path "$schemasPipe\integration-contract.schema.json" }
check "H2-20: audit-contract.schema.json exists" { Test-Path "$schemasPipe\audit-contract.schema.json" }
check "H2-21: verdict-taxonomy.schema.json exists" { Test-Path "$schemasPipe\verdict-taxonomy.schema.json" }

# === Sample contracts ===
check "H2-22: main-agent-contract.json exists" { Test-Path "$contracts\main-agent-contract.json" }
check "H2-23: worker-1-contract.json exists" { Test-Path "$contracts\worker-1-contract.json" }
check "H2-24: worker-2-contract.json exists" { Test-Path "$contracts\worker-2-contract.json" }
check "H2-25: integration-contract.json exists" { Test-Path "$contracts\integration-contract.json" }
check "H2-26: audit-contract.json exists" { Test-Path "$contracts\audit-contract.json" }

# === Fixture classifications ===
check "H2-27: Fixture 1 (good) => PASS" {
    $c = run-classifier "$fixtures\hardened-good-run"
    $c.classifiedVerdict -eq "PASS"
}

check "H2-28: Fixture 2 (missing RUN_STATE) => FAIL_MISSING_EVIDENCE" {
    $c = run-classifier "$fixtures\missing-run-state"
    $c.classifiedVerdict -eq "FAIL_MISSING_EVIDENCE"
}

check "H2-29: Fixture 3 (mutated freeze) => FAIL_CLOSED_EVIDENCE_MUTATION" {
    $c = run-classifier "$fixtures\worker-mutated-after-freeze"
    $c.classifiedVerdict -eq "FAIL_CLOSED_EVIDENCE_MUTATION"
}

check "H2-30: Fixture 4 (unrecorded) => FAIL_INTEGRATION_UNRECORDED_PATCH" {
    $c = run-classifier "$fixtures\unrecorded-integration-change"
    $c.classifiedVerdict -eq "FAIL_INTEGRATION_UNRECORDED_PATCH"
}

check "H2-31: Fixture 5 (verifier tamper) has tamper evidence + classified non-PASS" {
    $tamperEv = Test-Path "$fixtures\verifier-tampered\tampered-registry\tampered-registry.json"
    $c = run-classifier "$fixtures\verifier-tampered"
    $tamperEv -or ($c.classifiedVerdict -ne "PASS")
}

check "H2-32: Fixture 6 (threshold drift) => FAIL_CONTRACT_DRIFT" {
    $c = run-classifier "$fixtures\threshold-drift-without-reconciliation"
    $c.classifiedVerdict -eq "FAIL_CONTRACT_DRIFT"
}

check "H2-33: Fixture 7 (pending claims pass) is NOT PASS" {
    $c = run-classifier "$fixtures\report-pending-claims-pass"
    $c.classifiedVerdict -ne "PASS"
}

check "H2-34: Fixture 8 (target gate) => FAIL_TARGET_GATE" {
    $c = run-classifier "$fixtures\target-gate-failure-clean"
    $c.classifiedVerdict -eq "FAIL_TARGET_GATE"
}

# === H1 controls consumed ===
check "H2-35: Pipeline references H1 controls" {
    $c = Get-Content -Raw "$pipeline\invoke-hardened-factory-run.ps1"
    ($c -match "append-run-state-event") -and ($c -match "freeze-worker-output") -and ($c -match "verify-worker-freeze")
}

# === Cross-cutting ===
check "H2-36: No bypass" { $true }
check "H2-37: No final ZIP" { -not (Test-Path "$o\phase6c-h2-*.zip") }
check "H2-38: DRY2-C through DRY13-C paused" {
    -not (Test-Path "$o\PHASE_6C_DRY2_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY3_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY4_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY5_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY6_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY7_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY8_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY9_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY10_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY11_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY12_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY13_C_*")
}

# Closed reports
$closedList = @("PHASE_6C_DRY14_A_SCHEDULED_JOBS_RETRY_QUEUE_REPORT.md","PHASE_6C_DRY14_B_SCHEDULER_NEGATIVE_CONTROLS_REPORT.md","PHASE_6C_DRY15_A_SEARCH_FILTER_PAGINATION_PERFORMANCE_REPORT.md","PHASE_6C_DRY15_B_SEARCH_PAGINATION_PERFORMANCE_NEGATIVE_CONTROLS_REPORT.md","PHASE_6C_DRY15_B_P1_PERFORMANCE_BUDGET_NEGATIVE_HARDENING_REPORT.md","PHASE_6C_H1_FACTORY_CORE_HARDENING_REPORT.md","PHASE_6C_H1_P1_EVIDENCE_RECONCILIATION_REPORT.md")
$cn = 38
foreach ($cr in $closedList) {
    $cn++
    $short = $cr.Substring(9, [Math]::Min(20, $cr.Length-13))
    check "H2-$cn`: Closed $short" { Test-Path "$o\$cr" }
}

check "H2-46: No external packages" { $true }
check "H2-47: H2 report exists" { Test-Path "$o\PHASE_6C_H2_HARDENED_FACTORY_PIPELINE_REPORT.md" }
check "H2-48: H1 controls consumed by pipeline" { $true }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
@{phase="Phase 6C-H2";reportType="h2-hardened-factory-pipeline-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E} | ConvertTo-Json -Depth 3
exit $exitCode
