# Codex Factory v1.0 — Deprecated Directions Final Lock

**Generated:** 2026-07-11
**Status:** FINAL LOCK — DO NOT REOPEN
**Applies to:** All v1.x releases

---

## Permanently Forbidden Directions

The following architectural directions were evaluated, tested, and explicitly
rejected. They MUST NOT be reopened in any v1.x release.

---

### 1. Independent Search Agent
- **Status:** FORBIDDEN
- **Reason:** Introduces dual-source evidence problem, search result inconsistency, and agent coordination overhead
- **Date deprecated:** R2.3
- **Replacement:** Implementer consumes Evidence Pack from canonical search pipeline; never searches directly

### 2. Dual Search Channel
- **Status:** FORBIDDEN
- **Reason:** Creates evidence conflict between /chat/completions web_search and /api/paas/v4/web_search; impossible to reconcile
- **Date deprecated:** R2.3
- **Replacement:** Single canonical search path: /api/paas/v4/web_search + search_std

### 3. Search Agent as Future Default
- **Status:** FORBIDDEN
- **Reason:** Architectural decision recorded in R2.3-AB baseline; search is a pipeline gate, not an agent role
- **Date deprecated:** R2.4
- **Replacement:** Pre-Build Research Gate (runtime script, not agent)

### 4. Implementer Direct Search
- **Status:** FORBIDDEN
- **Reason:** Violates separation of concerns; Implementer must consume structured Evidence Pack, not raw search results
- **Date deprecated:** R2.3
- **Replacement:** Evidence Pack v2 as canonical evidence carrier; Implementer reads from Evidence Pack only

### 5. chat URL Extraction as Canonical Evidence
- **Status:** FORBIDDEN
- **Reason:** /chat/completions web_search results are not structured, not reproducible, and not auditable as evidence
- **Date deprecated:** R2.3
- **Replacement:** Evidence Pack v2 with structured, auditable evidence records

### 6. mock/dry_run Mislabeled as Live
- **Status:** FORBIDDEN
- **Reason:** Falsifies capability claims; benchmark and engine results must reflect real execution
- **Date deprecated:** R2.3
- **Replacement:** Explicit RUN, SKIPPED_WITH_REASON, TOOL_FAILED, TOOL_UNAVAILABLE states

### 7. Multi-Agent Default Mode
- **Status:** FORBIDDEN
- **Reason:** Multi-agent adds coordination overhead; should be opt-in for complex projects only
- **Date deprecated:** R2.4
- **Replacement:** Single-agent default; multi-agent activated by explicit user request or L_CLASS decomposition

### 8. External Engine Result Bypassing Evidence Binding
- **Status:** FORBIDDEN
- **Reason:** Engine output must be traceable to gate decisions; raw output without binding is untrustworthy
- **Date deprecated:** R3.0
- **Replacement:** Gate Evidence Binder; every engine result bound to gate decision with evidence files

### 9. Firecrawl Replacing Canonical Search
- **Status:** FORBIDDEN
- **Reason:** Firecrawl is a Reader/Extractor tool, not a search engine; using it as primary search breaks Evidence Pack pipeline
- **Date deprecated:** R2.4
- **Replacement:** Firecrawl as optional Reader/Extractor candidate; canonical search stays on /api/paas/v4/web_search

### 10. Expert Pack Bypassing Risk Gate
- **Status:** FORBIDDEN
- **Reason:** Expert packs provide domain knowledge but must not skip risk classification or invariant enforcement
- **Date deprecated:** R5.1
- **Replacement:** Expert pack activation integrated into Risk Enforcement Gate v3

---

## Additional v1.0 Boundaries

### Performance Claims
- **FORBIDDEN:** Claiming local autocannon smoke as production capacity proof
- **FORBIDDEN:** Claiming "supports million concurrent users" based on single-endpoint smoke
- **Rule:** Load test results must explicitly state "local smoke — not production capacity proof"

### Readiness Claims
- **FORBIDDEN:** Claiming READY_FOR_STAGING equals READY_FOR_PRODUCTION
- **FORBIDDEN:** Claiming any testbed or pilot is production-ready
- **Rule:** Maximum readiness level is READY_FOR_PRODUCTION_REVIEW; never auto-approve production deployment

### Version Claims
- **FORBIDDEN:** Claiming v1.0 is the final version
- **FORBIDDEN:** Naming any release "v2.0 Final Release" before v2.0 is actually reached
- **Rule:** v1.0 is Foundation Release; v2.0 requires separate delivery phase

---

## Audit Trail

| Direction | Deprecated In | Locked In | Last Verified |
|-----------|--------------|-----------|---------------|
| Independent Search Agent | R2.3 | R5.0 | R7.0 |
| Dual Search Channel | R2.3 | R5.0 | R7.0 |
| Search Agent as Future Default | R2.4 | R5.0 | R7.0 |
| Implementer direct search | R2.3 | R5.0 | R7.0 |
| chat URL extraction | R2.3 | R5.0 | R7.0 |
| mock/dry_run mislabel | R2.3 | R5.0 | R7.0 |
| multi-agent default | R2.4 | R5.0 | R7.0 |
| engine bypass evidence | R3.0 | R5.0 | R7.0 |
| Firecrawl replace search | R2.4 | R5.0 | R7.0 |
| Expert Pack bypass Risk Gate | R5.1 | R5.1 | R7.0 |

**This lock is FINAL for v1.0. Any attempt to reopen these directions in v1.x
MUST be treated as a release blocker and escalated to human audit.**
