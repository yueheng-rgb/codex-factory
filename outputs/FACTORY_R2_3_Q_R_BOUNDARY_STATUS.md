# R2.3-Q to R2.3-R to R2.3-S Status Summary

**Date:** 2026-07-11  
**Purpose:** Define clear boundaries between R2.3-Q, R2.3-R, and R2.3-S. Prevent future misclassification.

---

## Phase Status Table

| Phase | Classification | What Was Proven | What Was NOT Proven |
|-------|---------------|-----------------|---------------------|
| **R2.3-Q** | A_PROVIDER = LIVE_PROVIDER_API_CONNECTED_AND_EP_VERIFIED | ZhipuAI API is reachable; real outbound request works; secret gate works | web_search tool was NOT invoked; response was LLM knowledge answer; source was API endpoint URL |
| **R2.3-R** | A = LIVE_SEARCH_TOOL_OR_API_INVOKED_AND_EP_VERIFIED | web_search tool invoked (server-side); 10 real external URLs extracted; Quality Gate v3 passed | Multi-provider; multi-query; production readiness; all search scenarios |
| **R2.3-S** | A = SEARCH_PIPELINE_CONSOLIDATED_WITH_REGRESSION_GUARDRAILS | 10 fatal Quality Gate checks; 4 regression tests; contract; EP schema v2; verification harness | Multi-provider live; frontend integration; production deployment |

---

## Classification Rules (DO NOT VIOLATE)

| Rule | Detail |
|------|--------|
| Plain chat completion ≠ live_search | R2.3-Q pattern of "As of my last update..." must always be D |
| API endpoint ≠ search source | open.bigmodel.cn/api/paas/... must always be rejected by CHK-11 |
| dry_run/manual ≠ live_search | CHK-0 fatal rejection, regardless of source quality |
| LLM knowledge ≠ search result | "I am a large language model..." patterns trigger CHK-10 fatal |
| metadata verified ≠ behavior verified | R2.3-E/F distinction applies to search too |

---

## Current State (as of R2.3-S)

- **Pipeline:** need_search → Provider Selector → WebSearch Tool → Quality Gate v4 → Research Intake → Evidence Pack → Agents
- **Active provider:** ZhipuAI GLM-4 (Chat Completions + web_search tool)
- **Quality Gate:** v4, 10 fatal checks, maxScore=16
- **Regression tests:** 4/4 PASS (1 positive, 3 negative)
- **Independent Search Agent:** DEPRECATED (DIR-007)
- **Dual Search Channel:** DEPRECATED (DIR-008)
- **Production Ready:** NOT CLAIMED
- **Multi-provider ready:** NOT CLAIMED
- **Frontend integrated:** NOT CLAIMED

---

## Boundary Guards

- [x] R2.3-Q corrected classification recorded
- [x] R2.3-R classification A recorded
- [x] R2.3-S pipeline consolidated
- [x] Regression guardrails active
- [x] fatal Quality Gate checks enforce all 10 rules
- [x] No Independent Search Agent
- [x] No Dual Search Channel
- [x] Implementer blocked from provider direct access
- [x] Evidence Pack is sole fact carrier
- [x] local-first preserved
