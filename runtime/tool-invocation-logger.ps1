# Tool Invocation Logger
# Part of: FACTORY-R2.3-J-MCP-TOOL-SANDBOX

$script:FR = if ($PSScriptRoot) { Split-Path $PSScriptRoot -Parent } else { "C:\Codex_App_Factory" }
$script:LedgerPath = Join-Path $script:FR "governance\tool-invocations\tool-invocation-index.jsonl"

$ledgerDir = Join-Path $script:FR "governance\tool-invocations"
if (-not (Test-Path $ledgerDir)) { New-Item -ItemType Directory -Path $ledgerDir -Force | Out-Null }

function Write-ToolInvocation {
    param($ProjectId,$PhaseId,$AgentId,$ToolId,$RequestedAction,$Decision,$Reason,$SandboxMode="none",$HumanApproval=$false,$FilesRead=@(),$FilesWritten=@(),$NetworkUsed=$false,$SecretsUsed=$false,$Artifacts=@(),$Caveats=@(),$GateChecks=@())
    $invId = "TOOL-INV-$ToolId-$AgentId-$(Get-Date -Format 'yyyyMMddHHmmss')"
    $rec = [PSCustomObject]@{
        invocationId=$invId;projectId=$ProjectId;phaseId=$PhaseId;agentId=$AgentId;toolId=$ToolId
        requestedAction=$RequestedAction;decision=$Decision;reason=$Reason;sandboxMode=$SandboxMode
        humanApproval=$HumanApproval;filesRead=$FilesRead;filesWritten=$FilesWritten
        networkUsed=$NetworkUsed;secretsUsed=$SecretsUsed;artifactsProduced=$Artifacts
        timestamp=Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz";caveats=$Caveats;gateChecks=$GateChecks
    }
    $rec | ConvertTo-Json -Compress -Depth 3 | Add-Content -Path $script:LedgerPath -Encoding UTF8
    return $rec
}
Write-Verbose "Tool Invocation Logger initialized."
