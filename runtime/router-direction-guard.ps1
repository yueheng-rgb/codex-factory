# R2.3-O Step 0 — Router / Planner Direction Guard
# Prevents superseded/deprecated directions from being selected as next phase.

$script:DirectionLedgerPath = Join-Path (Split-Path $PSScriptRoot -Parent) "governance\direction-decisions\direction-decision-index.jsonl"

function Get-DirectionDecisions {
    param([string]$Status)
    if (-not (Test-Path $script:DirectionLedgerPath)) {
        Write-Warning "Direction ledger not found"
        return @()
    }
    $lines = Get-Content $script:DirectionLedgerPath -Encoding UTF8 | Where-Object { $_.Trim() -ne '' }
    $decisions = $lines | ForEach-Object { try { $_ | ConvertFrom-Json } catch { $null } } | Where-Object { $_ }
    if ($Status) { $decisions = $decisions | Where-Object { $_.status -eq $Status } }
    return $decisions | Sort-Object directionId
}

function Get-ActiveDirection {
    $active = Get-DirectionDecisions -Status "active"
    if ($active.Count -eq 0) { return $null }
    return $active[0]
}

function Test-DirectionAllowed {
    param([Parameter(Mandatory=$true)][string]$DirectionId)
    $decisions = Get-DirectionDecisions
    $dir = $decisions | Where-Object { $_.directionId -eq $DirectionId }
    if (-not $dir) {
        return [PSCustomObject]@{
            allowed = $false; decision = "UNKNOWN_DIRECTION"
            reason = "Direction {0} not found in registry" -f $DirectionId
            recommendedDirection = "DIR-004"
        }
    }
    switch ($dir.status) {
        "active" { return [PSCustomObject]@{ allowed = $true; decision = "ALLOW"; reason = "Direction is active" } }
        "superseded" {
            return [PSCustomObject]@{ allowed = $false; decision = "REJECT_SUPERSEDED"
                reason = "Direction {0} is superseded by {1}" -f $DirectionId, $dir.supersededBy
                recommendedDirection = $dir.supersededBy }
        }
        "deprecated" {
            return [PSCustomObject]@{ allowed = $false; decision = "REJECT_DEPRECATED"
                reason = "Direction {0} is deprecated: {1}" -f $DirectionId, $dir.reason
                recommendedDirection = if ($dir.supersededBy) { $dir.supersededBy } else { "DIR-004" } }
        }
        "deferred" {
            return [PSCustomObject]@{ allowed = $false; decision = "REJECT_DEFERRED"
                reason = "Direction {0} is deferred: prerequisites not met ({1} total)" -f $DirectionId, $dir.prerequisites.Count
                missingPrerequisites = $dir.prerequisites
                recommendedDirection = "DIR-004" }
        }
        "completed" { return [PSCustomObject]@{ allowed = $false; decision = "REJECT_COMPLETED"; reason = "Already completed" } }
        default { return [PSCustomObject]@{ allowed = $false; decision = "UNKNOWN_STATUS"; reason = "Unknown status" } }
    }
}

function Invoke-BetterMethodCheck {
    param([Parameter(Mandatory=$true)][string]$ProposedDirection, [string]$EvidenceRef = "")
    $checks = @(); $pass = $true
    $activeDir = Get-ActiveDirection
    if ($activeDir -and $activeDir.directionId -ne $ProposedDirection) {
        $checks += "BETTER_METHOD: Active direction {0} supersedes {1}" -f $activeDir.directionId, $ProposedDirection
        $pass = $false
    }
    if (-not $EvidenceRef) { $checks += "NO_EVIDENCE"; $pass = $false }
    $dirCheck = Test-DirectionAllowed -DirectionId $ProposedDirection
    if (-not $dirCheck.allowed) { $checks += "DIRECTION_BLOCKED: {0}" -f $dirCheck.reason; $pass = $false }
    if ($ProposedDirection -match "live.api|real.api|production" -and $EvidenceRef -notmatch "key|approval|secret") {
        $checks += "HIDDEN_RISK: External API without key/approval"; $pass = $false
    }
    return [PSCustomObject]@{ pass = $pass; checks = $checks; recommendation = if ($pass) { "Proceed" } else { "Use DIR-004" } }
}


function Test-SearchAgentAllowed {
    # DEPRECATED: Independent Search Agent is not allowed
    # Single WebSearch Tool is the only external search capability
    return [PSCustomObject]@{
        allowed = $false
        decision = "REJECT_SEARCH_AGENT_DEPRECATED"
        reason = "Independent Search Agent is deprecated per DIR-007/DIR-008. Use Single WebSearch Tool pipeline (DIR-010)."
        recommendedDirection = "DIR-010"
    }
}

function Test-DualSearchChannel {
    # DEPRECATED: Two parallel search truth sources not allowed
    return [PSCustomObject]@{
        allowed = $false
        decision = "REJECT_DUAL_CHANNEL_DEPRECATED"
        reason = "Dual search channel is deprecated per DIR-008. Single WebSearch Tool pipeline only."
        recommendedDirection = "DIR-010"
    }
}

function Get-SearchArchitectureConstraints {
    # Returns the hard constraints for search architecture
    return [PSCustomObject]@{
        singleWebSearchTool = $true
        independentSearchAgent = $false
        dualSearchChannel = $false
        searchAgentDirectNetwork = $false
        searchAgentDirectToImplementer = $false
        implementerDirectSearch = $false
        evidencePackSoleCarrier = $true
        activeDirections = @("DIR-004","DIR-010","DIR-011")
        deprecatedDirections = @("DIR-007","DIR-008","DIR-009")
    }
}

Write-Verbose "Direction Guard loaded. Active: $(if(Get-ActiveDirection){(Get-ActiveDirection).directionId}else{'none'})"
