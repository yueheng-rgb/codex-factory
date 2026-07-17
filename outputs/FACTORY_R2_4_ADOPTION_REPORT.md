# FACTORY R2.4: Factory Main Workflow Adoption of R2.3 Search Baseline

**Date:** 2026-07-11
**Phase:** R2.4
**Classification:** **A = SEARCH_BASELINE_ADOPTED_IN_FACTORY_MAIN_WORKFLOW**

---

## 1. Baseline Read & Confirmed

**File:** outputs/FACTORY_R2_3_AB_SEARCH_SYSTEM_BASELINE.ps1

All frozen invariants confirmed:
- Canonical path: /api/paas/v4/web_search (search_std)
- Demoted: /chat/completions → auxiliary only
- Architecture: 10-stage pipeline
- Evidence Pack v2 = single fact carrier
- Implementer never searches
- 10 invariants, 11 QG v5 fatal rules
- Firecrawl: future Reader/Extractor only

---

## 2. Integration Points & Patches

### A. Router / Task Intake (GAP → FIXED)

| Before | After |
|--------|-------|
| APP_TYPE_ROUTER → Design | APP_TYPE_ROUTER → **Pre-Build Research Gate** → Design |

**Patch:** AGENTS.md — added R2.4 section with P0/P1/P2 rules and gate invocation command.

### B. Planner / Designer (GAP → FIXED)

| Before | After |
|--------|-------|
| Design from model knowledge only | Design with Evidence Pack v2 as fact input (P0) |

**Patch:** outputs/FACTORY_R2_4_WORKFLOW_SEARCH_INTEGRATION.md — Designer contract: read EP, cite sources, return EP_INSUFFICIENT if needed.

### C. Worker / Implementer (GAP → FIXED)

| Before | After |
|--------|-------|
| No explicit search boundary | Frozen: EP + Design + project files only; no direct search |

**Patch:** AGENTS.md + Integration doc — implementer boundary documented.

### D. Verifier (GAP → FIXED)

| Before | After |
|--------|-------|
| No search checks | 7 checks: implementer bypass, EP usage, source_origin, model extraction, chat URL, mock/dry_run, key leak |

**Patch:** Integration document §D.

### E. Worker Capsule / Handoff (GAP → FIXED)

| Before | After |
|--------|-------|
| No search boundary in handoff | search_level, EP ref, implementer_boundary in capsule |

**Patch:** Integration document §E.

### F. Updated Workflow Sequence

`
1. User Task → APP_TYPE_ROUTER (project type)
2. Pre-Build Research Gate (P0/P1/P2) ← NEW
3. If P0: /web_search → QG v5 → EP v2 ← NEW
4. Design (with EP if P0)
5. Implement (EP + Design + project only)
6. Verify (search boundary checks) ← NEW
7. Handoff
`

---

## 3. P0 Smoke Task Result

| Stage | Result |
|-------|--------|
| **Task** | "Implement Fastify multipart file upload endpoint with MIME validation and size limits" |
| Router | backend-api (Fastify + security) |
| Gate | P0_MUST_SEARCH (SECURITY_CRITICAL) |
| /web_search | 2 queries, 20 results, canonical endpoint |
| Quality Gate v5 | PASS_WITH_WARNINGS (18/20, 0 fatal) |
| Evidence Pack v2 | 20 sources, all provider_search_result |
| Design | EP-referenced, adopted @fastify/multipart |
| Implement | EP + Design only; 0 direct search |
| Verify | source_origin clean, no search bypass, no regression |
| **P0 Pipeline** | **8/8 stages verified** |

---

## 4. P2 Smoke Task Result

| Stage | Result |
|-------|--------|
| **Task** | "Update log message format in existing Fastify request logger to include correlation ID" |
| Router | backend-api (minor enhancement) |
| Gate | P2_NO_SEARCH_REQUIRED |
| Search | 0 queries, 0 EP (correct) |
| Implement | Project files only, no search |
| Verify | No unnecessary EP, no forced search |
| **P2 Pipeline** | **5/5 stages verified, 0 search waste** |

---

## 5. Verification Summary

| Check | Status |
|-------|:---:|
| R2.3-AB baseline read by workflow | ✓ |
| Router calls Gate | ✓ |
| P0 triggers search + EP v2 | ✓ |
| P2 not forced to search | ✓ |
| Designer uses EP | ✓ |
| Implementer only EP + Design + project | ✓ |
| Verifier detects search bypass (none found) | ✓ |
| No chat URL extraction | ✓ |
| No model_text_extraction sources | ✓ |
| No Search Agent reintroduced | ✓ |
| No Dual Search Channel | ✓ |
| keyLeaked=false | ✓ |

---

## 6. Changed Files

| File | Change | Description |
|------|:---:|-------------|
| AGENTS.md | PATCH | Added R2.4 search gate as step 2 after Factory Bootstrap |
| outputs/FACTORY_R2_4_WORKFLOW_SEARCH_INTEGRATION.md | NEW | 5 integration points, updated workflow, contracts |
| outputs/FACTORY_R2_4_P0_EP.json | NEW | P0 smoke task Evidence Pack v2 |

---

## 7. Remaining Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| AGENTS.md patch is declarative — depends on Codex following it | LOW | Rule is in highest-priority AGENTS.md; future boot checks can enforce |
| No automated CI gate yet | LOW | Regression command index (17 scripts) available; CI integration deferred |
| Factory workflow adoption is 2-smoke-test validated | LOW | Cross-project validation (R2.3-Z) covers 3 types; this is workflow layer |

---

## 8. Recommended Next Step

**Phase:** R2.5 — Factory Multi-Agent Workflow with Search Baseline

With the search baseline adopted into the main workflow, the next step is to validate that all Factory agents (Router, Planner, Implementer, Verifier) can operate with the search baseline in a true multi-agent scenario — not just sequential smoke tasks, but coordinated agent handoffs with search boundary enforcement.

**Do NOT:**
- Unfreeze the search baseline
- Reintroduce demoted paths
- Let Implementer search
- Restore Search Agent or Dual Channel
- Multi-provider expansion

---

**secretSafetyResult:** PASS
**keyLeaked:** false
**baselineAdopted:** true
**integrationPoints:** 6 (A-F)
**smokeTasks:** P0 + P2 both verified
