# generate-handoff.ps1 — Generate handoff packet for new Codex window
param([Parameter(Mandatory)]$ProjectPath, [switch]$Json)

$cfDir = Join-Path $ProjectPath ".codex-factory"
if (-not (Test-Path $cfDir)) { Write-Error ".codex-factory/ not found."; exit 1 }

# Validate first
Write-Host "[HANDOFF] Validating memory before handoff..."
$validateResult = & "$PSScriptRoot\validate-memory.ps1" -ProjectPath $ProjectPath -Json | ConvertFrom-Json
if (-not $validateResult.valid) {
    Write-Warning "Memory validation has errors. Handoff may be incomplete."
}

# Read all state
$state = Get-Content (Join-Path $cfDir "project-state.json") -Raw | ConvertFrom-Json
$tg = Get-Content (Join-Path $cfDir "task-graph.json") -Raw | ConvertFrom-Json
$ar = Get-Content (Join-Path $cfDir "active-risks.json") -Raw | ConvertFrom-Json
$vh = Get-Content (Join-Path $cfDir "verifier-history.json") -Raw | ConvertFrom-Json
$am = if (Test-Path (Join-Path $cfDir "architecture-map.json")) { Get-Content (Join-Path $cfDir "architecture-map.json") -Raw | ConvertFrom-Json } else { $null }
$rm = if (Test-Path (Join-Path $cfDir "requirement-map.json")) { Get-Content (Join-Path $cfDir "requirement-map.json") -Raw | ConvertFrom-Json } else { $null }

$completedStages = ($state.stages.PSObject.Properties | Where-Object { $_.Value -eq "COMPLETED" }).Name
$activeRisks = $ar.risks | Where-Object { $_.status -eq "ACTIVE" }
$criticalRisks = $activeRisks | Where-Object { $_.severity -eq "CRITICAL" }

# Build evidence paths
$evidencePaths = @()
if (Test-Path (Join-Path $cfDir "verifier-history.json")) { $evidencePaths += ".codex-factory/verifier-history.json" }
if (Test-Path (Join-Path $cfDir "verifier-results")) { $evidencePaths += ".codex-factory/verifier-results/" }
if ($am) { $evidencePaths += ".codex-factory/architecture-map.json" }
if ($rm) { $evidencePaths += ".codex-factory/requirement-map.json" }

$handoff = @{
    projectId = $state.projectId
    version = $state.version
    generatedAt = (Get-Date).ToString("o")
    currentStage = $state.currentStage
    selectedMode = $state.selectedMode
    complexityLevel = $state.complexityLevel
    agentCount = $state.agentCount
    completedStages = @($completedStages)
    taskSummary = "$($tg.completedTasks)/$($tg.totalTasks) tasks complete, $(($tg.tasks|Where-Object{$_.status-eq'PENDING'}).Count) pending"
    activeRiskCount = $activeRisks.Count
    criticalRiskCount = $criticalRisks.Count
    lastVerifierResult = if ($vh.entries.Count -gt 0) { $vh.entries[-1].result } else { "N/A" }
    keyDecisions = @()
    activeRisks = @($activeRisks | Select-Object id,description,severity,mitigation)
    evidencePaths = $evidencePaths
    forbiddenAssumptions = @("Conversation memory is trustworthy after rotation","Compressed summaries are evidence","Handoff is authoritative PASS","Memory files guarantee product quality")
    rejectedClaims = @()
    continuationInstructions = "Read .codex-factory/handoff-packet.json first. Then project-state.json and task-graph.json. Resume from stage '$($state.currentStage)' using mode '$($state.selectedMode)'."
    validationWarnings = $validateResult.warnings
}

$handoff | ConvertTo-Json -Depth 5 | Out-File (Join-Path $cfDir "handoff-packet.json") -Encoding UTF8

if ($Json) { $handoff | ConvertTo-Json -Depth 5 }
else {
    Write-Host "[HANDOFF] Packet generated: $cfDir\handoff-packet.json"
    Write-Host "  Stage: $($state.currentStage) | Mode: $($state.selectedMode)"
    Write-Host "  Tasks: $($handoff.taskSummary)"
    Write-Host "  Risks: $($handoff.activeRiskCount) active ($($handoff.criticalRiskCount) critical)"
    Write-Host "  Evidence paths: $($evidencePaths.Count)"
}
@{status="ok";handoffPath=(Join-Path $cfDir "handoff-packet.json");stage=$state.currentStage} | ConvertTo-Json
