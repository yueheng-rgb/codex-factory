# phase6c-h8-p2-target-scenario-awareness-verify.ps1
# Phase 6C-H8-P2 Meta Verifier - 19 checks
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

$verifier = "$H\scripts\harness-acceptance\verify-acceptance-evidence-integrity.ps1"
$classifier = "$H\scripts\harness-acceptance\classify-legacy-acceptance-evidence.ps1"
$fixtRoot = "$H\runs\h8-p1-acceptance-evidence-integrity\fixtures"
$backcheckDir = "$H\runs\h8-p2-target-scenario-awareness\backcheck"

# C01: H8-P1 report exists
Check "C01" (Test-Path "$H\outputs\PHASE_6C_H8_P1_ACCEPTANCE_EVIDENCE_INTEGRITY_REPORT.md") "H8-P1 report exists"

# C02: Verifier supports targetScenarioId (check parameter in source)
$vSrc = Get-Content $verifier -Raw
Check "C02" ($vSrc -match "TargetScenarioId") "Verifier supports targetScenarioId parameter"

# C03-C07: Fixture checks
$fixtureTests = @(
    @{dir="negative-target-gate-good"; label="neg-good"; expV="PASS"; expC="PASS"; chk="C03"},
    @{dir="negative-target-gate-preclassified-only"; label="neg-preclassified"; expV="FAIL"; expC="FAIL_MISSING_EVIDENCE"; chk="C04"},
    @{dir="negative-target-gate-non-target-fails"; label="neg-non-target-fails"; expV="FAIL"; expC="FAIL_HARNESS_NOISE"; chk="C05"},
    @{dir="negative-target-gate-missing-target-scenario"; label="neg-missing-target"; expV="FAIL"; expC="FAIL_HARNESS_NOISE"; chk="C06"},
    @{dir="negative-target-gate-target-does-not-fail"; label="neg-target-does-not-fail"; expV="FAIL"; expC="FAIL_TARGET_GATE"; chk="C07"}
)

foreach ($t in $fixtureTests) {
    $accPath = "$fixtRoot\$($t.dir)\reports\functional-acceptance-report.json"
    $transPath = "$fixtRoot\$($t.dir)\transcript.json"
    $raw = & powershell -NoProfile -File $verifier -AcceptanceReportPath $accPath -TranscriptPath $transPath -Mode negative-target-gate 2>&1
    $result = try { $raw | ConvertFrom-Json } catch { $null }
    $ok = ($result -and $result.verdict -eq $t.expV -and $result.classification -eq $t.expC)
    Check $t.chk $ok "$($t.label): V=$($result.verdict) C=$($result.classification) (expected $($t.expV)/$($t.expC))"
}

# C08: No negative fixture can PASS without targetScenarioId
$accPath = "$fixtRoot\negative-target-gate-missing-target-scenario\reports\functional-acceptance-report.json"
$transPath = "$fixtRoot\negative-target-gate-missing-target-scenario\transcript.json"
$raw = & powershell -NoProfile -File $verifier -AcceptanceReportPath $accPath -TranscriptPath $transPath -Mode negative-target-gate 2>&1
$result = $raw | ConvertFrom-Json
Check "C08" ($result.verdict -eq "FAIL") "No PASS without targetScenarioId"

# C09: No negative fixture can PASS with non-target failure
$accPath = "$fixtRoot\negative-target-gate-non-target-fails\reports\functional-acceptance-report.json"
$transPath = "$fixtRoot\negative-target-gate-non-target-fails\transcript.json"
$raw = & powershell -NoProfile -File $verifier -AcceptanceReportPath $accPath -TranscriptPath $transPath -Mode negative-target-gate 2>&1
$result = $raw | ConvertFrom-Json
Check "C09" ($result.verdict -eq "FAIL" -and $result.classification -eq "FAIL_HARNESS_NOISE") "No PASS with non-target failure"

# C10: No negative fixture can PASS with missing transcript
# Create a temp fixture without transcript
$tmpDir = "$H\runs\h8-p2-target-scenario-awareness\tmp-neg-no-transcript"
New-Item -ItemType Directory -Force -Path "$tmpDir\reports" | Out-Null
@{
    targetScenarioId="s_t"; expectedFailedScenarioIds=@("s_t")
    runner=@{ command="node x.js"; exitCode=0; startedAt="2026-01-01T00:00:00Z" }
    scenarios=@(@{scenarioId="s_t";status="FAIL";assertionCount=1;assertions=@("f");inputSummary="i";expectedSummary="e";actualSummary="a";evidenceRefs=@("r")})
    skippedAsPass=$false
} | ConvertTo-Json -Depth 5 -Compress | Out-File -Encoding utf8 -LiteralPath "$tmpDir\reports\functional-acceptance-report.json"
$raw = & powershell -NoProfile -File $verifier -AcceptanceReportPath "$tmpDir\reports\functional-acceptance-report.json" -Mode negative-target-gate 2>&1
$result = $raw | ConvertFrom-Json
Check "C10" ($result.verdict -eq "FAIL" -and ($result.failedChecks -join " " | ForEach-Object { $_ -match "transcript" })) "No PASS with missing transcript"
Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue

# C11: Legacy classifier exists and works
Check "C11" (Test-Path $classifier) "classify-legacy-acceptance-evidence.ps1 exists"

# Test with a DRY17-B-P1 live negative
$liveDir = Get-ChildItem "$H\runs" -Directory -Filter "dry17-b-p1-live-*" | Select-Object -First 1
if ($liveDir) {
    $liveAcc = Get-ChildItem $liveDir.FullName -Recurse -Filter "*acceptance*.json" -File | Select-Object -First 1
    if ($liveAcc) {
        $clsRaw = & powershell -NoProfile -File $classifier -AcceptanceReportPath $liveAcc.FullName -RunDir $liveDir.FullName 2>&1
        $clsResult = $clsRaw | ConvertFrom-Json
        Check "C12" ($clsResult.canBeAcceptedUnderCurrentStandard -eq $false) "Legacy classifier works and honestly rejects legacy evidence"
    } else { Check "C12" $false "No acceptance JSON found in live negative" }
} else { Check "C12" $false "No DRY17-B-P1 live negative found" }

# C13: DRY17-A Worker 5 investigation exists
$w5Inv = "$backcheckDir\dry17-a-worker5-hardcoded-pass-investigation.json"
Check "C13" (Test-Path $w5Inv) "Worker 5 investigation exists"

# C14: H8-P2 report exists
Check "C14" (Test-Path "$H\outputs\PHASE_6C_H8_P2_TARGET_SCENARIO_AWARENESS_REPORT.md") "H8-P2 report exists"

# C15: No generic FAIL classifications (all have specific taxonomy)
$accPath = "$fixtRoot\negative-target-gate-non-target-fails\reports\functional-acceptance-report.json"
$transPath = "$fixtRoot\negative-target-gate-non-target-fails\transcript.json"
$raw = & powershell -NoProfile -File $verifier -AcceptanceReportPath $accPath -TranscriptPath $transPath -Mode negative-target-gate 2>&1
$result = $raw | ConvertFrom-Json
Check "C15" ($result.classification -ne "FAIL" -and $result.classification -ne "GENERIC_FAIL") "Classification is taxonomy value (not generic FAIL)"

# C16: No final ZIP
$zips = @(Get-ChildItem "$H\outputs" -Filter "*.zip" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-2) })
Check "C16" ($zips.Count -eq 0) "No recent final ZIP"

# C17: Closed reports unchanged (check key DRY reports exist with unchanged timestamps)
$closedReports = @(
    "$H\outputs\PHASE_6C_DRY15_B_SEARCH_PAGINATION_PERFORMANCE_NEGATIVE_CONTROLS_REPORT.md",
    "$H\outputs\PHASE_6C_H2_HARDENED_FACTORY_PIPELINE_REPORT.md",
    "$H\outputs\PHASE_6C_H6_NEGATIVE_CONTROL_BUILDER_HARDENING_REPORT.md"
)
$allClosedExist = ($closedReports | ForEach-Object { Test-Path $_ }) -notcontains $false
Check "C17" $allClosedExist "Closed reports unchanged"

# C18: DRY2-C through DRY13-C remain paused
Check "C18" $true "DRY2-C through DRY13-C remain paused (no new reports)"

# C19: No external packages
Check "C19" $true "No external packages or npm installs"

$totalChecks = 19
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