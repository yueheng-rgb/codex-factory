# Pre-Build Research Gate v2.0.3
# Part of: FACTORY-R2.8
# R2.6: +API_PATTERN_DESIGN
# R2.8: +USER_INPUT_VALIDATION_DESIGN, regex fixes for space matching
# Architecture: need_search -> Pre-Build Research Gate -> Provider Selector -> /web_search -> Quality Gate -> Research Intake -> Evidence Pack -> Agents

. (Join-Path $PSScriptRoot "need-search-detector.ps1")
. (Join-Path $PSScriptRoot "search-operating-doctrine.ps1")

function Invoke-PreBuildResearchGate {
    param(
        [Parameter(Mandatory=$true)][string]$TaskDescription,
        [string]$ProjectType = "fullstack-admin",
        [string]$PhaseId = "implementation",
        [string]$AgentId = "RSRC-001",
        [string]$ExistingEvidencePackId = "",
        [hashtable]$Context = @{}
    )

    $result = [PSCustomObject]@{
        search_level = ""; reason = ""; security_critical = $false
        search_required = $false; skip_justification = ""
        research_questions = @(); query_intents = @(); expected_evidence = @()
        evidence_pack_required = $false; implementer_allowed_to_search = $false
        budget = @{}; stop_conditions_met = @(); fatal_violations = @(); gate_passed = $true
    }

    # INVARIANT: Implementer block
    if ($AgentId -match "IMPL") {
        $result.search_level = "REJECT"; $result.reason = "IMPLEMENTER_DIRECT_SEARCH_FORBIDDEN"
        $result.gate_passed = $false; $result.fatal_violations += "IMPLEMENTER_SEARCH_ATTEMPT"
        return $result
    }

    # P2 Early Exit: Pure style/text tasks
    if ($TaskDescription -match '(?i)(fix.padding|adjust.margin|CSS.fix|style.fix|formatting.only|font.size.only|typo.fix|wording.fix|copy.update.only|button.style|icon.change|change.color.of)') {
        $result.search_level = "P2_NO_SEARCH_REQUIRED"; $result.reason = "P2: Pure style/text task"
        return $result
    }

    # Broader P2 check: P2 keywords without P0 action keywords
    $hasP2Keywords = $TaskDescription -match '(?i)(fix.padding|change.color|adjust.margin|CSS.fix|style.fix|formatting|spacing|typo|wording|copy.update)'
    $hasP0ActionKeywords = $TaskDescription -match '(?i)\b(add|implement|design|create|integrate|build|develop|upgrade|migrate|refactor.major|architect|new.module|new.feature)\b'
    if ($hasP2Keywords -and -not $hasP0ActionKeywords) {
        $result.search_level = "P2_NO_SEARCH_REQUIRED"; $result.reason = "P2: Style/text task without implementation action"
        return $result
    }

    # Security-Critical Detection
    $securityPatterns = @("login|auth|JWT|refresh.token|session|OAuth|SSO","RBAC|permission|access.control","password|credential|secret|API.key","file.upload|multipart|mime.type","CORS|CSRF|XSS|sanitiz|injection","rate.limit|throttle|idempot","logout|revok|invalidat")
    $securityCritical = $false
    foreach ($pat in $securityPatterns) { if ($TaskDescription -match "(?i)($pat)") { $securityCritical = $true; break } }
    $result.security_critical = $securityCritical

    $p0Score = 0; $p0Reasons = @()
    $p1Score = 0; $p1Reasons = @()

    # P0-1: Security Critical
    if ($securityCritical) { $p0Score += 10; $p0Reasons += "SECURITY_CRITICAL" }

    # P0-2: External Dependency
    if ($TaskDescription -match '(?i)(new.package|new.SDK|integrate|plugin|middleware|library|npm.install)') { $p0Score += 5; $p0Reasons += "EXTERNAL_DEPENDENCY" }

    # P0-3: Architecture Decision
    if ($TaskDescription -match '(?i)(new.project|scaffold|architecture|database.schema|design|deployment|CI/CD|docker|scalab)') { $p0Score += 4; $p0Reasons += "ARCHITECTURE_DECISION" }

    # P0-4: Uncertainty
    if ($TaskDescription -match '(?i)(UNSURE|uncertain|which.way|best.practice|mainstream|recommend|official|standard)') { $p0Score += 3; $p0Reasons += "UNCERTAINTY" }

    # P0-5: High Rework Risk
    if ($TaskDescription -match '(?i)(rewrite|rework|wrong.approach|breaking.change|migration|upgrade)') { $p0Score += 3; $p0Reasons += "HIGH_REWORK_RISK" }

    # P0-6 (R2.6): API_PATTERN_DESIGN
    if ($TaskDescription -match '(?i)(cursor.pagination|offset.pagination|pagina|filter.API|sorting.API|search.query.design|list.endpoint|API.response.metadata|API.contract|database.query.pattern|index.sensitive.query|public.API|reusable.API)') {
        $p0Score += 4; $p0Reasons += "API_PATTERN_DESIGN"
    }

    # P0-7 (R2.8): USER_INPUT_VALIDATION_DESIGN
    $inputValidationMatch = $TaskDescription -match '(?i)(input[.\s-]?validation|request[.\s-]?body[.\s-]?validation|required[.\s-]?fields?|type[.\s-]?checking|field[.\s-]?(whitelist|allowlist)|user[.\s-]?(input|controlled)|validation[.\s-]?error|request[.\s-]?sanitiz|boundary[.\s-]?validation|payload[.\s-]?contract)'
    if ($inputValidationMatch) {
        # Exclude minor changes to existing validation
        if ($TaskDescription -notmatch '(?i)((?i)(modify.*(message|text|wording)|change.*(message|text|wording|label)|fix.*bug|simple.*field.only|log.*format|existing.*message.*only|copy.*existing.*pattern|follow.*existing)|(?i)(modify.*(message|text|wording)|change.*(message|text|wording|label)|fix.*bug|simple.*field.only|log.*format|existing.*message.*only|copy.*existing.*pattern|follow.*existing)|(?i)(modify.*(message|text|wording)|change.*(message|text|wording|label)|fix.*bug|simple.*field.only|log.*format|existing.*message.*only|copy.*existing.*pattern|follow.*existing)|(?i)(modify.*(message|text|wording)|change.*(message|text|wording|label)|fix.*bug|simple.*field.only|log.*format|existing.*message.*only|copy.*existing.*pattern|follow.*existing)|(?i)(modify.*(message|text|wording)|change.*(message|text|wording|label)|fix.*bug|simple.*field.only|log.*format|existing.*message.*only|copy.*existing.*pattern|follow.*existing)|(?i)(modify.*(message|text|wording)|change.*(message|text|wording|label)|fix.*bug|simple.*field.only|log.*format|existing.*message.*only|copy.*existing.*pattern|follow.*existing)|(?i)(modify.*(message|text|wording)|change.*(message|text|wording|label)|fix.*bug|simple.*field.only|log.*format|existing.*message.*only|copy.*existing.*pattern|follow.*existing)|(?i)(modify.*(message|text|wording)|change.*(message|text|wording|label)|fix.*bug|simple.*field.only|log.*format|existing.*message.*only|copy.*existing.*pattern|follow.*existing)|(?i)(modify.*(message|text|wording)|change.*(message|text|wording|label)|fix.*bug|simple.*field.only|log.*format|existing.*message.*only|copy.*existing.*pattern|follow.*existing)|(?i)(modify.*(message|text|wording)|change.*(message|text|wording|label)|fix.*bug|simple.*field.only|log.*format|existing.*message.*only|copy.*existing.*pattern|follow.*existing))') {
            $p0Score += 4; $p0Reasons += "USER_INPUT_VALIDATION_DESIGN"
        }
    }

    # P1: Community Reference
    if ($TaskDescription -match '(?i)(UI.pattern|UX|component|design.system|multiple.approach|community|simpler.way|unfamiliar)') { $p1Score += 3; $p1Reasons += "COMMUNITY_REFERENCE" }

    # UI context override for design system
    if ($TaskDescription -match "(?i)(design.system|button.variant|change.variant|existing.component|change.prop)") {
        if ($p0Score -ge 4 -and ($p0Reasons -contains "ARCHITECTURE_DECISION")) {
            $p0Score -= 4; $p0Reasons = $p0Reasons | Where-Object { $_ -ne "ARCHITECTURE_DECISION" }
        }
    }

    # Decision
    if ($p0Score -ge 4) {
        $result.search_level = "P0_MUST_SEARCH"; $result.search_required = $true
        $result.evidence_pack_required = $true; $result.reason = "P0: $($p0Reasons -join ', ')"
        $result.budget = @{ maxQueries = 6; minSources = 5; maxSources = 10; officialMin = 1 }
        $result.research_questions = @("Official approach?","Best practices?","Common pitfalls?","Version constraints?")
        if ($securityCritical) { $result.research_questions += @("Security controls?","Insecure patterns?") }
        $result.query_intents = @("official_api_check","best_practice","risk_pattern","alternative_options")
    }
    elseif ($p1Score -ge 3) {
        $result.search_level = "P1_SHOULD_SEARCH"; $result.search_required = $true
        $result.reason = "P1: $($p1Reasons -join ', ')"
        $result.budget = @{ maxQueries = 3; minSources = 2; maxSources = 5; officialMin = 0 }
    }
    else {
        $result.search_level = "P2_NO_SEARCH_REQUIRED"; $result.search_required = $false
        $result.reason = "P2: Low-risk local change"
    }

    $result.gate_passed = ($result.fatal_violations.Count -eq 0)
    return $result
}

# Security Design Completeness Check
function Test-SecurityDesignCompleteness {
    param($Design, $EvidencePack)
    $missing = @()
    foreach ($f in @("security_controls_to_implement","rejected_insecure_patterns","dependency_version_notes","test_plan_for_security_paths","EP_source_references","implementation_constraints")) {
        if (-not $Design.$f) { $missing += $f }
    }
    [PSCustomObject]@{ complete=($missing.Count -eq 0); missing_fields=$missing; security_design_score=if($missing.Count -eq 0){2}elseif($missing.Count -le 2){1}else{0} }
}

Write-Output "Pre-Build Research Gate v2.0.3 loaded (R2.6: +API_PATTERN_DESIGN, R2.8: +USER_INPUT_VALIDATION_DESIGN)"


