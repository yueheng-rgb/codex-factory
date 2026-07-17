# Sandbox Lifecycle Manager
# Part of: FACTORY-R2.3-L-NETWORK-BOUNDARY-AND-SANDBOX-LIFECYCLE

$script:FR = if ($PSScriptRoot) { Split-Path $PSScriptRoot -Parent } else { "C:\Codex_App_Factory" }
$script:SandboxDir = Join-Path $script:FR "governance\sandbox-sessions"
if (-not (Test-Path $script:SandboxDir)) { New-Item -ItemType Directory -Path $script:SandboxDir -Force | Out-Null }
$script:LedgerPath = Join-Path $script:SandboxDir "sandbox-session-index.jsonl"

function New-SandboxSession {
    param([string]$ProjectId,[string]$ToolId,[string]$AgentId,[string]$NetworkBoundary="loopback_only",[string[]]$AllowedHosts=@(),[string]$WorkspaceType="disposable")
    $sid = "SBOX-$(Get-Date -Format 'yyyyMMddHHmmss')-$ToolId"
    $wsPath = Join-Path $env:TEMP "factory-sandbox-$sid"
    New-Item -ItemType Directory -Path $wsPath -Force | Out-Null
    $session = [PSCustomObject]@{sessionId=$sid;projectId=$ProjectId;toolId=$ToolId;agentId=$AgentId;networkBoundary=$NetworkBoundary;allowedHosts=$AllowedHosts;workspaceType=$WorkspaceType;workspacePath=$wsPath;status="created";createdAt=Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz";lifecycle=@();artifacts=@()}
    $session.lifecycle += "created: $($session.createdAt)"
    $session | ConvertTo-Json -Compress -Depth 3 | Add-Content -Path $script:LedgerPath -Encoding UTF8
    Write-Host "  Sandbox created: $sid at $wsPath"
    return $session
}

function Start-SandboxSession { param($Session)
    $Session.status="running"; $Session.lifecycle+="started: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')"
    Write-Host "  Sandbox running: $($Session.sessionId)"
    return $Session
}

function Stop-SandboxSession { param($Session,[bool]$PreserveOnFailure=$false,[bool]$Failed=$false)
    $Session.status=if($Failed -and -not $PreserveOnFailure){"failed_cleaned"}elseif($Failed){"failed_preserved"}else{"completed"}
    $Session.lifecycle+="stopped: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz') status=$($Session.status)"
    return $Session
}

function Add-SandboxArtifact { param($Session,$ArtifactPath)
    if (Test-Path $ArtifactPath) { $Session.artifacts+=$ArtifactPath; $Session.lifecycle+="artifact: $ArtifactPath" }
    return $Session
}

function Invoke-CleanupSandbox { param($Session)
    if ($Session.status -eq "failed_preserved") { Write-Host "  Sandbox preserved: $($Session.workspacePath)"; return $Session }
    if (Test-Path $Session.workspacePath) { Remove-Item -Recurse -Force $Session.workspacePath -ErrorAction SilentlyContinue; Write-Host "  Sandbox cleaned: $($Session.workspacePath)" }
    $Session.lifecycle+="cleaned: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')"
    # Update ledger entry (append final state)
    $Session | ConvertTo-Json -Compress -Depth 3 | Add-Content -Path $script:LedgerPath -Encoding UTF8
    return $Session
}

Write-Verbose "Sandbox Lifecycle Manager initialized."
