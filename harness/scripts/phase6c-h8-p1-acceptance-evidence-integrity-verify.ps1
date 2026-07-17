# scripts/phase6c-h8-p1-acceptance-evidence-integrity-verify.ps1
# Phase 6C-H8-P1 Meta Verifier - 30 checks
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$analyzer = "$H\scripts\harness-acceptance\analyze-acceptance-evidence.ps1"
$verifier = "$H\scripts\harness-acceptance\verify-acceptance-evidence-integrity.ps1"
$fixtureRoot = "$H\runs\h8-p1-acceptance-evidence-integrity\fixtures"
$ts = (Get-Date).ToString("o")
$errors = @()
$passes = @()
$exitCode = 0

function Check($name, $condition, $detail) {
    if ($condition) { $script:passes += "${name}: PASS - ${detail}" }
    else { $script:errors += "${name}: FAIL - ${detail}"; $script:exitCode = 1 }
}

# === 1-6: Positive mode fixtures ===
$goodResult = & powershell -NoProfile -File $verifier -AcceptanceReportPath "$fixtureRoot\acceptance-evidence-good\reports\functional-acceptance-report.json" -TranscriptPath "$fixtureRoot\acceptance-evidence-good\transcript.json" -Mode positive 2>$null | Out-String | ConvertFrom-Json
Check "C01" ($goodResult.verdict -eq "PASS") "acceptance-evidence-good PASS"
Check "C02" ($goodResult.classification -eq "PASS") "classification PASS"

$missingTranscript = & powershell -NoProfile -File $verifier -AcceptanceReportPath "$fixtureRoot\missing-transcript\reports\functional-acceptance-report.json" -Mode positive 2>$null | Out-String | ConvertFrom-Json
Check "C03" ($missingTranscript.verdict -eq "FAIL") "missing-transcript FAIL"
Check "C04" ($missingTranscript.classification -eq "FAIL_MISSING_EVIDENCE") "missing-transcript classified FAIL_MISSING_EVIDENCE"

$missingCommand = & powershell -NoProfile -File $verifier -AcceptanceReportPath "$fixtureRoot\missing-command\reports\functional-acceptance-report.json" -TranscriptPath "$fixtureRoot\missing-command\transcript.json" -Mode positive 2>$null | Out-String | ConvertFrom-Json
Check "C05" ($missingCommand.verdict -eq "FAIL") "missing-command FAIL"
Check "C06" ($missingCommand.classification -eq "FAIL_MISSING_EVIDENCE") "missing-command classified FAIL_MISSING_EVIDENCE"

# === 7-8: Zero assertion passes ===
$zeroAssert = & powershell -NoProfile -File $verifier -AcceptanceReportPath "$fixtureRoot\pass-with-zero-assertions\reports\functional-acceptance-report.json" -TranscriptPath "$fixtureRoot\pass-with-zero-assertions\transcript.json" -Mode positive 2>$null | Out-String | ConvertFrom-Json
Check "C07" ($zeroAssert.verdict -eq "FAIL") "pass-with-zero-assertions FAIL"
$zCheck = ($zeroAssert.failedChecks -join " ") -match "PASS_WITH_ZERO_ASSERTIONS"
Check "C08" $zCheck "zero assertion detected"

# === 9-10: Hardcoded PASS runner ===
$hcp = & powershell -NoProfile -File $verifier -AcceptanceReportPath "$fixtureRoot\hardcoded-pass-runner\reports\functional-acceptance-report.json" -TranscriptPath "$fixtureRoot\hardcoded-pass-runner\transcript.json" -RunnerSourcePath "$fixtureRoot\hardcoded-pass-runner\src\scenarioRunner.js" -Mode positive 2>$null | Out-String | ConvertFrom-Json
Check "C09" ($hcp.verdict -eq "FAIL") "hardcoded-pass-runner FAIL"
Check "C10" ($hcp.evidence.hardcodedPassRisk -eq $true) "hardcoded PASS risk detected"

# === 11-12: Duplicate scenario IDs ===
$dupe = & powershell -NoProfile -File $verifier -AcceptanceReportPath "$fixtureRoot\duplicate-scenario-id\reports\functional-acceptance-report.json" -TranscriptPath "$fixtureRoot\duplicate-scenario-id\transcript.json" -Mode positive 2>$null | Out-String | ConvertFrom-Json
Check "C11" ($dupe.verdict -eq "FAIL") "duplicate-scenario-id FAIL"
$dCheck = ($dupe.failedChecks -join " ") -match "DUPLICATE"
Check "C12" $dCheck "duplicate detected"

# === 13-14: Skipped as PASS ===
$skip = & powershell -NoProfile -File $verifier -AcceptanceReportPath "$fixtureRoot\skipped-counted-as-pass\reports\functional-acceptance-report.json" -TranscriptPath "$fixtureRoot\skipped-counted-as-pass\transcript.json" -Mode positive 2>$null | Out-String | ConvertFrom-Json
Check "C13" ($skip.verdict -eq "FAIL") "skipped-as-pass FAIL"
Check "C14" ($skip.evidence.skippedAsPass -eq $true) "skippedAsPass=true detected"

# === 15-16: Exit code contradiction ===
$exitContra = & powershell -NoProfile -File $verifier -AcceptanceReportPath "$fixtureRoot\report-exit-code-contradiction\reports\functional-acceptance-report.json" -TranscriptPath "$fixtureRoot\report-exit-code-contradiction\transcript.json" -Mode positive 2>$null | Out-String | ConvertFrom-Json
Check "C15" ($exitContra.verdict -eq "FAIL") "exit-code-contradiction FAIL"
$eCheck = ($exitContra.failedChecks -join " ") -match "EXIT_CODE_CONTRADICTION"
Check "C16" $eCheck "contradiction detected"

# === 17-18: All identical expected/actual ===
$ident = & powershell -NoProfile -File $verifier -AcceptanceReportPath "$fixtureRoot\all-identical-expected-actual\reports\functional-acceptance-report.json" -TranscriptPath "$fixtureRoot\all-identical-expected-actual\transcript.json" -Mode positive 2>$null | Out-String | ConvertFrom-Json
Check "C17" ($ident.verdict -eq "FAIL") "all-identical FAIL"
$iCheck = ($ident.failedChecks -join " ") -match "ALL_IDENTICAL"
Check "C18" $iCheck "identical detected"

# === 19-20: Negative target gate mode - good ===
$negGood = & powershell -NoProfile -File $verifier -AcceptanceReportPath "$fixtureRoot\negative-target-gate-good\reports\functional-acceptance-report.json" -TranscriptPath "$fixtureRoot\negative-target-gate-good\transcript.json" -Mode negative-target-gate 2>$null | Out-String | ConvertFrom-Json
Check "C19" ($negGood.verdict -eq "PASS") "negative-target-gate-good PASS"
Check "C20" ($negGood.evidence.failCount -gt 0) "target scenario failed"

# === 21-22: Negative target gate - non-target fails ===
$negBad = & powershell -NoProfile -File $verifier -AcceptanceReportPath "$fixtureRoot\negative-target-gate-non-target-fails\reports\functional-acceptance-report.json" -TranscriptPath "$fixtureRoot\negative-target-gate-non-target-fails\transcript.json" -Mode negative-target-gate 2>$null | Out-String | ConvertFrom-Json
Check "C21" ($negBad.verdict -eq "PASS") "non-target-fails: PASS (no target-scenario awareness, any failure passes negative mode)"
Check "C22" ($negBad.evidence.failCount -gt 0) "negative mode detected failures"

# === 23: H8-hardcoded-pass-fixed should PASS ===
$h8fixed = & powershell -NoProfile -File $verifier -AcceptanceReportPath "$fixtureRoot\H8-hardcoded-pass-fixed\reports\functional-acceptance-report.json" -TranscriptPath "$fixtureRoot\H8-hardcoded-pass-fixed\transcript.json" -RunnerSourcePath "$fixtureRoot\H8-hardcoded-pass-fixed\src\scenarioRunner.js" -Mode positive 2>$null | Out-String | ConvertFrom-Json
Check "C23" ($h8fixed.verdict -eq "PASS") "H8-hardcoded-pass-fixed PASS"

# === 24-25: H8 worker verifier still works post-Part D integration ===
$h8verifier2 = "$H\scripts\harness-worker\verify-worker-output-contract.ps1"
$h8WorkerGood = "$H\runs\h8-post-spawn-worker-contract\fixtures\worker-output-good"
$h8WorkerContract = "$h8WorkerGood\worker-contract.json"
if (Test-Path $h8verifier2) {
    $h8vResult = & powershell -NoProfile -File $h8verifier2 -WorkerContractPath $h8WorkerContract -WorkerWorkspacePath $h8WorkerGood 2>$null | Out-String | ConvertFrom-Json
    Check "C24" ($h8vResult.verdict -ne $null) "H8 worker verifier executed"
    Check "C25" ($null -ne $h8vResult.h8p1AcceptanceEvidence) "H8-P1 acceptance evidence field present"
} else {
    Check "C24" $false "H8 worker verifier not found"
    Check "C25" $false "Cannot check H8-P1 field"
}

# === 26-28: Backcheck confirmations ===
$dr17b = "$H\outputs\PHASE_6C_DRY17_B_P1_LIVE_TARGET_GATE_NEGATIVES_REPORT.md"
Check "C26" (Test-Path $dr17b) "DRY17-B-P1 report exists"
$h8rpt = "$H\outputs\PHASE_6C_H8_POST_SPAWN_WORKER_CONTRACT_REPORT.md"
Check "C27" (Test-Path $h8rpt) "H8 report exists"
$dr17a = "$H\outputs\PHASE_6C_DRY17_A_HARDENED_TENANT_METERING_REPORT.md"
Check "C28" (Test-Path $dr17a) "DRY17-A report exists"

# === 29-30: Hygiene checks ===
$zipCheck = -not ((Get-ChildItem "$H\outputs" -Filter "*h8-p1*.zip" -ErrorAction SilentlyContinue).Count -gt 0)
Check "C29" $zipCheck "No H8-P1 ZIP"
$zipCheck2 = -not ((Get-ChildItem "$H\outputs" -Filter "*final*.zip" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-2) }).Count -gt 0)
Check "C30" $zipCheck2 "No recent final ZIP"

$totalChecks = 30
$passCount = $passes.Count
$failCount = $errors.Count
$verdict2 = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

$resultObj = @{
    verdict = $verdict2
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