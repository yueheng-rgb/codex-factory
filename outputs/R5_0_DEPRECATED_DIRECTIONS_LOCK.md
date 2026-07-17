# R5.0 — Deprecated Directions Lock
# Codex Factory Foundation RC v1.0.0
# Generated: 2026-07-11

## STATUS: PERMANENTLY LOCKED

These directions are permanently deprecated. Do not reopen under any future phase.
Violating any of these is grounds for classification D = INVALID.

---

## DEP-001: Independent Search Agent

- **Deprecated**: R2.3
- **Rationale**: Search is a pipeline component, not an autonomous agent.
  Separating search into an independent agent creates coordination overhead
  and evidence fragmentation.
- **Replacement**: Pre-Build Research Gate within main pipeline.
- **Enforcement**: `runtime/search-operating-doctrine.ps1` verifies no
  independent search agent exists.
- **Last verified**: 2026-07-11 (R5.0 readiness check)

## DEP-002: Dual Search Channel

- **Deprecated**: R2.3
- **Rationale**: Running two search paths (chat + API) creates conflicting
  evidence and makes it impossible to determine canonical truth.
- **Replacement**: Single canonical search path: `/api/paas/v4/web_search` + `search_std`.
- **Enforcement**: `runtime/search-operating-doctrine.ps1` verifies single channel.
- **Last verified**: 2026-07-11

## DEP-003: Search Agent as Future Default

- **Deprecated**: R2.4
- **Rationale**: Search is not the primary mode of operation. Most tasks
  do not need search. Making search the default would add latency and
  unnecessary evidence gathering to simple tasks.
- **Replacement**: Pre-Build Research Gate determines P0_MUST_SEARCH vs P2_NO_SEARCH.
- **Enforcement**: P2_NO_SEARCH tasks skip search entirely.
- **Last verified**: 2026-07-11

## DEP-004: Implementer Direct Search

- **Deprecated**: R2.4
- **Rationale**: Implementer searching directly bypasses Evidence Pack,
  Quality Gate, and canonical evidence rules. This creates unverifiable
  implementation based on unvetted search results.
- **Replacement**: Search results flow through Evidence Pack v2 → Quality Gate v5
  before reaching Implementer.
- **Enforcement**: `runtime/search-operating-doctrine.ps1`, workflow-search-consistency-check.
- **Last verified**: 2026-07-11

## DEP-005: Chat URL Extraction as Canonical Evidence

- **Deprecated**: R2.4
- **Rationale**: `/chat/completions` web_search returns URL snippets without
  full page context. These URLs cannot be independently verified and may
  point to outdated, incorrect, or inaccessible pages.
- **Replacement**: Evidence Pack v2 requires full page content via canonical search
  or Reader/Extractor adapter.
- **Enforcement**: Evidence Pack v2 schema rejects chat URL extraction as primary evidence.
- **Last verified**: 2026-07-11

## DEP-006: Mock/Dry_Run Mislabeled as Live

- **Deprecated**: R2.6
- **Rationale**: Labeling mock or dry_run results as "live" creates false
  confidence in untested capabilities. This is a safety-critical violation.
- **Replacement**: All results must carry accurate status: RUN, CLEAN,
  FINDINGS_PRESENT, TOOL_FAILED, TOOL_UNAVAILABLE, SKIPPED, DESIGN_ONLY.
- **Enforcement**: Evidence Binding requires verifiable source for every claim.
- **Last verified**: 2026-07-11 (all R3.x/R4.x phases correctly label TOOL_FAILED)

## DEP-007: Multi-Agent as Default Mode

- **Deprecated**: R2.8
- **Rationale**: Multi-agent mode adds coordination complexity. Most Factory
  tasks (starters, testbeds, pilots) are single-main-agent. Making multi-agent
  the default would slow down simple tasks.
- **Replacement**: Multi-agent is available but gated. Agent loader and
  permission gate determine when multi-agent is warranted.
- **Enforcement**: MULTI_AGENT_DEFAULT_REJECTED flag set in governance.
- **Last verified**: 2026-07-11

## DEP-008: Rebuilding Frozen Pipelines

- **Deprecated**: R5.0 (this phase)
- **Rationale**: Search, Multi-Agent, Verifier, Harness, AGENTS.md Bootstrap
  are frozen at Foundation RC baseline. Rebuilding them breaks the stable
  baseline and invalidates all benchmark and capability data.
- **Replacement**: Extend via new phases (R5.x, R6.0) that build ON TOP of
  the frozen baseline, not by modifying it.
- **Enforcement**: Any phase that modifies frozen pipeline files is D = INVALID.
- **Last verified**: 2026-07-11

## DEP-009: Firecrawl as Canonical Search Replacement

- **Deprecated**: R3.0
- **Rationale**: Firecrawl is a Reader/Extractor, not a search engine. Using
  it as canonical search would bypass the search provider and Quality Gate.
- **Replacement**: Firecrawl is a candidate Reader/Extractor for Evidence Pack
  enrichment, NOT a replacement for canonical search.
- **Enforcement**: External Engine Broker only activates Firecrawl as reader,
  not as search provider.
- **Last verified**: 2026-07-11

## DEP-010: External Tools Bypassing Evidence Binding

- **Deprecated**: R3.0
- **Rationale**: External engine results must enter the same evidence chain as
  all other Factory artifacts. Unguarded external tool output creates
  unverifiable claims.
- **Replacement**: All external engine results go through parser → Evidence
  Binding → Risk Enforcement Gate.
- **Enforcement**: `runtime/external-engine-broker.ps1` v1.1.0 enforces this.
- **Last verified**: 2026-07-11

---

## ENFORCEMENT

Any future phase that:
1. Restores Independent Search Agent → D = INVALID
2. Enables Dual Search Channel → D = INVALID
3. Makes Implementer search directly → D = INVALID
4. Uses chat URL extraction as canonical → D = INVALID
5. Labels mock/dry_run as live → D = INVALID
6. Makes multi-agent the default → D = INVALID
7. Rebuilds frozen pipelines → D = INVALID
8. Makes Firecrawl canonical search → D = INVALID
9. Bypasses Evidence Binding with external tools → D = INVALID
10. Exaggerates local smoke as production capacity → D = INVALID

---

*Deprecated Directions Lock — permanently frozen 2026-07-11*
*These directions will never be reopened in any future Codex Factory phase.*
