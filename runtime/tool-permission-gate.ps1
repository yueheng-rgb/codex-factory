# Tool Permission Gate v2 — with Network Boundary
# Part of: FACTORY-R2.3-L-NETWORK-BOUNDARY-AND-SANDBOX-LIFECYCLE
# Replaces networkAccess boolean with multi-level networkBoundary

. (Join-Path $PSScriptRoot "tool-registry-loader.ps1")

$script:NetworkLevels = @{
    "no_network"=0; "loopback_only"=1; "local_lan"=2
    "external_readonly"=3; "external_api"=4; "external_write"=5; "cloud_service"=6
}
$script:LocalFirstMaxLevel = 2

function Test-ToolPermission {
    param(
        [Parameter(Mandatory=$true)][string]$ProjectId,
        [string]$PhaseId="",
        [Parameter(Mandatory=$true)][string]$AgentId,
        [string]$ProjectType="fullstack-admin",
        [Parameter(Mandatory=$true)][string]$ToolId,
        [string]$RequestedAction="execute",
        [bool]$SandboxAvailable=$false,
        [bool]$HumanApproved=$false,
        [bool]$SecretsAllowed=$false,
        [bool]$FileWriteAllowed=$false,
        [bool]$CloudAllowed=$false,
        [string]$NetworkMode="local_first",
        [string[]]$RequestedHosts=@(),
        [bool]$IsLocalFirst=$true
    )

    $result = [PSCustomObject]@{Allowed=$false;Decision="REJECT";Reason="";ToolId=$ToolId;AgentId=$AgentId;ProjectId=$ProjectId;SandboxMode="none";NetworkBoundary="unknown";GateChecks=@();ToolInfo=$null}

    # CHECK 1: Tool exists
    $tool = Get-ToolById -ToolId $ToolId
    if (-not $tool) { $result.Reason="REJECT: Tool not found"; $result.GateChecks+="TOOL_EXISTS: FAIL"; return $result }
    $result.GateChecks+="TOOL_EXISTS: PASS"; $result.ToolInfo=$tool

    # Determine network boundary
    $nb = if ($tool.networkBoundary) { $tool.networkBoundary } else { if ($tool.networkAccess) { "external_api" } else { "no_network" } }
    $nbLevel = $script:NetworkLevels[$nb]
    $result.NetworkBoundary = $nb

    # CHECK 2: Tool status
    switch ($tool.status) {
        "quarantine" { $result.Reason="REJECT: QUARANTINED"; $result.GateChecks+="TOOL_STATUS: FAIL"; return $result }
        "rejected"   { $result.Reason="REJECT: REJECTED"; $result.GateChecks+="TOOL_STATUS: FAIL"; return $result }
        "deprecated" { $result.Reason="REJECT: DEPRECATED"; $result.GateChecks+="TOOL_STATUS: FAIL"; return $result }
    }
    $result.GateChecks+="TOOL_STATUS: PASS"

    # CHECK 3: Agent authorization
    if ($tool.allowedAgents -is [array] -and $tool.allowedAgents.Count -gt 0 -and $AgentId -notin $tool.allowedAgents) {
        $result.Reason="REJECT: Agent not authorized"; $result.GateChecks+="AGENT_AUTH: FAIL"; return $result
    }
    $result.GateChecks+="AGENT_AUTH: PASS"

    # CHECK 4: Project type
    if ($tool.allowedProjectTypes -is [array] -and "all" -notin $tool.allowedProjectTypes -and $ProjectType -notin $tool.allowedProjectTypes) {
        $result.Reason="REJECT: Project type mismatch"; $result.GateChecks+="PROJECT_TYPE: FAIL"; return $result
    }
    $result.GateChecks+="PROJECT_TYPE: PASS"

    # CHECK 5: Phase
    if ($PhaseId -and $tool.allowedPhases -is [array] -and $tool.allowedPhases.Count -gt 0 -and $PhaseId -notin $tool.allowedPhases) {
        $result.Reason="REJECT: Phase not allowed"; $result.GateChecks+="PHASE_MATCH: FAIL"; return $result
    }
    $result.GateChecks+="PHASE_MATCH: PASS"

    # CHECK 6: Network Boundary (replaces old networkAccess check)
    if ($nbLevel -gt 2 -and $IsLocalFirst) {
        if ($nbLevel -eq 3) {
            $result.Decision="PENDING_HUMAN"; $result.Reason="PENDING_HUMAN: external_readonly requires approval in local-first"; $result.GateChecks+="NETWORK: PENDING_HUMAN (external_readonly)"; return $result
        }
        if ($nbLevel -ge 4) {
            $result.Reason="REJECT: external_api/write/cloud not allowed in local-first mode (boundary=$nb)"; $result.GateChecks+="NETWORK: FAIL (boundary=$nb)"; return $result
        }
    }
    $result.GateChecks+="NETWORK: PASS (boundary=$nb, level=$nbLevel)"

    # CHECK 7: Host allowlist (if tool has allowedHosts and requests specific hosts)
    if ($RequestedHosts.Count -gt 0 -and $tool.allowedHosts -is [array] -and $tool.allowedHosts.Count -gt 0) {
        $violations = $RequestedHosts | Where-Object { $_ -notin $tool.allowedHosts -and $_ -notmatch "^127\.|^localhost|^::1" }
        if ($violations.Count -gt 0) {
            $result.Reason="REJECT: boundary_violation — hosts not in allowlist: $($violations -join ',')"; $result.GateChecks+="HOST_ALLOW: FAIL"; return $result
        }
    }
    $result.GateChecks+="HOST_ALLOW: PASS"

    # CHECK 8: Sandbox
    if ($tool.sandboxRequired -and -not $SandboxAvailable) {
        $result.Decision="PENDING_SANDBOX"; $result.Reason="PENDING_SANDBOX: sandbox required"; $result.SandboxMode="pending"; $result.GateChecks+="SANDBOX: FAIL"; return $result
    }
    $result.GateChecks+="SANDBOX: PASS"

    # CHECK 9: Human
    if ($tool.humanConfirmationRequired -and -not $HumanApproved) {
        $result.Decision="PENDING_HUMAN"; $result.Reason="PENDING_HUMAN: human approval required"; $result.GateChecks+="HUMAN: FAIL"; return $result
    }
    $result.GateChecks+="HUMAN: PASS"

    # CHECK 10: Secrets
    if ($tool.requiredSecrets -and -not $SecretsAllowed) {
        $result.Reason="REJECT: Secrets required but not allowed"; $result.GateChecks+="SECRETS: FAIL"; return $result
    }
    $result.GateChecks+="SECRETS: PASS"

    # CHECK 11: File write
    if ($tool.fileWriteAccess -and -not $FileWriteAllowed) {
        $result.Reason="REJECT: File write required but not allowed"; $result.GateChecks+="FILE_WRITE: FAIL"; return $result
    }
    $result.GateChecks+="FILE_WRITE: PASS"

    # CHECK 12: Cloud
    if ($tool.cloudRequired -and -not $CloudAllowed) {
        $result.Reason="REJECT: Cloud required but not allowed"; $result.GateChecks+="CLOUD: FAIL"; return $result
    }
    $result.GateChecks+="CLOUD: PASS"

    # Passed all checks
    if ($tool.dryRunSupported -and $SandboxAvailable) { $result.SandboxMode="dryRun" }
    elseif ($tool.sandboxRequired -and $SandboxAvailable) { $result.SandboxMode="disposable" }
    $result.Decision = if ($tool.status -eq "sandboxReady") { "ALLOW_WITH_SANDBOX" } else { "ALLOW_WITH_CONTROLS" }
    $result.Allowed = $true
    $result.Reason = "ALLOW: Tool permitted (boundary=$nb)"
    return $result
}
Write-Verbose "Tool Permission Gate v2 initialized."
