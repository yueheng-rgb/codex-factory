# Capability Loader
# Part of: FACTORY-R2.3-C-CAPABILITY-REGISTRY-RUNTIME
# Loads and indexes capability candidates from registries.
# Usage: . .\runtime\capability-loader.ps1; $caps = Get-CapabilitiesByAgent -AgentId "IMPL-FE-001"

. "$PSScriptRoot\registry-integrity-check.ps1"

$script:CapabilityCache = $null
$script:CapabilityLookup = @{}
$script:LoadedAt = $null

function Initialize-CapabilityCache {
    if ($script:CapabilityCache -ne $null) { return }
    
    $script:CapabilityCache = @()
    $script:CapabilityLookup = @{}
    
    $regPath = Join-Path $script:FactoryRoot "registries"
    $masterFile = Join-Path $regPath $script:RegistryFiles["master"]
    $entries = Get-RegistryEntries -FilePath $masterFile
    
    foreach ($e in $entries) {
        if ($e._parseError) { continue }
        $script:CapabilityCache += $e
        $cid = $e.capabilityId
        if ($cid) { $script:CapabilityLookup[$cid] = $e }
    }
    
    $script:LoadedAt = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
    Write-Verbose "CAP_LOADER: Loaded $($script:CapabilityCache.Count) capabilities into cache"
}

function Get-CapabilityById {
    param([Parameter(Mandatory=$true)]$CapabilityId)
    Initialize-CapabilityCache
    return $script:CapabilityLookup[$CapabilityId]
}

function Get-CapabilitiesByType {
    param([Parameter(Mandatory=$true)][string]$Type)
    Initialize-CapabilityCache
    return $script:CapabilityCache | Where-Object { $_.type -eq $Type }
}

function Get-CapabilitiesByPriority {
    param([Parameter(Mandatory=$true)][string]$Priority)
    Initialize-CapabilityCache
    return $script:CapabilityCache | Where-Object { $_.priority -eq $Priority }
}

function Get-CapabilitiesByAgent {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({ $_ -in $script:KnownAgentIds })]
        [string]$AgentId
    )
    Initialize-CapabilityCache
    return $script:CapabilityCache | Where-Object { 
        $_.applicableAgents -is [array] -and $_.applicableAgents -contains $AgentId
    }
}

function Get-CapabilitiesByProjectType {
    param([Parameter(Mandatory=$true)][string]$ProjectType)
    Initialize-CapabilityCache
    return $script:CapabilityCache | Where-Object {
        $apt = $_.applicableProjectTypes
        ($apt -is [array] -and ($apt -contains "all" -or $apt -contains $ProjectType)) -or
        ($apt -eq "all")
    }
}

function Get-CapabilitiesByPhase {
    param([string]$PhaseId)
    Initialize-CapabilityCache

    $phasePattern = switch -Wildcard ($PhaseId) {
        "*DESIGN*"   { @("design") }
        "*IMPL*"     { @("implementation") }
        "*VERIFY*"   { @("verification") }
        "*RESEARCH*" { @("research") }
        "*AUDIT*"    { @("audit") }
        "*PLAN*"     { @("planning") }
        default      { @("any") }
    }
    
    if ($phasePattern -contains "any") { return $script:CapabilityCache }
    return $script:CapabilityCache | Where-Object {
        $apt = $_.applicableProjectTypes
        $apt -is [array]
    }
}

function Get-CapabilitiesByRiskLevel {
    param([string]$MaxRiskLevel = "medium")
    Initialize-CapabilityCache
    $riskOrder = @{ "none"=0; "low"=1; "medium"=2; "high"=3; "critical"=4; "unknown"=99 }
    $maxOrdinal = $riskOrder[$MaxRiskLevel]
    if ($null -eq $maxOrdinal) { $maxOrdinal = 2 }
    
    return $script:CapabilityCache | Where-Object {
        $r = $_.securityRisk
        if (-not $r) { return $false }
        $o = $riskOrder[$r]
        if ($null -eq $o) { $o = 99 }
        return $o -le $maxOrdinal
    }
}

function Get-CapabilitiesByAction {
    param([string]$Action)
    Initialize-CapabilityCache
    return $script:CapabilityCache | Where-Object { $_.recommendedAction -eq $Action }
}

function Get-CapabilitiesByFilter {
    param(
        [string]$AgentId,
        [string]$ProjectType,
        [string]$PhaseId,
        [string]$MaxRiskLevel = "medium",
        [string]$Priority,
        [string]$Type
    )
    Initialize-CapabilityCache
    $results = $script:CapabilityCache

    if ($AgentId) {
        $results = $results | Where-Object { $_.applicableAgents -is [array] -and $_.applicableAgents -contains $AgentId }
    }
    if ($ProjectType) {
        $results = $results | Where-Object {
            $apt = $_.applicableProjectTypes
            ($apt -is [array] -and ($apt -contains "all" -or $apt -contains $ProjectType)) -or ($apt -eq "all")
        }
    }
    if ($Type) {
        $results = $results | Where-Object { $_.type -eq $Type }
    }
    if ($Priority) {
        $results = $results | Where-Object { $_.priority -eq $Priority }
    }

    return $results
}

function Get-CapabilityStats {
    Initialize-CapabilityCache
    $byType = $script:CapabilityCache | Group-Object -Property type | ForEach-Object { @{type=$_.Name; count=$_.Count} }
    $byTrust = $script:CapabilityCache | Group-Object -Property trustLevel | ForEach-Object { @{trustLevel=$_.Name; count=$_.Count} }
    $byAction = $script:CapabilityCache | Group-Object -Property recommendedAction | ForEach-Object { @{action=$_.Name; count=$_.Count} }
    $byPriority = $script:CapabilityCache | Group-Object -Property priority | ForEach-Object { @{priority=$_.Name; count=$_.Count} }

    return [PSCustomObject]@{
        totalCapabilities = $script:CapabilityCache.Count
        loadedAt = $script:LoadedAt
        byType = $byType
        byTrustLevel = $byTrust
        byAction = $byAction
        byPriority = $byPriority
    }
}

Write-Verbose "Capability Loader initialized."
