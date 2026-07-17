# phase6c-h1-p1-evidence-reconciliation-verify.ps1 — Phase 6C-H1-P1
# Evidence reconciliation & report hygiene verifier.
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@(); $E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$core = "$H\scripts\harness-core"
$o = "$H\outputs"
$run = "$H\runs\h1-factory-core-hardening"
$h1Report = "$o\PHASE_6C_H1_FACTORY_CORE_HARDENING_REPORT.md"

# === Part 1: Re-run H1 meta verifier ===
$metaVerdict = "UNKNOWN"; $metaTotal = 0; $metaPass = 0; $metaFail = 0
$metaOut = & powershell -NoProfile -ExecutionPolicy Bypass -File "$H\scripts\phase6c-h1-factory-core-hardening-verify.ps1" 2>&1 | Out-String
$metaExit = $LASTEXITCODE

if ($metaOut.Trim().Length -gt 0) {
    try {
        $metaJson = $metaOut.Trim() | ConvertFrom-Json
        $metaVerdict = $metaJson.verdict
        $metaTotal = $metaJson.totalChecks
        $metaPass = $metaJson.passCount
        $metaFail = $metaJson.failCount
    } catch { $metaVerdict = "PARSE_ERROR" }
}

check "H1P1-01: Meta verifier exit code captured" { $metaExit -ne $null }
check "H1P1-02: Meta verifier exit code = 0" { $metaExit -eq 0 }
check "H1P1-03: Meta verifier verdict = PASS" { $metaVerdict -eq "PASS" }
check "H1P1-04: Meta verifier 34 checks" { $metaTotal -eq 34 }
check "H1P1-05: Meta verifier 34 pass" { $metaPass -eq 34 }
check "H1P1-06: Meta verifier 0 fail" { $metaFail -eq 0 }

# === Part 2: Report hygiene ===
check "H1P1-07: H1 report exists" { Test-Path $h1Report }

$reportContent = ""
if (Test-Path $h1Report) { $reportContent = Get-Content $h1Report -Raw }

check "H1P1-08: No PENDING in report" {
    -not ($reportContent -match 'Verdict.*PENDING' -or $reportContent -match 'PENDING.*verifier')
}

check "H1P1-09: No corrupted paths (uns/h1-)" {
    -not ($reportContent -match '(?<!\w)uns/')
}

$actualScripts = @(Get-ChildItem $core -Filter *.ps1).Count
check "H1P1-10: 11 scripts in harness-core" { $actualScripts -eq 11 }

check "H1P1-11: No control chars in report" {
    $bad = [regex]::Matches($reportContent, '[\x00-\x08\x0B\x0C\x0E-\x1F]')
    $bad.Count -eq 0
}

check "H1P1-12: No duplicate fixture rows" {
    $rows = [regex]::Matches($reportContent, '\| \d+ \|.*\|.*\|.*\|.*\|.*\|')
    $texts = $rows | ForEach-Object { $_.Value }
    $unique = $texts | Select-Object -Unique
    $unique.Count -eq $texts.Count
}

# === Part 3: Script inventory ===
$required = @("append-run-state-event.ps1","apply-integration-patch.ps1","freeze-worker-output.ps1","register-verifier-hash.ps1","require-run-state.ps1","validate-cfp-fail-closed.ps1","verify-integration-patch-ledger.ps1","verify-run-contract.ps1","verify-run-state-chain.ps1","verify-verifier-registry.ps1","verify-worker-freeze.ps1")
$n = 12
foreach ($rs in $required) {
    $n++
    $label = "H1P1-{0:D2}: {1} exists" -f $n, $rs
    check $label { Test-Path "$core\$rs" }
}

# === Part 4: append/verify state functional ===
check "H1P1-24: append-run-state-event functional" {
    $testDir = "$run\p1-test-state"
    if (Test-Path $testDir) { Remove-Item -Recurse -Force $testDir }
    $result = & "$core\append-run-state-event.ps1" -RunDir $testDir -EventType "test_event" -ActorRole "P1-Verifier" -Payload @{test=$true} -RunId "h1-p1-test" | ConvertFrom-Json
    $result.status -eq "APPENDED"
}

check "H1P1-25: verify-run-state-chain functional" {
    $testDir = "$run\p1-test-state"
    $result = & "$core\verify-run-state-chain.ps1" -RunDir $testDir | ConvertFrom-Json
    $result.verdict -eq "PASS"
}
if (Test-Path "$run\p1-test-state") { Remove-Item -Recurse -Force "$run\p1-test-state" }

# === Part 5: Meta transcript ===
check "H1P1-26: Meta transcript exists" { Test-Path "$run\meta-verifier-stdout.json" }

# === Part 6: Closed reports ===
$closed = @(
    "PHASE_6C_DRY14_A_SCHEDULED_JOBS_RETRY_QUEUE_REPORT.md",
    "PHASE_6C_DRY14_B_SCHEDULER_NEGATIVE_CONTROLS_REPORT.md",
    "PHASE_6C_DRY15_A_SEARCH_FILTER_PAGINATION_PERFORMANCE_REPORT.md",
    "PHASE_6C_DRY15_B_SEARCH_PAGINATION_PERFORMANCE_NEGATIVE_CONTROLS_REPORT.md",
    "PHASE_6C_DRY15_B_P1_PERFORMANCE_BUDGET_NEGATIVE_HARDENING_REPORT.md"
)
$cn = 26
foreach ($cr in $closed) {
    $cn++
    $shortName = ($cr -replace 'PHASE_6C_','' -replace '_REPORT\.md','').Substring(0,[Math]::Min(30,($cr.Length-14)))
    $label = "H1P1-{0:D2}: Closed report {1}" -f $cn, $shortName
    check $label { Test-Path "$o\$cr" }
}

# === Part 7: Cross-cutting ===
check "H1P1-32: No final ZIP" { -not (Test-Path "$o\phase6c-h1-p1-*.zip") }
check "H1P1-33: DRY2-C through DRY13-C paused" {
    -not (Test-Path "$o\PHASE_6C_DRY2_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY3_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY4_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY5_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY6_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY7_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY8_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY9_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY10_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY11_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY12_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY13_C_*")
}
check "H1P1-34: P1 report exists" { Test-Path "$o\PHASE_6C_H1_P1_EVIDENCE_RECONCILIATION_REPORT.md" }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
@{phase="Phase 6C-H1-P1";reportType="h1-p1-evidence-reconciliation-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E;metaVerifierExitCode=$metaExit;metaVerifierVerdict=$metaVerdict} | ConvertTo-Json -Depth 3
exit $exitCode
