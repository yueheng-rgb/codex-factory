# Tool Registry Loader
# Part of: FACTORY-R2.3-J-MCP-TOOL-SANDBOX
# Loads tool/MCP candidate entries from registry

$script:FactoryRoot = if ($PSScriptRoot) { Split-Path $PSScriptRoot -Parent } else { "C:\Codex_App_Factory" }
$script:ToolCache = $null
$script:ToolLookup = @{}

function Initialize-ToolCache {
    if ($script:ToolCache -ne $null) { return }
    $script:ToolCache = @()
    $script:ToolLookup = @{}
    $regPath = Join-Path $script:FactoryRoot "registries\tool-candidate-registry.jsonl"
    if (-not (Test-Path $regPath)) { Write-Warning "Tool registry not found: $regPath"; return }
    $lines = Get-Content $regPath -Encoding UTF8 | Where-Object { $_.Trim() -ne "" }
    foreach ($line in $lines) {
        try {
            $entry = $line | ConvertFrom-Json
            $script:ToolCache += $entry
            if ($entry.toolId) { $script:ToolLookup[$entry.toolId] = $entry }
        } catch { Write-Warning "Tool registry parse error: $_" }
    }
    Write-Verbose "TOOL_LOADER: Loaded $($script:ToolCache.Count) tools"
}

function Get-ToolById {
    param([Parameter(Mandatory=$true)][string]$ToolId)
    Initialize-ToolCache
    return $script:ToolLookup[$ToolId]
}

function Get-ToolsByType {
    param([Parameter(Mandatory=$true)][string]$Type)
    Initialize-ToolCache
    return $script:ToolCache | Where-Object { $_.type -eq $Type }
}

function Get-ToolsByAgent {
    param([Parameter(Mandatory=$true)][string]$AgentId)
    Initialize-ToolCache
    return $script:ToolCache | Where-Object { $_.allowedAgents -is [array] -and $_.allowedAgents -contains $AgentId }
}

function Get-ToolsByRiskLevel {
    param([Parameter(Mandatory=$true)][string]$RiskLevel)
    Initialize-ToolCache
    return $script:ToolCache | Where-Object { $_.riskLevel -eq $RiskLevel }
}

Write-Verbose "Tool Registry Loader initialized."
