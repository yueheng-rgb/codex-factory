# verify-acceptance-evidence-integrity.ps1 - Phase 6C-H8-P2 (target-scenario-aware)
param(
    [Parameter(Mandatory=$true)][string]$AcceptanceReportPath,
    [string]$TranscriptPath = "",
    [string]$RequiredScenariosPath = "",
    [string]$RunnerSourcePath = "",
    [string]$Mode = "positive",
    [string]$TargetScenarioId = "",
    [string[]]$ExpectedFailedScenarioIds = @(),
    [string[]]$AllowedNonTargetFailedScenarioIds = @(),
    [string[]]$RequiredNonTargetScenarioIds = @()
)
$ErrorActionPreference = "Continue"
$analyzer = Join-Path (Split-Path $PSCommandPath -Parent) "analyze-acceptance-evidence.ps1"
$ts = (Get-Date).ToString("o")

$analyzerArgs = @("-NoProfile", "-File", $analyzer, "-AcceptanceReportPath", $AcceptanceReportPath)
if ($TranscriptPath) { $analyzerArgs += @("-TranscriptPath", $TranscriptPath) }
if ($RequiredScenariosPath) { $analyzerArgs += @("-RequiredScenariosPath", $RequiredScenariosPath) }
if ($RunnerSourcePath) { $analyzerArgs += @("-RunnerSourcePath", $RunnerSourcePath) }

$raw = & powershell @analyzerArgs 2>&1 | Out-String
$evidence = try { $raw | ConvertFrom-Json } catch { $null }
if (-not $evidence) {
    Write-Output (ConvertTo-Json -InputObject @{verdict="FAIL"; classification="FAIL_HARNESS_NOISE"; reason="Analyzer returned null"; raw=$raw} -Compress)
    exit 1
}

$errors = @()
$classification = "PASS"

# Pre-checks
if ($evidence.hardcodedPassRisk) { $errors += "Hardcoded PASS risk detected"; $classification = "FAIL_HARNESS_NOISE" }
if ($evidence.skippedAsPass) { $errors += "Skipped scenarios counted as PASS"; $classification = "FAIL_HARNESS_NOISE" }

# Read acceptance JSON for target metadata fallback
$acceptanceJson = $null
try { $acceptanceJson = Get-Content $AcceptanceReportPath -Raw | ConvertFrom-Json } catch {}

if (-not $TargetScenarioId -and $acceptanceJson -and $acceptanceJson.targetScenarioId) { $TargetScenarioId = $acceptanceJson.targetScenarioId }
if ($ExpectedFailedScenarioIds.Count -eq 0 -and $acceptanceJson -and $acceptanceJson.expectedFailedScenarioIds) { $ExpectedFailedScenarioIds = @($acceptanceJson.expectedFailedScenarioIds) }
if ($RequiredNonTargetScenarioIds.Count -eq 0 -and $acceptanceJson -and $acceptanceJson.requiredNonTargetScenarioIds) { $RequiredNonTargetScenarioIds = @($acceptanceJson.requiredNonTargetScenarioIds) }

# Evidence checks from analyzer (non-ALL_SCENARIOS_PASS issues)
$allScenariosPassIssue = $false
foreach ($issue in $evidence.issues) {
    if ($issue -match "ALL_SCENARIOS_PASS") {
        $allScenariosPassIssue = $true
        if ($Mode -eq "negative-target-gate") { $errors += $issue }
        continue
    }
    if ($issue -match "MISSING_TRANSCRIPT|MISSING_COMMAND|MISSING_EXIT_CODE|PASS_WITH_ZERO_ASSERTIONS|MISSING_REQUIRED_SCENARIO|MISSING_EVIDENCE_REFS|MISSING_SCENARIO_DATA") { 
        $errors += $issue
        if ($classification -eq "PASS") { $classification = "FAIL_MISSING_EVIDENCE" }
    }
    elseif ($issue -match "DUPLICATE|EXIT_CODE_CONTRADICTION|NO_RUNNER_TIMESTAMP|ALL_IDENTICAL|SKIPPED_AS_PASS|UNKNOWN_SCENARIO") {
        $errors += $issue
        if ($classification -eq "PASS") { $classification = "FAIL_HARNESS_NOISE" }
    }
}

# Mode-specific checks
if ($Mode -eq "positive") {
    $allPassOk = ($evidence.failCount -eq 0 -and $evidence.skipCount -eq 0)
    if (-not $allPassOk) { $errors += "Positive mode: not all scenarios PASS (fail=$($evidence.failCount), skip=$($evidence.skipCount))" }
    if ($evidence.issues | Where-Object { $_ -match "PASS_WITH_ZERO_ASSERTIONS" }) { $errors += "Positive mode: PASS scenarios with zero assertions" }
}
elseif ($Mode -eq "negative-target-gate") {
    # === H8-P2: Target-scenario-aware negative mode ===
    
    # Preclassified-only check
    if ($acceptanceJson -and $acceptanceJson.preclassified -eq $true) {
        $errors += "Preclassified-only evidence: negative must be live-executed"
        if ($classification -eq "PASS") { $classification = "FAIL_MISSING_EVIDENCE" }
    }
    
    # TargetScenarioId required
    if (-not $TargetScenarioId) {
        $errors += "Negative mode: targetScenarioId missing (cannot determine which scenario should fail)"
        if ($classification -eq "PASS") { $classification = "FAIL_HARNESS_NOISE" }
    }
    else {
        $scenarioIds = @()
        if ($acceptanceJson -and $acceptanceJson.scenarios) { $scenarioIds = @($acceptanceJson.scenarios | ForEach-Object { $_.scenarioId }) }
        
        # Target must exist
        if ($TargetScenarioId -notin $scenarioIds) {
            $errors += "Negative mode: target scenario '$TargetScenarioId' not found in report"
            if ($classification -eq "PASS") { $classification = "FAIL_HARNESS_NOISE" }
        }
        else {
            $targetScenario = $acceptanceJson.scenarios | Where-Object { $_.scenarioId -eq $TargetScenarioId }
            
            # PRIORITY 1: Check target not failing -> FAIL_TARGET_GATE
            if ($targetScenario.status -ne "FAIL") {
                $errors += "Negative mode: target scenario '$TargetScenarioId' did not FAIL (actual: $($targetScenario.status))"
                if ($classification -eq "PASS") { $classification = "FAIL_TARGET_GATE" }
            }
            
            # PRIORITY 2: Check non-target unexpected failures -> FAIL_HARNESS_NOISE (overrides FAIL_TARGET_GATE)
            $nonTargetIds = @($scenarioIds | Where-Object { $_ -ne $TargetScenarioId })
            $allowedSet = @($ExpectedFailedScenarioIds) + @($AllowedNonTargetFailedScenarioIds) + @($TargetScenarioId)
            $unexpectedFailures = $false
            foreach ($sid in $nonTargetIds) {
                if ($sid -in $allowedSet) { continue }
                $ns = $acceptanceJson.scenarios | Where-Object { $_.scenarioId -eq $sid }
                if ($ns -and $ns.status -eq "FAIL") {
                    $errors += "Negative mode: non-target scenario '$sid' unexpectedly FAILED"
                    $unexpectedFailures = $true
                }
            }
            if ($unexpectedFailures) { $classification = "FAIL_HARNESS_NOISE" }
            
            # Check required non-target scenarios PASS
            foreach ($rid in $RequiredNonTargetScenarioIds) {
                if ($rid -in $scenarioIds) {
                    $rs = $acceptanceJson.scenarios | Where-Object { $_.scenarioId -eq $rid }
                    if ($rs -and $rs.status -ne "PASS") {
                        $errors += "Negative mode: required non-target scenario '$rid' did not PASS (actual: $($rs.status))"
                        if ($classification -eq "PASS") { $classification = "FAIL_HARNESS_NOISE" }
                    }
                }
            }
        }
    }
    
    # Evidence quality checks for negative mode
    if ($evidence.issues | Where-Object { $_ -match "MISSING_TRANSCRIPT" }) {
        $errors += "Negative mode: transcript required for target-gate verification"
        if ($classification -eq "PASS") { $classification = "FAIL_MISSING_EVIDENCE" }
    }
    if ($evidence.issues | Where-Object { $_ -match "MISSING_COMMAND" }) {
        $errors += "Negative mode: runner command required"
        if ($classification -eq "PASS") { $classification = "FAIL_MISSING_EVIDENCE" }
    }
    if ($evidence.issues | Where-Object { $_ -match "MISSING_EXIT_CODE" }) {
        $errors += "Negative mode: runner exit code required"
        if ($classification -eq "PASS") { $classification = "FAIL_MISSING_EVIDENCE" }
    }
    if ($evidence.hardcodedPassRisk) {
        $errors += "Negative mode: hardcoded PASS risk in negative control"
        if ($classification -eq "PASS") { $classification = "FAIL_HARNESS_NOISE" }
    }
    
    # PRIORITY 3: ALL_SCENARIOS_PASS (lowest priority, only if nothing else classified)
    if ($allScenariosPassIssue -and $classification -eq "PASS") {
        $classification = "FAIL_HARNESS_NOISE"
    }
}

# Safety: never return generic FAIL
if ($errors.Count -gt 0 -and $classification -eq "PASS") { $classification = "FAIL_HARNESS_NOISE" }

$verdict = if ($errors.Count -eq 0) { "PASS" } else { "FAIL" }
$result = @{
    verdict = $verdict
    classification = $classification
    failedChecks = $errors
    evidence = $evidence
    checkedAt = $ts
    mode = $Mode
    targetScenarioId = $TargetScenarioId
}
Write-Output (ConvertTo-Json -InputObject $result -Depth 4 -Compress)
exit $(if ($verdict -eq "FAIL") { 1 } else { 0 })