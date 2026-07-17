# Search Operating Doctrine v2.0.0
# Part of: FACTORY-R2.3-Y
# Purpose: Consolidated search policy incorporating evidence from R2.3-W (design) and R2.3-X (implementation)
# Quality-first, bounded search. Not all tasks need search. Not all searches are equal.

# =============================================
# P0_MUST_SEARCH: Search REQUIRED before design/implementation
# =============================================

$P0_TRIGGERS = @{

    # --- Category 1: Security-Critical Tasks (R2.3-X evidence: 0→2 security score improvement) ---
    SECURITY_CRITICAL = @(
        "login|authentication|auth",
        "JWT|refresh.token|access.token",
        "session|cookie.auth|token.storage",
        "OAuth|SSO|single.sign.on|social.login",
        "password.reset|forgot.password",
        "logout|token.revocation|session.invalidation",
        "RBAC|ABAC|role.based.access|permission.model|access.control",
        "authorization.middleware|permission.check|guard.decorator",
        "CORS|CSRF|XSS|injection|sanitization",
        "secret.management|API.key.storage|env.management",
        "rate.limit|throttle|DDoS",
        "idempotency|idempotency.key",
        "file.upload.security|upload.validation|mime.check"
    )

    # --- Category 2: External Dependencies & Version-Sensitive (R2.3-W evidence: API surface confirmation) ---
    EXTERNAL_DEPENDENCY = @(
        "new.package|new.SDK|new.API|integrate.third.party",
        "cloud.service|storage.service|payment.gateway|SMS|email.service",
        "framework.plugin|middleware.choice|library.selection",
        "dependency.upgrade|version.bump|migration.guide",
        "configuration.option|API.surface|plugin.options",
        "official.docs|API.reference|breaking.change"
    )

    # --- Category 3: Architecture & Design Decisions ---
    ARCHITECTURE_DECISION = @(
        "new.project|project.start|scaffold|greenfield",
        "new.module|module.design|feature.design",
        "database.schema|data.model|entity.design",
        "caching.strategy|Redis|memcache",
        "concurrency|parallelism|worker|queue|job",
        "deployment|CI/CD|Docker|container",
        "search.functionality|full.text.search",
        "AI.integration|LLM|embedding|vector",
        "scalability|horizontal.scale|vertical.scale"
    )

    # --- Category 4: High-Rework-Risk Tasks ---
    HIGH_REWORK_RISK = @(
        "wrong.approach.causes.rewrite|architectural.rewrite",
        "multiple.viable.approaches|choose.between|decide.between",
        "UNSURE|uncertain|not.sure|which.way",
        "mainstream|best.practice|industry.standard|recommended.way",
        "mature.solution|existing.project|similar.project|reference.project",
        "outdated|deprecated|still.relevant|current.version"
    )
}

# =============================================
# P1_SHOULD_SEARCH: Search recommended but skippable with project evidence
# =============================================

$P1_TRIGGERS = @(
    "UI.pattern|UX.pattern|component.library|design.system",
    "multiple.approaches|alternative.routes|different.ways",
    "community.practice|common.pattern|popular.approach",
    "simpler.solution|easier.way|less.complex",
    "unfamiliar.library|unfamiliar.plugin|first.time.using"
)

# =============================================
# P2_NO_SEARCH_REQUIRED: Default no search
# =============================================

$P2_TRIGGERS = @(
    "known.local.bug|identified.bug|reproduced.bug",
    "small.style.fix|CSS.change|formatting|spacing",
    "text.change|copy.update|label.fix|wording",
    "add.tests|write.tests|test.coverage|supplement.tests",
    "follow.existing.pattern|copy.existing.implementation|same.as.before",
    "refactor.existing|rename|move.file|restructure.no.behavior.change",
    "user.provided.specific.implementation|explicit.instructions.given",
    "documentation.only|README|CHANGELOG|report.writing",
    "migration.path.known|well.understood.migration"
)

# =============================================
# Search Budget (quality-first, bounded)
# =============================================

$SEARCH_BUDGET = @{
    P0 = @{ maxQueries = 6; minSources = 5; maxSources = 10; officialMin = 1 }
    P1 = @{ maxQueries = 3; minSources = 2; maxSources = 5; officialMin = 0 }
    P2 = @{ maxQueries = 0; minSources = 0; maxSources = 0; officialMin = 0 }
}

# =============================================
# Query Strategy (R2.3-Y optimization)
# =============================================

$QUERY_STRATEGY = @{
    # Query formation rules
    R1_TECHNICAL_TERMS_FIRST = "Include framework/library name + version context"
    R2_OFFICIAL_SOURCE_TARGET = "Append 'official documentation' or 'official docs' for P0"
    R3_ENGLISH_FALLBACK = "If first query returns Chinese-dominated results, retry with English query + 'site:github.com OR site:stackoverflow.com OR official'"
    R4_MULTI_ANGLE = "P0: query from at least 2 angles (official docs + community/issue + tutorial/guide)"
    R5_QUERY_INTENT = "Each query must have query_intent field: official_api_check | best_practice | risk_pattern | alternative_options"
    
    # Language strategy
    L1_PRIMARY = "Chinese (search_std default)"
    L2_SUPPLEMENT = "English (when authoritative English sources are needed: official docs, GitHub, RFC)"
    L3_ENG_TRIGGER = "Trigger English supplement when: official_source_hit < 1 AND authoritative_source_gap detected"
    L4_ENG_PATTERN = "Append: 'site:github.com OR site:npmjs.com OR official documentation' in English queries"
}

# =============================================
# Source Ranking (R2.3-Y optimization)
# =============================================

$SOURCE_RANKING = @{
    TIER_1_GOLD = @{
        label = "TIER_1_GOLD (最高优先级)"
        types = @("official_documentation", "official_SDK_repo", "official_example", "RFC_spec")
        weight = 3
        minRequired_P0 = 1
    }
    TIER_2_SILVER = @{
        label = "TIER_2_SILVER (高优先级)"
        types = @("mainstream_open_source_repo", "well_maintained_library", "authoritative_tech_article", "official_blog")
        weight = 2
    }
    TIER_3_BRONZE = @{
        label = "TIER_3_BRONZE (辅助参考)"
        types = @("community_tutorial", "StackOverflow_accepted", "GitHub_issue_resolution", "tech_blog")
        weight = 1
    }
    TIER_4_SUPPLEMENT = @{
        label = "TIER_4_SUPPLEMENT (仅辅助，不可单独定方案)"
        types = @("personal_blog", "low_quality_article", "unverified_comment", "AI_generated_summary")
        weight = 0
        constraint = "CANNOT be sole basis for design decision"
    }
}

# =============================================
# Evidence Pack Quality Fields (R2.3-Y: v2 additions)
# =============================================

$EP_QUALITY_FIELDS_V2 = @{
    # Per-source additions
    per_source = @(
        "source_type",           # official_doc | reference_project | article | issue | benchmark | other
        "source_tier",           # tier_1_gold | tier_2_silver | tier_3_bronze | tier_4_supplement
        "source_language",       # zh | en | other
        "freshness_note",        # e.g., "2025-06", "2024-Q4", "unknown"
        "maturity_signal",       # stable | beta | deprecated | unknown
        "risk_signal",           # breaking_changes | security_advisory | unmaintained | deprecated_api
        "version_or_dependency_note",
        "selected_reason",
        "limitations"
    )
    
    # Top-level additions
    top_level = @(
        "source_type_counts",          # { official: N, community: N, article: N, issue: N }
        "official_sources_count",
        "community_sources_count",
        "authoritative_source_gap",    # true if no official source
        "research_coverage_summary",
        "rejected_sources_summary",
        "open_questions",
        "confidence_level",            # high | medium | low
        "implementation_checklist",
        "test_checklist"
    )
}

# =============================================
# P0 Security Task Mandatory Requirements (R2.3-Y)
# =============================================

$P0_SECURITY_REQUIREMENTS = @{
    evidence_pack_must_have = @(
        "security_risk_notes",
        "minimum_controls",
        "rejected_insecure_alternatives",
        "required_tests_for_failure_paths",
        "dependency_version_constraints",
        "implementation_checklist",
        "test_checklist"
    )
    design_must_have = @(
        "security_controls_to_implement",
        "rejected_insecure_patterns",
        "dependency_version_notes",
        "test_plan_for_security_paths",
        "EP_source_references",
        "implementation_constraints"
    )
}

# =============================================
# Search Stop Conditions (R2.3-Y)
# =============================================

$STOP_CONDITIONS = @(
    "official_or_authoritative_source_confirms_core_approach",
    "at_least_2_independent_sources_support_main_route",
    "alternative_approaches_identified",
    "common_pitfalls_or_anti_patterns_identified",
    "version_or_dependency_constraints_recorded",
    "evidence_pack_sufficient_for_design",
    "further_search_only_produces_duplicate_information"
)

$P0_EXTRA_QUERY_JUSTIFICATION = @{
    trigger = "P0 exceeds 6 queries"
    must_explain = @(
        "why_more_search_needed",
        "what_evidence_is_missing",
        "expected_value_of_extra_queries"
    )
}

# =============================================
# Firecrawl Boundary (R2.3-Y)
# =============================================

$FIRECRAWL_BOUNDARY = @{
    status = "FUTURE_CANDIDATE_NOT_ACTIVE"
    allowed_roles = @("reader_provider", "extractor_provider", "crawler_provider", "source_enrichment_provider")
    forbidden_roles = @("independent_search_agent", "canonical_search_replacement", "direct_implementer_tool", "evidence_pack_bypass")
    activation_requires = "Separate Reader/Extractor Feasibility Spike based on existing URLs, NOT replacing /web_search source discovery"
}

# =============================================
# Invariants (never to be violated)
# =============================================

$INVARIANTS = @(
    "IMPLEMENTER_NEVER_SEARCHES",
    "EVIDENCE_PACK_IS_ONLY_FACT_CARRIER",
    "/chat/completions URL EXTRACTION != CANONICAL EVIDENCE",
    "PLAIN_LLM_ANSWER != SEARCH_EVIDENCE",
    "API_ENDPOINT_URL != EXTERNAL_SOURCE",
    "MOCK/DRY_RUN != LIVE_SEARCH",
    "CANNOT_SKIP_P0_WITHOUT_EVIDENCE",
    "P2_CANNOT_BE_FORCED_TO_SEARCH",
    "auditPassed != runtimeVerified",
    "metadata_verified != behavior_verified",
    "NO_INDEPENDENT_SEARCH_AGENT",
    "NO_DUAL_SEARCH_CHANNEL"
)

Write-Output "Search Operating Doctrine v2.0 loaded"
Write-Output "  P0 triggers: $(($P0_TRIGGERS.SECURITY_CRITICAL + $P0_TRIGGERS.EXTERNAL_DEPENDENCY + $P0_TRIGGERS.ARCHITECTURE_DECISION + $P0_TRIGGERS.HIGH_REWORK_RISK).Count) patterns"
Write-Output "  P1 triggers: $($P1_TRIGGERS.Count) patterns"
Write-Output "  P2 triggers: $($P2_TRIGGERS.Count) patterns"
Write-Output "  Invariants: $($INVARIANTS.Count)"
