# Factory Main Workflow — R2.3-AB Search Baseline Integration
# Part of: R2.4
# Status: ADOPTED
# References: outputs/FACTORY_R2_3_AB_SEARCH_SYSTEM_BASELINE.ps1

# =============================================
# INTEGRATION POINT A: Router / Task Intake
# =============================================

# After APP_TYPE_ROUTER classifies project type and before Design stage,
# Router MUST invoke the Pre-Build Research Gate.

ROUTER_SEARCH_CHECK = {
    step = "AFTER project type classification, BEFORE design output"
    action = "Invoke-PreBuildResearchGate -TaskDescription <task> -AgentId RSRC-001 -ProjectType <type>"
    outcomes = @(
        "P0_MUST_SEARCH: block design until Evidence Pack v2 generated",
        "P1_SHOULD_SEARCH: recommend search, skippable with justification",
        "P2_NO_SEARCH_REQUIRED: proceed directly to design"
    )
    reference = "runtime/pre-build-research-gate.ps1 v2.0.1"
}

# =============================================
# INTEGRATION POINT B: Planner / Designer
# =============================================

# If task is P0, Designer MUST consume Evidence Pack v2 as fact input.
# Design MUST reference EP sources explicitly.

DESIGNER_SEARCH_CONTRACT = {
    for_P0 = @(
        "Read Evidence Pack v2 before producing Design",
        "Cite EP sources in Design (EP_source_references)",
        "Record adopted_approach with source_backed_reasons",
        "Record rejected_alternatives with reasons",
        "If EP insufficient, return EP_INSUFFICIENT — do NOT use LLM knowledge to fill gaps"
    )
    for_P2 = @(
        "No Evidence Pack needed",
        "Use project files and existing patterns only"
    )
    reference = "outputs/FACTORY_R2_3_AA_DESIGN.md (example)"
}

# =============================================
# INTEGRATION POINT C: Worker / Implementer
# =============================================

IMPLEMENTER_SEARCH_BOUNDARY = {
    allowed_inputs = @("Evidence Pack v2", "Design document", "Project files")
    forbidden = @(
        "Direct search (any provider)",
        "Provider API call",
        "Provider raw response read",
        "LLM knowledge gap-fill for key decisions",
        "/chat/completions URL extraction for evidence"
    )
    if_ep_insufficient = "Return EP_INSUFFICIENT with missing evidence list. Do NOT search."
    reference = "FACTORY_R2_3_AB_SEARCH_SYSTEM_BASELINE.ps1 §4"
}

# =============================================
# INTEGRATION POINT D: Verifier
# =============================================

VERIFIER_SEARCH_CHECKS = @(
    "IMPLEMENTER_DIRECT_SEARCH: check if implementer bypassed search boundary",
    "EP_USAGE: check if Evidence Pack was referenced in Design",
    "SOURCE_ORIGIN: all EP sources must be provider_search_result",
    "NO_MODEL_EXTRACTION: zero model_text_extraction sources",
    "NO_CHAT_URL: zero /chat/completions URL extraction",
    "NO_MOCK_DRY_RUN: live search tasks must have live evidence",
    "KEY_LEAK: zero API key in any output file"
)

# =============================================
# INTEGRATION POINT E: Worker Capsule / Handoff
# =============================================

HANDOFF_SEARCH_BOUNDARY = {
    must_include = @(
        "search_level: P0 / P1 / P2",
        "evidence_pack_ref: path to EP if P0",
        "implementer_boundary: DO NOT SEARCH",
        "allowed_inputs: EP + Design + project files"
    )
}

# =============================================
# WORKFLOW SEQUENCE (UPDATED)
# =============================================

UPDATED_WORKFLOW = @(
    "1. User Task → APP_TYPE_ROUTER (project type classification)",
    "2. Pre-Build Research Gate (P0/P1/P2 — NEW)",
    "3. If P0: /web_search → Quality Gate v5 → Evidence Pack v2 (NEW)",
    "4. Design (with EP if P0, project files if P2)",
    "5. Implementer (EP + Design + project files only; NO search)",
    "6. Verifier (check search boundary + EP usage + source origin)",
    "7. Handoff"
)

Write-Output "Factory Workflow Search Integration defined. 5 integration points, 7-stage updated workflow."
