# GLM Search Adapter
# Part of: FACTORY-R2.3-N
# Supports 3 modes: manual, dry_run, live_api
# Flow: Implementer check ¡ú Human approval ¡ú Secret check ¡ú Gate ¡ú Execute

. (Join-Path $PSScriptRoot "tool-registry-loader.ps1")
. (Join-Path $PSScriptRoot "tool-permission-gate.ps1")
. (Join-Path $PSScriptRoot "secret-presence-check.ps1")
. (Join-Path $PSScriptRoot "search-result-quality-gate.ps1")
. (Join-Path $PSScriptRoot "search-invocation-logger.ps1")
. (Join-Path $PSScriptRoot "read-only-search-adapter.ps1")

function New-GLMEmptyResponse {
    param([string]$RequestId, [string]$Query, [string]$Mode, [bool]$Accepted, [string]$GateDecision, [string]$GateReason, [string[]]$Caveats, [bool]$SecretPresent=$false, [string]$NetworkBoundary="no_network", [bool]$HumanApproval=$false, [string]$DowngradedFrom="none")
    return [PSCustomObject]@{
        responseId = "GLM-RESP-$RequestId"; requestId = $RequestId
        provider = "glm_search"; mode = $Mode; query = $Query
        queryHash = $null; accepted = $Accepted; gateDecision = $GateDecision; gateReason = $GateReason
        normalizedResults = @(); sourceRefs = @(); resultCount = 0; sourceCount = 0
        retrievalTime = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"; caveats = $Caveats
        qualityGateStatus = $null; secretPresent = $SecretPresent
        networkBoundary = $NetworkBoundary; humanApproval = $HumanApproval; downgradedFrom = $DowngradedFrom
    }
}

function Invoke-GLMSearch {
    param(
        [Parameter(Mandatory=$true)][string]$RequestId,
        [Parameter(Mandatory=$true)][string]$Query,
        [Parameter(Mandatory=$true)][ValidateSet("manual","dry_run","live_api")][string]$ProviderMode,
        [ValidateSet("knowledge_reserve","project_time")][string]$SearchIntent = "knowledge_reserve",
        [string[]]$Domains = @(),
        [hashtable]$DateRange = $null,
        [int]$ResultCount = 10,
        [ValidateSet("real_time","last_week","last_month","last_6_months","last_year","any")][string]$FreshnessRequirement = "any",
        [bool]$CitationRequired = $true,
        [bool]$UserApproval = $false,
        [hashtable]$ManualInput = $null,
        [string]$ProjectId = "PROJ-SEARCH-GLM",
        [string]$PhaseId = "research-intake",
        [string]$AgentId = "RSRC-001"
    )

    $caveats = @()
    $actualMode = $ProviderMode
    $downgradedFrom = "none"
    $searchToolInvoked = $false

    # =============================================
    # CHECK 1: Implementer agents BLOCKED
    # =============================================
    if ($AgentId -match "IMPL") {
        $caveats += "Implementer agents are NOT allowed to use search providers"
        Write-SearchInvocation -ProjectId $ProjectId -PhaseId $PhaseId -AgentId $AgentId `
            -RequestId $RequestId -Provider "glm_search" -Mode $ProviderMode `
            -QueryRaw $Query -Decision "REJECT" -Caveats $caveats
        return New-GLMEmptyResponse -RequestId $RequestId -Query $Query -Mode $ProviderMode `
            -Accepted $false -GateDecision "REJECT" -GateReason "Implementer agent not authorized" -Caveats $caveats
    }

    # =============================================
    # CHECK 2: live_api human approval
    # =============================================
    if ($ProviderMode -eq "live_api" -and (-not $UserApproval)) {
        Write-SearchInvocation -ProjectId $ProjectId -PhaseId $PhaseId -AgentId $AgentId `
            -RequestId $RequestId -Provider "glm_search" -Mode $ProviderMode `
            -QueryRaw $Query -Decision "PENDING_HUMAN" -SecretPresent $false `
            -Caveats @("live_api requires human approval ¡ª set UserApproval=true") -HumanApproval $false
        return New-GLMEmptyResponse -RequestId $RequestId -Query $Query -Mode $ProviderMode `
            -Accepted $false -GateDecision "PENDING_HUMAN" -GateReason "Human approval required for live_api" `
            -Caveats @("live_api requires human approval") -HumanApproval $false
    }

    # =============================================
    # CHECK 3: Secret presence for live_api
    # =============================================
    $secretCheck = Test-SecretPresence -EnvVarNames @("ZHIPUAI_API_KEY","GLM_API_KEY") -ProviderType "glm_search"
    if ($ProviderMode -eq "live_api" -and (-not $secretCheck.secretPresent)) {
        $actualMode = "dry_run"
        $downgradedFrom = "live_api"
        $caveats += "live_api downgraded to dry_run: API key not found (checked ZHIPUAI_API_KEY, GLM_API_KEY)"
    }

    # =============================================
    # CHECK 4: Permission Gate
    # =============================================
    $gateToolId = if ($actualMode -eq "live_api") { "TOOL-GLM-SEARCH-001" } else { "TOOL-SEARCH-ADAPTER-001" }
    $gateResult = Test-ToolPermission `
        -ProjectId $ProjectId -AgentId $AgentId -ToolId $gateToolId `
        -ProjectType "all" -IsLocalFirst $(if($actualMode -eq "live_api" -and $UserApproval){$false}else{$true}) -NetworkMode $(if($actualMode -eq "live_api"){"external_api"}else{"local_first"}) `
        -HumanApproved $UserApproval -SecretsAllowed ($actualMode -eq "live_api") `
        -FileWriteAllowed $(if($actualMode -eq "live_api"){$true}else{$false}) -CloudAllowed $false -SandboxAvailable $(if($actualMode -eq "live_api"){$true}else{$false})

    if ($gateResult.Decision -eq "REJECT") {
        # If live_api blocked by gate (external_api in local-first), downgrade
        if ($actualMode -eq "live_api") {
            $actualMode = "dry_run"
            $downgradedFrom = if ($downgradedFrom -eq "none") { "live_api" } else { $downgradedFrom }
            $caveats += "live_api blocked by gate: $($gateResult.Reason). Downgraded to dry_run."
            # Re-gate with no_network tool
            $gateResult = Test-ToolPermission `
                -ProjectId $ProjectId -AgentId $AgentId -ToolId "TOOL-SEARCH-ADAPTER-001" `
                -ProjectType "all" -IsLocalFirst $true -NetworkMode "local_first" `
                -HumanApproved $UserApproval -SecretsAllowed $false `
                -FileWriteAllowed $false -CloudAllowed $false -SandboxAvailable $false
        } else {
            $caveats += "Permission gate rejected: $($gateResult.Reason)"
            Write-SearchInvocation -ProjectId $ProjectId -PhaseId $PhaseId -AgentId $AgentId `
                -RequestId $RequestId -Provider "glm_search" -Mode $actualMode `
                -QueryRaw $Query -Decision "REJECT" -Caveats $caveats -DowngradedFrom $downgradedFrom
            return New-GLMEmptyResponse -RequestId $RequestId -Query $Query -Mode $actualMode `
                -Accepted $false -GateDecision "REJECT" -GateReason $gateResult.Reason `
                -Caveats $caveats -SecretPresent $secretCheck.secretPresent -DowngradedFrom $downgradedFrom
        }
    }

    # =============================================
    # STEP 5: Execute by mode
    # =============================================
    $normalizedResults = @()
    $sourceRefs = @()

    switch ($actualMode) {
        "manual" {
            if (-not $ManualInput) {
                $caveats += "manual_mode requires ManualInput"
                Write-SearchInvocation -ProjectId $ProjectId -PhaseId $PhaseId -AgentId $AgentId `
                    -RequestId $RequestId -Provider "glm_search" -Mode $actualMode `
                    -QueryRaw $Query -Decision "REJECT" -Caveats $caveats -DowngradedFrom $downgradedFrom
                return New-GLMEmptyResponse -RequestId $RequestId -Query $Query -Mode $actualMode `
                    -Accepted $false -GateDecision "REJECT" -GateReason "Manual input missing" `
                    -Caveats $caveats -DowngradedFrom $downgradedFrom
            }
            foreach ($link in $ManualInput.links) {
                $normalizedResults += [PSCustomObject]@{
                    title = $link.title; url = $link.url
                    snippet = if ($link.snippet) { $link.snippet } else { "" }
                    siteName = ""; publishDate = if ($link.publishDate) { $link.publishDate } else { $null }
                    sourceType = if ($link.sourceType) { $link.sourceType } else { "unknown" }
                    trustIndicator = "unknown"
                }
                $sourceRefs += [PSCustomObject]@{
                    title = $link.title; url = $link.url
                    sourceType = if ($link.sourceType) { $link.sourceType } else { "unknown" }
                    publishDate = if ($link.publishDate) { $link.publishDate } else { $null }
                }
            }
            $caveats += "manual_mode: results provided by human/external AI, not verified by Factory. No network call made."
        }

        "dry_run" {
            $mockResults = @(
                @{title="Next.js Documentation ¡ª Getting Started";url="https://nextjs.org/docs";snippet="Official Next.js documentation covering routing, rendering, data fetching, and deployment.";siteName="nextjs.org";sourceType="official_docs";trustIndicator="high"},
                @{title="Next.js 15 Release Notes";url="https://nextjs.org/blog/next-15";snippet="Next.js 15 introduces React 19 support, improved Turbopack, and partial prerendering.";siteName="nextjs.org";sourceType="official_docs";trustIndicator="high"},
                @{title="Building Production-Ready Next.js Apps ¡ª Vercel";url="https://vercel.com/guides/nextjs-production";snippet="Best practices for deploying Next.js applications to production on Vercel.";siteName="vercel.com";sourceType="blog";trustIndicator="medium"},
                @{title="Next.js GitHub Repository";url="https://github.com/vercel/next.js";snippet="The official Next.js repository with source code, issues, and discussions.";siteName="github.com";sourceType="github";trustIndicator="high"},
                @{title="Awesome Next.js ¡ª Community Curated";url="https://github.com/unicodeveloper/awesome-nextjs";snippet="A curated list of awesome Next.js resources, libraries, and tools.";siteName="github.com";sourceType="community";trustIndicator="medium"}
            )
            $idx = 0
            foreach ($mr in $mockResults) {
                if ($ResultCount -and $idx -ge $ResultCount) { break }
                $normalizedResults += [PSCustomObject]@{
                    title=$mr.title; url=$mr.url; snippet=$mr.snippet
                    siteName=$mr.siteName; publishDate="2026-07-01"
                    sourceType=$mr.sourceType; trustIndicator=$mr.trustIndicator
                }
                $sourceRefs += [PSCustomObject]@{title=$mr.title; url=$mr.url; sourceType=$mr.sourceType; publishDate="2026-07-01"}
                $idx++
            }
            $caveats += "dry_run_mode: mock/fixture results, NOT real search results. No network call made."
        }

        "live_api" {
            $caveats += "live_api_mode: attempting real API call to ZhipuAI GLM-4"
            $searchToolInvoked = $false
            try {
                $apiKey = $null
                foreach ($name in @("ZHIPUAI_API_KEY","GLM_API_KEY")) {
                    $val = [Environment]::GetEnvironmentVariable($name,"Process")
                    if ($val) { $apiKey = $val; break }
                }
                if (-not $apiKey) {
                    throw "API key not available"
                }
                $body = @{
                    model = "glm-4"
                    messages = @(
                        @{role="system";content="You MUST use web_search to search the internet. After searching, list every URL found with its title using format: URL: <url> ¡ª Title: <title>. Do NOT answer from your own knowledge without searching first."},
                        @{role="user";content=$Query}
                    )
                    tools = @(@{type="web_search";web_search=@{enable=$true;search_query=$Query}})
                    # tool_choice omitted ¡ª glm-4 auto-uses web_search when tools present
                    max_tokens = 4096; temperature = 0.1
                }
                $bodyJson = $body | ConvertTo-Json -Depth 5 -Compress
                $response = Invoke-RestMethod -Uri "https://open.bigmodel.cn/api/paas/v4/chat/completions" `
                    -Method Post -Headers @{"Authorization"="Bearer $apiKey";"Content-Type"="application/json"} `
                    -Body $bodyJson -TimeoutSec 30
                $searchToolInvoked = $false
                if ($response.choices -and $response.choices[0].message) {
                    $msg = $response.choices[0].message
                    if ($msg.tool_calls) {
                        foreach ($tc in $msg.tool_calls) {
                            if ($tc.type -eq "web_search" -and $tc.web_search) {
                                $searchToolInvoked = $true
                                foreach ($sr in $tc.web_search) {
                                    $normalizedResults += [PSCustomObject]@{
                                        title=if($sr.title){$sr.title}else{"Untitled"}
                                        url=if($sr.url){$sr.url}else{"no-url"}
                                        snippet=if($sr.snippet){$sr.snippet}else{""}
                                        siteName=if($sr.site_name){$sr.site_name}else{""}
                                        publishDate=$null; sourceType="glm_search_result"; trustIndicator="medium"
                                    }
                                    $sourceRefs += [PSCustomObject]@{title=if($sr.title){$sr.title}else{"Untitled"};url=if($sr.url){$sr.url}else{""};sourceType="glm_search_result";publishDate=$null}
                                }
                            }
                        }
                    }
                    if (-not $searchToolInvoked) {
                        # R2.3-R: Try extracting URLs from content (server-side web_search pattern)
                        $urlPattern = 'URL:\s*(https?://[^\s,\]]+)\s*[-¨C¡ª]+\s*Title:\s*(.+?)(?=URL:|$)'
                        $contentMatches = [regex]::Matches($msg.content, $urlPattern, 'Multiline')
                        if ($contentMatches.Count -gt 0) {
                            $searchToolInvoked = $true
                            foreach ($m in $contentMatches) {
                                $extractedUrl = $m.Groups[1].Value.Trim()
                                $extractedTitle = $m.Groups[2].Value.Trim()
                                $normalizedResults += [PSCustomObject]@{
                                    title=$extractedTitle
                                    url=$extractedUrl
                                    snippet=""
                                    siteName=""
                                    publishDate=$null
                                    sourceType="glm_search_result"
                                    trustIndicator="medium"
                                }
                                $sourceRefs += [PSCustomObject]@{
                                    title=$extractedTitle
                                    url=$extractedUrl
                                    sourceType="glm_search_result"
                                    publishDate=$null
                                }
                            }
                            $caveats += "web_search_invoked_server_side: extracted $($contentMatches.Count) URLs from model response (server-side search, not tool_calls)"
                        } else {
                            $caveats += "web_search_tool_not_invoked: model answered from knowledge, NOT real search results. No tool_calls and no URLs in response."
                        }
                    }
                }
                if ($searchToolInvoked) {
                    $caveats += "live_api_mode: real API call completed with web_search tool invocation (ZhipuAI GLM-4)"
                } else {
                    $caveats += "live_api_mode: API call completed but web_search tool was NOT invoked (ZhipuAI GLM-4 answered from knowledge)"
                }
            } catch {
                $caveats += "live_api_mode: API call failed ($($_.Exception.Message)). Downgraded to dry_run."
                $actualMode = "dry_run"
                # Fall back to dry_run
                $mockResults = @(@{title="Next.js Documentation";url="https://nextjs.org/docs";snippet="Official Next.js docs.";siteName="nextjs.org";sourceType="official_docs";trustIndicator="high"})
                foreach ($mr in $mockResults) {
                    $normalizedResults += [PSCustomObject]@{title=$mr.title;url=$mr.url;snippet=$mr.snippet;siteName=$mr.siteName;publishDate="2026-07-01";sourceType=$mr.sourceType;trustIndicator=$mr.trustIndicator}
                    $sourceRefs += [PSCustomObject]@{title=$mr.title;url=$mr.url;sourceType=$mr.sourceType;publishDate="2026-07-01"}
                }
            }
        }
    }

    # =============================================
    # STEP 6: Quality Gate
    # =============================================
    $qualityResult = $null
    if ($normalizedResults.Count -gt 0) {
        $fakeIntake = [PSCustomObject]@{sourceRefs=$sourceRefs;provider="glm_search";claimedFacts=@()}
        $qualityResult = Test-SearchResultQuality -IntakePacket $fakeIntake
        $caveats += "Quality gate: $($qualityResult.verdict) (score=$($qualityResult.score)/$($qualityResult.maxScore))"
    }

    # =============================================
    # STEP 7: Freshness caveat
    # =============================================
    if ($FreshnessRequirement -ne "any") {
        $caveats += "Freshness requirement: $FreshnessRequirement (not fully validated in adapter)"
    }

    # =============================================
    # STEP 8: Citation check
    # =============================================
    if ($CitationRequired -and $sourceRefs.Count -eq 0) {
        $caveats += "Citation required but no source references available"
    }

    # =============================================
    # STEP 9: Write invocation ledger
    # =============================================
    $invDecision = if ($downgradedFrom -ne "none") { "DOWNGRADED_TO_DRY_RUN" } else { "ALLOW_WITH_CONTROLS" }
    Write-SearchInvocation -ProjectId $ProjectId -PhaseId $PhaseId -AgentId $AgentId `
        -RequestId $RequestId -Provider "glm_search" -Mode $actualMode `
        -QueryRaw $Query -ResultCount $normalizedResults.Count -SourceCount $sourceRefs.Count `
        -Decision $invDecision -SecretPresent $secretCheck.secretPresent `
        -NetworkBoundary $(if($actualMode -eq "live_api"){"external_api"}else{"no_network"}) `
        -HumanApproval $UserApproval -QualityScore $(if($qualityResult){$qualityResult.score}else{0}) `
        -QualityVerdict $(if($qualityResult){$qualityResult.verdict}else{"unknown"}) `
        -DowngradedFrom $downgradedFrom -Caveats $caveats

    # =============================================
    # STEP 10: Build final response
    # =============================================
    $queryHash = $null
    if ($Query) {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $hashBytes = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Query))
        $queryHash = [System.BitConverter]::ToString($hashBytes) -replace '-',''
    }

    return [PSCustomObject]@{
        responseId = "GLM-RESP-$RequestId"; requestId = $RequestId
        provider = "glm_search"; mode = $actualMode; query = $Query; queryHash = $queryHash
        accepted = $true; gateDecision = $gateResult.Decision
        normalizedResults = $normalizedResults; sourceRefs = $sourceRefs
        resultCount = $normalizedResults.Count; sourceCount = $sourceRefs.Count
        retrievalTime = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"; caveats = $caveats
        searchToolInvoked = $searchToolInvoked
        qualityGateStatus = if ($qualityResult) { [PSCustomObject]@{passed=($qualityResult.verdict -ne "reject");score=$qualityResult.score;verdict=$qualityResult.verdict;issues=@()} } else { $null }
        secretPresent = $secretCheck.secretPresent
        networkBoundary = if ($actualMode -eq "live_api") { "external_api" } else { "no_network" }
        humanApproval = $UserApproval; downgradedFrom = $downgradedFrom
    }
}

function Convert-GLMResponseToResearchIntake {
    param([Parameter(Mandatory=$true)]$GLMResponse, [string]$SubmittedBy="RSRC-001")
    if (-not $GLMResponse.accepted) {
        return [PSCustomObject]@{intakeId="INTAKE-$(Get-Date -Format 'yyyyMMdd')-REJECTED";accepted=$false;reason="GLM response not accepted"}
    }
    $links = @()
    foreach ($sr in $GLMResponse.sourceRefs) {
        $links += [PSCustomObject]@{url=$sr.url;title=$sr.title;type=if($sr.sourceType -eq "official_docs"){"official_docs"}elseif($sr.sourceType -eq "github"){"github"}elseif($sr.sourceType -eq "blog"){"blog"}else{"other"};relevance="medium"}
    }
    return [PSCustomObject]@{
        intakeId="INTAKE-$(Get-Date -Format 'yyyyMMdd')-$(Get-Random -Minimum 100 -Maximum 999)"
        query=[PSCustomObject]@{question=$GLMResponse.query;searchMode="knowledge_reserve";domain="general";context="GLM Search Adapter ¡ª R2.3-N";requestedBy=$SubmittedBy;versionConstraints=""}
        provider=[PSCustomObject]@{providerId="glm-search-adapter";type="glm_search";capability="Web search via ZhipuAI GLM-4";strengths=@("Real-time web search","Structured results","Domain filtering");weaknesses=@("Requires API key","Results may be incomplete");freshness="real-time";citationRequirement="always";trustLimit="AVAILABLE";canBeDirectSource=$false}
        rawResult=($GLMResponse.normalizedResults | ConvertTo-Json -Depth 3 -Compress)
        links=$links;sourceTitles=($GLMResponse.sourceRefs|%{$_.title});publishDates=($GLMResponse.sourceRefs|%{$_.publishDate}|?{$_})
        claimedFacts=@();codeSnippets=@()
        uncertainty=if($GLMResponse.mode -eq "dry_run"){"high"}elseif($GLMResponse.mode -eq "manual"){"medium"}else{"medium"}
        providerConfidence="medium";userNotes="Generated by GLM Search Adapter in $($GLMResponse.mode) mode."
        submittedAt=Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz";submittedBy=$SubmittedBy
    }
}

Write-Verbose "GLM Search Adapter v2 loaded. Modes: manual | dry_run | live_api"
