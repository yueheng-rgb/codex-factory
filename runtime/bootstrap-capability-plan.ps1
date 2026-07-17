# Bootstrap Capability Plan Generator
# Part of: FACTORY-R2.3-D-CAPABILITY-GOVERNANCE-INTEGRATION
# Integrates with Factory Bootstrap to generate capability plans per project/phase.
# Usage: . .\runtime\bootstrap-capability-plan.ps1; New-CapabilityPlan -ProjectId "PROJ-001" -PhaseId "PHASE-DESIGN" -ProjectType "fullstack-admin" -ActiveAgents @("PM-001","ARCH-001")

param(
    [string]$FactoryRoot = "C:\Codex_App_Factory"
)

. (Join-Path $FactoryRoot "runtime\capability-loader.ps1")
. (Join-Path $FactoryRoot "runtime\capability-permission-gate.ps1")
. (Join-Path $FactoryRoot "runtime\capability-decision-logger.ps1")

<#
.SYNOPSIS
Generates a capability plan for a project phase. Evaluates every applicable capability
through the permission gate and partitions into allow/monitor/block/pending buckets.
#>
function New-CapabilityPlan {
    param(
        [Parameter(Mandatory=$true)][string]$ProjectId,
        [Parameter(Mandatory=$true)][string]$PhaseId,
        [Parameter(Mandatory=$true)][string]$ProjectType,
        [string[]]$ActiveAgents = @("PM-001", "ARCH-001", "IMPL-FE-001", "IMPL-BE-001", "IMPL-DB-001", "VER-001", "SEC-001", "INTG-001", "AUD-001", "RSRC-001", "LIB-001"),
        [string]$RequestedMode = "full",
        [bool]$LocalFirst = $true,
        [bool]$NetworkAllowed = $true,
        [bool]$CloudAllowed = $false,
        [bool]$SecretsAllowed = $false,
        [bool]$SandboxAvailable = $false,
        [bool]$HumanApprovalAvailable = $false,
        [string]$OutputDir = ""
    )

    if (-not $OutputDir) {
        $OutputDir = Join-Path $FactoryRoot "governance\capability-plans"
    }
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }

    Initialize-CapabilityCache

    # Collect all capabilities applicable to this project type
    $projectCaps = Get-CapabilitiesByProjectType -ProjectType $ProjectType

    # Partition by permission gate for each agent
    $allAllowed   = @{}
    $allMonitor   = @{}
    $allBlocked   = @{}
    $allPendingH  = @{}
    $allPendingS  = @{}
    $allRejected  = @{}
    $seenCaps     = @{}

    foreach ($agentId in $ActiveAgents) {
        $agentCaps = $projectCaps | Where-Object {
            $_.applicableAgents -is [array] -and ($_.applicableAgents -contains $agentId)
        }

        foreach ($cap in $agentCaps) {
            $cid = $cap.capabilityId
            if ($seenCaps.ContainsKey("$agentId|$cid")) { continue }
            $seenCaps["$agentId|$cid"] = $true

            $permResult = Test-CapabilityPermission `
                -ProjectId $ProjectId -PhaseId $PhaseId -AgentId $agentId `
                -ProjectType $ProjectType -CapabilityId $cid `
                -HasAuth $SecretsAllowed -HasWriteScope $true `
                -HasSandbox $SandboxAvailable `
                -HasHumanConfirmation $HumanApprovalAvailable `
                -IsLocalFirst $LocalFirst

            # Log decision
            Write-CapabilityDecision -DecisionResult $permResult -ProjectId $ProjectId -PhaseId $PhaseId -AgentId $agentId | Out-Null

            $summary = [PSCustomObject]@{
                capabilityId      = $cid
                name              = $cap.name
                type              = $cap.type
                trustLevel        = $cap.trustLevel
                recommendedAction = $cap.recommendedAction
                priority          = $cap.priority
                securityRisk      = $cap.securityRisk
                reason            = $permResult.Reason
                agentId           = $agentId
            }

            switch ($permResult.Decision) {
                "ALLOW"               { if (-not $allAllowed.ContainsKey($cid))   { $allAllowed[$cid] = $summary } }
                "ALLOW_WITH_CONTROLS" { if (-not $allAllowed.ContainsKey($cid))   { $allAllowed[$cid] = $summary } }
                "MONITOR_ONLY"        { if (-not $allMonitor.ContainsKey($cid))   { $allMonitor[$cid] = $summary } }
                "PENDING_HUMAN"       { if (-not $allPendingH.ContainsKey($cid))  { $allPendingH[$cid] = $summary } }
                "PENDING_SANDBOX"     { if (-not $allPendingS.ContainsKey($cid))  { $allPendingS[$cid] = $summary } }
                "REJECT"              { if (-not $allRejected.ContainsKey($cid))   { $allRejected[$cid] = $summary } }
                default               { if (-not $allBlocked.ContainsKey($cid))    { $allBlocked[$cid] = $summary } }
            }
        }
    }

    # Identify capabilities NOT evaluated for any active agent
    $evaluatedIds = @{}
    foreach ($k in $seenCaps.Keys) {
        $parts = $k -split '\|', 2
        if ($parts.Count -eq 2) { $evaluatedIds[$parts[1]] = $true }
    }
    $unevaluated = $projectCaps | Where-Object { -not $evaluatedIds.ContainsKey($_.capabilityId) } | ForEach-Object {
        [PSCustomObject]@{ capabilityId=$_.capabilityId; name=$_.name; type=$_.type; reason="No active agent in applicableAgents" }
    }

    # Build risk summary
    $riskCounts = @{ none=0; low=0; medium=0; high=0; critical=0; unknown=0 }
    foreach ($cap in $projectCaps) {
        $r = $cap.securityRisk
        if ($riskCounts.ContainsKey($r)) { $riskCounts[$r]++ } else { $riskCounts["unknown"]++ }
    }

    $plan = [PSCustomObject]@{
        planId                    = "CAP-PLAN-$ProjectId-$PhaseId"
        projectId                 = $ProjectId
        phaseId                   = $PhaseId
        projectType               = $ProjectType
        requestedMode             = $RequestedMode
        generatedAt               = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
        constraints = [PSCustomObject]@{
            localFirst              = $LocalFirst
            networkAllowed          = $NetworkAllowed
            cloudAllowed            = $CloudAllowed
            secretsAllowed          = $SecretsAllowed
            sandboxAvailable        = $SandboxAvailable
            humanApprovalAvailable  = $HumanApprovalAvailable
        }
        activeAgents              = $ActiveAgents
        summary = [PSCustomObject]@{
            totalCapabilitiesInScope   = $projectCaps.Count
            allowedCount               = $allAllowed.Count
            monitorOnlyCount           = $allMonitor.Count
            blockedCount               = $allBlocked.Count
            pendingHumanCount          = $allPendingH.Count
            pendingSandboxCount        = $allPendingS.Count
            rejectedCount              = $allRejected.Count
            unevaluatedCount           = ($unevaluated | Measure-Object).Count
        }
        allowedCapabilities        = @($allAllowed.Values)
        monitorOnlyCapabilities    = @($allMonitor.Values)
        blockedCapabilities        = @($allBlocked.Values)
        pendingHumanCapabilities   = @($allPendingH.Values)
        pendingSandboxCapabilities = @($allPendingS.Values)
        rejectedCapabilities       = @($allRejected.Values)
        unevaluatedCapabilities    = @($unevaluated)
        capabilityRiskSummary = [PSCustomObject]@{
            totalInScope = $projectCaps.Count
            riskDistribution = $riskCounts
        }
        recommendedNextAction      = if ($allPendingH.Count -gt 0) { "resolve_pending_human_approvals" }
                                     elseif ($allPendingS.Count -gt 0) { "enable_sandbox_or_reject" }
                                     elseif ($allRejected.Count -gt ($projectCaps.Count * 0.3)) { "review_rejected_ratio" }
                                     else { "proceed_with_allowed_capabilities" }
    }

    # Save to file
    $planPath = Join-Path $OutputDir "$ProjectId-$PhaseId-capability-plan.json"
    $plan | ConvertTo-Json -Depth 5 | Out-File -FilePath $planPath -Encoding UTF8
    Write-Host "CAP_PLAN: Saved to $planPath" -ForegroundColor Green
    Write-Host "  Allowed: $($allAllowed.Count) | Monitor: $($allMonitor.Count) | Blocked: $($allBlocked.Count)" -ForegroundColor White
    Write-Host "  Pending Human: $($allPendingH.Count) | Pending Sandbox: $($allPendingS.Count) | Rejected: $($allRejected.Count)" -ForegroundColor White
    Write-Host "  Recommended: $($plan.recommendedNextAction)" -ForegroundColor Cyan

    return $plan
}

<#
.SYNOPSIS
Generates capability plans for multiple common project type + phase combinations for testing.
#>
function New-SampleCapabilityPlans {
    $scenarios = @(
        @{ ProjectId="PROJ-DEMO-001"; PhaseId="PHASE-DESIGN"; ProjectType="fullstack-admin"; ActiveAgents=@("PM-001","ARCH-001") },
        @{ ProjectId="PROJ-DEMO-001"; PhaseId="PHASE-IMPL-FE"; ProjectType="fullstack-admin"; ActiveAgents=@("IMPL-FE-001") },
        @{ ProjectId="PROJ-DEMO-001"; PhaseId="PHASE-VERIFY"; ProjectType="fullstack-admin"; ActiveAgents=@("VER-001","SEC-001") },
        @{ ProjectId="PROJ-DEMO-002"; PhaseId="PHASE-DESIGN"; ProjectType="miniapp"; ActiveAgents=@("PM-001","ARCH-001") },
        @{ ProjectId="PROJ-DEMO-003"; PhaseId="PHASE-DESIGN"; ProjectType="saas-tool"; ActiveAgents=@("PM-001","ARCH-001","SEC-001") }
    )

    $results = @()
    foreach ($s in $scenarios) {
        Write-Host "`n=== $($s.ProjectId) / $($s.PhaseId) / $($s.ProjectType) ===" -ForegroundColor Yellow
        $plan = New-CapabilityPlan @s -LocalFirst $true -NetworkAllowed $true -CloudAllowed $false `
            -SecretsAllowed $false -SandboxAvailable $false -HumanApprovalAvailable $false
        $results += $plan
    }
    return $results
}

Write-Verbose "Bootstrap Capability Plan Generator loaded."
