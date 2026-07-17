# Capability Decision Record Logger
# Part of: FACTORY-R2.3-C-CAPABILITY-REGISTRY-RUNTIME
# Records permission gate decisions for auditability.
# Usage: . .\runtime\capability-decision-logger.ps1; Write-CapabilityDecision -DecisionResult $result -ProjectId "PROJ-001" -PhaseId "PHASE-IMPL" -AgentId "IMPL-FE-001"

. "$PSScriptRoot\capability-permission-gate.ps1"

$script:DecisionIndexPath = Join-Path (Split-Path $PSScriptRoot -Parent) "governance\capability-decisions\capability-decision-index.jsonl"

function Write-CapabilityDecision {
    param(
        [Parameter(Mandatory=$true)]$DecisionResult,
        [Parameter(Mandatory=$true)][string]$ProjectId,
        [Parameter(Mandatory=$true)][string]$PhaseId,
        [Parameter(Mandatory=$true)][string]$AgentId
    )
    
    $ts = Get-Date -Format "yyyyMMddHHmmss"
    $shortAgent = $AgentId -replace '[^A-Z0-9]', ''
    $capShort = $DecisionResult.CapabilityId -replace '[^A-Z0-9]', ''
    $decisionId = "CDEC-$shortAgent-$capShort-$ts"
    
    $record = [PSCustomObject]@{
        decisionId       = $decisionId
        timestamp        = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
        projectId        = $ProjectId
        phaseId          = $PhaseId
        agentId          = $AgentId
        capabilityId     = $DecisionResult.CapabilityId
        decision         = $DecisionResult.Decision
        reason           = $DecisionResult.Reason
        riskLevel        = if ($DecisionResult.CapabilityInfo) { $DecisionResult.CapabilityInfo.trustLevel } else { "unknown" }
        requiredControls = $DecisionResult.RequiredControls
        gateChecks       = $DecisionResult.GateChecks
        capabilityName   = if ($DecisionResult.CapabilityInfo) { $DecisionResult.CapabilityInfo.name } else { "" }
        capabilityType   = if ($DecisionResult.CapabilityInfo) { $DecisionResult.CapabilityInfo.type } else { "" }
    }
    
    $jsonLine = $record | ConvertTo-Json -Compress -Depth 3
    Add-Content -Path $script:DecisionIndexPath -Value $jsonLine -Encoding UTF8
    
    return $record
}

function Get-CapabilityDecisions {
    param(
        [string]$ProjectId,
        [string]$AgentId,
        [string]$CapabilityId,
        [string]$Decision,
        [int]$MaxResults = 100
    )
    if (-not (Test-Path $script:DecisionIndexPath)) { return @() }
    
    $lines = Get-Content $script:DecisionIndexPath -Encoding UTF8 | Where-Object { $_.Trim() -ne "" }
    $results = @()
    foreach ($line in $lines) {
        try {
            $obj = $line | ConvertFrom-Json
            if ($ProjectId -and $obj.projectId -ne $ProjectId) { continue }
            if ($AgentId -and $obj.agentId -ne $AgentId) { continue }
            if ($CapabilityId -and $obj.capabilityId -ne $CapabilityId) { continue }
            if ($Decision -and $obj.decision -ne $Decision) { continue }
            $results += $obj
            if ($results.Count -ge $MaxResults) { break }
        } catch { }
    }
    return $results
}

Write-Verbose "Capability Decision Logger loaded."
