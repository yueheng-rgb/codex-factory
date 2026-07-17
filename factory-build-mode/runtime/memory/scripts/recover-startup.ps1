# recover-startup.ps1 — Startup recovery for new Codex window
# Uses ZERO trusted conversation memory — reads only from .codex-factory/ files
param([Parameter(Mandatory)]$ProjectPath, [switch]$Json)

$cfDir = Join-Path $ProjectPath ".codex-factory"
if (-not (Test-Path $cfDir)) { Write-Error ".codex-factory/ not found. Cannot recover."; exit 1 }

$recovery = @{
    success = $false
    projectPath = $ProjectPath
    timestamp = (Get-Date).ToString("o")
    source = ".codex-factory/ files only (zero trusted conversation memory)"
    validationPassed = $false
    currentStage = "UNKNOWN"
    warnings = @()
    instructions = ""
}

# Step 1: Validate memory first
Write-Host "[RECOVER] Step 1: Validating memory integrity..."
$validateResult = & "$PSScriptRoot\validate-memory.ps1" -ProjectPath $ProjectPath -Json | ConvertFrom-Json
if (-not $validateResult.valid) {
    $recovery.warnings += "Memory validation FAILED. Review issues before continuing."
    $recovery.instructions = "Memory validation failed. Fix issues in .codex-factory/ before resuming."
    if ($Json) { $recovery | ConvertTo-Json -Depth 4 } else { Write-Host "RECOVERY FAILED: Memory validation failed" }
    exit 2
}
$recovery.validationPassed = $true

# Step 2: Read state
Write-Host "[RECOVER] Step 2: Reading project state..."
$state = Get-Content (Join-Path $cfDir "project-state.json") -Raw | ConvertFrom-Json
$recovery.currentStage = $state.currentStage
$recovery.selectedMode = $state.selectedMode
$recovery.complexityLevel = $state.complexityLevel
$recovery.projectId = $state.projectId

# Step 3: Stale handoff check
Write-Host "[RECOVER] Step 3: Checking handoff freshness..."
$handoff = Get-Content (Join-Path $cfDir "handoff-packet.json") -Raw | ConvertFrom-Json
try {
    $handoffAge = (Get-Date) - [DateTime]::Parse($handoff.generatedAt)
    if ($handoffAge.TotalHours -gt 24) {
        $recovery.warnings += "Handoff packet is stale ($([Math]::Round($handoffAge.TotalHours,1)) hours old). Proceed with caution."
    }
} catch {
    $recovery.warnings += "Cannot parse handoff timestamp. Proceed with caution."
}

# Step 4: Check for compressed summary as sole evidence
$summaryFiles = Get-ChildItem $cfDir -Filter "*summary*" -File -ErrorAction SilentlyContinue
if ($summaryFiles -and $handoff.evidencePaths.Count -eq 0) {
    $recovery.warnings += "Compressed summary found but no evidence paths in handoff. Compressed summaries are NOT evidence."
}

# Step 5: Read task graph state
Write-Host "[RECOVER] Step 4: Reading task graph..."
$tg = Get-Content (Join-Path $cfDir "task-graph.json") -Raw | ConvertFrom-Json
$recovery.taskSummary = "$($tg.completedTasks)/$($tg.totalTasks) tasks complete"

# Step 6: Read active risks
Write-Host "[RECOVER] Step 5: Reading active risks..."
$ar = Get-Content (Join-Path $cfDir "active-risks.json") -Raw | ConvertFrom-Json
$criticalActive = ($ar.risks | Where-Object { $_.status -eq "ACTIVE" -and $_.severity -eq "CRITICAL" }).Count
if ($criticalActive -gt 0) {
    $recovery.warnings += "$criticalActive CRITICAL risks active. Review before continuing."
}

# Step 7: Build continuation instructions
$recovery.success = $true
$recovery.instructions = @"
Continue from stage '$($state.currentStage)' using mode '$($state.selectedMode)'.
1. Read handoff-packet.json for full context
2. Read task-graph.json for work items
3. Read decision-log.jsonl for decisions made
4. Read active-risks.json for known risks
5. Resume build pipeline from stage: $($state.currentStage)
6. Update project-state.json after each stage completion
"@

if ($Json) {
    $recovery | ConvertTo-Json -Depth 4
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " STARTUP RECOVERY COMPLETE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Project: $($recovery.projectId)"
    Write-Host "Stage: $($recovery.currentStage)"
    Write-Host "Mode: $($recovery.selectedMode)"
    Write-Host "Tasks: $($recovery.taskSummary)"
    if ($recovery.warnings.Count -gt 0) {
        Write-Host "WARNINGS:" -ForegroundColor Yellow
        foreach ($w in $recovery.warnings) { Write-Host "  - $w" -ForegroundColor Yellow }
    }
    Write-Host ""
    Write-Host $recovery.instructions
}

exit 0
