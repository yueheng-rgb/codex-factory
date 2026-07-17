# factory-agent-manager.ps1 — H13-A Agent Lifecycle Manager
param(
    [string]$Action,
    [string]$AgentId,
    [string]$TaskId,
    [string]$Role,
    [string]$CapsulePath,
    [string]$WorktreePath,
    [string]$ParentPhase,
    [switch]$ForkContext,
    [switch]$IsolationRequired,
    [switch]$PassThru
)

$stateDir = "$PSScriptRoot\..\governance\factory-state"
$registryPath = "$stateDir\AGENT_REGISTRY.json"

function Get-Registry {
    if (Test-Path $registryPath) {
        $json = Get-Content $registryPath -Raw
        return $json | ConvertFrom-Json
    }
    return $null
}

function Save-Registry($reg) {
    $reg | ConvertTo-Json -Depth 5 | Set-Content $registryPath -Encoding UTF8
}

function Write-Result($obj) {
    if ($PassThru) { $obj | ConvertTo-Json -Depth 3 }
    else { Write-Host ($obj | ConvertTo-Json -Depth 3) }
}

switch ($Action) {
    "create" {
        $reg = Get-Registry
        if (-not $reg) { $reg = @{ registryId = "FACTORY_AGENT_REGISTRY"; agents = @() } }
        $agent = [PSCustomObject]@{
            agentId = $AgentId
            taskId = $TaskId
            role = $Role
            status = "created"
            createdAt = (Get-Date -Format "o")
            capsulePath = $CapsulePath
            worktreePath = $WorktreePath
            parentPhase = $ParentPhase
            forkContext = $ForkContext.IsPresent
            isolationRequired = $IsolationRequired.IsPresent
            expectedOutputs = @()
            actualOutputs = @()
            evidencePaths = @()
            riskSignals = @()
            lastHeartbeatAt = $null
            closedAt = $null
            handoffPath = $null
        }
        $agents = @($reg.agents) + @($agent)
        $reg | Add-Member -NotePropertyName "agents" -NotePropertyValue $agents -Force
        Save-Registry $reg
        Write-Result @{ status = "created"; agentId = $AgentId; exitCode = 0 }
    }
    "heartbeat" {
        $reg = Get-Registry
        $found = $false
        $agents = @($reg.agents) | ForEach-Object {
            $a = $_
            if ($a.agentId -eq $AgentId) {
                $found = $true
                $a | Add-Member -NotePropertyName "lastHeartbeatAt" -NotePropertyValue (Get-Date -Format "o") -Force
                if ($a.status -eq "created") {
                    $a | Add-Member -NotePropertyName "status" -NotePropertyValue "running" -Force
                }
            }
            $a
        }
        $reg | Add-Member -NotePropertyName "agents" -NotePropertyValue @($agents) -Force
        Save-Registry $reg
        Write-Result @{ status = if ($found) { "heartbeat" } else { "not_found" }; agentId = $AgentId; exitCode = if ($found) { 0 } else { 1 } }
    }
    "close" {
        $reg = Get-Registry
        $found = $false
        $agents = @($reg.agents) | ForEach-Object {
            $a = $_
            if ($a.agentId -eq $AgentId) {
                $found = $true
                $a | Add-Member -NotePropertyName "status" -NotePropertyValue "closed" -Force
                $a | Add-Member -NotePropertyName "closedAt" -NotePropertyValue (Get-Date -Format "o") -Force
            }
            $a
        }
        $reg | Add-Member -NotePropertyName "agents" -NotePropertyValue @($agents) -Force
        Save-Registry $reg
        Write-Result @{ status = if ($found) { "closed" } else { "not_found" }; agentId = $AgentId; exitCode = if ($found) { 0 } else { 1 } }
    }
    "cancel" {
        $reg = Get-Registry
        $found = $false
        $agents = @($reg.agents) | ForEach-Object {
            $a = $_
            if ($a.agentId -eq $AgentId) {
                $found = $true
                $a | Add-Member -NotePropertyName "status" -NotePropertyValue "cancelled" -Force
                $a | Add-Member -NotePropertyName "closedAt" -NotePropertyValue (Get-Date -Format "o") -Force
            }
            $a
        }
        $reg | Add-Member -NotePropertyName "agents" -NotePropertyValue @($agents) -Force
        Save-Registry $reg
        Write-Result @{ status = if ($found) { "cancelled" } else { "not_found" }; agentId = $AgentId; exitCode = if ($found) { 0 } else { 1 } }
    }
    "quarantine" {
        $reg = Get-Registry
        $found = $false
        $agents = @($reg.agents) | ForEach-Object {
            $a = $_
            if ($a.agentId -eq $AgentId) {
                $found = $true
                $a | Add-Member -NotePropertyName "status" -NotePropertyValue "quarantined" -Force
                $signals = @($a.riskSignals) + @("manual_quarantine")
                $a | Add-Member -NotePropertyName "riskSignals" -NotePropertyValue $signals -Force
            }
            $a
        }
        $reg | Add-Member -NotePropertyName "agents" -NotePropertyValue @($agents) -Force
        Save-Registry $reg
        Write-Result @{ status = if ($found) { "quarantined" } else { "not_found" }; agentId = $AgentId; exitCode = if ($found) { 0 } else { 1 } }
    }
    "handoff" {
        $reg = Get-Registry
        $found = $false
        $agents = @($reg.agents) | ForEach-Object {
            $a = $_
            if ($a.agentId -eq $AgentId) {
                $found = $true
                $a | Add-Member -NotePropertyName "handoffPath" -NotePropertyValue $CapsulePath -Force
                $a | Add-Member -NotePropertyName "status" -NotePropertyValue "done" -Force
            }
            $a
        }
        $reg | Add-Member -NotePropertyName "agents" -NotePropertyValue @($agents) -Force
        Save-Registry $reg
        Write-Result @{ status = if ($found) { "handoff" } else { "not_found" }; agentId = $AgentId; exitCode = if ($found) { 0 } else { 1 } }
    }
    default {
        Write-Result @{ status = "error"; message = "Unknown action: $Action"; exitCode = 2 }
    }
}
