# factory-agent-progress.ps1 — H13-A Agent Progress Tracker
param(
    [string]$AgentId,
    [string]$TaskId,
    [string]$EventType,
    [int]$ProgressPercent,
    [string]$CurrentStep,
    [string[]]$ArtifactPaths,
    [string[]]$EvidencePaths,
    [string]$Blocker,
    [string]$RiskSignal,
    [string]$Message,
    [switch]$PassThru
)

$stateDir = "$PSScriptRoot\..\governance\factory-state"
$progressPath = "$stateDir\AGENT_PROGRESS.jsonl"

$event = @{
    eventId = "evt-" + (Get-Date -Format "yyyyMMddHHmmss") + "-" + (Get-Random -Minimum 1000 -Maximum 9999)
    agentId = $AgentId
    taskId = $TaskId
    eventType = $EventType
    timestamp = (Get-Date -Format "o")
    progressPercent = $ProgressPercent
    currentStep = $CurrentStep
    artifactPaths = if ($ArtifactPaths) { @($ArtifactPaths) } else { @() }
    evidencePaths = if ($EvidencePaths) { @($EvidencePaths) } else { @() }
    blocker = $Blocker
    riskSignal = $RiskSignal
    message = $Message
}

$line = $event | ConvertTo-Json -Depth 3 -Compress
Add-Content -Path $progressPath -Value $line -Encoding UTF8

if ($PassThru) {
    $line
} else {
    Write-Host "Progress recorded: $($event.eventId) - $EventType"
}
