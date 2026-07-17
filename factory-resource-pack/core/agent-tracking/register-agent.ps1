<#
.SYNOPSIS
    Register a new agent in AGENT_REGISTRY.json (native generation)
.PARAMETER AgentId
    Unique agent identifier
.PARAMETER Phase
    Phase this agent belongs to (e.g., "H14")
.PARAMETER Role
    Agent role: builder, verifier, skeptic, integrator
.PARAMETER ForkContext
    Whether fork_context was used (default: false)
.PARAMETER IsReadOnly
    Whether agent is read-only (default: false)
.PARAMETER SpawnMethod
    Spawn method used (default: none)
.PARAMETER SpawnId
    Spawn ID if available (default: none)
.PARAMETER IsolationRequired
    Whether H10 isolation is required (default: false)
.PARAMETER OwnerBoundary
    Worktree/scope or equivalent ownership boundary
.EXAMPLE
    powershell -File scripts/register-agent.ps1 -AgentId "h14-builder-1" -Phase "H14" -Role "builder" -OwnerBoundary "scripts/factoryctl.ps1"
.NOTES
    All entries created by this script are nativeGenerated: true.
    Existing reconstructedFromEvidence entries are never modified.
#>

param(
    [Parameter(Mandatory)] [string]$AgentId,
    [Parameter(Mandatory)] [string]$Phase,
    [Parameter(Mandatory)] [string]$Role,
    [bool]$ForkContext = $false,
    [bool]$IsReadOnly = $false,
    [string]$SpawnMethod = "",
    [string]$SpawnId = "",
    [bool]$IsolationRequired = $false,
    [string]$OwnerBoundary = ""
)

$BaseDir = $PSScriptRoot | Split-Path -Parent
$RegistryPath = Join-Path $BaseDir "governance\factory-state\AGENT_REGISTRY.json"

if (-not (Test-Path $RegistryPath)) {
    $registry = [PSCustomObject]@{
        _nativeGenerationActive = $true
        _nativeGenerationEnabledAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
        agents = @()
        totalAgents = 0
        phasesCovered = @()
        rolesUsed = @()
    }
} else {
    $registry = Get-Content $RegistryPath -Raw | ConvertFrom-Json
}

# Check if agent already exists
$existing = @($registry.agents).Where({$_.agentId -eq $AgentId})
if ($existing.Count -gt 0) {
    Write-Output "Agent $AgentId already registered. Skipping."
    exit 0
}

$newAgent = [ordered]@{
    agentId = $AgentId
    phase = $Phase
    role = $Role
    forkContext = $ForkContext
    isReadOnly = $IsReadOnly
    spawnMethod = if ($SpawnMethod) { $SpawnMethod } else { "none" }
    spawnId = if ($SpawnId) { $SpawnId } else { "" }
    isolationRequired = $IsolationRequired
    ownerBoundary = if ($OwnerBoundary) { $OwnerBoundary } else { "governance/factory-state" }
    verdict = "pending"
    nativeGenerated = $true
    registeredAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
}

$registry.agents = @($registry.agents) + $newAgent
$registry.totalAgents = $registry.agents.Count

if ($registry.phasesCovered -notcontains $Phase) {
    $registry.phasesCovered = @($registry.phasesCovered) + $Phase
}
if ($registry.rolesUsed -notcontains $Role) {
    $registry.rolesUsed = @($registry.rolesUsed) + $Role
}

$registry | ConvertTo-Json -Depth 6 | Set-Content $RegistryPath -Encoding UTF8
Write-Output "Registered agent: $AgentId (phase=$Phase, role=$Role, nativeGenerated=true)"
