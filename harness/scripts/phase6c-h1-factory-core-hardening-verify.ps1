# phase6c-h1-factory-core-hardening-verify.ps1 — Phase 6C-H1
# Meta-verifier for the entire H1 hardening batch.
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@(); $E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}
$core = "$H\scripts\harness-core"
$gov = "$H\governance\harness-core"
$run = "$H\runs\h1-factory-core-hardening"
$o = "$H\outputs"
$reg = "$gov\verifier-registry.json"

# --- Part A: Verifier Hash Lock ---
check "H1-A01: register-verifier-hash.ps1 exists" { Test-Path "$core\register-verifier-hash.ps1" }
check "H1-A02: verify-verifier-registry.ps1 exists" { Test-Path "$core\verify-verifier-registry.ps1" }
check "H1-A03: Registry exists" { Test-Path $reg }
check "H1-A04: Registry validates" { (& "$core\verify-verifier-registry.ps1" -RegistryPath $reg | ConvertFrom-Json).verdict -eq "PASS" }
check "H1-A05: Registry has >=4 entries" { (Get-Content $reg -Raw|ConvertFrom-Json).registry.Count -ge 4 }
check "H1-A06: Tamper fixture fails" {
    $r = & "$core\verify-verifier-registry.ps1" -RegistryPath "$run\verifier-lock\tampered\tampered-registry.json" -HarnessRoot $H | ConvertFrom-Json
    $r.verdict -eq "FAIL"
}

# --- Part B: Worker Freeze ---
check "H1-B01: freeze-worker-output.ps1 exists" { Test-Path "$core\freeze-worker-output.ps1" }
check "H1-B02: verify-worker-freeze.ps1 exists" { Test-Path "$core\verify-worker-freeze.ps1" }
check "H1-B03: Good freeze passes" {
    $r = & "$core\verify-worker-freeze.ps1" -FreezeManifestPath "$run\worker-freeze\good\worker-freeze-manifests\worker-1.freeze.json" | ConvertFrom-Json
    $r.verdict -eq "PASS"
}
check "H1-B04: Mutated freeze fails" {
    $r = & "$core\verify-worker-freeze.ps1" -FreezeManifestPath "$run\worker-freeze\mutated-after-freeze\worker-freeze-manifests\worker-1.freeze.json" | ConvertFrom-Json
    $r.verdict -eq "FAIL"
}

# --- Part C: Integration Ledger ---
check "H1-C01: apply-integration-patch.ps1 exists" { Test-Path "$core\apply-integration-patch.ps1" }
check "H1-C02: verify-integration-patch-ledger.ps1 exists" { Test-Path "$core\verify-integration-patch-ledger.ps1" }
check "H1-C03: Good ledger passes" {
    $r = & "$core\verify-integration-patch-ledger.ps1" -LedgerPath "$run\integration-ledger\good\integration-patches.jsonl" | ConvertFrom-Json
    $r.verdict -eq "PASS"
}
check "H1-C04: Missing ledger fails" {
    $r = & "$core\verify-integration-patch-ledger.ps1" -LedgerPath "$run\integration-ledger\unrecorded-modification\integration-patches.jsonl" | ConvertFrom-Json
    $r.verdict -eq "FAIL"
}

# --- Part D: Mandatory RUN_STATE ---
check "H1-D01: require-run-state.ps1 exists" { Test-Path "$core\require-run-state.ps1" }
check "H1-D02: Good RUN_STATE passes" {
    $r = & "$core\require-run-state.ps1" -RunDir "$run\run-state\good" | ConvertFrom-Json
    $r.verdict -eq "PASS"
}
check "H1-D03: Missing RUN_STATE fails" {
    $r = & "$core\require-run-state.ps1" -RunDir "$run\run-state\missing-run-state" | ConvertFrom-Json
    $r.verdict -eq "FAIL"
}
check "H1-D04: Broken hash chain fails" {
    $r = & "$core\require-run-state.ps1" -RunDir "$run\run-state\broken-hash-chain" | ConvertFrom-Json
    $r.verdict -eq "FAIL"
}
check "H1-D05: Missing required event fails" {
    $r = & "$core\require-run-state.ps1" -RunDir "$run\run-state\missing-required-event" | ConvertFrom-Json
    $r.verdict -eq "FAIL"
}

# --- Part E: CFP Fail-Closed ---
check "H1-E01: validate-cfp-fail-closed.ps1 exists" { Test-Path "$core\validate-cfp-fail-closed.ps1" }
check "H1-E02: Good CFP passes" {
    $r = & "$core\validate-cfp-fail-closed.ps1" -RunDir "$run\cfp\good" | ConvertFrom-Json
    $r.verdict -eq "PASS"
}
check "H1-E03: Skip-attempt fails" {
    $r = & "$core\validate-cfp-fail-closed.ps1" -RunDir "$run\cfp\skipped-as-pass-attempt" | ConvertFrom-Json
    $r.verdict -eq "FAIL_MISSING_EVIDENCE"
}

# --- Part F: Contract-Driven Budget ---
check "H1-F01: Schema exists" { Test-Path "$H\schemas\harness-core\run-contract.schema.json" }
check "H1-F02: verify-run-contract.ps1 exists" { Test-Path "$core\verify-run-contract.ps1" }
check "H1-F03: Sample contract exists" { Test-Path "$run\contracts\sample-run-contract.json" }
check "H1-F04: Good contract passes" {
    $r = & "$core\verify-run-contract.ps1" -ContractPath "$run\contracts\sample-run-contract.json" -RunDir "$run\contracts\good" | ConvertFrom-Json
    $r.verdict -eq "PASS"
}
check "H1-F05: Threshold drift fails" {
    $r = & "$core\verify-run-contract.ps1" -ContractPath "$run\contracts\threshold-drift\drifted-contract.json" -RunDir "$run\contracts\threshold-drift" | ConvertFrom-Json
    $r.verdict -eq "FAIL"
}

# --- Cross-cutting ---
check "H1-G01: No final ZIP" { -not (Test-Path "$o\phase6c-h1-*.zip") }
check "H1-G02: DRY2-C through DRY13-C paused" {
    -not (Test-Path "$o\PHASE_6C_DRY2_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY3_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY4_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY5_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY6_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY7_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY8_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY9_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY10_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY11_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY12_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY13_C_*")
}
check "H1-G03: DRY14 report unchanged" { Test-Path "$o\PHASE_6C_DRY14_A_SCHEDULED_JOBS_RETRY_QUEUE_REPORT.md" }
check "H1-G04: DRY15-A report unchanged" { Test-Path "$o\PHASE_6C_DRY15_A_SEARCH_FILTER_PAGINATION_PERFORMANCE_REPORT.md" }
check "H1-G05: DRY15-B report unchanged" { Test-Path "$o\PHASE_6C_DRY15_B_SEARCH_PAGINATION_PERFORMANCE_NEGATIVE_CONTROLS_REPORT.md" }
check "H1-G06: DRY15-B-P1 report unchanged" { Test-Path "$o\PHASE_6C_DRY15_B_P1_PERFORMANCE_BUDGET_NEGATIVE_HARDENING_REPORT.md" }
check "H1-G07: Final report exists" { Test-Path "$o\PHASE_6C_H1_FACTORY_CORE_HARDENING_REPORT.md" }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
@{phase="Phase 6C-H1";reportType="h1-factory-core-hardening-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E} | ConvertTo-Json -Depth 3
exit $exitCode
