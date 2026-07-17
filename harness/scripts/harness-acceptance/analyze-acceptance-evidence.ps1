# analyze-acceptance-evidence.ps1 - Phase 6C-H8-P1
# Pattern-based acceptance evidence analyzer. Detects hardcoded PASS, missing transcripts, etc.
param(
    [Parameter(Mandatory=$true)][string]$AcceptanceReportPath,
    [string]$TranscriptPath = "",
    [string]$StdoutPath = "",
    [string]$StderrPath = "",
    [string]$RequiredScenariosPath = "",
    [string]$RunnerSourcePath = ""
)
$ErrorActionPreference = "Continue"
$issues = @()
$ts = (Get-Date).ToString("o")

if (-not (Test-Path $AcceptanceReportPath)) { 
    Write-Output (ConvertTo-Json -InputObject @{verdict="FAIL"; classification="FAIL_MISSING_EVIDENCE"; issues=@("Acceptance report not found"); checkedAt=$ts} -Depth 3)
    exit 1 
}

$report = Get-Content $AcceptanceReportPath -Raw | ConvertFrom-Json
$requiredScenarios = @()
if ($RequiredScenariosPath -and (Test-Path $RequiredScenariosPath)) { 
    $rs = Get-Content $RequiredScenariosPath -Raw | ConvertFrom-Json
    $requiredScenarios = @(if ($rs -is [array]) { $rs } else { $rs.requiredScenarios })
}

# Check 1: Missing transcript
$hasTranscript = ($TranscriptPath -and (Test-Path $TranscriptPath))
$transcriptContent = if ($hasTranscript) { Get-Content $TranscriptPath -Raw } else { "" }
if (-not $hasTranscript) { $issues += "MISSING_TRANSCRIPT: No transcript file found" }

# Check 2: Missing command
$hasCommand = ($report.runner -and $report.runner.command)
if (-not $hasCommand) { $issues += "MISSING_COMMAND: No runner command in report" }

# Check 3: Missing exit code
$hasExitCode = ($report.runner -and $report.runner.exitCode -ne $null)
if (-not $hasExitCode) { $issues += "MISSING_EXIT_CODE: No runner exit code" }

# Check 4: Scenario PASS with zero assertions
$scenarios = @(if ($report.scenarios) { $report.scenarios } else { @() })
$zeroAssertionPasses = @()
foreach ($s in $scenarios) {
    if ($s.status -eq "PASS" -and ($s.assertionCount -eq 0 -or (-not $s.assertions) -or $s.assertions.Count -eq 0)) {
        $zeroAssertionPasses += $s.scenarioId
    }
}
if ($zeroAssertionPasses.Count -gt 0) { $issues += "PASS_WITH_ZERO_ASSERTIONS: $($zeroAssertionPasses -join ', ')" }

# Check 5: Required scenario missing
if ($requiredScenarios.Count -gt 0) {
    $presentIds = @($scenarios | ForEach-Object { $_.scenarioId })
    foreach ($req in $requiredScenarios) {
        if ($req -notin $presentIds) { $issues += "MISSING_REQUIRED_SCENARIO: $req" }
    }
}

# Check 6: Unknown scenario present
if ($requiredScenarios.Count -gt 0) {
    $presentIds = @($scenarios | ForEach-Object { $_.scenarioId })
    foreach ($pid in $presentIds) {
        if ($pid -notin $requiredScenarios) { $issues += "UNKNOWN_SCENARIO: $pid" }
    }
}

# Check 7: Duplicate scenario IDs
$idCounts = @{}
foreach ($s in $scenarios) { 
    if (-not $idCounts[$s.scenarioId]) { $idCounts[$s.scenarioId] = 0 }
    $idCounts[$s.scenarioId]++ 
}
$dupes = @($idCounts.Keys | Where-Object { $idCounts[$_] -gt 1 })
if ($dupes.Count -gt 0) { $issues += "DUPLICATE_SCENARIO_IDS: $($dupes -join ', ')" }

# Check 8: Skipped counted as PASS
$skippedAsPass = ($report.skippedAsPass -eq $true)
$skippedPasses = @($scenarios | Where-Object { $_.status -eq "PASS" -and (-not $_.assertions -or $_.assertions.Count -eq 0) })
if ($skippedAsPass -or $skippedPasses.Count -gt 0) { $issues += "SKIPPED_AS_PASS: $($skippedPasses.Count) scenarios" }

# Check 9: All scenarios have identical expected/actual summaries
$expectedSet = @{}
$actualSet = @{}
foreach ($s in $scenarios) {
    $expectedSet[$s.expectedSummary] = $true
    $actualSet[$s.actualSummary] = $true
}
if ($expectedSet.Count -eq 1 -and $scenarios.Count -gt 1) { $issues += "ALL_IDENTICAL_EXPECTED: All scenarios share same expectedSummary" }
if ($actualSet.Count -eq 1 -and $scenarios.Count -gt 1) { $issues += "ALL_IDENTICAL_ACTUAL: All scenarios share same actualSummary" }

# Check 10: All PASS in negative context
$allPass = ($scenarios.Count -gt 0 -and @($scenarios | Where-Object { $_.status -ne "PASS" }).Count -eq 0)
if ($allPass) { $issues += "ALL_SCENARIOS_PASS: No failures in report (may be hardcoded)" }

# Check 11: Report created without runner execution timestamp
if (-not $report.runner -or -not $report.runner.startedAt) { $issues += "NO_RUNNER_TIMESTAMP: No runner execution timestamp" }

# Check 12: Report status contradicts exit code
if ($report.runner -and $report.runner.exitCode -ne $null) {
    $allScenariosPass = (@($scenarios | Where-Object { $_.status -ne "PASS" }).Count -eq 0)
    if ($allScenariosPass -and $report.runner.exitCode -ne 0) { $issues += "EXIT_CODE_CONTRADICTION: All PASS but exitCode=$($report.runner.exitCode)" }
}

# Check 13: Hardcoded PASS patterns in runner source
$hardcodedPassRisk = $false
$hardcodedSignals = @()
if ($RunnerSourcePath -and (Test-Path $RunnerSourcePath)) {
    $src = Get-Content $RunnerSourcePath -Raw
    # Tighter regex: match literal 'status = "PASS"' or 'status: "PASS"' (not inside ternaries)
    if ($src -match 'status\s*=\s*\"PASS\"\s*;|status\s*:\s*\"PASS\"\s*[,}]') { $hardcodedSignals += "status:PASS hardcoded literal" }
    if ($src -match 'all.*scenarios.*PASS|every.*scenario.*PASS|\bmap\s*\(.*=>\s*PASS\b') { $hardcodedSignals += "all/every/map scenarios to PASS unconditionally" }
    if ($src -match 'writeFile.*acceptance.*without|write.*acceptance.*JSON.*without.*run') { $hardcodedSignals += "writes acceptance JSON without invoking scenarios" }
    if ($src -match 'hardcoded.*pass|always.*return.*pass|return\s*\{\s*passed\s*:\s*true') { $hardcodedSignals += "hardcoded PASS return pattern" }
    if ($src -match 'scenarios\.forEach.*=>.*PASS|\.map\s*\(\s*function\s*\(\)\s*\{\s*return\s*PASS') { $hardcodedSignals += "scenario iteration mapped to PASS" }
}
if ($hardcodedSignals.Count -gt 0) { $hardcodedPassRisk = $true; $issues += "HARDCODED_PASS_RISK: $($hardcodedSignals -join '; ')" }

# Check 14: Missing evidenceRefs
$missingRefs = @($scenarios | Where-Object { -not $_.evidenceRefs -or $_.evidenceRefs.Count -eq 0 })
if ($missingRefs.Count -gt 0) { $issues += "MISSING_EVIDENCE_REFS: $($missingRefs.scenarioId -join ', ')" }

# Check 15: No per-scenario input/expected/actual data
$missingData = @($scenarios | Where-Object { -not $_.inputSummary -or -not $_.expectedSummary -or -not $_.actualSummary })
if ($missingData.Count -gt 0) { $issues += "MISSING_SCENARIO_DATA: $($missingData.scenarioId -join ', ')" }

$exitCode = if ($issues.Count -gt 0) { 1 } else { 0 }
$result = @{
    verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
    issues = $issues
    hardcodedPassRisk = $hardcodedPassRisk
    skippedAsPass = $skippedAsPass
    scenarioCount = $scenarios.Count
    passCount = @($scenarios | Where-Object { $_.status -eq "PASS" }).Count
    failCount = @($scenarios | Where-Object { $_.status -eq "FAIL" }).Count
    skipCount = @($scenarios | Where-Object { $_.status -eq "SKIPPED" }).Count
    checkedAt = $ts
}
Write-Output (ConvertTo-Json -InputObject $result -Depth 4 -Compress)
exit $exitCode