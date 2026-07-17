# Search Invocation Logger
# Part of: FACTORY-R2.3-N
# Records every search adapter invocation. NEVER stores raw query or API key.

. (Join-Path (Split-Path $PSScriptRoot -Parent) "runtime\tool-invocation-logger.ps1")

$script:SearchInvocationIndexPath = Join-Path (Split-Path $PSScriptRoot -Parent) "governance\search-invocations\search-invocation-index.jsonl"

function Write-SearchInvocation {
    param(
        [Parameter(Mandatory=$true)][string]$ProjectId,
        [string]$PhaseId = "research",
        [Parameter(Mandatory=$true)][string]$AgentId,
        [string]$RequestId,
        [Parameter(Mandatory=$true)][string]$Provider,
        [Parameter(Mandatory=$true)][string]$Mode,
        [string]$QueryRaw,
        [int]$ResultCount = 0,
        [int]$SourceCount = 0,
        [Parameter(Mandatory=$true)][string]$Decision,
        [bool]$SecretPresent = $false,
        [string]$NetworkBoundary = "external_api",
        [bool]$HumanApproval = $false,
        [int]$QualityScore = 0,
        [string]$QualityVerdict = "unknown",
        [string]$DowngradedFrom = "none",
        [string[]]$Caveats = @()
    )
    $queryHash = $null
    if ($QueryRaw) {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $hashBytes = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($QueryRaw))
        $queryHash = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
    }
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
    $invocationId = "SRCH-INV-$(Get-Date -Format 'yyyyMMdd')-$((Get-Random -Minimum 100 -Maximum 999))"
    $entry = [PSCustomObject]@{
        invocationId = $invocationId
        projectId = $ProjectId
        phaseId = $PhaseId
        agentId = $AgentId
        requestId = $RequestId
        provider = $Provider
        mode = $Mode
        queryHash = $queryHash
        rawQueryStored = $false
        resultCount = $ResultCount
        sourceCount = $SourceCount
        decision = $Decision
        secretPresent = $SecretPresent
        networkBoundary = $NetworkBoundary
        humanApproval = $HumanApproval
        qualityScore = $QualityScore
        qualityVerdict = $QualityVerdict
        downgradedFrom = $DowngradedFrom
        timestamp = $timestamp
        caveats = $Caveats
    }
    $entry | ConvertTo-Json -Compress -Depth 3 | Out-File -FilePath $script:SearchInvocationIndexPath -Append -Encoding UTF8
    $null
}

function Get-SearchInvocationHistory {
    param([string]$AgentId, [string]$Provider, [int]$Limit = 20)
    if (-not (Test-Path $script:SearchInvocationIndexPath)) { return @() }
    $lines = Get-Content $script:SearchInvocationIndexPath -Encoding UTF8 | Where-Object { $_.Trim() -ne '' }
    $results = $lines | ForEach-Object { try { $_ | ConvertFrom-Json } catch { $null } } | Where-Object { $_ -ne $null }
    if ($AgentId) { $results = $results | Where-Object { $_.agentId -eq $AgentId } }
    if ($Provider) { $results = $results | Where-Object { $_.provider -eq $Provider } }
    return ($results | Sort-Object timestamp -Descending | Select-Object -First $Limit)
}

Write-Verbose "Search Invocation Logger loaded."
