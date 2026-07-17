# ZhipuAI Structured Web Search Adapter v1.0.0
# Part of: FACTORY-R2.3-V
# Canonical search path: POST /api/paas/v4/web_search
# Returns structured search_result[] with title, link, content
# Chat completions web_search tool is DEMOTED to auxiliary only

. (Join-Path $PSScriptRoot "secret-presence-check.ps1")
. (Join-Path $PSScriptRoot "tool-permission-gate.ps1")
. (Join-Path $PSScriptRoot "search-invocation-logger.ps1")

function Invoke-StructuredWebSearch {
    param(
        [Parameter(Mandatory=$true)][string]$RequestId,
        [Parameter(Mandatory=$true)][string]$Query,
        [ValidateSet("search_std")][string]$SearchEngine = "search_std",
        [int]$Count = 5,
        [ValidateSet("noLimit","day","week","month","year")][string]$RecencyFilter = "noLimit",
        [bool]$UserApproval = $false,
        [string]$ProjectId = "PROJ-SEARCH-WEB",
        [string]$PhaseId = "pre-build-research",
        [string]$AgentId = "RSRC-001",
        [string]$UserId = "codex-factory-structured-search"
    )

    $caveats = @()
    $searchToolInvoked = $false
    $searchResults = @()
    $sourceRefs = @()

    # =============================================
    # CHECK 1: Implementer agents BLOCKED
    # =============================================
    if ($AgentId -match "IMPL") {
        Write-SearchInvocation -ProjectId $ProjectId -PhaseId $PhaseId -AgentId $AgentId `
            -RequestId $RequestId -Provider "zhipuai_structured_web_search" -Mode "live_api" `
            -QueryRaw $Query -Decision "REJECT" `
            -Caveats @("Implementer agents cannot invoke search")
        return [PSCustomObject]@{
            requestId = $RequestId; accepted = $false; mode = "rejected"
            gateDecision = "REJECT"; gateReason = "Implementer agent not authorized"
            searchResultCount = 0; sourceRefs = @(); caveats = @("IMPLEMENTER_BLOCKED")
            searchToolInvoked = $false; endpoint = "/api/paas/v4/web_search"
        }
    }

    # =============================================
    # CHECK 2: Human approval for live search
    # =============================================
    if (-not $UserApproval) {
        Write-SearchInvocation -ProjectId $ProjectId -PhaseId $PhaseId -AgentId $AgentId `
            -RequestId $RequestId -Provider "zhipuai_structured_web_search" -Mode "live_api" `
            -QueryRaw $Query -Decision "PENDING_HUMAN" -HumanApproval $false
        return [PSCustomObject]@{
            requestId = $RequestId; accepted = $false; mode = "pending_human"
            gateDecision = "PENDING_HUMAN"; gateReason = "Human approval required"
            searchResultCount = 0; sourceRefs = @(); caveats = @("PENDING_HUMAN")
            searchToolInvoked = $false; endpoint = "/api/paas/v4/web_search"
        }
    }

    # =============================================
    # CHECK 3: Secret presence
    # =============================================
    $secretCheck = Test-SecretPresence -EnvVarNames @("ZHIPUAI_API_KEY","GLM_API_KEY") -ProviderType "zhipuai_structured_web_search"
    if (-not $secretCheck.secretPresent) {
        Write-SearchInvocation -ProjectId $ProjectId -PhaseId $PhaseId -AgentId $AgentId `
            -RequestId $RequestId -Provider "zhipuai_structured_web_search" -Mode "live_api" `
            -QueryRaw $Query -Decision "DOWNGRADED_NO_KEY" -SecretPresent $false
        return [PSCustomObject]@{
            requestId = $RequestId; accepted = $false; mode = "no_key"
            gateDecision = "REJECT"; gateReason = "API key not found"
            searchResultCount = 0; sourceRefs = @(); caveats = @("NO_API_KEY")
            searchToolInvoked = $false; endpoint = "/api/paas/v4/web_search"
        }
    }

    # =============================================
    # CHECK 4: Tool permission gate
    # =============================================
    $gateResult = Test-ToolPermission `
        -ProjectId $ProjectId -AgentId $AgentId -ToolId "TOOL-GLM-SEARCH-001" `
        -ProjectType "all" -IsLocalFirst $false -NetworkMode "external_api" `
        -HumanApproved $UserApproval -SecretsAllowed $true `
        -FileWriteAllowed $true -CloudAllowed $false -SandboxAvailable $true

    if ($gateResult.Decision -eq "REJECT") {
        Write-SearchInvocation -ProjectId $ProjectId -PhaseId $PhaseId -AgentId $AgentId `
            -RequestId $RequestId -Provider "zhipuai_structured_web_search" -Mode "live_api" `
            -QueryRaw $Query -Decision "REJECT" -Caveats @($gateResult.Reason)
        return [PSCustomObject]@{
            requestId = $RequestId; accepted = $false; mode = "gate_rejected"
            gateDecision = "REJECT"; gateReason = $gateResult.Reason
            searchResultCount = 0; sourceRefs = @(); caveats = @($gateResult.Reason)
            searchToolInvoked = $false; endpoint = "/api/paas/v4/web_search"
        }
    }

    # =============================================
    # STEP 5: Execute live structured search
    # =============================================
    $runtimeTimestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
    try {
        $apiKey = $null
        foreach ($name in @("ZHIPUAI_API_KEY","GLM_API_KEY")) {
            $val = [Environment]::GetEnvironmentVariable($name,"Process")
            if ($val) { $apiKey = $val; break }
        }
        if (-not $apiKey) { throw "API key not available in runtime" }

        $body = @{
            search_query = $Query
            search_engine = $SearchEngine
            search_intent = $false
            count = $Count
            search_recency_filter = $RecencyFilter
            request_id = $RequestId
            user_id = $UserId
        }
        $bodyJson = $body | ConvertTo-Json -Depth 4 -Compress

        $response = Invoke-RestMethod `
            -Uri "https://open.bigmodel.cn/api/paas/v4/web_search" `
            -Method Post `
            -Headers @{"Authorization"="Bearer $apiKey";"Content-Type"="application/json"} `
            -Body $bodyJson -TimeoutSec 30

        $searchToolInvoked = $true
        $caveats += "structured_web_search: real /api/paas/v4/web_search call completed"
        $caveats += "search_engine: $SearchEngine"
        $caveats += "response_id: $(if($response.id){$response.id}else{'N/A'})"

        # Parse search_result[] 
        if ($response.search_result) {
            $rawResults = if ($response.search_result -is [array]) { $response.search_result } else { @($response.search_result) }
            foreach ($sr in $rawResults) {
                $url = if ($sr.link) { $sr.link } elseif ($sr.url) { $sr.url } else { "" }
                $searchResults += [PSCustomObject]@{
                    title = if ($sr.title) { $sr.title } else { "Untitled" }
                    url = $url
                    content = if ($sr.content) { $sr.content } else { "" }
                    snippet = if ($sr.snippet) { $sr.snippet } else { "" }
                }
                $sourceRefs += [PSCustomObject]@{
                    title = if ($sr.title) { $sr.title } else { "Untitled" }
                    url = $url
                    content = if ($sr.content) { $sr.content } else { "" }
                    snippet = if ($sr.snippet) { $sr.snippet } else { "" }
                    sourceType = "provider_search_result"
                    sourceOrigin = "provider_search_result"
                    endpoint = "/api/paas/v4/web_search"
                    searchEngine = $SearchEngine
                    requestId = $response.request_id
                    responseId = if($response.id){$response.id}else{""}
                }
            }
            $caveats += "search_result_count: $($rawResults.Count)"
        } else {
            $caveats += "no search_result in response — keys: $($response.PSObject.Properties.Name -join ', ')"
        }

        if ($response.request_id) {
            $caveats += "request_id: $($response.request_id)"
        }

    } catch {
        $caveats += "structured_web_search: API call failed — $($_.Exception.Message)"
        $searchToolInvoked = $false
    }

    # =============================================
    # STEP 6: Write invocation ledger
    # =============================================
    Write-SearchInvocation -ProjectId $ProjectId -PhaseId $PhaseId -AgentId $AgentId `
        -RequestId $RequestId -Provider "zhipuai_structured_web_search" -Mode "live_api" `
        -QueryRaw $Query -ResultCount $searchResults.Count -SourceCount $sourceRefs.Count `
        -Decision $(if($searchToolInvoked){"ALLOW_WITH_CONTROLS"}else{"REJECT"}) `
        -SecretPresent $true -NetworkBoundary "external_api" `
        -HumanApproval $UserApproval -QualityScore $(if($searchResults.Count -gt 0){12}else{0}) `
        -QualityVerdict $(if($searchResults.Count -gt 0){"structured_results_available"}else{"no_results"}) `
        -Caveats $caveats

    # =============================================
    # STEP 7: Return canonical response
    # =============================================
    return [PSCustomObject]@{
        requestId = $RequestId
        accepted = $true
        mode = "live_api"
        gateDecision = $gateResult.Decision
        gateReason = $gateResult.Reason
        searchToolInvoked = $searchToolInvoked
        searchResultCount = $searchResults.Count
        sourceCount = $sourceRefs.Count
        sourceRefs = $sourceRefs
        normalizedResults = $searchResults
        endpoint = "/api/paas/v4/web_search"
        searchEngine = $SearchEngine
        responseRequestId = if($response.request_id){$response.request_id}else{""}
        responseId = if($response.id){$response.id}else{""}
        runtimeTimestamp = $runtimeTimestamp
        caveats = $caveats
        secretPresent = $true
        humanApproval = $UserApproval
    }
}

Write-Verbose "ZhipuAI Structured Web Search Adapter v1.0.0 loaded. Canonical: /api/paas/v4/web_search"
