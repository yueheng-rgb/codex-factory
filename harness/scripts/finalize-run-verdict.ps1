# finalize-run-verdict.ps1 鈥?Phase 6C-O-R1
# Aggregates machine evidence into final verdict.
# Supports -PhaseMode SelfTest (allows NOT_APPLICABLE for engineering/validateState)
# and -PhaseMode Project (all hard gates must be PASS).
param(
    [Parameter(Mandatory=$true)][string]$RunDir,
    [ValidateSet("SelfTest","Project")][string]$PhaseMode = "Project",
    [switch]$Json
)

$ErrorActionPreference = "Continue"
$hardGates = [ordered]@{}
$failures = [System.Collections.ArrayList]::new()
$exitCode = 0

function Get-NumericExitCode($path) {
    if (-not (Test-Path $path)) { return $null }
    try { $val = (Get-Content $path -Raw).Trim(); if ($val -match '^\d+$') { return [int]$val } } catch {}
    return $null
}

# --- Engineering Gate ---
$npmCiEc = Get-NumericExitCode (Join-Path $RunDir "command-logs\npm-ci-exitcode.txt")
$typecheckEc = Get-NumericExitCode (Join-Path $RunDir "command-logs\typecheck-exitcode.txt")
$testEc = Get-NumericExitCode (Join-Path $RunDir "command-logs\test-unit-exitcode.txt")
$buildEc = Get-NumericExitCode (Join-Path $RunDir "command-logs\build-exitcode.txt")

$engCodes = @($npmCiEc, $typecheckEc, $testEc, $buildEc)
$engMissing = ($engCodes | Where-Object { $null -eq $_ }).Count
$engNonZero = ($engCodes | Where-Object { $_ -ne $null -and $_ -ne 0 }).Count

if ($engMissing -eq 4 -and $PhaseMode -eq "SelfTest") {
    $hardGates["engineering"] = "NOT_APPLICABLE"
    $hardGates["engineeringNote"] = "SelfTest: no build pipeline"
} elseif ($engNonZero -gt 0) {
    $hardGates["engineering"] = "FAIL"
    [void]$failures.Add("engineering: $engNonZero commands non-zero exit code")
} elseif ($engMissing -gt 0) {
    if ($PhaseMode -eq "SelfTest") {
        $hardGates["engineering"] = "NOT_APPLICABLE"
        $hardGates["engineeringNote"] = "SelfTest: $engMissing engineering exitcode files missing or non-numeric"
    } else {
        $hardGates["engineering"] = "FAIL"
        [void]$failures.Add("engineering: $engMissing exitcode files missing or non-numeric")
    }
} else {
    $hardGates["engineering"] = "PASS"
}

# --- validateState Gate ---
$vsStdoutPath = Join-Path $RunDir "command-logs\validate-state-stdout.log"
$vsEcPath = Join-Path $RunDir "command-logs\validate-state-exitcode.txt"

if (-not (Test-Path $vsStdoutPath)) {
    if ($PhaseMode -eq "SelfTest") {
        $hardGates["validateState"] = "NOT_APPLICABLE"
        $hardGates["validateStateNote"] = "SelfTest: no validate-state stdout"
    } else {
        $hardGates["validateState"] = "FAIL"
        [void]$failures.Add("validateState: stdout not found")
    }
} else {
    try {
        $vsRaw = Get-Content $vsStdoutPath -Raw -Encoding UTF8
        if ($vsRaw.TrimStart().StartsWith('{')) {
            $vs = $vsRaw | ConvertFrom-Json
            if ($vs.verdict -eq "run_passed" -and $vs.status -eq "PASS" -and $vs.errors.Count -eq 0) {
                $hardGates["validateState"] = "PASS"
            } else {
                $hardGates["validateState"] = "FAIL"
                [void]$failures.Add("validateState: verdict=$($vs.verdict) status=$($vs.status) errors=$($vs.errors.Count)")
            }
        } else {
            if ($PhaseMode -eq "SelfTest") {
                $hardGates["validateState"] = "NOT_APPLICABLE"
                $hardGates["validateStateNote"] = "SelfTest: validate-state stdout is non-JSON (self-test phase)"
            } else {
                $hardGates["validateState"] = "FAIL"
                [void]$failures.Add("validateState: stdout is not valid JSON")
            }
        }
    } catch {
        if ($PhaseMode -eq "SelfTest") {
            $hardGates["validateState"] = "NOT_APPLICABLE"
            $hardGates["validateStateNote"] = "SelfTest: validate-state stdout parse error"
        } else {
            $hardGates["validateState"] = "FAIL"
            [void]$failures.Add("validateState: stdout parse error")
        }
    }
}

# --- Evidence Gate ---
$egPath = Join-Path $RunDir "evidence-gate-report.json"
if (-not (Test-Path $egPath)) {
    $hardGates["evidenceGate"] = "FAIL"
    [void]$failures.Add("evidenceGate: report not found")
} else {
    try {
        $eg = Get-Content $egPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($eg.verdict -eq "PASS") { $hardGates["evidenceGate"] = "PASS" }
        else { $hardGates["evidenceGate"] = "FAIL"; [void]$failures.Add("evidenceGate: $($eg.failedGates)/$($eg.totalGates) failed") }
    } catch { $hardGates["evidenceGate"] = "FAIL"; [void]$failures.Add("evidenceGate: parse error") }
}

# --- SHA256SUMS ---
$shaPath = Join-Path $RunDir "sha256sums-validation-report.json"
if (-not (Test-Path $shaPath)) { $hardGates["sha256sums"] = "FAIL"; [void]$failures.Add("sha256sums: report not found") }
else {
    try {
        $sr = Get-Content $shaPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($sr.status -eq "PASS" -or $sr.verdict -eq "PASS") { $hardGates["sha256sums"] = "PASS" }
        else { $hardGates["sha256sums"] = "FAIL"; [void]$failures.Add("sha256sums: not PASS") }
    } catch { $hardGates["sha256sums"] = "FAIL"; [void]$failures.Add("sha256sums: parse error") }
}

# --- Release Evidence Completeness ---
$recPath = Join-Path $RunDir "release-evidence-completeness-report.json"
if (-not (Test-Path $recPath)) { $hardGates["releaseEvidenceCompleteness"] = "FAIL"; [void]$failures.Add("releaseEvidenceCompleteness: report not found") }
else {
    try {
        $rec = Get-Content $recPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($rec.status -eq "PASS" -or $rec.verdict -eq "PASS") { $hardGates["releaseEvidenceCompleteness"] = "PASS" }
        else { $hardGates["releaseEvidenceCompleteness"] = "FAIL" }
    } catch { $hardGates["releaseEvidenceCompleteness"] = "FAIL" }
}

# --- Manifest Format ---
$mfPath = Join-Path $RunDir "manifest-format-validation-report.json"
if (-not (Test-Path $mfPath)) { $hardGates["manifestFormat"] = "FAIL"; [void]$failures.Add("manifestFormat: report not found") }
else {
    try {
        $mf = Get-Content $mfPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($mf.status -eq "PASS" -or $mf.verdict -eq "PASS") { $hardGates["manifestFormat"] = "PASS" }
        else { $hardGates["manifestFormat"] = "FAIL" }
    } catch { $hardGates["manifestFormat"] = "FAIL" }
}

# --- Ownership ---
$owPath = Join-Path $RunDir "ownership-audit-report.json"
if (-not (Test-Path $owPath)) { $hardGates["ownership"] = "FAIL"; [void]$failures.Add("ownership: report not found") }
else {
    try {
        $ow = Get-Content $owPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($ow.status -eq "PASS" -or $ow.verdict -eq "PASS") { $hardGates["ownership"] = "PASS" }
        else { $hardGates["ownership"] = "FAIL" }
    } catch { $hardGates["ownership"] = "FAIL" }
}

# --- Provenance ---
$pvPath = Join-Path $RunDir "provenance-validation-report.json"
if (-not (Test-Path $pvPath)) { $hardGates["provenance"] = "FAIL"; [void]$failures.Add("provenance: report not found") }
else {
    try {
        $pv = Get-Content $pvPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($pv.status -eq "PASS" -or $pv.verdict -eq "PASS") { $hardGates["provenance"] = "PASS" }
        else { $hardGates["provenance"] = "FAIL" }
    } catch { $hardGates["provenance"] = "FAIL" }
}

# --- Fixture Tests (SelfTest only) ---
$testResultsPath = Join-Path $RunDir "test-results.json"
$fixtureTests = "NOT_CHECKED"
if (Test-Path $testResultsPath) {
    try {
        $tr = Get-Content $testResultsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $fixtureTests = "$($tr.passedTests)/$($tr.totalTests) passed"
        if ($tr.failedTests -gt 0) { [void]$failures.Add("fixtureTests: $($tr.failedTests) failures") }
    } catch {}
}
$hardGates["fixtureTests"] = $fixtureTests

# --- Bundle Layout ---
$blPath = Join-Path $RunDir "bundle-layout-report.json"
if (-not (Test-Path $blPath)) {
    if ($PhaseMode -eq "SelfTest") {
        $hardGates["bundleLayout"] = "NOT_APPLICABLE"
        $hardGates["bundleLayoutNote"] = "SelfTest: no bundle layout check"
    } else {
        $hardGates["bundleLayout"] = "FAIL"
        [void]$failures.Add("bundleLayout: report not found")
    }
} else {
    try {
        $bl = Get-Content $blPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($bl.verdict -eq "PASS") { $hardGates["bundleLayout"] = "PASS" }
        else { $hardGates["bundleLayout"] = "FAIL"; [void]$failures.Add("bundleLayout: $($bl.errors.Count) violations") }
    } catch { $hardGates["bundleLayout"] = "FAIL"; [void]$failures.Add("bundleLayout: parse error") }
}

# --- Final Verdict ---
$allPass = $true
foreach ($k in $hardGates.Keys) {
    if ($k -match 'Note$') { continue }
    if ($hardGates[$k] -eq "FAIL") { $allPass = $false; break }
    if ($hardGates[$k] -eq "NOT_APPLICABLE" -and $PhaseMode -eq "Project") { $allPass = $false; [void]$failures.Add("${k}: NOT_APPLICABLE not allowed in Project mode"); break }
}
$verdict = if ($allPass) { "PASS" } else { "FAIL" }
$exitCode = if ($allPass) { 0 } else { 1 }

$hardGates["phaseMode"] = $PhaseMode
if ($PhaseMode -eq "SelfTest") {
    $hardGates["notApplicablePolicy"] = "SelfTest mode allows engineering/validateState NOT_APPLICABLE for guardrail self-tests. Project mode never allows NOT_APPLICABLE."
}

$report = @{
    schemaVersion = "6C-O-R1"
    runDir = $RunDir
    timestamp = (Get-Date).ToString("o")
    verdict = $verdict
    phaseMode = $PhaseMode
    hardGates = $hardGates
    hardGateFailures = @($failures)
    derivationRule = "FinalVerdict = PASS only if ALL hard gates PASS. SelfTest: NOT_APPLICABLE allowed for engineering/validateState. Project: all must be PASS."
}

if ($Json) {
    Write-Output ($report | ConvertTo-Json -Depth 4)
} else {
    Write-Output "=== Final Verdict ==="
    Write-Output "Mode: $PhaseMode | Verdict: $verdict"
    foreach ($k in $hardGates.Keys) {
        if ($k -match 'Note$' -or $k -eq "notApplicablePolicy") { continue }
        $icon = if ($hardGates[$k] -eq "PASS") { "[PASS]" } elseif ($hardGates[$k] -eq "FAIL") { "[FAIL]" } else { "[N/A]" }
        Write-Output "$icon $k : $($hardGates[$k])"
    }
    if ($failures.Count -gt 0) { Write-Output "`nFailures:"; foreach ($f in $failures) { Write-Output "  - $f" } }
}

exit $exitCode