# FACTORY R2.8: Input Validation Gate Fix & Feature Batch Regression

**Date:** 2026-07-11
**Phase:** R2.8
**Classification:** **A = INPUT_VALIDATION_GATE_FIXED_AND_BATCH_REGRESSION_PASS**

---

## 1. R2.7 Correction

| Field | Before | After (R2.8) |
|-------|--------|-------------|
| Classification | A | **B** |
| Reason | — | POST /products input validation design misclassified as P2 |
| Tests | 11/11 PASS | Retained |

---

## 2. Gate Changes (v2.0.3)

### New Trigger: USER_INPUT_VALIDATION_DESIGN

**Triggers when task involves:**
- Input validation, request body validation, schema validation
- Required fields, type checking, field whitelist/allowlist
- User-controlled input, validation error response design
- Payload contract, request sanitization, boundary validation

**Score:** +4 (sufficient for P0 when it's the only trigger)

**P2 exclusion (no search):**
- Modify validation error message (minor text change)
- Fix existing validation bug (well-understood)
- Copy existing field pattern (no new contract)
- Simple field addition following existing schema

### Regex Fix
All patterns now use [.\s-]? or .* to match both "input.validation" and "input validation" (dots, spaces, hyphens).

---

## 3. Regression Task Results (5/5 Correct)

| ID | Task | Expected | Result |
|----|------|:---:|--------|
| A | POST /products input validation | P0 | **P0_MUST_SEARCH** (USER_INPUT_VALIDATION_DESIGN) ✓ |
| B | PATCH /products update validation | P0 | **P0_MUST_SEARCH** (USER_INPUT_VALIDATION_DESIGN) ✓ |
| C | Modify validation error message | P2 | **P2_NO_SEARCH_REQUIRED** ✓ |
| D | Add field copying existing pattern | P2 | **P2_NO_SEARCH_REQUIRED** ✓ |
| E | File upload MIME validation | P0 | **P0_MUST_SEARCH** (SECURITY_CRITICAL) ✓ |

---

## 4. Products API Regression

| Test Group | Count | Result |
|------------|:---:|:---:|
| R2.5: List + Filter + Health | 3/3 | PASS |
| R2.7 F1: Detail + 404 | 2/2 | PASS |
| R2.7 F2: Create + missing fields + negative price | 3/3 | PASS |
| R2.7 F3: Status transitions (a→i, i→ar, ar→a blocked) | 3/3 | PASS |
| **Total** | **11/11** | **PASS** |

---

## 5. Oversoarch Guardrail

| Guardrail | Result |
|-----------|:---:|
| Modify validation message → P2, no search | ✓ |
| Copy existing field → P2, no search | ✓ |
| P2 + search without escalation → FAIL_WORKFLOW_CONSISTENCY | ✓ (checker active) |

---

## 6. Implementer Boundary

| Check | Result |
|-------|:---:|
| IMPL agent search attempt → REJECT | ✓ |
| Fatal: IMPLEMENTER_SEARCH_ATTEMPT | ✓ |

---

## 7. Gate Evolution Summary

| Version | Phase | Change |
|---------|-------|--------|
| v2.0.1 | R2.3-Y | Original P0/P1/P2 + CSS exclusion |
| v2.0.2 | R2.6 | +API_PATTERN_DESIGN |
| v2.0.3 | R2.8 | +USER_INPUT_VALIDATION_DESIGN, regex space fixes |

---

## 8. Changed Files

| File | Change |
|------|:---:|
| untime/pre-build-research-gate.ps1 | Rebuilt v2.0.3 (+USER_INPUT_VALIDATION_DESIGN, regex fixes) |
| outputs/FACTORY_R2_7_FEATURE_BATCH_REPORT.md | Classification A→B, added R2.8 correction note |

---

## 9. Remaining Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Gate is regex-based — may miss novel patterns | LOW | Regular regression (R2.6, R2.7, R2.8) catches gaps |
| P2 exclusion regexes may have edge cases | LOW | modify.*message pattern is broad; monitor for false exclusions |

---

## 10. Recommended Next Step

**Phase:** R2.9 — Search Pipeline Operational Freeze & Factory Delivery Standard

With the gate stabilized through 3 cycles of fixes and regression, and 5 functioning Products API endpoints delivered:
1. Freeze the search pipeline as operational standard
2. Document the Products API as a reference implementation
3. Create a Factory task template that includes search gate as a mandatory step

**Do NOT:**
- Continue gate optimization
- Multi-provider
- Production Readiness
- Restore Search Agent or Dual Channel

---

**secretSafetyResult:** PASS
**keyLeaked:** false
**gateVersion:** v2.0.3
**regressionPassRate:** 5/5 gate + 11/11 products API
