# classify-legacy-acceptance-evidence.ps1 - Phase 6C-H8-P2
# Classifies legacy acceptance evidence against H8-P2 current standard
param(
    [Parameter(Mandatory=$true)][string]$AcceptanceReportPath,
    [string]$TranscriptPath = "",
    [string]$RunDir = ""
)
$ErrorActionPreference = "Continue"
$ts = (Get-Date).ToString("o")
$missingFields = @()
$upgradeRequired = $false
$canBeAccepted = $true

if (-not (Test-Path $AcceptanceReportPath)) {
    Write-Output (ConvertTo-Json -InputObject @{
        verdict="FAIL"; classification="FAIL_MISSING_EVIDENCE"
        legacyEvidence=$false; missingFields=@("ACCEPTANCE_REPORT_NOT_FOUND")
        upgradeRequired=$true; canBeAcceptedUnderCurrentStandard=$false
        recommendedAction="Create acceptance report"; checkedAt=$ts
    } -Depth 4 -Compress)
    exit 0
}

try { $report = Get-Content $AcceptanceReportPath -Raw | ConvertFrom-Json } catch {
    Write-Output (ConvertTo-Json -InputObject @{
        verdict="FAIL"; classification="FAIL_HARNESS_NOISE"
        legacyEvidence=$true; missingFields=@("INVALID_JSON")
        upgradeRequired=$true; canBeAcceptedUnderCurrentStandard=$false
        recommendedAction="Fix JSON format"; checkedAt=$ts
    } -Depth 4 -Compress)
    exit 0
}

# Check H8-P2 required fields
if (-not $report.runner -or -not $report.runner.command) { $missingFields += "runner.command"; $canBeAccepted = $false }
if (-not $report.runner -or -not $report.runner.exitCode -and $report.runner.exitCode -ne 0) { $missingFields += "runner.exitCode"; $canBeAccepted = $false }
if (-not $report.runner -or -not $report.runner.startedAt) { $missingFields += "runner.startedAt"; $canBeAccepted = $false }

# Transcript
if ($TranscriptPath) {
    if (-not (Test-Path $TranscriptPath)) { $missingFields += "transcript_file"; $canBeAccepted = $false }
} else {
    # Search for transcript in run dir
    $foundTranscript = $false
    if ($RunDir -and (Test-Path $RunDir)) {
        $transFiles = @(Get-ChildItem $RunDir -Recurse -Filter "*transcript*" -File -ErrorAction SilentlyContinue)
        if ($transFiles.Count -gt 0) { $foundTranscript = $true }
    }
    if (-not $foundTranscript) { $missingFields += "transcript"; $canBeAccepted = $false }
}

# Scenarios
$scenarios = @(if ($report.scenarios) { $report.scenarios } else { @() })
if ($scenarios.Count -eq 0) { $missingFields += "scenarios"; $canBeAccepted = $false }

# Check scenario format (legacy uses name/passed vs scenarioId/status)
$usesLegacyFormat = $false
$scenarioFormatIssues = @()
foreach ($s in $scenarios) {
    if (-not $s.scenarioId -and $s.name) { $scenarioFormatIssues += "name_instead_of_scenarioId"; $usesLegacyFormat = $true }
    if (-not $s.status -and $s.passed -ne $null) { $scenarioFormatIssues += "passed_instead_of_status"; $usesLegacyFormat = $true }
    if (-not $s.assertions -or $s.assertions.Count -eq 0) { $scenarioFormatIssues += "missing_assertions" }
    if (-not $s.evidenceRefs -or $s.evidenceRefs.Count -eq 0) { $scenarioFormatIssues += "missing_evidenceRefs" }
    if (-not $s.inputSummary) { $scenarioFormatIssues += "missing_inputSummary" }
    if (-not $s.expectedSummary) { $scenarioFormatIssues += "missing_expectedSummary" }
    if (-not $s.actualSummary) { $scenarioFormatIssues += "missing_actualSummary" }
}
$uniqueIssues = @($scenarioFormatIssues | Select-Object -Unique)
if ($uniqueIssues.Count -gt 0) { $missingFields += $uniqueIssues; $canBeAccepted = $false }

$upgradeRequired = (-not $canBeAccepted)
$classification = if ($missingFields.Count -gt 0) { "FAIL_MISSING_EVIDENCE" } else { "PASS" }
$verdict = if ($canBeAccepted) { "PASS" } else { "FAIL" }

$recommendedAction = if ($upgradeRequired) {
    "Upgrade acceptance evidence: add runner.command/exitCode/startedAt, generate transcript, use scenarioId/status format, add assertions/evidenceRefs/inputSummary/expectedSummary/actualSummary per scenario"
} else { "Evidence meets H8-P2 standard" }

$result = @{
    verdict = $verdict
    classification = $classification
    legacyEvidence = $usesLegacyFormat
    missingFields = $missingFields
    upgradeRequired = $upgradeRequired
    canBeAcceptedUnderCurrentStandard = $canBeAccepted
    recommendedAction = $recommendedAction
    scenarioCount = $scenarios.Count
    usesLegacyFormat = $usesLegacyFormat
    checkedAt = $ts
}
Write-Output (ConvertTo-Json -InputObject $result -Depth 4 -Compress)
exit 0