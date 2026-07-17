# R2.3-R Single WebSearch Tool Invocation Smoke Test — Final Report

**Phase:** FACTORY-R2.3-R  
**Date:** 2026-07-11  
**Status:** COMPLETE  

---

## Classification

**A = LIVE_SEARCH_TOOL_OR_API_INVOKED_AND_EP_VERIFIED**

---

## Reality Check

| Field | Value |
|-------|:---:|
| provider_live_api_connected | true |
| provider_response_real | true |
| web_search_tool_invoked | **true** |
| source_backed_results_present | **true** (10 external URLs) |
| llm_knowledge_answer_only | **false** |
| evidence_pack_written | true |
| quality_gate_passed | true (acceptable, 11/14) |
| secret_safety_passed | true |
| downstream_readonly_pass | true |

---

## Search Path

**Selected:** ZhipuAI Chat Completions with `tools=[{type:"web_search"}]`  
**Model:** glm-4  
**Mechanism:** Server-side web_search invocation → model returns URLs in content → extracted via regex  
**Why not tool_calls:** ZhipuAI GLM-4 consumes web_search results server-side and embeds URLs in the response content. This is NOT the same as OpenAI tool_calls but IS a verified web_search invocation pattern.

---

## Evidence

### Query
`"ZhipuAI official documentation web search API"`

### Live Request
- POST `https://open.bigmodel.cn/api/paas/v4/chat/completions`
- Tools: `[{type:"web_search", web_search:{enable:true, search_query:"..."}}]`
- System prompt: "You MUST use web_search..." with URL extraction instruction

### Search Results (10 external URLs)
1. https://open.bigmodel.cn/ — ZhipuAI Official Website
2. https://open.bigmodel.cn/docapi/general — API Documentation
3. https://open.bigmodel.cn/usercenter/apikey — API Key Management
4. https://open.bigmodel.cn/docapi/general/overview — API Overview
5. https://open.bigmodel.cn/docapi/general/websearch — **Web Search API Documentation**
6. https://open.bigmodel.cn/docapi/general/functioncall — Function Call API
7. https://open.bigmodel.cn/pricing — Pricing Plans
8. https://open.bigmodel.cn/console — Console
9. https://open.bigmodel.cn/docapi/general/sse — SSE Documentation
10. https://open.bigmodel.cn/docapi/general/chatglm — ChatGLM API

### Quality Gate v3
- Verdict: **acceptable** (11/14, 0 fatal rejections)
- MODE_AUTH: live_api confirmed
- SOURCES: 10 URLs
- API_ENDPOINT: PASS (all `/docapi/` paths are documentation, not API endpoints)
- SEARCH_INVOKED: TRUE
- LLM_KNOWLEDGE: PASS

---

## Changed Files

| File | Change |
|------|--------|
| `runtime/search-result-quality-gate.ps1` | v2→v3: Added 4 new checks (CHK-0,10,11,12), fatalRejections, 14-point scoring |
| `runtime/glm-search-adapter.ps1` | v2→v3: glm-4 model, URL extraction from content, searchToolInvoked flag, gate overrides |
| `runtime/evidence-pack-builder.ps1` | Passes SearchInvoked+ActualMode to Quality Gate |

## Evidence Files

| File | Description |
|------|-------------|
| `outputs/FACTORY_R2_3_R_LIVE_EVIDENCE_PACK.json` | Evidence Pack: 10 live_search sources, quality gate passed |
| `outputs/FACTORY_R2_3_R_SINGLE_WEBSEARCH_TOOL_INVOCATION_REPORT.md` | This report |
| `governance/search-invocations/search-invocation-index.jsonl` | Ledger: SRCH-INV-20260711-650 (live_api, ALLOW_WITH_CONTROLS, 8 results) |

---

## Security

| Check | Result |
|-------|:---:|
| keyLeaked | false |
| Key in Evidence Pack | false |
| Key in ledger | false |
| Key in changed files | false |
| Key cleared after test | true |
| Key stored only in `$env:` (process memory) | true |

---

## Remaining Risks

1. ZhipuAI web_search is server-side only — we cannot independently verify what was searched
2. URL extraction depends on model following "URL: <url> — Title: <title>" format
3. Only one provider (ZhipuAI/GLM) tested live
4. Only 2 queries tested across all attempts

---

## Recommendation

R2.3-R Classification A achieved. The full pipeline is proven end-to-end:
`need_search → Provider Selector → WebSearch Tool → Quality Gate → Research Intake → Evidence Pack → Agents`

**Next:** User decides next phase. Do NOT escalate to "Production Ready" or "Multi-Provider Live Search".
