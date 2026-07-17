# Runtime Permission Gate
# Part of: FACTORY-R2.2-AGENT-RUNTIME-BINDING
# Checks whether a given agent is allowed to perform a requested action.
# Usage: . .\runtime\permission-gate.ps1; Test-AgentPermission -AgentId "PM-001" -Action "write" -TargetPath "governance/" -Skill "codex-factory"

. "$PSScriptRoot\agent-loader.ps1"

<#
.SYNOPSIS
Checks if an agent has permission to perform a requested action.
Returns a result object with Allowed (bool), Reason (string), and details.

.PARAMETER AgentId
The agent requesting permission.

.PARAMETER Action
The action: read, write, execute, spawn.

.PARAMETER TargetPath
The path the agent wants to access (relative to project root).

.PARAMETER Skill
Optional. The skill the agent wants to load.

.PARAMETER ProjectId
Optional. The project context. Required for write actions.
#>
function Test-AgentPermission {
    param(
        [Parameter(Mandatory=$true)]
        [string]$AgentId,

        [Parameter(Mandatory=$true)]
        [ValidateSet("read", "write", "execute", "spawn")]
        [string]$Action,

        [string]$TargetPath = "",

        [string]$Skill = "",

        [string]$ProjectId = ""
    )

    $result = [PSCustomObject]@{
        Allowed    = $false
        Reason     = ""
        AgentId    = $AgentId
        Action     = $Action
        TargetPath = $TargetPath
        Skill      = $Skill
        ProjectId  = $ProjectId
        GateChecks = @()
    }

    # CHECK 1: Agent exists
    $agent = Get-AgentDefinition -AgentId $AgentId -ErrorAction SilentlyContinue
    if (-not $agent) {
        $result.Reason = "PERMISSION_DENIED: Agent '$AgentId' is not a registered agent."
        $result.GateChecks += "AGENT_REGISTRATION: FAIL"
        return $result
    }
    $result.GateChecks += "AGENT_REGISTRATION: PASS"

    # CHECK 2: Forbidden action
    if (Get-Member -InputObject $agent -Name "forbiddenActions" -MemberType Properties) {
        $forbidden = $agent.forbiddenActions
        foreach ($fb in $forbidden) {
            # Simple substring match for forbidden actions
            if ($Action -eq "write" -and ($fb -match "write_implementation_code|write_code")) {
                # Only block if target path looks like implementation code
                if ($TargetPath -match "\.(tsx?|jsx?|py|java|go|rs)$" -and $TargetPath -notmatch "governance|knowledge-bank|outputs|reports") {
                    $result.Reason = "PERMISSION_DENIED: Agent '$AgentId' forbidden action matches: '$fb' for path '$TargetPath'"
                    $result.GateChecks += "FORBIDDEN_ACTION: FAIL ($fb)"
                    return $result
                }
            }
            if ($fb -match "write_project_files" -and $Action -eq "write" -and $TargetPath -match "^projects/") {
                $result.Reason = "PERMISSION_DENIED: Agent '$AgentId' cannot write to project files (forbidden: $fb)"
                $result.GateChecks += "FORBIDDEN_ACTION: FAIL ($fb)"
                return $result
            }
        }
    }
    $result.GateChecks += "FORBIDDEN_ACTION: PASS"

    # CHECK 3: Write scope check
    if ($Action -eq "write" -and $TargetPath) {
        if (-not $ProjectId) {
            $result.Reason = "PERMISSION_DENIED: ProjectId is required for write actions."
            $result.GateChecks += "PROJECT_ID: FAIL (missing)"
            return $result
        }

        $allowed = $false
        if (Get-Member -InputObject $agent -Name "allowedWriteScopes" -MemberType Properties) {
            foreach ($scope in $agent.allowedWriteScopes) {
                # Replace {projectId} placeholder
                $resolvedScope = $scope -replace '\{projectId\}', $ProjectId
                # Check if targetPath starts with the allowed scope (as substring)
                if ($TargetPath.StartsWith($resolvedScope, [StringComparison]::OrdinalIgnoreCase) -or
                    $resolvedScope.StartsWith($TargetPath, [StringComparison]::OrdinalIgnoreCase)) {
                    $allowed = $true
                    break
                }
                # Also check if scope is a wildcard match
                if ($resolvedScope -eq "contract_defined_paths_only") {
                    # Accept for implementer — detailed check deferred to contract
                    if ($AgentId -match "^IMPL-") {
                        $allowed = $true
                        break
                    }
                }
            }
        }

        if (-not $allowed) {
            $result.Reason = "PERMISSION_DENIED: Agent '$AgentId' write scope does not include '$TargetPath'. Allowed: $($agent.allowedWriteScopes -join ', ')"
            $result.GateChecks += "WRITE_SCOPE: FAIL"
            return $result
        }
        $result.GateChecks += "WRITE_SCOPE: PASS"
    }

    # CHECK 4: Skill check
    if ($Skill) {
        $skillAllowed = $false
        if (Get-Member -InputObject $agent -Name "allowedSkills" -MemberType Properties) {
            $skills = $agent.allowedSkills
            # Handle variant skill profiles
            if ($skills.PSObject.Properties.Name -contains $AgentId) {
                $variantSkills = $skills.$AgentId
                if ($variantSkills.required -contains $Skill -or $variantSkills.optional -contains $Skill) {
                    $skillAllowed = $true
                }
                if ($variantSkills.forbidden -contains $Skill) {
                    $result.Reason = "PERMISSION_DENIED: Skill '$Skill' is FORBIDDEN for agent '$AgentId'"
                    $result.GateChecks += "SKILL_CHECK: FAIL (forbidden)"
                    return $result
                }
            } else {
                # Non-variant: check required + optional
                $required = if ($skills.required) { $skills.required } else { @() }
                $optional = if ($skills.optional) { $skills.optional } else { @() }
                $forbidden = if ($skills.forbidden) { $skills.forbidden } else { @() }

                if ($forbidden -contains $Skill) {
                    $result.Reason = "PERMISSION_DENIED: Skill '$Skill' is FORBIDDEN for agent '$AgentId'"
                    $result.GateChecks += "SKILL_CHECK: FAIL (forbidden)"
                    return $result
                }
                if ($required -contains $Skill -or $optional -contains $Skill) {
                    $skillAllowed = $true
                }
            }
        }

        if (-not $skillAllowed) {
            $result.Reason = "PERMISSION_DENIED: Skill '$Skill' is not in allowed skills for agent '$AgentId'"
            $result.GateChecks += "SKILL_CHECK: FAIL (not allowed)"
            return $result
        }
        $result.GateChecks += "SKILL_CHECK: PASS"
    }

    # All checks passed
    $result.Allowed = $true
    $result.Reason = "PERMISSION_GRANTED: All checks passed."
    return $result
}

<#
.SYNOPSIS
Bulk-check a permission against multiple agent definitions (for testing).
#>
function Assert-Permission {
    param(
        [string]$AgentId,
        [string]$Action,
        [string]$TargetPath = "",
        [string]$Skill = "",
        [string]$ProjectId = "",
        [bool]$ExpectAllowed = $true
    )

    $result = Test-AgentPermission -AgentId $AgentId -Action $Action -TargetPath $TargetPath -Skill $Skill -ProjectId $ProjectId
    $testPassed = ($result.Allowed -eq $ExpectAllowed)

    return [PSCustomObject]@{
        TestCase      = "Agent=$AgentId Action=$Action Path=$TargetPath Skill=$Skill"
        ExpectAllowed = $ExpectAllowed
        ActualAllowed = $result.Allowed
        Passed        = $testPassed
        Reason        = $result.Reason
    }
}
