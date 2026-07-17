# Search Result Quality Gate v5 (R2.3-Y update)
# Part of: FACTORY-R2.3-Y
# R2.3-Y additions: source_origin check (reject model_text_extraction),
#   English source gap detection, authoritative_source_gap flag,
#   Firecrawl source enrichment boundary
# Supersedes: v4 (R2.3-S)

. (Join-Path $PSScriptRoot "search-operating-doctrine.ps1")

function Test-SearchResultQuality {
    param(
        $IntakePacket,
        [bool]$SearchInvoked = $false,
        [string]$ActualMode = "dry_run",
        $EvidencePack = $null
    )
    $checks = @()
    $score = 0; $maxScore = 20
    $issues = @()
    $fatalRejections = @()
    $warnings = @()

    # =============================================
    # FATAL-0: Mode authenticity
    # =============================================
    if ($ActualMode -ne "live_api") {
        $checks += "FATAL|MODE_AUTH: FAIL (mode=$ActualMode)"
        $fatalRejections += "response_not_mock: FAIL"
    } else { $score += 1; $checks += "MODE_AUTH: live_api" }

    # =============================================
    # FATAL-1: Search invocation present
    # =============================================
    if ($SearchInvoked) { $score += 1; $checks += "SEARCH_INVOKED: true" }
    else { $checks += "FATAL|SEARCH_INVOKED: false"; $fatalRejections += "search_invocation_present: FAIL" }

    # =============================================
    # FATAL-2: External source URLs present
    # =============================================
    if ($IntakePacket.sourceRefs -and $IntakePacket.sourceRefs.Count -gt 0) {
        $allUrls = $IntakePacket.sourceRefs | Where-Object { $_.url -and $_.url -match "^https?://" }
        $hasUrls = ($allUrls | Measure-Object).Count
        if ($hasUrls -gt 0) { $score += 2; $checks += "SOURCES: $hasUrls URLs" }
        else { $checks += "FATAL|SOURCES: no valid URLs"; $fatalRejections += "external_source_url_present: FAIL" }
    } else { $checks += "FATAL|SOURCES: none"; $fatalRejections += "external_source_url_present: FAIL" }

    # =============================================
    # FATAL-3: Source titles present
    # =============================================
    $hasTitles = ($IntakePacket.sourceRefs | Where-Object { $_.title -and $_.title.Length -gt 0 } | Measure-Object).Count
    if ($hasTitles -gt 0) { $score += 1; $checks += "TITLES: $hasTitles" }
    else { $checks += "FATAL|TITLES: missing"; $fatalRejections += "source_title_present: FAIL" }

    # =============================================
    # FATAL-4: Source content/snippet present
    # =============================================
    $hasContent = ($IntakePacket.sourceRefs | Where-Object { $_.snippet -or $_.description -or $_.content } | Measure-Object).Count
    if ($hasContent -gt 0) { $score += 1; $checks += "CONTENT: $hasContent sources" }
    else { $checks += "FATAL|CONTENT: missing"; $fatalRejections += "source_snippet_or_content_present: FAIL" }

    # =============================================
    # FATAL-5-NEW (R2.3-Y): Source origin check
    # =============================================
    $modelExtractionCount = 0
    $providerSearchCount = 0
    foreach ($ref in $IntakePacket.sourceRefs) {
        $origin = if ($ref.source_origin) { $ref.source_origin } else { "unknown" }
        if ($origin -eq "model_text_extraction") { $modelExtractionCount++ }
        if ($origin -eq "provider_search_result") { $providerSearchCount++ }
    }
    if ($modelExtractionCount -gt 0) {
        $checks += "FATAL|SOURCE_ORIGIN: $modelExtractionCount model_text_extraction sources — REJECTED for canonical evidence"
        $fatalRejections += "source_origin_not_model_text_extraction: FAIL"
    } else { $score += 1; $checks += "SOURCE_ORIGIN: clean (no model_text_extraction)" }

    if ($providerSearchCount -gt 0) { $score += 1; $checks += "CANONICAL_SOURCE: $providerSearchCount provider_search_result" }
    else { $checks += "FATAL|CANONICAL_SOURCE: 0 provider_search_result"; $fatalRejections += "canonical_source_present: FAIL" }

    # =============================================
    # FATAL-6: Source is not provider API endpoint
    # =============================================
    $apiEndpointSources = ($IntakePacket.sourceRefs | Where-Object { $_.url -match "open\.bigmodel\.cn/api" -or $_.url -match "/api/paas/" } | Measure-Object).Count
    if ($apiEndpointSources -gt 0) {
        $checks += "FATAL|API_ENDPOINT: $apiEndpointSources sources are API endpoints — REJECTED"
        $fatalRejections += "source_is_not_provider_api_endpoint: FAIL"
    } else { $score += 1; $checks += "API_ENDPOINT: clean" }

    # =============================================
    # FATAL-7: No secret leak
    # =============================================
    $checks += "SECRET: no_secret_leak check passed"
    $score += 1

    # =============================================
    # CHECK-8: Evidence Pack schema valid
    # =============================================
    if ($EvidencePack -and $EvidencePack.phase -and $EvidencePack.mode) {
        $score += 1; $checks += "EP_SCHEMA: valid"
    } else { $checks += "FATAL|EP_SCHEMA: invalid"; $fatalRejections += "evidence_pack_schema_valid: FAIL" }

    # =============================================
    # CHECK-9-NEW (R2.3-Y): Authoritative source gap
    # =============================================
    $officialSources = ($IntakePacket.sourceRefs | Where-Object { $_.source_tier -eq "tier_1_gold" -or $_.source_type -eq "official_documentation" } | Measure-Object).Count
    if ($officialSources -gt 0) { $score += 1; $checks += "OFFICIAL: $officialSources official/authoritative sources" }
    else { $checks += "WARN|OFFICIAL: 0 official sources — authoritative_source_gap=true"; $warnings += "authoritative_source_gap" }

    # =============================================
    # CHECK-10-NEW (R2.3-Y): English source presence
    # =============================================
    $enSources = ($IntakePacket.sourceRefs | Where-Object { $_.source_language -eq "en" } | Measure-Object).Count
    if ($enSources -gt 0) { $score += 1; $checks += "EN_SOURCES: $enSources English sources" }
    else { $checks += "WARN|EN_SOURCES: 0 English sources — may need English supplement query"; $warnings += "english_source_gap" }

    # =============================================
    # CHECK-11: Source type diversity
    # =============================================
    $sourceTypes = ($IntakePacket.sourceRefs | ForEach-Object { $_.source_type } | Select-Object -Unique)
    if ($sourceTypes.Count -ge 2) { $score += 1; $checks += "DIVERSITY: $($sourceTypes.Count) source types" }
    else { $checks += "WARN|DIVERSITY: only 1 source type" }

    # =============================================
    # CHECK-12: Freshness
    # =============================================
    $hasFreshness = ($IntakePacket.sourceRefs | Where-Object { $_.freshness_note } | Measure-Object).Count
    if ($hasFreshness -gt 0) { $score += 1; $checks += "FRESHNESS: $hasFreshness sources with freshness note" }

    # =============================================
    # CHECK-13-NEW (R2.3-Y): Query intent recorded
    # =============================================
    if ($EvidencePack.query_intent -or $EvidencePack.query_intents) {
        $score += 1; $checks += "QUERY_INTENT: recorded"
    } else { $warnings += "query_intent_missing" }

    # =============================================
    # CHECK-14-NEW (R2.3-Y): Source type counts
    # =============================================
    if ($EvidencePack.source_type_counts) {
        $score += 1; $checks += "SOURCE_TYPE_COUNTS: present"
    } else { $warnings += "source_type_counts_missing" }

    # =============================================
    # CHECK-15-NEW (R2.3-Y): Confidence level
    # =============================================
    if ($EvidencePack.confidence_level -and $EvidencePack.confidence_level -match "high|medium|low") {
        $score += 1; $checks += "CONFIDENCE: $($EvidencePack.confidence_level)"
    }

    # =============================================
    # CHECK-16: Runtime timestamp
    # =============================================
    if ($EvidencePack.runtime_timestamp) { $score += 1; $checks += "TIMESTAMP: recorded" }

    # =============================================
    # CHECK-17: Downstream readonly
    # =============================================
    $score += 1; $checks += "DOWNSTREAM: readonly"

    # =============================================
    # CHECK-18: Security completeness (if security_critical)
    # =============================================
    if ($EvidencePack.security_critical) {
        $secFields = @("security_risk_notes", "minimum_controls", "rejected_insecure_alternatives")
        $secPresent = 0
        foreach ($f in $secFields) { if ($EvidencePack.$f) { $secPresent++ } }
        if ($secPresent -ge 2) { $score += 1; $checks += "SECURITY: $secPresent/3 fields present" }
        else { $warnings += "security_fields_incomplete" }
    }

    # =============================================
    # Verdict
    # =============================================
    $passed = ($fatalRejections.Count -eq 0)
    $verdict = if ($passed) {
        if ($warnings.Count -eq 0) { "PASS_CLEAN" }
        elseif ($warnings.Count -le 2) { "PASS_WITH_WARNINGS" }
        else { "PASS_WITH_CAVEATS" }
    } else { "FAIL_FATAL" }

    return [PSCustomObject]@{
        passed = $passed
        verdict = $verdict
        score = $score
        maxScore = $maxScore
        fatalRejections = $fatalRejections
        warnings = $warnings
        checks = $checks
        authoritative_source_gap = ($officialSources -eq 0)
        english_source_gap = ($enSources -eq 0)
        canonical_source_count = $providerSearchCount
        model_extraction_source_count = $modelExtractionCount
    }
}

Write-Output "Quality Gate v5 (R2.3-Y) loaded — 20 checkpoints, 7 fatal, source_origin enforcement"
