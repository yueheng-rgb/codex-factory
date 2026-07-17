# Evidence Pack Builder
# Part of: FACTORY-R2.3-O
# Builds standardized Evidence Pack from search results + quality gate + research intake

. (Join-Path $PSScriptRoot "glm-search-adapter.ps1")
. (Join-Path $PSScriptRoot "search-result-quality-gate.ps1")

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

    if (-not $GLMResponse.accepted) {
        return [PSCustomObject]@{
            evidenceId = "EVID-$(Get-Date -Format 'yyyyMMdd')-REJECTED"
            task = $Task; projectId = $ProjectId; phaseId = $PhaseId
            searchRound = $SearchRound; queryTime = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
            triggerReason = $TriggerReason; provider = $GLMResponse.provider
            mode = $GLMResponse.mode; accepted = $false
            rejectionReason = $GLMResponse.gateReason
            sources = @(); qualityGateStatus = $null
            allowedNextActions = @("resubmit_search")
            forbiddenUse = @("do_not_use_for_implementation")
            usableByAgents = @(); notUsableByAgents = @("ALL")
            conflictsDetected = $false
            deltaFromPreviousRound = "no_results"
            roundHistory = $PreviousEvidenceIds
        }
    }

    # Build sources from GLM response
    $sources = @()
    foreach ($sr in $GLMResponse.sourceRefs) {
        $sources += [PSCustomObject]@{
            title = $sr.title
            url = $sr.url
            sourceType = if ($sr.sourceType -eq "official_docs") { "official_doc" }
                         elseif ($sr.sourceType -match "github") { "github_issue" }
                         elseif ($sr.sourceType -eq "blog") { "community_blog" }
                         elseif ($sr.sourceType -eq "community") { "community_blog" }
                         elseif ($sr.sourceType -eq "ai_generated") { "ai_generated" }
                         else { "unknown" }
            authority = if ($sr.sourceType -eq "official_docs" -or $sr.sourceType -match "github") { "high" }
                        elseif ($sr.sourceType -eq "blog") { "medium" }
                        elseif ($sr.sourceType -eq "community") { "low" }
                        else { "unknown" }
            freshness = if ($sr.publishDate) {
                $days = ((Get-Date) - [datetime]::Parse($sr.publishDate)).Days
                if ($days -le 30) { "current" } elseif ($days -le 180) { "recent" } else { "stale" }
            } else { "unknown" }
            retrievedAt = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
            claimSupported = $Task
            evidenceExcerpt = ""
            uncertainty = if ($GLMResponse.mode -eq "dry_run") { "high" } elseif ($GLMResponse.mode -eq "manual") { "medium" } else { "low" }
        }
    }

    # Quality gate (R2.3-R: pass search invocation context)
    $fakeIntake = [PSCustomObject]@{sourceRefs=$GLMResponse.sourceRefs;provider=$GLMResponse.provider;claimedFacts=@()}
    $searchInvokedFlag = if ($GLMResponse.searchToolInvoked) { $GLMResponse.searchToolInvoked } else { $false }
    $actualModeFlag = if ($GLMResponse.mode) { $GLMResponse.mode } else { "dry_run" }
    $quality = Test-SearchResultQuality -IntakePacket $fakeIntake -SearchInvoked $searchInvokedFlag -ActualMode $actualModeFlag

    # Determine allowed next actions
    $nextActions = @("read_reference")
    if ($quality.verdict -eq "high_quality" -and $quality.trustRecommendation -eq "trusted_reference") {
        $nextActions += @("use_in_implementation","use_in_contracts")
    } elseif ($quality.verdict -in @("high_quality","acceptable") -and $quality.trustRecommendation -ne "do_not_use") {
        $nextActions += "use_as_reference"
    }

    $forbidden = @("do_not_enter_skill_registry_directly","do_not_treat_as_verified_knowledge")
    if ($quality.trustRecommendation -eq "needs_human_review") {
        $forbidden += "do_not_use_without_human_review"
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

    return [PSCustomObject]@{
        evidenceId = $evidenceId
        task = $Task; projectId = $ProjectId; phaseId = $PhaseId
        searchRound = $SearchRound
        queryTime = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
        triggerReason = $TriggerReason
        provider = $GLMResponse.provider
        mode = $GLMResponse.mode
        accepted = $true
        sources = $sources
        sourceCount = $sources.Count
        qualityGateStatus = [PSCustomObject]@{
            passed = ($quality.verdict -ne "reject")
            score = $quality.score
            verdict = $quality.verdict
            trustRecommendation = $quality.trustRecommendation
        }
        allowedNextActions = $nextActions
        forbiddenUse = $forbidden
        usableByAgents = $AllowedAgents
        notUsableByAgents = $ForbiddenAgents
        conflictsDetected = ($quality.issues -contains "DUPLICATES" -or $quality.issues -contains "AI_ONLY")
        deltaFromPreviousRound = $delta
        roundHistory = $PreviousEvidenceIds
        secretPresent = $GLMResponse.secretPresent
        humanApproval = $GLMResponse.humanApproval
    }
}

Write-Verbose "Evidence Pack Builder loaded."
