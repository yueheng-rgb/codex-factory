# Agent Definition Loader
# Part of: FACTORY-R2.2-AGENT-RUNTIME-BINDING
# Loads and validates agent definition JSON files.
# Usage: . .\runtime\agent-loader.ps1; $agent = Get-AgentDefinition -AgentId "PM-001"

$script:AgentDefinitionsPath = Join-Path $PSScriptRoot "..\governance\multi-agent\agent-definitions"

# Required fields for every agent definition
$script:RequiredFields = @(
    "agentId", "role", "responsibilities", "permissions",
    "allowedWriteScopes", "forbiddenActions", "allowedSkills",
    "requiredInputs", "requiredOutputs", "handoffRequired",
    "evidenceLevel", "failurePolicy"
)

# Registered agent IDs
$script:KnownAgentIds = @(
    "PM-001", "RSRC-001", "LIB-001", "ARCH-001",
    "IMPL-FE-001", "IMPL-BE-001", "IMPL-DB-001",
    "VER-001", "SEC-001", "INTG-001", "AUD-001"
)

# Map friendly names to agent definition files
$script:AgentFileMap = @{
    "PM-001"       = "router.agent.json"
    "RSRC-001"     = "research.agent.json"
    "LIB-001"      = "librarian.agent.json"
    "ARCH-001"     = "architect.agent.json"
    "IMPL-FE-001"  = "implementer.agent.json"
    "IMPL-BE-001"  = "implementer.agent.json"
    "IMPL-DB-001"  = "implementer.agent.json"
    "VER-001"      = "verifier.agent.json"
    "SEC-001"      = "security.agent.json"
    "INTG-001"     = "integrator.agent.json"
    "AUD-001"      = "drift-auditor.agent.json"
}

<#
.SYNOPSIS
Loads a single agent definition from its JSON file and validates required fields.
#>
function Get-AgentDefinition {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({ $_ -in $script:KnownAgentIds })]
        [string]$AgentId
    )

    $fileName = $script:AgentFileMap[$AgentId]
    if (-not $fileName) {
        Write-Error "AGENT_LOADER: No file mapping for agentId '$AgentId'"
        return $null
    }

    $filePath = Join-Path $script:AgentDefinitionsPath $fileName
    if (-not (Test-Path $filePath)) {
        Write-Error "AGENT_LOADER: Agent definition file not found: $filePath"
        return $null
    }

    try {
        $agent = Get-Content $filePath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Error "AGENT_LOADER: Failed to parse JSON for '$AgentId': $($_.Exception.Message)"
        return $null
    }

    # Validate required fields
    $missingFields = @()
    foreach ($field in $script:RequiredFields) {
        if (-not (Get-Member -InputObject $agent -Name $field -MemberType Properties)) {
            $missingFields += $field
        }
    }

    if ($missingFields.Count -gt 0) {
        Write-Error "AGENT_LOADER: Agent '$AgentId' missing required fields: $($missingFields -join ', ')"
        return $null
    }

    # If loading a variant (IMPL-FE/BE/DB), extract variant-specific overrides
    if ($AgentId -match "^IMPL-(FE|BE|DB)-001$" -and (Get-Member -InputObject $agent -Name "variants" -MemberType Properties)) {
        # Variant overrides exist; caller should use them
    }

    Write-Verbose "AGENT_LOADER: Successfully loaded agent '$AgentId' ($($agent.role))"
    return $agent
}

<#
.SYNOPSIS
Loads all agent definitions and returns a summary.
#>
function Get-AllAgentDefinitions {
    $agents = @{}
    foreach ($agentId in $script:KnownAgentIds) {
        $agent = Get-AgentDefinition -AgentId $agentId -ErrorAction SilentlyContinue
        if ($agent) {
            $agents[$agentId] = $agent
        }
    }
    return $agents
}

<#
.SYNOPSIS
Validates that all 9 agent definition files are loadable.
Returns a result object with pass/fail per agent.
#>
function Test-AllAgentDefinitions {
    $results = @()
    foreach ($agentId in $script:KnownAgentIds) {
        $agent = Get-AgentDefinition -AgentId $agentId -ErrorAction SilentlyContinue
        $results += [PSCustomObject]@{
            AgentId = $agentId
            Loadable = ($null -ne $agent)
            Role     = if ($agent) { $agent.role } else { "N/A" }
            Fields   = if ($agent) { "OK ($($script:RequiredFields.Count) fields)" } else { "FAILED" }
        }
    }
    return $results
}

Write-Verbose "Agent Definition Loader initialized. Known agents: $($script:KnownAgentIds.Count)"
