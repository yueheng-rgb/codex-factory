# R2.3-O Step 0 — Direction Reconciliation & Deprecation Report

**Date:** 2026-07-10  
**Status:** COMPLETE  
**Verification:** 5/5 direction guard tests PASS

---

## 1. Summary

R2.3-N's Claim Audit revealed 5 overstatements and a direction drift where "GLM Live API" and "Frontend Tool Trial" were presented as immediate next phases. This Step 0 formally reconciles the roadmap, marks wrong directions as deferred/deprecated, establishes a Direction Decision Registry, creates a Router/Planner Guard, and sets **Evidence Search Loop (DIR-004)** as the sole active next phase.

---

## 2. Directions Status Registry

| ID | Title | Status | Superseded By |
|----|-------|:---:|---|
| DIR-001 | GLM Live API Smoke Test as Immediate Default | **deferred** | DIR-004 |
| DIR-002 | Frontend Tool Trial / Stitch MCP as Immediate | **deferred** | DIR-004 |
| DIR-003 | First Real API / GLM Live Integration Completed | **deprecated** | DIR-004 |
| DIR-004 | Evidence Search Loop as Active Next Phase | **active** | — |
| DIR-005 | Production Readiness Language | **deprecated** | — |
| DIR-006 | Search Provider Live API (General) | **deferred** | DIR-004 |

---

## 3. Files Modified / Corrected

| File | Change | Type |
|------|--------|:---:|
| FACTORY_R2_3_N_NEXT_PHASE_RECOMMENDATION.md | Replaced: Frontend Tool Trial → Evidence Search Loop; GLM Live API → deferred | **CORRECTED** |
| FACTORY_R2_3_M_NEXT_PHASE_RECOMMENDATION.md | Replaced: "First Real API" language removed | **CORRECTED** |
| FACTORY_R2_3_N_GLM_SEARCH_ADAPTER_DESIGN.md | Clarified: "candidate/framework only, NOT YET EXECUTED" | **CORRECTED** (during Claim Audit) |
| FACTORY_R2_3_N_EXTERNAL_SEARCH_PROVIDER_ADAPTER_REPORT.md | "first real external" → "External Search Provider Adapter MVP" | **CORRECTED** (during Claim Audit) |
| FACTORY_R2_3_N_RESEARCH_INTAKE_INTEGRATION_REPORT.md | "real ZhipuAI API call" → "GATED, NOT YET EXECUTED" | **CORRECTED** (during Claim Audit) |

---

## 4. Files NOT Modified (Historical / Audit Evidence Preserved)

| File | Reason |
|------|--------|
| FACTORY_R2_3_B_NEXT_PHASE_PLAN.md | Historical plan from earlier phase |
| FACTORY_R2_3_D_NEXT_PHASE_RECOMMENDATION.md | Historical, from pre-search phases |
| FACTORY_R2_3_J_NEXT_PHASE_RECOMMENDATION.md | Reference to earlier R2.3-J phase |
| FACTORY_R2_3_K_NEXT_PHASE_RECOMMENDATION.md | Playwright sandbox trial completed |
| FACTORY_R2_3_L_NEXT_PHASE_RECOMMENDATION.md | Network boundary phase — "Production Readiness" noted as deprecated (DIR-005) |
| FACTORY_R2_3_M_LOCAL_RUNTIME_READINESS_STATEMENT.md | States "NOT Production Ready" correctly |
| FACTORY_R2_3_N_CLAIM_AUDIT_REPORT.md | **Preserved as audit evidence** — documents the overstatements found |

---

## 5. New Files Created

| File | Purpose |
|------|---------|
| schemas/direction-decision.schema.json | Schema for direction status records |
| governance/direction-decisions/direction-decision-index.jsonl | 6 entry ledger (DIR-001 through DIR-006) |
| untime/router-direction-guard.ps1 | Router/Planner guard: blocks superseded/deprecated/deferred directions |

---

## 6. Router / Planner Guard Rules

Active rules enforced by untime/router-direction-guard.ps1:

1. **superseded/deprecated** directions → **REJECT** (cannot be selected as next phase)
2. **deferred** directions → **REJECT** without prerequisites (API key, human approval, etc.)
3. **active** direction → **ALLOW** (DIR-004 only)
4. **Better-method check** required for any proposed new direction:
   - Is there a better active method?
   - Is there evidence?
   - Are there hidden risks (external API without key)?

---

## 7. Direction Guard Test Results

`
DIR-001 (GLM live):       allowed=False → REJECT_DEFERRED    ✅
DIR-002 (Frontend):       allowed=False → REJECT_DEFERRED    ✅
DIR-003 (First Real API): allowed=False → REJECT_DEPRECATED  ✅
DIR-004 (Evidence Loop):  allowed=True  → ALLOW              ✅
DIR-005 (Prod Ready):     allowed=False → REJECT_DEPRECATED  ✅
5/5 expected results match
`

---

## 8. R2.3-O Entry Conditions

Before entering R2.3-O Evidence Search Loop:

- [x] Old GLM live API immediate direction removed from active roadmap
- [x] Frontend Tool Trial immediate direction removed from active roadmap
- [x] First Real API overstatements corrected / deprecated
- [x] Evidence Search Loop is the only active next phase
- [x] Deferred directions preserved, not auto-executed
- [x] Historical audit evidence preserved (no files deleted)
- [x] Direction Decision Registry operational
- [x] Router/Planner Direction Guard operational

**Conclusion:** Step 0 is COMPLETE. R2.3-O Evidence Search Loop is ready to start.
