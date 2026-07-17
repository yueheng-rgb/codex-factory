<#
.SYNOPSIS
    Record a native progress event in AGENT_PROGRESS.jsonl
.PARAMETER Event
    Event type: create, spawn_requested, spawn_confirmed, heartbeat, artifact, handoff, close, progress
.PARAMETER AgentId
    Agent identifier
.PARAMETER Phase
    Current phase
.PARAMETER Role
    Agent role
.PARAMETER ExtraJson
    Additional JSON properties as a hashtable string (e.g., '@{outputCount=3;verdict="PASS"}')
.EXAMPLE
    powershell -File scripts/record-progress.ps1 -Event "artifact" -AgentId "h14-builder-1" -Phase "H14" -Role "builder" -ExtraJson "@{outputCount=1;paths=@('scripts/factoryctl.ps1')}"
.NOTES
    All entries created by this script are nativeGenerated: true.
#>

param(
    [Parameter(Mandatory)] [string]$Event,
    [Parameter(Mandatory)] [string]$AgentId,
    [Parameter(Mandatory)] [string]$Phase,
    [Parameter(Mandatory)] [string]$Role,
    [string]$ExtraJson = ""
)

$BaseDir = $PSScriptRoot | Split-Path -Parent
$ProgressPath = Join-Path $BaseDir "governance\factory-state\AGENT_PROGRESS.jsonl"

$entry = [ordered]@{
    event = $Event
    agentId = $AgentId
    phase = $Phase
    role = $Role
    nativeGenerated = $true
    source = "scripts/record-progress.ps1"
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
}

if ($ExtraJson) {
    try {
        $extra = Invoke-Expression $ExtraJson
        foreach ($k in $extra.Keys) {
            $entry[$k] = $extra[$k]
        }
    } catch {
        Write-Warning "Failed to parse ExtraJson: $_"
    }
}

$line = $entry | ConvertTo-Json -Compress -Depth 6
Add-Content -Path $ProgressPath -Value $line -Encoding UTF8
Write-Output "Recorded: event=$Event agentId=$AgentId phase=$Phase"
