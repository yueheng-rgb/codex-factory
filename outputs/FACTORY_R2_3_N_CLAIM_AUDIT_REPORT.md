# R2.3-N Claim Audit Report

**Audit Date:** 2026-07-10  
**Phase Under Audit:** FACTORY-R2.3-N  
**Auditor:** SEC-001 / Claim Audit Process  
**Classification:** **B — LIVE_API_READY_NOT_EXECUTED**

---

## Audit Questions & Evidence

### Q1: Was live_api_mode actually executed?

**Answer: NO.**

Zero live_api entries in the search invocation ledger have decision=ALLOW_WITH_CONTROLS. All 9 live_api entries are either PENDING_HUMAN (6) or REJECT (3).

### Q2: Is there a real GLM / Zhipu API key?

**Answer: NO.**

- ZHIPUAI_API_KEY (Process): not set
- GLM_API_KEY (Process): not set
- ZHIPUAI_API_KEY (User): not set
- GLM_API_KEY (User): not set
- ZHIPUAI_API_KEY (Machine): not set
- GLM_API_KEY (Machine): not set
- All ledger entries: secretPresent=false

### Q3: API key only from environment variables?

**Answer: YES — by design.**

The adapter checks ZHIPUAI_API_KEY and GLM_API_KEY env vars only. No key was ever found. The secret-presence-check.ps1 enforces env-var-only policy. This part is correct.

### Q4: Did the user explicitly approve live_api?

**Answer: NO.**

No record of user explicitly approving live_api mode for real API calls. In simulation scenarios, -UserApproval was set to $true for S04-S06 as part of testing the adapter framework, not as actual user authorization for real outbound calls.

### Q5: Evidence of real outbound API request?

**Answer: NO.**

- Zero live_api + ALLOW_WITH_CONTROLS ledger entries
- The adapter's live_api code path was exercised only in simulation S06, which used a fake key (	est-key-real-abcdef123456) that caused the real Invoke-RestMethod call to fail → downgrade to dry_run
- No successful Invoke-RestMethod to open.bigmodel.cn ever completed

### Q6: Evidence of real provider response?

**Answer: NO.**

All 44 ledger entries used mock/dry_run data or manual input. No ZhipuAI API response data exists in any ledger, output, or log.

### Q7: What modes are in the search-invocation ledger?

**Answer:**

| Mode | Count | Decisions |
|------|:---:|------|
| manual | 17 | ALLOW_WITH_CONTROLS: 13, REJECT: 4 |
| dry_run | 18 | ALLOW_WITH_CONTROLS: 6, REJECT: 8, DOWNGRADED_TO_DRY_RUN: 4 |
| live_api | 9 | PENDING_HUMAN: 6, REJECT: 3 |

### Q8: Any mode=live_api + decision=ALLOW_WITH_CONTROLS?

**Answer: NO. Zero entries.**

### Q9: Any live_api_not_executed_by_policy / downgraded / missing_key records?

**Answer:**

- LIVE_API_NOT_EXECUTED_BY_POLICY: 0 entries (this status exists in schema but was never used)
- DOWNGRADED_TO_DRY_RUN: 4 entries — all are in dry_run mode (the downgrade already happened before ledger write), downgradedFrom=live_api
- missing_key or equivalent: captured as DOWNGRADED_TO_DRY_RUN with secretPresent=false

**Gap:** The LIVE_API_NOT_EXECUTED_BY_POLICY decision exists in the schema but was never used. Scenarios that should use it (S04: no key + no approval) used DOWNGRADED_TO_DRY_RUN instead. This is a minor schema-vs-implementation inconsistency but does not affect the audit conclusion.

### Q10: Overstatements in reports?

**Answer: YES — 5 instances found.**

| File | Claim | Severity |
|------|-------|:---:|
| FACTORY_R2_3_N_EXTERNAL_SEARCH_PROVIDER_ADAPTER_REPORT.md | "establishes the **first real external** search provider adapter" | HIGH |
| FACTORY_R2_3_N_EXTERNAL_SEARCH_PROVIDER_ADAPTER_REPORT.md | "production search" (in readiness context) | MEDIUM |
| FACTORY_R2_3_N_GLM_SEARCH_ADAPTER_DESIGN.md | "**first real API** call" / "**real** API call" | HIGH |
| FACTORY_R2_3_N_GLM_SEARCH_ADAPTER_DESIGN.md | "**first external_api provider** registered" | MEDIUM |
| FACTORY_R2_3_N_RESEARCH_INTAKE_INTEGRATION_REPORT.md | "**real ZhipuAI API call**" in pipeline diagram | HIGH |

All of these imply a real API connection that did not happen. The adapter FRAMEWORK is complete and functional, but no real API call was ever executed.

---

## Classification

**Verdict: B — LIVE_API_READY_NOT_EXECUTED**

| Criterion | Evidence | Verdict |
|-----------|----------|:---:|
| live_api code path exists | Yes, in glm-search-adapter.ps1 | ✅ |
| API key exists | No, all env vars empty | ❌ |
| Human explicitly approved | No | ❌ |
| Real outbound request | No | ❌ |
| Real provider response | No | ❌ |
| Gate/quality/ledger framework | Fully operational | ✅ |
| manual_mode works | Yes, 17 entries | ✅ |
| dry_run_mode works | Yes, 18 entries | ✅ |
| Safe downgrade on missing key | Yes, 4 entries | ✅ |

---

## Required Report Corrections

All 5 overstatement instances MUST be corrected:

1. ~~"first real external search provider adapter"~~ → "External Search Provider Adapter MVP (framework, not yet live-connected)"
2. ~~"production search"~~ → Remove from readiness context
3. ~~"first real API" / "real API call"~~ → "live_api code path (gated, not yet executed)"
4. ~~"first external_api provider registered"~~ → "first external_api provider registered (candidate status, pending first real call)"
5. ~~"real ZhipuAI API call" in pipeline~~ → "ZhipuAI API call (gated, requires key + human approval)"

---

## What R2.3-N Actually Delivers

**Did deliver:**
- Complete 3-mode adapter framework (manual/dry_run/live_api code paths)
- Secret handling policy and presence check
- Search Quality Gate v2 (12-point)
- Research Intake integration
- Search Invocation Ledger
- Tool Permission Gate integration
- 10/10 simulation PASS (framework validation, not real API validation)
- 32/32 verification PASS

**Did NOT deliver:**
- Real GLM/Zhipu API connection
- Real outbound network request
- Real provider response data
- Any live_api + ALLOW_WITH_CONTROLS ledger entry
- Human approval for live API
- API key deployment
