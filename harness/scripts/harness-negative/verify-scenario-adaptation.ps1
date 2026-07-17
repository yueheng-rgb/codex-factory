# verify-scenario-adaptation.ps1 — Phase 6C-H6
# Governs scenario adaptation for negative controls
param([Parameter(Mandatory=$true)][string]$NegativeRunDir, [string]$ParentRunDir = "")
$ErrorActionPreference = "Continue"

$adaptationFile = Join-Path $NegativeRunDir "scenario-adaptation.json"
$tr = Join-Path $NegativeRunDir "reports\acceptance-transcript.json"

if (-not (Test-Path $tr)) { Write-Output (@{verdict="FAIL"; classification="FAIL_MISSING_EVIDENCE"; reason="No transcript"} | ConvertTo-Json); exit 1 }

$transcript = Get-Content $tr -Raw | ConvertFrom-Json
$failed = @($transcript.transcript | Where-Object { -not $_.passed })
$adaptedCount = 0
$adapt = $null

# Check for adaptation manifest
if (Test-Path $adaptationFile) {
    $adapt = Get-Content $adaptationFile -Raw | ConvertFrom-Json
    $adaptedCount = $adapt.adaptedScenarios.Count
}

$failedCount = $failed.Count
$hasAdaptation = ($null -ne $adapt)

# Classification logic
if ($failedCount -eq 1 -and -not $hasAdaptation) {
    $result = @{verdict="PASS"; classification="CLEAN_SINGLE_FAILURE"; failedCount=1; adaptedCount=0; reason="Single scenario failure without adaptation"; timestamp=(Get-Date).ToString("o")}
} elseif ($hasAdaptation) {
    # Build set of adapted scenario IDs (handle both string and object formats)
    $adaptedSet = @{}
    foreach ($aid in $adapt.adaptedScenarios) {
        if ($aid -is [string]) { $adaptedSet[$aid] = $true }
        elseif ($aid.scenarioId) { $adaptedSet[$aid.scenarioId] = $true }
        else { $adaptedSet["$aid"] = $true }
    }
    $failedIds = @($failed | ForEach-Object { $_.id })
    $uncovered = @($failedIds | Where-Object { -not $adaptedSet[$_] })
    if ($uncovered.Count -gt 0) {
        $result = @{verdict="FAIL"; classification="FAIL_HARNESS_NOISE"; failedCount=$failedCount; adaptedCount=$adaptedCount; reason="Adaptation hides non-target failures: $($uncovered -join ', ')"; uncoveredFailures=@($uncovered); timestamp=(Get-Date).ToString("o")}
    } elseif ($adapt.approved) {
        $result = @{verdict="PASS_WITH_CAVEAT"; classification="PASS_WITH_CAVEAT"; failedCount=$failedCount; adaptedCount=$adaptedCount; reason="All failed scenarios covered by approved adaptation"; timestamp=(Get-Date).ToString("o")}
    } else {
        $result = @{verdict="PASS_WITH_CAVEAT"; classification="PASS_WITH_CAVEAT"; failedCount=$failedCount; adaptedCount=$adaptedCount; reason="All failed scenarios covered by adaptation (unapproved)"; timestamp=(Get-Date).ToString("o")}
    }
} elseif ($failedCount -gt 1 -and -not $hasAdaptation) {
    $result = @{verdict="FAIL"; classification="FAIL_HARNESS_NOISE"; failedCount=$failedCount; adaptedCount=0; reason="Multiple scenario failures without adaptation governance"; timestamp=(Get-Date).ToString("o")}
} elseif ($failedCount -eq 0) {
    $result = @{verdict="FAIL"; classification="FAIL_TARGET_GATE"; failedCount=0; adaptedCount=0; reason="NO failures - target-gate negative must fail"; timestamp=(Get-Date).ToString("o")}
} else {
    $result = @{verdict="FAIL"; classification="FAIL_HARNESS_NOISE"; failedCount=$failedCount; adaptedCount=$adaptedCount; reason="Unclassified adaptation state"; timestamp=(Get-Date).ToString("o")}
}

Write-Output ($result | ConvertTo-Json -Compress)
if ($result.verdict -match "FAIL") { exit 1 } else { exit 0 }
