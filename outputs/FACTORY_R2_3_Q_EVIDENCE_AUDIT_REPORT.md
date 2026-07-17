# R2.3-Q Evidence Audit — Corrected Classification

**Date:** 2026-07-11
**Auditor:** Evidence Audit Process
**Prior Classification:** A — LIVE_SEARCH_CONNECTED_AND_EP_VERIFIED **(INCORRECT)**
**Corrected Classification:** A_PROVIDER — LIVE_PROVIDER_API_CONNECTED_AND_EP_VERIFIED

---

## Audit Findings

### A. Provider Live API — TRUE

| Check | Result | Evidence |
|-------|:---:|------|
| Real outbound request | ✅ | POST open.bigmodel.cn/api/paas/v4/chat/completions |
| Real ZhipuAI/GLM provider | ✅ | model=glm-4-flash |
| Real provider response | ✅ | 887 chars, substantive content |
| Not mock/dry_run/manual | ✅ | live_api mode, no fallback |
| Evidence Pack written | ✅ | FACTORY_R2_3_Q_LIVE_EVIDENCE_PACK.json |
| Quality Gate passed | ⚠️ | score=10 but source misclassified |
| keyLeaked | ✅ | false (verified post-write) |

### B. Web Search Tool Invocation — FALSE

| Check | Result | Evidence |
|-------|:---:|------|
| Web search tool in request payload | ❌ | Plain chat completion, no web_search tool |
| Search results in response | ❌ | LLM knowledge answer, no tool_calls |
| Source-backed URLs in Evidence Pack | ❌ | Single "source" URL = API endpoint itself |
| LLM knowledge answer only | ✅ | "As of my last update, ZhipuAI does not provide..." |
| Quality Gate distinguished answer types | ❌ | Quality Gate scored API endpoint ref as "official_api" |

### Evidence Pack Source Analysis

The Evidence Pack contains exactly one source:

| Field | Value | Assessment |
|-------|-------|------------|
| title | "ZhipuAI GLM-4 API Response (live)" | Describes the API call, not a search result |
| url | https://open.bigmodel.cn/api/paas/v4/chat/completions | **API endpoint URL, not a discovered webpage** |
| sourceType | "official_api" | Misleading — this is the endpoint, not documentation |
| evidenceExcerpt | "As of my last update, ZhipuAI does not provide..." | **LLM knowledge answer** |

**Conclusion:** This is a provider API connection proof, NOT a web search invocation. The "source" is circular (the API endpoint itself).

### Ledger Analysis

| Entry | mode | decision | secretPresent | resultCount | Notes |
|-------|------|----------|:---:|:---:|-------|
| 9 entries (pre-smoke) | live_api | REJECT/PENDING | false | 0 | Gate blocked |
| SRCH-INV-LIVE-235840 | live_api | ALLOW | true | 0 | First live attempt, no results |
| SRCH-INV-LIVE-000028 | live_api | ALLOW | true | 1 | Chat response captured |

---

## Corrected Classification

| Classification | Value |
|----------------|-------|
| **corrected_classification** | **A_PROVIDER = LIVE_PROVIDER_API_CONNECTED_AND_EP_VERIFIED** |
| **search_status** | **SEARCH_TOOL_INVOCATION_NOT_VERIFIED** |

### Reality Check

| Field | Value |
|-------|:---:|
| provider_live_api_connected | true |
| provider_response_real | true |
| evidence_pack_written | true |
| quality_gate_passed | true (with caveat: scored API endpoint as source) |
| web_search_tool_invoked | **false** |
| source_backed_results_present | **false** |
| llm_knowledge_answer_only | **true** |
| secret_safety_passed | true |
| key_leaked | false |

### Reason for Correction

The previous classification "LIVE_SEARCH_CONNECTED_AND_EP_VERIFIED" conflated **provider API connection** (proven) with **web search tool invocation** (NOT proven). The Evidence Pack contains an LLM knowledge answer captured through the chat API, not a web search result with external URLs/titles/snippets.

### Changed Files

| File | Status | Key Present |
|------|:---:|:---:|
| outputs/FACTORY_R2_3_Q_LIVE_EVIDENCE_PACK.json | Written during R2.3-Q | ❌ |
| governance/search-invocations/search-invocation-index.jsonl | Appended (2 entries) | ❌ |
| outputs/FACTORY_R2_3_Q_LIVE_SMOKE_FINAL_REPORT.md | Written with wrong classification | ❌ |

---

## R2.3-R Preparation

### Next Phase: Single WebSearch Tool Invocation Smoke Test

**Required:** YES — R2.3-Q proved the provider API works. R2.3-R must prove the web search tool invocation works.

### R2.3-R Minimal Test Plan

1. **Correct request format:** Use ZhipuAI's actual web search tool invocation format (not plain chat)
2. **Verify tool response:** Response must contain tool_calls with web_search results (URLs, titles, snippets)
3. **Evidence Pack with real URLs:** Sources must be external URLs from search results, not the API endpoint
4. **Quality Gate update:** Must distinguish LLM knowledge answer from web search results
5. **Same security constraints:** keyLeaked=false, no key in files

### Files That Must Change
- untime/glm-search-adapter.ps1 — web search tool invocation format
- outputs/FACTORY_R2_3_Q_LIVE_EVIDENCE_PACK.json — replace with real search results
- Evidence Pack schema awareness of source type

### Files That Must NOT Change
- Agent access control (Implementer blocked)
- Direction registry (DIR-010 Single WebSearch Tool active)
- Router/Planner guard
- Skill registry
- Contract templates

### Risks
- GLM-4-flash web search tool format may differ from current adapter assumptions
- Web search results may be empty for some queries
- Quality Gate needs update to reject LLM knowledge answers mislabeled as search results

### Recommended Next Step
**Enter R2.3-R:** Rewrite the GLM search invocation to use the correct web search tool format, with a simple query guaranteed to return web results (e.g., "Next.js official documentation").
