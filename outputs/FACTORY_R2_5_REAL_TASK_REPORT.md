# FACTORY R2.5: Real Factory Task Execution with Adopted Workflow

**Date:** 2026-07-11
**Phase:** R2.5
**Classification:** **B = REAL_FACTORY_TASK_COMPLETED_WITH_GATE_CLASSIFICATION_DEFECT (corrected in R2.6)**

---

## 1. Selected Real Task

**Task:** "Build Fastify API endpoint with cursor-based pagination, multi-field filtering, and text search for a products resource list"

**Why this task:**
- Real, useful pattern needed across Factory projects
- Involves architectural decisions (cursor vs offset, API conventions)
- Implementable and testable in-memory (SQLite)
- Produces observable, measurable results

---

## 2. Full Workflow Trace

| # | Stage | Result |
|---|-------|--------|
| 1 | **Factory Bootstrap** | Project type: backend-api, Stack: Fastify + SQLite |
| 2 | **Router** | backend-api (API endpoint with data query patterns) |
| 3 | **Gate** | P2_NO_SEARCH_REQUIRED ⚠ (classification gap noted) |
| 4 | **/web_search** | 2 queries, 19 results, canonical endpoint |
| 5 | **Quality Gate v5** | PASS_WITH_WARNINGS (16/20, 0 fatal) |
| 6 | **Evidence Pack v2** | 19 sources, 0 official (authoritative gap) |
| 7 | **Design** | Cursor pagination, filter[], search, sort — EP-backed |
| 8 | **Implement** | products-api.js — EP + Design + project only; 0 search |
| 9 | **Verify** | 7/7 tests pass; no search bypass |
| 10 | **Handoff** | Recorded below |

---

## 3. Gate Classification Gap

**Issue:** Gate classified "Build Fastify API endpoint with cursor-based pagination" as P2_NO_SEARCH_REQUIRED.

**Root cause:** The regex-based P0 patterns don't cover "API pattern design" keywords like "pagination", "cursor", "filtering", "query parameters".

**Impact:** Low — the task still benefited from EP because search was run anyway. But a real P2-only workflow would have skipped search.

**Recommendation:** Add API pattern design triggers to P0 ARCHITECTURE_DECISION category in future doctrine update (not in R2.5 scope).

---

## 4. Design (EP-Backed)

| Decision | Source |
|----------|--------|
| Cursor-based pagination | EP: REST API best practices, industry standard (GitHub, Stripe) |
| base64 JSON cursor encoding | EP: cursor pattern from API design sources |
| filter[] parameter convention | EP: REST filtering conventions |
| LIKE-based text search (not full-text engine) | Design judgment: MVP complexity tradeoff |
| LIMIT + 1 for hasMore detection | EP: common cursor pagination pattern |

---

## 5. Implementation

**File:** untime/tests/r2-3-x-implementation-trial/products-api.js

**Key features:**
- Cursor-based pagination (stable, no offset drift)
- Multi-field filtering via ?category=X&status=Y
- Text search via ?search=term (SQL LIKE)
- Sortable: ?sort=price&order=desc
- Whitelist-based input validation (prevents SQL injection)
- Schema validation via Fastify JSON schema
- 50 seed products across 5 categories

**Implementer constraints verified:**
- Inputs: EP v2 + Design + project files only
- No direct search
- No /web_search call
- No chat URL extraction
- No LLM knowledge gap-fill

---

## 6. Test Results (7/7 PASS)

| Test | Result | Detail |
|------|:---:|--------|
| T1: Basic list | PASS | 20 items, hasMore=true, total=50 |
| T2: Cursor pagination | PASS | Next page returned 20 items |
| T3: Category filter | PASS | 10 electronics items |
| T4: Text search | PASS | 2 items matching "Product 5" |
| T5: Sort by price desc | PASS | Correct descending order |
| T6: Invalid limit (101) | PASS | Rejected with 400 |
| T7: Health check | PASS | ok, 50 products |

---

## 7. Verifier Result

| Check | Status |
|-------|:---:|
| Functionality complete | ✓ (pagination, filtering, search, sort) |
| Tests pass | ✓ (7/7) |
| EP used in design | ✓ (cursor pattern, filter convention from EP) |
| Implementer search boundary | ✓ (no direct search, no bypass) |
| No chat URL extraction | ✓ |
| No model_text_extraction | ✓ |
| No mock/dry_run | ✓ |
| No Search Agent | ✓ |
| No Dual Channel | ✓ |
| keyLeaked | false |

---

## 8. Handoff Summary

| Field | Value |
|-------|-------|
| search_level | P2_NO_SEARCH_REQUIRED (gate), P0 effective (actual) |
| evidence_pack_ref | outputs/FACTORY_R2_5_EP.json |
| design_ref | outputs/FACTORY_R2_5_DESIGN.md |
| implementation_ref | untime/tests/r2-3-x-implementation-trial/products-api.js |
| implementer_boundary | EP + Design + project files only; NO direct search |
| test_results | 7/7 PASS |
| verifier_checks | All passed; no bypass detected |

---

## 9. Output Files

| File | Description |
|------|-------------|
| outputs/FACTORY_R2_5_EP.json | Evidence Pack v2 (19 sources) |
| outputs/FACTORY_R2_5_DESIGN.md | Design document (EP-backed) |
| untime/tests/r2-3-x-implementation-trial/products-api.js | Implementation (cursor pagination, filter, search, sort) |
| untime/tests/r2-3-x-implementation-trial/r2-5-products.db | SQLite database (50 seed products) |

---


---

## R2.6 Correction (2026-07-11)

**Original classification A downgraded to B.** Reason: Gate classified this API pattern design task as P2_NO_SEARCH_REQUIRED, but the actual workflow executed /web_search, QG v5, and EP v2 — a workflow consistency violation. The gate has been fixed in R2.6 to add API_PATTERN_DESIGN as a P0 trigger category. The implementation (7/7 tests) remains valid and is retained.




| Risk | Severity | Mitigation |
|------|----------|------------|
| Gate classifies API design tasks as P2 | MEDIUM | Add API pattern keywords to P0 in next doctrine revision |
| LIKE-based search performance (no index) | LOW | Add SQLite FTS5 for production; sufficient for MVP |
| No authentication on endpoint | LOW | Task scope was pagination/filter only; auth is separate concern |

---

## 11. Recommended Next Step

**Phase:** R2.6 — Multi-Task Factory Pipeline Stress Test

Run 3-5 diverse Factory tasks through the adopted workflow in sequence to validate:
1. Gate consistency across task types
2. EP reuse (same project, multiple P0 tasks)
3. Implementer boundary holds under task variety
4. No workflow fatigue (later tasks don't skip gate)

Do NOT unfreeze baseline, reintroduce demoted paths, or let Implementer search.

---

**secretSafetyResult:** PASS
**keyLeaked:** false
**workflowStages:** 10/10 completed
**testPassRate:** 7/7 (100%)
