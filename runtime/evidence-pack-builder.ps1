# Evidence Pack Builder
# Part of: FACTORY-R2.3-O
# Builds standardized Evidence Pack from search results + quality gate + research intake

. (Join-Path $PSScriptRoot "glm-search-adapter.ps1")
. (Join-Path $PSScriptRoot "search-result-quality-gate.ps1")

# The integrity hash deliberately excludes contentHash/contentHashAlgorithm.  Both
# the builder and the pre-build gate use this exact canonical projection so a
# saved pack can be checked after it crosses a process/context boundary.
function Get-EvidencePackIntegrityHash {
    param([Parameter(Mandatory=$true)]$EvidencePack)

    $canonicalSources = @()
    foreach ($source in @(@($EvidencePack.sources) | Where-Object { $null -ne $_ })) {
        $canonicalSources += [ordered]@{
            title = [string]$source.title
            url = [string]$source.url
            sourceType = [string]$source.sourceType
            sourceOrigin = [string]$source.sourceOrigin
            authority = [string]$source.authority
            freshness = [string]$source.freshness
            publishedAt = [string]$source.publishedAt
            retrievedAt = [string]$source.retrievedAt
            claimSupported = [string]$source.claimSupported
            evidenceExcerpt = [string]$source.evidenceExcerpt
            uncertainty = [string]$source.uncertainty
        }
    }

    $quality = $EvidencePack.qualityGateStatus
    $canonical = [ordered]@{
        evidenceId = [string]$EvidencePack.evidenceId
        task = [string]$EvidencePack.task
        projectId = [string]$EvidencePack.projectId
        phaseId = [string]$EvidencePack.phaseId
        searchRound = [int]$EvidencePack.searchRound
        queryTime = [string]$EvidencePack.queryTime
        triggerReason = [string]$EvidencePack.triggerReason
        provider = [string]$EvidencePack.provider
        mode = [string]$EvidencePack.mode
        accepted = ($EvidencePack.accepted -eq $true)
        rejectionReason = [string]$EvidencePack.rejectionReason
        sources = $canonicalSources
        sourceCount = [int]$EvidencePack.sourceCount
        qualityGateStatus = [ordered]@{
            passed = ($quality.passed -eq $true)
            score = [int]$quality.score
            verdict = [string]$quality.verdict
            trustRecommendation = [string]$quality.trustRecommendation
            fatalRejections = @(@($quality.fatalRejections) | Where-Object { $null -ne $_ -and [string]$_ -ne "" } | ForEach-Object { [string]$_ })
            warnings = @(@($quality.warnings) | Where-Object { $null -ne $_ -and [string]$_ -ne "" } | ForEach-Object { [string]$_ })
        }
        allowedNextActions = @(@($EvidencePack.allowedNextActions) | Where-Object { $null -ne $_ -and [string]$_ -ne "" } | ForEach-Object { [string]$_ })
        forbiddenUse = @(@($EvidencePack.forbiddenUse) | Where-Object { $null -ne $_ -and [string]$_ -ne "" } | ForEach-Object { [string]$_ })
        usableByAgents = @(@($EvidencePack.usableByAgents) | Where-Object { $null -ne $_ -and [string]$_ -ne "" } | ForEach-Object { [string]$_ })
        notUsableByAgents = @(@($EvidencePack.notUsableByAgents) | Where-Object { $null -ne $_ -and [string]$_ -ne "" } | ForEach-Object { [string]$_ })
        conflictsDetected = ($EvidencePack.conflictsDetected -eq $true)
        deltaFromPreviousRound = [string]$EvidencePack.deltaFromPreviousRound
        roundHistory = @(@($EvidencePack.roundHistory) | Where-Object { $null -ne $_ -and [string]$_ -ne "" } | ForEach-Object { [string]$_ })
        secretPresent = ($EvidencePack.secretPresent -eq $true)
        humanApproval = ($EvidencePack.humanApproval -eq $true)
    }

    $json = $canonical | ConvertTo-Json -Depth 12 -Compress
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        return ([System.BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function ConvertTo-EvidenceSourceType {
    param([string]$SourceType)
    if ($SourceType -in @("official_docs", "official_documentation", "official_SDK_repo", "official_example")) { return "official_doc" }
    if ($SourceType -match "(?i)github") { return "github_issue" }
    if ($SourceType -in @("blog", "community", "community_tutorial", "tech_blog", "personal_blog")) { return "community_blog" }
    if ($SourceType -in @("ai_generated", "AI_generated_summary")) { return "ai_generated" }
    return "unknown"
}

function ConvertTo-QualitySourceType {
    param([string]$SourceType)
    if ($SourceType -in @("official_docs", "official_documentation")) { return "official_documentation" }
    if ($SourceType -in @("official_SDK_repo", "official_example")) { return $SourceType }
    if ($SourceType -match "(?i)github") { return "mainstream_open_source_repo" }
    if ($SourceType -in @("blog", "tech_blog")) { return "tech_blog" }
    if ($SourceType -in @("community", "community_tutorial")) { return "community_tutorial" }
    if ($SourceType -in @("ai_generated", "AI_generated_summary")) { return "AI_generated_summary" }
    return "other"
}

function New-EvidencePack {
    param(
        [Parameter(Mandatory=$true)][string]$Task,
        [Parameter(Mandatory=$true)][string]$ProjectId,
        [string]$PhaseId = "implementation",
        [int]$SearchRound = 1,
        [Parameter(Mandatory=$true)][string]$TriggerReason,
        [Parameter(Mandatory=$true)]$GLMResponse,
        [string[]]$AllowedAgents = @("RSRC-001","LIB-001","ARCH-001","VER-001","IMPL-FE-001","IMPL-BE-001"),
        [string[]]$ForbiddenAgents = @(),
        [string]$PreviousEvidenceId = "",
        [string[]]$PreviousEvidenceIds = @()
    )

    if ($GLMResponse.accepted -ne $true) {
        $rejectedPack = [PSCustomObject]@{
            evidenceId = "EVID-$(Get-Date -Format 'yyyyMMdd')-REJECTED"
            task = $Task; projectId = $ProjectId; phaseId = $PhaseId
            searchRound = $SearchRound; queryTime = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
            triggerReason = $TriggerReason; provider = $GLMResponse.provider
            mode = $GLMResponse.mode; accepted = $false
            rejectionReason = $GLMResponse.gateReason
            sources = @(); sourceCount = 0; qualityGateStatus = $null
            allowedNextActions = @("resubmit_search")
            forbiddenUse = @("do_not_use_for_implementation")
            usableByAgents = @(); notUsableByAgents = @("ALL")
            conflictsDetected = $false
            deltaFromPreviousRound = "no_results"
            roundHistory = $PreviousEvidenceIds
        }
        $rejectedPack | Add-Member -NotePropertyName contentHashAlgorithm -NotePropertyValue "SHA256"
        $rejectedPack | Add-Member -NotePropertyName contentHash -NotePropertyValue (Get-EvidencePackIntegrityHash -EvidencePack $rejectedPack)
        return $rejectedPack
    }

    # Build canonical intake sources and legacy Evidence Pack sources from the
    # same records.  Missing origin/content is never silently promoted to real
    # provider evidence.
    $sources = @()
    $intakeSources = @()
    $normalizedByUrl = @{}
    foreach ($normalized in @($GLMResponse.normalizedResults)) {
        if ($normalized.url) { $normalizedByUrl[[string]$normalized.url] = $normalized }
    }
    $caveatText = (@($GLMResponse.caveats) -join " ")
    foreach ($sr in $GLMResponse.sourceRefs) {
        $normalized = if ($sr.url -and $normalizedByUrl.ContainsKey([string]$sr.url)) { $normalizedByUrl[[string]$sr.url] } else { $null }
        $snippet = if ($sr.snippet) { [string]$sr.snippet }
                   elseif ($sr.description) { [string]$sr.description }
                   elseif ($sr.content) { [string]$sr.content }
                   elseif ($normalized -and $normalized.snippet) { [string]$normalized.snippet }
                   else { "" }
        $sourceOrigin = if ($sr.source_origin) { [string]$sr.source_origin }
                        elseif ($caveatText -match "(?i)(model[_ -]?text[_ -]?extraction|extracted.+model response|server[_ -]?side.+extracted)") { "model_text_extraction" }
                        elseif ($GLMResponse.mode -eq "live_api" -and $GLMResponse.searchToolInvoked -eq $true) { "provider_search_result" }
                        else { "unknown" }
        $qualitySourceType = ConvertTo-QualitySourceType -SourceType ([string]$sr.sourceType)
        $sourceTier = if ($sr.source_tier) { [string]$sr.source_tier }
                      elseif ($qualitySourceType -in @("official_documentation", "official_SDK_repo", "official_example")) { "tier_1_gold" }
                      elseif ($qualitySourceType -eq "mainstream_open_source_repo") { "tier_2_silver" }
                      else { "tier_4_supplement" }
        $freshnessNote = if ($sr.freshness_note) { [string]$sr.freshness_note }
                         elseif ($sr.publishDate) { "published $($sr.publishDate)" }
                         else { "" }

        $intakeSources += [PSCustomObject]@{
            title = [string]$sr.title
            url = [string]$sr.url
            snippet = $snippet
            source_origin = $sourceOrigin
            source_type = $qualitySourceType
            source_tier = $sourceTier
            source_language = if ($sr.source_language) { [string]$sr.source_language } else { "other" }
            freshness_note = $freshnessNote
        }

        $freshness = "unknown"
        if ($sr.publishDate) {
            try {
                $days = ((Get-Date) - [datetime]::Parse([string]$sr.publishDate)).Days
                $freshness = if ($days -le 30) { "current" } elseif ($days -le 180) { "recent" } else { "stale" }
            }
            catch { $freshness = "unknown" }
        }
        $sources += [PSCustomObject]@{
            title = $sr.title
            url = $sr.url
            sourceType = ConvertTo-EvidenceSourceType -SourceType ([string]$sr.sourceType)
            sourceOrigin = $sourceOrigin
            authority = if ($qualitySourceType -in @("official_documentation", "official_SDK_repo", "official_example", "mainstream_open_source_repo")) { "high" }
                        elseif ($sr.sourceType -eq "blog") { "medium" }
                        elseif ($sr.sourceType -eq "community") { "low" }
                        else { "unknown" }
            freshness = $freshness
            publishedAt = if ($sr.publishDate) { [string]$sr.publishDate } else { "" }
            retrievedAt = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
            claimSupported = $Task
            evidenceExcerpt = $snippet
            uncertainty = if ($GLMResponse.mode -eq "dry_run") { "high" } elseif ($GLMResponse.mode -eq "manual") { "medium" } else { "low" }
        }
    }

    # Quality gate.  The v5 gate requires an Evidence Pack-shaped context; pass
    # a provisional v2 projection instead of null (which is always FAIL_FATAL).
    $fakeIntake = [PSCustomObject]@{sourceRefs=$intakeSources;provider=$GLMResponse.provider;claimedFacts=@()}
    $searchInvokedFlag = ($GLMResponse.searchToolInvoked -eq $true)
    $actualModeFlag = if ($GLMResponse.mode) { $GLMResponse.mode } else { "dry_run" }
    $officialCount = @($intakeSources | Where-Object { $_.source_tier -eq "tier_1_gold" }).Count
    $communityCount = @($intakeSources | Where-Object { $_.source_type -in @("community_tutorial", "tech_blog", "personal_blog") }).Count
    $provisionalEvidence = [PSCustomObject]@{
        phase = $PhaseId
        mode = $actualModeFlag
        provider = [string]$GLMResponse.provider
        search_invoked = $searchInvokedFlag
        query = if ($GLMResponse.query) { [string]$GLMResponse.query } else { $Task }
        query_intents = @("official_api_check", "best_practice", "risk_pattern")
        runtime_timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
        sources = $intakeSources
        source_type_counts = [PSCustomObject]@{official=$officialCount;community=$communityCount;article=0;issue=0;other=($intakeSources.Count-$officialCount-$communityCount)}
        confidence_level = "medium"
        security_critical = $false
        downstream_readonly_result = "readonly"
    }
    $quality = Test-SearchResultQuality -IntakePacket $fakeIntake -SearchInvoked $searchInvokedFlag -ActualMode $actualModeFlag -EvidencePack $provisionalEvidence

    $acceptedVerdicts = @("PASS_CLEAN", "PASS_WITH_WARNINGS", "PASS_WITH_CAVEATS", "high_quality", "acceptable")
    $qualityAccepted = ($quality.passed -eq $true -and [string]$quality.verdict -in $acceptedVerdicts)
    $trustRecommendation = if (-not $qualityAccepted) { "do_not_use" }
                           elseif ($quality.verdict -in @("PASS_CLEAN", "high_quality")) { "trusted_reference" }
                           elseif ($quality.verdict -eq "PASS_WITH_CAVEATS") { "needs_human_review" }
                           else { "reference_only" }

    # Determine allowed next actions
    $nextActions = if ($qualityAccepted) { @("read_reference", "bind_to_pre_build_research_gate") } else { @("resubmit_search", "review_quality_gate_failures") }
    if ($qualityAccepted -and $quality.verdict -in @("PASS_CLEAN", "PASS_WITH_WARNINGS", "high_quality", "acceptable")) {
        $nextActions += "use_as_reference"
    }

    $forbidden = @("do_not_enter_skill_registry_directly","do_not_treat_as_verified_knowledge","do_not_use_for_implementation_without_research_gate")
    if ($trustRecommendation -eq "needs_human_review") {
        $forbidden += "do_not_use_without_human_review"
    }
    if (-not $qualityAccepted) {
        $forbidden += @("do_not_use_for_implementation", "quality_gate_failed")
    }
    if ($GLMResponse.mode -eq "dry_run") {
        $forbidden += "dry_run_results_not_production_data"
    }

    # Build delta from previous
    $delta = ""
    if ($PreviousEvidenceIds.Count -gt 0) {
        $delta = "round {0}: {1} new sources, trigger: {2}" -f $SearchRound, $sources.Count, $TriggerReason
    }

    $evidenceId = "EVID-$(Get-Date -Format 'yyyyMMdd')-$(Get-Random -Minimum 100 -Maximum 999)"

    $pack = [PSCustomObject]@{
        evidenceId = $evidenceId
        task = $Task; projectId = $ProjectId; phaseId = $PhaseId
        searchRound = $SearchRound
        queryTime = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
        triggerReason = $TriggerReason
        provider = $GLMResponse.provider
        mode = $GLMResponse.mode
        accepted = $qualityAccepted
        rejectionReason = if ($qualityAccepted) { "" } else { "QUALITY_GATE_$([string]$quality.verdict)" }
        sources = $sources
        sourceCount = $sources.Count
        qualityGateStatus = [PSCustomObject]@{
            passed = $qualityAccepted
            score = $quality.score
            verdict = $quality.verdict
            trustRecommendation = $trustRecommendation
            fatalRejections = @($quality.fatalRejections)
            warnings = @($quality.warnings)
        }
        allowedNextActions = $nextActions
        forbiddenUse = $forbidden
        usableByAgents = if ($qualityAccepted) { $AllowedAgents } else { @() }
        notUsableByAgents = if ($qualityAccepted) { $ForbiddenAgents } else { @("ALL") }
        conflictsDetected = (@($quality.issues) -contains "DUPLICATES" -or @($quality.issues) -contains "AI_ONLY")
        deltaFromPreviousRound = $delta
        roundHistory = $PreviousEvidenceIds
        secretPresent = $GLMResponse.secretPresent
        humanApproval = $GLMResponse.humanApproval
    }
    $pack | Add-Member -NotePropertyName contentHashAlgorithm -NotePropertyValue "SHA256"
    $pack | Add-Member -NotePropertyName contentHash -NotePropertyValue (Get-EvidencePackIntegrityHash -EvidencePack $pack)
    return $pack
}

Write-Verbose "Evidence Pack Builder loaded."
