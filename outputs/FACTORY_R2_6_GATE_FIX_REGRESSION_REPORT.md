# FACTORY R2.6: Workflow Gate Classification Fix & Real Task Regression

**Date:** 2026-07-11
**Phase:** R2.6
**Classification:** **A = GATE_CLASSIFICATION_FIXED_AND_REAL_TASK_REGRESSION_PASS**

---

## 1. R2.5 Correction

| Field | Before | After (R2.6) |
|-------|--------|-------------|
| Classification | A | **B** |
| Reason | — | Gate classified API pattern design as P2; workflow executed /web_search regardless — consistency violation |
| Implementation | 7/7 PASS | **Retained** (implementation is correct) |
| Products API | Working | **Preserved** (working, tests pass) |
| Evidence | Valid | **Valid** (EP, Design, code all retained) |

---

## 2. Gate Rule Change

### New P0 Trigger: API_PATTERN_DESIGN

**File:** untime/pre-build-research-gate.ps1 v2.0.2

Triggers when task involves:
- cursor pagination, offset pagination, pagina*
- ilter API, sorting API, search query design
- list endpoint, API response metadata
- API contract, database query pattern
- public API, eusable API

**Score:** +4 (enough to push to P0 when combined with any other signal)

**Rationale:** API contract design is high-rework-risk — wrong decision on cursor vs offset, filter parameter conventions, or response metadata format causes cascading frontend/backend changes.

---

## 3. Regression Task Results (4/4 Correct)

| ID | Task | Expected | Actual | Consistent |
|----|------|:---:|:---:|:---:|
| A | Products API (pagination/filter/search) | P0 | **P0_MUST_SEARCH** (API_PATTERN_DESIGN) | ✓ |
| B | Log format update | P2 | **P2_NO_SEARCH_REQUIRED** | ✓ |
| C | Local API bug (decimal filter) | P2 | **P2_NO_SEARCH_REQUIRED** | ✓ |
| D | Bug + pagination uncertainty | P0/P1 | **P0_MUST_SEARCH** (UNCERTAINTY + API_PATTERN_DESIGN) | ✓ |

---

## 4. Workflow Consistency Checks

| Check | Result |
|-------|:---:|
| P0 + search executed + EP exists → PASS | ✓ |
| P2 + 0 queries → PASS | ✓ |
| P2 + search queries + no escalation → FAIL_WORKFLOW_CONSISTENCY | **New check added** |
| EP exists + P2 gate + no escalation → FAIL_WORKFLOW_CONSISTENCY | **New check added** |

**Implementation:** untime/workflow-search-consistency-check.ps1

---

## 5. P2 Oversearch Guardrail

| Task | Level | Queries | EP | Guardrail |
|------|:---:|:---:|:---:|:---:|
| Log format | P2 | 0 | No | ✓ |
| Local API bug | P2 | 0 | No | ✓ |
| Products API | **P0** | 2 | Yes | ✓ (correctly P0) |

---

## 6. Implementer Boundary

| Check | Result |
|-------|:---:|
| IMPL agent tries to search → REJECT | ✓ |
| Fatal violation: IMPLEMENTER_SEARCH_ATTEMPT | ✓ |

---

## 7. Products API Status (Preserved from R2.5)

| Check | Status |
|-------|:---:|
| Server starts | ✓ |
| GET /api/products?limit=3 → 3 items, total=50 | ✓ |
| GET /api/products?category=books&sort=price&order=asc → filtered + sorted | ✓ |
| GET /health → ok | ✓ |
| R2.5 EP and Design retained | ✓ |

---

## 8. Changed Files

| File | Change | Description |
|------|:---:|-------------|
| untime/pre-build-research-gate.ps1 | UPDATE v2.0.2 | Added API_PATTERN_DESIGN P0 trigger |
| untime/workflow-search-consistency-check.ps1 | NEW | 4-rule workflow consistency checker |
| outputs/FACTORY_R2_5_REAL_TASK_REPORT.md | PATCHED | Classification A→B, added R2.6 correction note |

---

## 9. Verifier Updates

| Check | R2.4 | R2.6 |
|-------|:---:|:---:|
| IMPLEMENTER_DIRECT_SEARCH | ✓ | ✓ |
| EP_USAGE | ✓ | ✓ |
| SOURCE_ORIGIN | ✓ | ✓ |
| **search_level_execution_consistency** | — | **NEW** |

---

## 10. Remaining Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Other API patterns not yet in triggers (rate limit, auth middleware design) | LOW | Already covered by SECURITY_CRITICAL; API_PATTERN_DESIGN handles data-access patterns |
| Regex-based classification is inherently limited | LOW | Adequate for current Factory scope; ML upgrade future |

---

## 11. Recommended Next Step

**Phase:** R2.7 — Multi-Agent Handoff with Search Boundary Enforcement

With the gate fixed and workflow consistency checks in place, validate that when multiple agents (Router, Researcher, Designer, Implementer, Verifier) operate in sequence, the search boundary is enforced at each handoff point — not just at the first gate.

**Do NOT:**
- Expand search capabilities
- Multi-provider
- Production Readiness
- Restore Search Agent or Dual Channel

---

**secretSafetyResult:** PASS
**keyLeaked:** false
**gateVersion:** v2.0.2 (+API_PATTERN_DESIGN)
**regressionPassRate:** 4/4 (100%)
