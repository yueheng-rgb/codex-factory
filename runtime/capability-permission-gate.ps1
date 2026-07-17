# Capability Permission Gate
# Part of: FACTORY-R2.3-C-CAPABILITY-REGISTRY-RUNTIME
# Enforces permission checks for capability usage by agents.
# Usage: . .\runtime\capability-permission-gate.ps1; Test-CapabilityPermission -AgentId "IMPL-FE-001" -CapabilityId "CAP-SKILL-001" -ProjectId "PROJ-001"

. "$PSScriptRoot\agent-loader.ps1"
. "$PSScriptRoot\capability-loader.ps1"

function Test-CapabilityPermission {
    param(
        [Parameter(Mandatory=$true)][string]$ProjectId,
        [string]$PhaseId = "",
        [Parameter(Mandatory=$true)][string]$AgentId,
        [string]$ProjectType = "fullstack-admin",
        [Parameter(Mandatory=$true)][string]$CapabilityId,
        [string]$RequestedAction = "import",
        [bool]$HasAuth = $false,
        [bool]$HasWriteScope = $false,
        [bool]$HasSandbox = $false,
        [bool]$HasHumanConfirmation = $false,
        [bool]$IsLocalFirst = $true
    )

    $result = [PSCustomObject]@{
        Allowed          = $false
        Decision         = "REJECT"
        Reason           = ""
        CapabilityId     = $CapabilityId
        AgentId          = $AgentId
        ProjectId        = $ProjectId
        ProjectType      = $ProjectType
        RequestedAction  = $RequestedAction
        RequiredControls = @()
        GateChecks       = @()
        CapabilityInfo   = $null
    }

    # CHECK 1: Capability exists
    $cap = Get-CapabilityById -CapabilityId $CapabilityId
    if (-not $cap) {
        $result.Reason = "REJECT: Capability '$CapabilityId' not found in registry"
        $result.GateChecks += "CAP_EXISTS: FAIL"
        return $result
    }
    $result.GateChecks += "CAP_EXISTS: PASS"
    $result.CapabilityInfo = [PSCustomObject]@{
        name = $cap.name; type = $cap.type; trustLevel = $cap.trustLevel
        recommendedAction = $cap.recommendedAction; priority = $cap.priority
    }

    # CHECK 2: Agent exists
    $agent = Get-AgentDefinition -AgentId $AgentId -ErrorAction SilentlyContinue
    if (-not $agent) {
        $result.Reason = "REJECT: Agent '$AgentId' is not registered"
        $result.GateChecks += "AGENT_EXISTS: FAIL"
        return $result
    }
    $result.GateChecks += "AGENT_EXISTS: PASS"

    # CHECK 3: Capability status — quarantine / reject / deprecated (MUST come before secrets)
    if ($cap.recommendedAction -eq "quarantine") {
        $result.Reason = "REJECT: Capability '$CapabilityId' is in QUARANTINE"
        $result.GateChecks += "CAP_STATUS: FAIL (quarantine)"
        return $result
    }
    if ($cap.recommendedAction -eq "reject") {
        $result.Reason = "REJECT: Capability '$CapabilityId' has been REJECTED"
        $result.GateChecks += "CAP_STATUS: FAIL (reject)"
        return $result
    }
    if ($cap.recommendedAction -eq "deprecated") {
        $result.Reason = "REJECT: Capability '$CapabilityId' is DEPRECATED"
        $result.GateChecks += "CAP_STATUS: FAIL (deprecated)"
        return $result
    }

    # CHECK 4: Action-based gating — monitor → MONITOR_ONLY (BEFORE secrets/agent checks)
    if ($cap.recommendedAction -eq "monitor") {
        $result.Decision = "MONITOR_ONLY"
        $result.Allowed = $false
        $result.Reason = "MONITOR_ONLY: Capability '$CapabilityId' recommended action is 'monitor' — observe only, do not invoke"
        $result.GateChecks += "ACTION_MONITOR: MONITOR_ONLY"
        return $result
    }

    $result.GateChecks += "CAP_STATUS: PASS ($($cap.recommendedAction))"

    # CHECK 5: Agent eligibility — is agent in applicableAgents?
    if ($cap.applicableAgents -is [array] -and $cap.applicableAgents.Count -gt 0) {
        if ($cap.applicableAgents -notcontains $AgentId) {
            $result.Reason = "REJECT: Agent '$AgentId' not in applicableAgents for '$CapabilityId'. Applicable: $($cap.applicableAgents -join ', ')"
            $result.GateChecks += "AGENT_ELIGIBILITY: FAIL"
            return $result
        }
    }
    $result.GateChecks += "AGENT_ELIGIBILITY: PASS"

    # CHECK 6: Project type applicability
    $apt = $cap.applicableProjectTypes
    if ($apt -is [array]) {
        if ($apt -notcontains "all" -and $apt -notcontains $ProjectType) {
            $result.Reason = "REJECT: ProjectType '$ProjectType' not in applicableProjectTypes for '$CapabilityId'. Applicable: $($apt -join ', ')"
            $result.GateChecks += "PROJECT_TYPE: FAIL"
            return $result
        }
    } elseif ($apt -is [string] -and $apt -ne "all" -and $apt -ne $ProjectType) {
        $result.Reason = "REJECT: ProjectType '$ProjectType' mismatch for '$CapabilityId'"
        $result.GateChecks += "PROJECT_TYPE: FAIL"
        return $result
    }
    $result.GateChecks += "PROJECT_TYPE: PASS"

    # CHECK 7: requiredSecrets
    $reqSecrets = $cap.requiredSecrets
    if ($reqSecrets -is [array] -and $reqSecrets.Count -gt 0) {
        if (-not $HasAuth) {
            $result.Reason = "REJECT: Capability '$CapabilityId' requires secrets ($($reqSecrets -join ', ')) but no auth configured"
            $result.GateChecks += "SECRETS: FAIL"
            return $result
        }
        $result.RequiredControls += "secrets_configured"
    }
    $result.GateChecks += "SECRETS: PASS"

    # CHECK 8: fileWriteAccess
    if ($cap.fileWriteAccess -eq $true -or $cap.fileWriteAccess -eq "true") {
        if (-not $HasWriteScope) {
            $result.Reason = "REJECT: Capability '$CapabilityId' requires file write access but agent lacks write scope"
            $result.GateChecks += "FILE_WRITE: FAIL"
            return $result
        }
        $result.RequiredControls += "write_scope_confirmed"
    }
    $result.GateChecks += "FILE_WRITE: PASS"

    # CHECK 9: networkAccess
    if ($cap.networkAccess -eq $true -or $cap.networkAccess -eq "true") {
        $result.RequiredControls += "network_access"
        $result.GateChecks += "NETWORK: WARN"
    } else {
        $result.GateChecks += "NETWORK: PASS"
    }

    # CHECK 10: cloudRequired — reject if local-first
    if ($cap.cloudRequired -eq $true -or $cap.cloudRequired -eq "true") {
        if ($IsLocalFirst) {
            $result.Reason = "REJECT: Capability '$CapabilityId' requires cloud but project is local-first"
            $result.GateChecks += "CLOUD: FAIL (local-first)"
            return $result
        }
        $result.RequiredControls += "cloud_configured"
    }
    $result.GateChecks += "CLOUD: PASS"

    # CHECK 11: requiresHumanConfirmation (derived from trustLevel)
    if ($cap.trustLevel -eq "AVAILABLE" -or $cap.trustLevel -eq "CAUTION") {
        if (-not $HasHumanConfirmation) {
            $result.Decision = "PENDING_HUMAN"
            $result.Allowed = $false
            $result.Reason = "PENDING_HUMAN: Capability '$CapabilityId' trust level '$($cap.trustLevel)' requires human confirmation"
            $result.GateChecks += "HUMAN_CONFIRM: PENDING"
            $result.RequiredControls += "human_confirmation"
            return $result
        }
        $result.GateChecks += "HUMAN_CONFIRM: PASS"
    }

    # CHECK 12: requiresSandbox (derived from securityRisk)
    if ($cap.securityRisk -eq "high" -or $cap.securityRisk -eq "critical") {
        if (-not $HasSandbox) {
            $result.Decision = "PENDING_SANDBOX"
            $result.Allowed = $false
            $result.Reason = "PENDING_SANDBOX: Capability '$CapabilityId' has security risk '$($cap.securityRisk)', sandbox required"
            $result.GateChecks += "SANDBOX: PENDING"
            $result.RequiredControls += "sandbox_environment"
            return $result
        }
        $result.GateChecks += "SANDBOX: PASS"
    }

    # CHECK 13: local runner needed
    if (($cap.localRunnerRequired -eq $true -or $cap.localRunnerRequired -eq "true") -and $cap.type -eq "runner") {
        $result.RequiredControls += "local_runner_available"
        $result.GateChecks += "LOCAL_RUNNER: WARN"
    } else {
        $result.GateChecks += "LOCAL_RUNNER: PASS"
    }

    # All checks passed
    $result.Allowed = $true
    $result.Decision = if ($result.RequiredControls.Count -gt 0) { "ALLOW_WITH_CONTROLS" } else { "ALLOW" }
    $result.Reason = "ALLOW: Capability '$CapabilityId' is permitted for agent '$AgentId' in project '$ProjectId'"
    if ($result.RequiredControls.Count -gt 0) {
        $result.Reason += ". Controls: $($result.RequiredControls -join ', ')"
    }
    $result.GateChecks += "FINAL: $($result.Decision)"

    return $result
}

function Assert-CapabilityPermission {
    param(
        [string]$AgentId,
        [string]$CapabilityId,
        [string]$ProjectId = "PROJ-SIM-001",
        [string]$ProjectType = "fullstack-admin",
        [string]$PhaseId = "PHASE-IMPL-001",
        [string]$RequestedAction = "import",
        [hashtable]$Overrides = @{},
        [string]$ExpectDecision = "ALLOW"
    )
    $params = @{
        ProjectId = $ProjectId; PhaseId = $PhaseId; AgentId = $AgentId
        ProjectType = $ProjectType; CapabilityId = $CapabilityId
        RequestedAction = $RequestedAction
        HasAuth = $false; HasWriteScope = $false; HasSandbox = $false
        HasHumanConfirmation = $false; IsLocalFirst = $true
    }
    foreach ($key in $Overrides.Keys) { $params[$key] = $Overrides[$key] }
    
    $r = Test-CapabilityPermission @params
    $passed = ($r.Decision -eq $ExpectDecision)
    
    return [PSCustomObject]@{
        TestCase       = "Agent=$AgentId Cap=$CapabilityId"
        ExpectDecision = $ExpectDecision
        ActualDecision = $r.Decision
        Passed         = $passed
        Reason         = $r.Reason
    }
}

Write-Verbose "Capability Permission Gate loaded."
