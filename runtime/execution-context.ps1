# Agent Execution Context Generator with Capability Injection
# Part of: FACTORY-R2.3-C-CAPABILITY-REGISTRY-RUNTIME
# Extends R2.2 execution-context.ps1 to inject capability information.
# Usage: . .\runtime\execution-context.ps1; $ctx = New-AgentExecutionContext -AgentId "PM-001" -ProjectId "PROJ-099"

. "$PSScriptRoot\agent-loader.ps1"
. "$PSScriptRoot\permission-gate.ps1"
. "$PSScriptRoot\capability-loader.ps1"
. "$PSScriptRoot\capability-permission-gate.ps1"

function New-AgentExecutionContext {
    param(
        [Parameter(Mandatory=$true)][string]$AgentId,
        [Parameter(Mandatory=$true)][string]$ProjectId,
        [string]$PhaseId = "PHASE-001",
        [string]$TaskId = "",
        [string]$ProjectType = "fullstack-admin",
        [bool]$IsLocalFirst = $true
    )

    $agent = Get-AgentDefinition -AgentId $AgentId -ErrorAction Stop
    if (-not $agent) {
        Write-Error "EXEC_CTX: Cannot create context — agent '$AgentId' not found"
        return $null
    }

    $resolvedSkills = $agent.allowedSkills
    if ($AgentId -match "^IMPL-(FE|BE|DB)-001$" -and
        (Get-Member -InputObject $agent.allowedSkills -Name $AgentId -MemberType Properties)) {
        $resolvedSkills = $agent.allowedSkills.$AgentId
    }

    $agentType = if (Get-Member -InputObject $agent -Name "type" -MemberType Properties) { $agent.type } else { "on-demand" }

    # --- R2.3-C: Capability injection ---
    Initialize-CapabilityCache
    
    # Get all capabilities applicable to this agent AND project type
    $agentCaps = Get-CapabilitiesByAgent -AgentId $AgentId
    $relevantCaps = $agentCaps | Where-Object {
        $apt = $_.applicableProjectTypes
        ($apt -is [array] -and ($apt -contains "all" -or $apt -contains $ProjectType)) -or ($apt -eq "all")
    }

    # Partition capabilities by permission gate result
    $allowedCapabilities = @()
    $blockedCapabilities = @()
    $pendingHumanCapabilities = @()
    $pendingSandboxCapabilities = @()
    $monitorOnlyCapabilities = @()

    foreach ($cap in $relevantCaps) {
        $permResult = Test-CapabilityPermission `
            -ProjectId $ProjectId -PhaseId $PhaseId -AgentId $AgentId `
            -ProjectType $ProjectType -CapabilityId $cap.capabilityId `
            -IsLocalFirst $IsLocalFirst

        $capSummary = [PSCustomObject]@{
            capabilityId      = $cap.capabilityId
            name              = $cap.name
            type              = $cap.type
            trustLevel        = $cap.trustLevel
            recommendedAction = $cap.recommendedAction
            priority          = $cap.priority
            reason            = $cap.reason
        }

        switch ($permResult.Decision) {
            "ALLOW"              { $allowedCapabilities += $capSummary }
            "ALLOW_WITH_CONTROLS"{ $allowedCapabilities += $capSummary }
            "PENDING_HUMAN"      { $pendingHumanCapabilities += $capSummary }
            "PENDING_SANDBOX"    { $pendingSandboxCapabilities += $capSummary }
            "MONITOR_ONLY"       { $monitorOnlyCapabilities += $capSummary }
            default              { $blockedCapabilities += $capSummary }
        }
    }

    # Build risk summary
    $riskCounts = @{low=0; medium=0; high=0; critical=0; none=0}
    foreach ($cap in $relevantCaps) {
        $r = $cap.securityRisk
        if ($riskCounts.ContainsKey($r)) { $riskCounts[$r]++ }
    }
    $capabilityRiskSummary = [PSCustomObject]@{
        totalApplicable     = $relevantCaps.Count
        allowed             = $allowedCapabilities.Count
        blocked             = $blockedCapabilities.Count
        pendingHuman        = $pendingHumanCapabilities.Count
        pendingSandbox      = $pendingSandboxCapabilities.Count
        monitorOnly         = $monitorOnlyCapabilities.Count
        riskDistribution    = $riskCounts
    }

    # Build capability load reasons
    $capabilityLoadReason = @()
    if ($PhaseId -match "DESIGN") { $capabilityLoadReason += "design_phase_templates_and_blueprints" }
    if ($PhaseId -match "IMPL")   { $capabilityLoadReason += "implementation_phase_sdks_and_tools" }
    if ($PhaseId -match "VERIFY") { $capabilityLoadReason += "verification_phase_test_and_lint" }
    if ($AgentId -match "^(RSRC|LIB)") { $capabilityLoadReason += "research_and_knowledge_intake" }
    if ($AgentId -eq "SEC-001")   { $capabilityLoadReason += "security_audit_tools" }
    if ($AgentId -eq "AUD-001")   { $capabilityLoadReason += "drift_detection_tools" }

    # --- Build final context ---
    $context = [PSCustomObject]@{
        # Identity
        contextId        = "CTX-$ProjectId-$AgentId-$PhaseId"
        projectId        = $ProjectId
        phaseId          = $PhaseId
        agentId          = $AgentId
        taskId           = $TaskId
        role             = $agent.role
        category         = if (Get-Member -InputObject $agent -Name "category") { $agent.category } else { "unknown" }
        agentType        = $agentType
        projectType      = $ProjectType
        isLocalFirst     = $IsLocalFirst

        # Permissions
        allowedWriteScopes = $agent.allowedWriteScopes
        forbiddenActions   = $agent.forbiddenActions
        permissions        = $agent.permissions

        # Skills
        allowedSkills    = $resolvedSkills

        # Contract
        requiredInputs   = $agent.requiredInputs
        requiredOutputs  = $agent.requiredOutputs
        handoffRequired  = $agent.handoffRequired
        evidenceLevel    = $agent.evidenceLevel
        failurePolicy    = $agent.failurePolicy

        # Runtime state
        createdAt        = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
        status           = "ACTIVATED"

        # Permissions snapshot (pre-computed)
        canReadProjects  = (Test-AgentPermission -AgentId $AgentId -Action "read"  -TargetPath "projects/$ProjectId/").Allowed
        canWriteDesign   = (Test-AgentPermission -AgentId $AgentId -Action "write" -TargetPath "projects/$ProjectId/docs/architecture/" -ProjectId $ProjectId).Allowed
        canWriteCode     = (Test-AgentPermission -AgentId $AgentId -Action "write" -TargetPath "projects/$ProjectId/src/" -ProjectId $ProjectId).Allowed
        canSpawnAgents   = (Test-AgentPermission -AgentId $AgentId -Action "spawn").Allowed

        # R2.3-C: Capability injection
        allowedCapabilities          = $allowedCapabilities
        blockedCapabilities          = $blockedCapabilities
        pendingHumanApprovalCapabilities = $pendingHumanCapabilities
        pendingSandboxCapabilities   = $pendingSandboxCapabilities
        monitorOnlyCapabilities      = $monitorOnlyCapabilities
        capabilityRiskSummary        = $capabilityRiskSummary
        capabilityLoadReason         = $capabilityLoadReason
    }

    return $context
}

function New-AllAgentExecutionContexts {
    param(
        [Parameter(Mandatory=$true)][string]$ProjectId,
        [string]$PhaseId = "PHASE-001",
        [string]$OutputDir = "",
        [string]$ProjectType = "fullstack-admin",
        [bool]$IsLocalFirst = $true
    )
    if (-not $OutputDir) { $OutputDir = Join-Path $PSScriptRoot "contexts" }
    if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

    $contexts = @{}
    $knownIds = @("PM-001", "ARCH-001", "IMPL-FE-001", "IMPL-BE-001", "IMPL-DB-001",
                  "VER-001", "SEC-001", "INTG-001", "AUD-001", "RSRC-001", "LIB-001")
    foreach ($agentId in $knownIds) {
        try {
            $ctx = New-AgentExecutionContext -AgentId $agentId -ProjectId $ProjectId `
                -PhaseId $PhaseId -ProjectType $ProjectType -IsLocalFirst $IsLocalFirst
            if ($ctx) {
                $contexts[$agentId] = $ctx
                $outFile = Join-Path $OutputDir "$agentId-$ProjectId-context.json"
                $ctx | ConvertTo-Json -Depth 5 | Out-File -FilePath $outFile -Encoding UTF8
            }
        } catch {
            Write-Warning "EXEC_CTX: Failed to create context for $agentId : $_"
        }
    }
    return $contexts
}

Write-Verbose "Execution Context Generator (R2.3-C) loaded."
