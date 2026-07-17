# FACTORY R2.3 Search System Baseline
# Frozen: 2026-07-11 (R2.3-AB)
# Status: HANDOFF READY
# Purpose: Single source of truth for search subsystem architecture, constraints, and regression verification.

# =============================================
# 1. CANONICAL SEARCH PATH
# =============================================

CANONICAL_PROVIDER = "ZhipuAI"
CANONICAL_ENDPOINT = "POST https://open.bigmodel.cn/api/paas/v4/web_search"
CANONICAL_SEARCH_ENGINE = "search_std"
CANONICAL_RESPONSE_FIELD = "response.search_result[]"
CANONICAL_SOURCE_ORIGIN = "provider_search_result"
EVIDENCE_PACK_SOURCE = "structured search_result only"

# =============================================
# 2. DEMOTED PATH
# =============================================

DEMOTED_ENDPOINT = "/chat/completions + web_search tool"
DEMOTED_STATUS = "auxiliary_search_assisted_chat"
DEMOTED_RESTRICTIONS = @(
    "CANNOT generate canonical Evidence Pack",
    "CANNOT be used for A-level live search classification",
    "CANNOT extract URLs from model text into EP",
    "CANNOT replace /web_search",
    "R2.3-R/U classification downgraded to B_UNCORROBORATED"
)

# =============================================
# 3. ARCHITECTURE (IMMUTABLE)
# =============================================

ARCHITECTURE = @(
    "need_search",
    "Pre-Build Research Gate v2.0.1",
    "Provider Selector",
    "ZhipuAI Structured Web Search API /api/paas/v4/web_search",
    "Quality Gate v5",
    "Research Intake",
    "Evidence Pack v2",
    "Design",
    "Implementer",
    "Verify"
)

# =============================================
# 4. EVIDENCE RULE (IMMUTABLE)
# =============================================

EVIDENCE_RULE = @{
    single_fact_carrier = "Evidence Pack v2"
    design_inputs = @("Evidence Pack", "Design", "Project Files")
    implementer_inputs = @("Evidence Pack", "Design", "Project Files")
    implementer_forbidden = @(
        "direct search",
        "provider API call",
        "provider raw response read",
        "LLM knowledge gap-fill for key facts",
        "chat URL extraction for evidence"
    )
}

# =============================================
# 5. SEARCH NECESSITY POLICY (P0/P1/P2)
# =============================================

P0_MUST_SEARCH = @{
    triggers = @(
        "SECURITY_CRITICAL: auth, JWT, session, RBAC, CORS, CSRF, rate limit, secret mgmt, file upload",
        "EXTERNAL_DEPENDENCY: new package, SDK, API, cloud service, plugin, framework middleware",
        "ARCHITECTURE_DECISION: new project, module, database schema, caching, deployment, AI integration",
        "HIGH_REWORK_RISK: UNSURE, multiple approaches, mainstream inquiry, upgrade, migration"
    )
    budget = @{ maxQueries = 6; minSources = 5; maxSources = 10; officialMin = 1 }
    evidence_pack_required = True
}

P1_SHOULD_SEARCH = @{
    triggers = @(
        "UI pattern, design system reference",
        "Multiple implementation routes for standard feature",
        "Community practice reference value",
        "Unfamiliar library or plugin"
    )
    budget = @{ maxQueries = 3; minSources = 2; maxSources = 5; officialMin = 0 }
}

P2_NO_SEARCH_REQUIRED = @{
    triggers = @(
        "Known local bug fix",
        "Style/text/formatting change",
        "Test supplementation",
        "Pure documentation",
        "Copy existing pattern (no security/dep/arch change)"
    )
    budget = @{ maxQueries = 0 }
    p2_early_exit = "CSS/style/text tasks excluded even with security keywords"
}

# =============================================
# 6. QUALITY GATE v5 FATAL RULES
# =============================================

QG_V5_FATAL = @(
    "search_invocation_present = true",
    "external_source_url_present = true",
    "source_title_present = true",
    "source_snippet_or_content_present = true",
    "source_origin = provider_search_result (reject model_text_extraction)",
    "source_is_not_provider_api_endpoint = true",
    "source_is_not_llm_knowledge_answer = true",
    "response_not_mock = true",
    "response_not_dry_run = true",
    "no_secret_leak = true",
    "evidence_pack_schema_valid = true"
)

QG_V5_NON_FATAL = @(
    "authoritative_source_gap detection",
    "english_source_gap detection",
    "query_intent recording",
    "source_type_counts recording",
    "security_field completeness (if security_critical)"
)

# =============================================
# 7. FIRECRAWL BOUNDARY
# =============================================

FIRECRAWL_STATUS = "FUTURE_CANDIDATE_NOT_ACTIVE"
FIRECRAWL_ALLOWED = @("reader_provider", "extractor_provider", "crawler_provider", "source_enrichment_provider")
FIRECRAWL_FORBIDDEN = @("independent_search_agent", "canonical_search_replacement", "direct_implementer_tool", "evidence_pack_bypass")
FIRECRAWL_ACTIVATION = "Requires separate Reader/Extractor Feasibility Spike. CANNOT replace /web_search source discovery."

# =============================================
# 8. INVARIANTS (NEVER VIOLATE)
# =============================================

INVARIANTS = @(
    "IMPLEMENTER_NEVER_SEARCHES",
    "EVIDENCE_PACK_IS_ONLY_FACT_CARRIER",
    "/chat/completions URL EXTRACTION != CANONICAL EVIDENCE",
    "PLAIN_LLM_ANSWER != SEARCH_EVIDENCE",
    "API_ENDPOINT_URL != EXTERNAL_SOURCE",
    "MOCK/DRY_RUN != LIVE_SEARCH",
    "CANNOT_SKIP_P0_WITHOUT_EVIDENCE",
    "P2_CANNOT_BE_FORCED_TO_SEARCH",
    "NO_INDEPENDENT_SEARCH_AGENT",
    "NO_DUAL_SEARCH_CHANNEL"
)

# =============================================
# 9. KEY RUNTIME FILES
# =============================================

RUNTIME_FILES = @{
    doctrine = "runtime/search-operating-doctrine.ps1 (v2.0, 11KB)"
    gate = "runtime/pre-build-research-gate.ps1 (v2.0.1, 14.8KB)"
    quality_gate = "runtime/search-result-quality-gate.ps1 (v5, 10KB)"
    adapter = "runtime/zhipuai-structured-search-adapter.ps1 (v1.0, 9.9KB)"
    need_search = "runtime/need-search-detector.ps1 (v1.0, 6KB)"
    regression = "runtime/search-doctrine-regression-tests.ps1 (v1.0, 8.1KB)"
    ev_schema = "schemas/evidence-pack-v2.schema.json (4.3KB)"
}

# =============================================
# 10. PHASE LEDGER (R2.3 SEARCH)
# =============================================

PHASE_LEDGER = @(
    @{phase="R2.3-Q"; status="A_PROVIDER"; summary="Provider API connected, search not verified"},
    @{phase="R2.3-R"; status="B_UNCORROBORATED"; summary="Chat web_search uncorroborated, demoted"},
    @{phase="R2.3-S"; status="A"; summary="Pipeline consolidated, 10 fatal gates, 4 regression"},
    @{phase="R2.3-T"; status="A"; summary="Pre-Build Research Gate P0/P1/P2 established"},
    @{phase="R2.3-U"; status="B_UNCORROBORATED"; summary="Real trial but chat URL extraction"},
    @{phase="R2.3-U-BILLING"; status="A_BILLING_CONFIRMED"; summary="/web_search billing probe confirmed search_std"},
    @{phase="R2.3-V"; status="A"; summary="Canonical structured /web_search migration complete"},
    @{phase="R2.3-W"; status="A"; summary="Design comparison: external search value confirmed"},
    @{phase="R2.3-X"; status="A"; summary="Implementation comparison: value confirmed"},
    @{phase="R2.3-Y"; status="A"; summary="Search Operating Doctrine v2.0 optimized"},
    @{phase="R2.3-Z"; status="A"; summary="Cross-project validation (Fastify/Next.js/CLI)"},
    @{phase="R2.3-AA"; status="A"; summary="E2E P0 pipeline demo: rate limit"}
)

Write-Output "Search System Baseline frozen. 10 sections, 12 invariants, 12 phases recorded."
