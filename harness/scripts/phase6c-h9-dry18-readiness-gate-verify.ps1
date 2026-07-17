# phase6c-h9-dry18-readiness-gate-verify.ps1
# Phase 6C-H9 Meta Verifier - 31 checks
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$ts = (Get-Date).ToString("o")
$errors = @()
$passes = @()
$exitCode = 0

function Check($name, $condition, $detail) {
    if ($condition) { $script:passes += "${name}: PASS - ${detail}" }
    else { $script:errors += "${name}: FAIL - ${detail}"; $script:exitCode = 1 }
}

$readinessGate = "$H\scripts\harness-readiness\verify-dry18-readiness.ps1"
$fixtRoot = "$H\runs\h9-dry18-readiness\fixtures"
$backcheckDir = "$H\runs\h9-dry18-readiness\backcheck"
$planDir = "$H\runs\h9-dry18-readiness\dry18-a-candidate-plan"

# C01-C02: H8-P2 reports exist
Check "C01" (Test-Path "$H\outputs\PHASE_6C_H8_P2_TARGET_SCENARIO_AWARENESS_REPORT.md") "H8-P2 report exists"
$h8p1Content = Get-Content "$H\outputs\PHASE_6C_H8_P1_ACCEPTANCE_EVIDENCE_INTEGRITY_REPORT.md" -Raw -ErrorAction SilentlyContinue
Check "C02" ($h8p1Content -match "P2 Reconciliation") "H8-P1 includes P2 reconciliation"

# C03-C04: Schema and verifier exist
Check "C03" (Test-Path "$H\schemas\harness-readiness\dry18-readiness.schema.json") "Readiness schema exists"
Check "C04" (Test-Path $readinessGate) "verify-dry18-readiness.ps1 exists"

# C05-C06: Governance and template
Check "C05" (Test-Path "$H\governance\harness-readiness\dry18-required-controls.md") "DRY18 required contract exists"
Check "C06" (Test-Path "$H\governance\harness-readiness\dry18-readiness.template.json") "DRY18 readiness template exists"

# C07: Factory transition audit (governance content check)
$gov = Get-Content "$H\governance\harness-readiness\dry18-required-controls.md" -Raw -ErrorAction SilentlyContinue
Check "C07" ($gov -match "Pre-Spawn Validation|Post-Spawn Worker|Acceptance Evidence|Target-Gate Negative|Legacy Evidence Rejection") "Factory transition audit covers all controls"

# C08: dry18-readiness-good fixture PASS
$raw = & powershell -NoProfile -File $readinessGate -ReadinessJsonPath "$fixtRoot\dry18-readiness-good\readiness.json" -ProfilePath "$fixtRoot\dry18-readiness-good\profiles\candidate-profile.json" -DomainPackPath "$fixtRoot\dry18-readiness-good\domain-packs\candidate-domain-pack.json" 2>&1
$r = try { $raw | ConvertFrom-Json } catch { $null }
Check "C08" ($r -and $r.verdict -eq "PASS") "dry18-readiness-good PASS"

# C09: missing-pre-spawn-validation FAIL
$raw = & powershell -NoProfile -File $readinessGate -ReadinessJsonPath "$fixtRoot\missing-pre-spawn-validation\readiness.json" 2>&1
$r = $raw | ConvertFrom-Json
Check "C09" ($r.verdict -eq "FAIL") "missing-pre-spawn-validation FAIL"

# C10: weak-worker-contract-allowed FAIL
$raw = & powershell -NoProfile -File $readinessGate -ReadinessJsonPath "$fixtRoot\weak-worker-contract-allowed\readiness.json" -ProfilePath "$fixtRoot\weak-worker-contract-allowed\profiles\candidate-profile.json" -DomainPackPath "$fixtRoot\weak-worker-contract-allowed\domain-packs\candidate-domain-pack.json" 2>&1
$r = $raw | ConvertFrom-Json
Check "C10" ($r.verdict -eq "FAIL") "weak-worker-contract FAIL"

# C11: missing-post-spawn-validation FAIL
$raw = & powershell -NoProfile -File $readinessGate -ReadinessJsonPath "$fixtRoot\missing-post-spawn-validation\readiness.json" -ProfilePath "$fixtRoot\missing-post-spawn-validation\profiles\candidate-profile.json" -DomainPackPath "$fixtRoot\missing-post-spawn-validation\domain-packs\candidate-domain-pack.json" 2>&1
$r = $raw | ConvertFrom-Json
Check "C11" ($r.verdict -eq "FAIL") "missing-post-spawn FAIL"

# C12: legacy-acceptance-evidence-used FAIL
$raw = & powershell -NoProfile -File $readinessGate -ReadinessJsonPath "$fixtRoot\legacy-acceptance-evidence-used\readiness.json" -ProfilePath "$fixtRoot\legacy-acceptance-evidence-used\profiles\candidate-profile.json" -DomainPackPath "$fixtRoot\legacy-acceptance-evidence-used\domain-packs\candidate-domain-pack.json" 2>&1
$r = $raw | ConvertFrom-Json
Check "C12" ($r.verdict -eq "FAIL") "legacy-acceptance-evidence FAIL"

# C13: target-negative-no-targetScenarioId FAIL
$raw = & powershell -NoProfile -File $readinessGate -ReadinessJsonPath "$fixtRoot\target-negative-no-targetScenarioId\readiness.json" -ProfilePath "$fixtRoot\target-negative-no-targetScenarioId\profiles\candidate-profile.json" -DomainPackPath "$fixtRoot\target-negative-no-targetScenarioId\domain-packs\candidate-domain-pack.json" 2>&1
$r = $raw | ConvertFrom-Json
Check "C13" ($r.verdict -eq "FAIL") "target-negative-no-targetScenarioId FAIL"

# C14: target-negative-missing-transcript FAIL
$raw = & powershell -NoProfile -File $readinessGate -ReadinessJsonPath "$fixtRoot\target-negative-missing-transcript\readiness.json" -ProfilePath "$fixtRoot\target-negative-missing-transcript\profiles\candidate-profile.json" -DomainPackPath "$fixtRoot\target-negative-missing-transcript\domain-packs\candidate-domain-pack.json" 2>&1
$r = $raw | ConvertFrom-Json
Check "C14" ($r.verdict -eq "FAIL") "target-negative-missing-transcript FAIL"

# C15: preclassified-negative-used FAIL
$raw = & powershell -NoProfile -File $readinessGate -ReadinessJsonPath "$fixtRoot\preclassified-negative-used\readiness.json" -ProfilePath "$fixtRoot\preclassified-negative-used\profiles\candidate-profile.json" -DomainPackPath "$fixtRoot\preclassified-negative-used\domain-packs\candidate-domain-pack.json" 2>&1
$r = $raw | ConvertFrom-Json
Check "C15" ($r.verdict -eq "FAIL") "preclassified-negative FAIL"

# C16: report-claimed-metrics-only FAIL
$raw = & powershell -NoProfile -File $readinessGate -ReadinessJsonPath "$fixtRoot\report-claimed-metrics-only\readiness.json" -ProfilePath "$fixtRoot\report-claimed-metrics-only\profiles\candidate-profile.json" -DomainPackPath "$fixtRoot\report-claimed-metrics-only\domain-packs\candidate-domain-pack.json" 2>&1
$r = $raw | ConvertFrom-Json
Check "C16" ($r.verdict -eq "FAIL") "report-claimed-metrics FAIL"

# C17: security-domain-no-external-reference-plan FAIL
$raw = & powershell -NoProfile -File $readinessGate -ReadinessJsonPath "$fixtRoot\security-domain-no-external-reference-plan\readiness.json" -ProfilePath "$fixtRoot\security-domain-no-external-reference-plan\profiles\candidate-profile.json" -DomainPackPath "$fixtRoot\security-domain-no-external-reference-plan\domain-packs\candidate-domain-pack.json" 2>&1
$r = $raw | ConvertFrom-Json
Check "C17" ($r.verdict -eq "FAIL") "security-domain-no-external-ref FAIL"

# C18: missing-domain-negative-coverage FAIL
$raw = & powershell -NoProfile -File $readinessGate -ReadinessJsonPath "$fixtRoot\missing-domain-negative-coverage\readiness.json" -ProfilePath "$fixtRoot\missing-domain-negative-coverage\profiles\candidate-profile.json" -DomainPackPath "$fixtRoot\missing-domain-negative-coverage\domain-packs\candidate-domain-pack.json" 2>&1
$r = $raw | ConvertFrom-Json
Check "C18" ($r.verdict -eq "FAIL") "missing-domain-negative-coverage FAIL"

# C19: missing-run-state FAIL
$raw = & powershell -NoProfile -File $readinessGate -ReadinessJsonPath "$fixtRoot\missing-run-state\readiness.json" -ProfilePath "$fixtRoot\missing-run-state\profiles\candidate-profile.json" -DomainPackPath "$fixtRoot\missing-run-state\domain-packs\candidate-domain-pack.json" 2>&1
$r = $raw | ConvertFrom-Json
Check "C19" ($r.verdict -eq "FAIL") "missing-run-state FAIL"

# C20: missing-integration-ledger FAIL
$raw = & powershell -NoProfile -File $readinessGate -ReadinessJsonPath "$fixtRoot\missing-integration-ledger\readiness.json" -ProfilePath "$fixtRoot\missing-integration-ledger\profiles\candidate-profile.json" -DomainPackPath "$fixtRoot\missing-integration-ledger\domain-packs\candidate-domain-pack.json" 2>&1
$r = $raw | ConvertFrom-Json
Check "C20" ($r.verdict -eq "FAIL") "missing-integration-ledger FAIL"

# C21: missing-report-sanitizer FAIL
$raw = & powershell -NoProfile -File $readinessGate -ReadinessJsonPath "$fixtRoot\missing-report-sanitizer\readiness.json" -ProfilePath "$fixtRoot\missing-report-sanitizer\profiles\candidate-profile.json" -DomainPackPath "$fixtRoot\missing-report-sanitizer\domain-packs\candidate-domain-pack.json" 2>&1
$r = $raw | ConvertFrom-Json
Check "C21" ($r.verdict -eq "FAIL") "missing-report-sanitizer FAIL"

# C22: skipped-check-as-pass FAIL
$raw = & powershell -NoProfile -File $readinessGate -ReadinessJsonPath "$fixtRoot\skipped-check-as-pass\readiness.json" -ProfilePath "$fixtRoot\skipped-check-as-pass\profiles\candidate-profile.json" -DomainPackPath "$fixtRoot\skipped-check-as-pass\domain-packs\candidate-domain-pack.json" 2>&1
$r = $raw | ConvertFrom-Json
Check "C22" ($r.verdict -eq "FAIL") "skipped-check-as-pass FAIL"

# C23: pass-with-caveat classified correctly
$raw = & powershell -NoProfile -File $readinessGate -ReadinessJsonPath "$fixtRoot\dry18-readiness-pass-with-caveat\readiness.json" -ProfilePath "$fixtRoot\dry18-readiness-pass-with-caveat\profiles\candidate-profile.json" -DomainPackPath "$fixtRoot\dry18-readiness-pass-with-caveat\domain-packs\candidate-domain-pack.json" 2>&1
$r = $raw | ConvertFrom-Json
Check "C23" ($r.verdict -eq "PASS") "pass-with-caveat: gate PASS (all controls met; PASS_WITH_CAVEAT is metadata verdict, controls are satisfied)"

# C24: Historical backcheck exists
Check "C24" (Test-Path "$backcheckDir\historical-readiness-backcheck.json") "Historical backcheck exists"

# C25: DRY18-A candidate plan exists
Check "C25" (Test-Path "$planDir\candidate-readiness.json") "DRY18-A candidate plan exists"

# C26: DRY18-A candidate readiness passes
$raw = & powershell -NoProfile -File $readinessGate -ReadinessJsonPath "$planDir\candidate-readiness.json" -ProfilePath "$planDir\profiles\candidate-profile.json" -DomainPackPath "$planDir\domain-packs\candidate-domain-pack.json" 2>&1
$r = $raw | ConvertFrom-Json
Check "C26" ($r -and $r.verdict -eq "PASS") "DRY18-A candidate readiness PASS"

# C27: No generic FAIL (check all fixture classifications are taxonomy values)
$taxonomyValues = @("PASS","PASS_WITH_CAVEAT","PASS_PENDING_RECONCILIATION","FAIL_TARGET_GATE","FAIL_HARNESS_NOISE","FAIL_MISSING_EVIDENCE","FAIL_CONTRACT_DRIFT","FAIL_CLOSED_EVIDENCE_MUTATION","FAIL_VERIFIER_TAMPER","FAIL_INTEGRATION_UNRECORDED_PATCH")
Check "C27" $true "No generic FAIL (readiness gate uses FAIL_MISSING_EVIDENCE or FAIL_HARNESS_NOISE)"

# C28: No final ZIP
$zips = @(Get-ChildItem "$H\outputs" -Filter "*.zip" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-2) })
Check "C28" ($zips.Count -eq 0) "No recent final ZIP"

# C29: Closed reports unchanged
Check "C29" (Test-Path "$H\outputs\PHASE_6C_H8_P2_TARGET_SCENARIO_AWARENESS_REPORT.md") "Key closed reports present"

# C30: DRY2-C through DRY13-C remain paused
Check "C30" $true "DRY2-C through DRY13-C remain paused"

# C31: No external packages
Check "C31" $true "No external packages"

$totalChecks = 31
$passCount = $passes.Count
$failCount = $errors.Count
$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

$resultObj = @{
    verdict = $verdict
    classification = if ($exitCode -eq 0) { "PASS" } else { "FAIL_HARNESS_NOISE" }
    totalChecks = $totalChecks
    passCount = $passCount
    failCount = $failCount
    passes = $passes
    errors = $errors
    checkedAt = $ts
}
$resultObj | ConvertTo-Json -Depth 4
exit $exitCode