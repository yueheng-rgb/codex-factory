<#
.SYNOPSIS Factory Memory MCP Server — Minimal Prototype
.DESCRIPTION Wraps Context OS scripts as MCP-style tool layer. PROTOTYPE_LOCAL_ONLY.
#>
param([string]$Tool,[string]$Query,[string]$Type,[string]$Phase,[string]$Confidence,[switch]$Json)

$ErrorActionPreference = "Stop"
$BaseDir = if ($env:FACTORY_REPO) { $env:FACTORY_REPO } else { $PSScriptRoot | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent }
$CosDir = Join-Path $BaseDir "governance\context-os"
$GovDir = Join-Path $BaseDir "governance\factory-state"
$ScriptsDir = Join-Path $BaseDir "scripts\context-os"
$ts = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"

function Invoke-CurrentState {
    $ccp = Get-Content (Join-Path $CosDir "FACTORY_CURRENT_CONTEXT_PACKET.json") -Raw | ConvertFrom-Json
    $state = Get-Content (Join-Path $GovDir "current-factory-state.json") -Raw | ConvertFrom-Json
    @{
        tool = "factory.memory.currentState"
        currentTrustedPhase = $ccp.currentTrustedPhase
        finalPackageStatus = $state.finalPackageStatus
        finalZipPath = $state.finalZipPath
        finalZipSha256 = $state.finalZipSha256
        pluginScaffoldStatus = $state.pluginScaffoldStatus
        agentOSEstablished = $state.agentOSEstablished
        contextOSEstablished = $state.contextOSEstablished
        sourceArtifactPaths = @("governance/factory-state/current-factory-state.json","governance/context-os/FACTORY_CURRENT_CONTEXT_PACKET.json")
        confidence = "HIGH"
        verifiedAt = $ts
    }
}

function Invoke-Search {
    $result = & (Join-Path $ScriptsDir "query-memory.ps1") -Type $Type -Phase $Phase -Confidence $Confidence -Json
    $result | Add-Member -Force -NotePropertyName "tool" -NotePropertyValue "factory.memory.search"
    $result
}

function Invoke-OpenRisks {
    $ccp = Get-Content (Join-Path $CosDir "FACTORY_CURRENT_CONTEXT_PACKET.json") -Raw | ConvertFrom-Json
    @{
        tool = "factory.memory.openRisks"
        activeRisks = $ccp.activeRisks
        rejectedClaims = $ccp.rejectedClaims
        experimentalComponents = $ccp.finalPackage.experimentalComponents
        recommendedNextPhase = $ccp.recommendedNextPhase
        verifiedAt = $ts
    }
}

function Invoke-BuildStartupPacket {
    $result = & (Join-Path $ScriptsDir "build-context-packet.ps1") -PacketType "startup" -Json
    $result | Add-Member -Force -NotePropertyName "tool" -NotePropertyValue "factory.memory.buildStartupPacket"
    $result | Add-Member -Force -NotePropertyName "startupVerificationRequired" -NotePropertyValue $true
    $result
}

function Invoke-Validate {
    $result = & (Join-Path $ScriptsDir "validate-context-memory.ps1") -Json
    $result | Add-Member -Force -NotePropertyName "tool" -NotePropertyValue "factory.memory.validate"
    $result
}

function Invoke-Verify {
    $factoryctl = Join-Path $BaseDir "scripts\factoryctl.ps1"
    if (Test-Path $factoryctl) {
        $result = & $factoryctl verify -Json 2>&1 | Out-String | ConvertFrom-Json
        $result | Add-Member -Force -NotePropertyName "tool" -NotePropertyValue "factory.verify"
        $result | Add-Member -Force -NotePropertyName "note" -NotePropertyValue "EXPERIMENTAL: wraps factoryctl.ps1"
        $result
    } else {
        @{tool="factory.verify";verdict="UNAVAILABLE";note="factoryctl.ps1 not found or MCP runtime not registered";verifiedAt=$ts}
    }
}

$output = switch ($Tool) {
    "currentState" { Invoke-CurrentState }
    "search" { Invoke-Search }
    "openRisks" { Invoke-OpenRisks }
    "buildStartupPacket" { Invoke-BuildStartupPacket }
    "validate" { Invoke-Validate }
    "verify" { Invoke-Verify }
    default { @{tool="factory.memory";error="Unknown tool: $Tool";availableTools=@("currentState","search","openRisks","buildStartupPacket","validate","verify");verifiedAt=$ts} }
}

if ($Json) { $output | ConvertTo-Json -Depth 4 } else { Write-Output ($output | ConvertTo-Json -Depth 4) }
$output
