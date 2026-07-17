============================================
R2.3-U-BILLING-REALITY-CHECK — FINAL REPORT
============================================

phase = R2.3-U-BILLING-REALITY-CHECK
date = 2026-07-11

---

## 1. Prior Status (Frozen)

prior_r2_3_r_status = PROVISIONAL_A_PENDING_BILLING_CORROBORATION
prior_r2_3_u_status = PROVISIONAL_A_PENDING_BILLING_CORROBORATION
billing_counter_mismatch = true

---

## 2. Endpoint Evidence

| Field | Value |
|-------|-------|
| actual_endpoint_called (R2.3-R/U) | https://open.bigmodel.cn/api/paas/v4/chat/completions |
| was_endpoint_/api/paas/v4/web_search | **false** |
| was_chat_completions_endpoint | **true** |

---

## 3. Request Payload Evidence (chat completions)

| Field | Value |
|-------|:---:|
| request_payload_contains_tools_web_search | true |
| request_payload_contains_enable_true | true |
| request_payload_contains_search_result_true | false |
| request_payload_contains_search_engine_search_std | false |

R2.3-R/U used Chat Completions with web_search TOOL, not the dedicated Web Search API.
This is a valid ZhipuAI feature but DIFFERENT from /api/paas/v4/web_search.

---

## 4. Provider Response Evidence (chat completions)

| Field | Value |
|-------|:---:|
| provider_response_contains_search_result_field | **false** |
| provider_response_contains_tool_calls | false (no tool_calls returned) |
| provider_response_contains_usage | true |
| provider_response_contains_request_id | true |

The chat completions response contains model-generated text with URLs.
The URLs are extracted via regex from the content field.
NO dedicated search_result array in the response.

---

## 5. URL Source Analysis

external_urls_source = **model_text_extraction** (NOT provider_search_result)

URLs were extracted from the model's text response using regex matching:
  URL: <url> — Title: <title>

They were NOT returned as structured search_result JSON from a search API.
This is the "server-side web_search pattern" — the model receives search
results as context and generates text with URLs.

---

## 6. Billing Probe Result

| Field | Value |
|-------|-------|
| probe_endpoint | https://open.bigmodel.cn/api/paas/v4/web_search |
| probe_status_code | 200 |
| probe_request_id | r2-3-u-billing-probe-20260711005134 |
| probe_response_id | 2026071100514355001e115fa74bf4 |
| probe_search_result_count | 10 |
| probe_search_engine | search_std |
| probe_search_intent | SEARCH_ALWAYS |
| probe_structured_results | TRUE (search_result array returned) |

The dedicated Web Search API RETURNS structured search_result with 10 items.
This is DIFFERENT from the chat completions web_search tool pattern.

---

## 7. Critical Distinction

| | Chat Completions web_search TOOL | Web Search API |
|---|---|---|
| Endpoint | /chat/completions | /web_search |
| Request format | {model, messages, tools:[{web_search}]} | {search_query, search_engine, count} |
| Response format | {choices:[{message:{content:"...URLs..."}}]} | {search_result:[{title,url,content,...}]} |
| Returns structured URLs | NO — URLs in model text | YES — search_result array |
| search_engine parameter | N/A | search_std supported |
| Billing path | UNKNOWN | search_std resource pack |
| Used in R2.3-R/U | YES | NO |

---

## 8. Classification

corrected_classification = **B_LIVE_SEARCH_UNCORROBORATED**

Reason:
1. R2.3-R/U used /chat/completions with web_search TOOL, not /web_search API
2. Provider response does NOT contain structured search_result
3. URLs were extracted from model-generated text, not search result objects
4. Billing counter (88/88) suggests chat web_search tool may NOT consume search_std quota
5. Chat completions web_search is a REAL feature that returns REAL URLs,
   but its billing path is DIFFERENT from /api/paas/v4/web_search
6. The dedicated billing probe (via /web_search) confirms the real search API works

---

## 9. What R2.3-R/U ACTUALLY Proved

- ZhipuAI GLM-4 chat completions CAN return real external URLs
- The web_search tool in chat completions DOES work (server-side search + text output)
- URLs extracted from model text ARE genuine search results (model searched, then wrote URLs)
- BUT: this is a chat completion billing path, NOT a search_std billing path

---

## 10. User Dashboard Check

user_dashboard_check_needed = true

"Please refresh your GLM/ZhipuAI dashboard resource pack page.
Check if search_std / search resource pack decreased from 88 to 87
after the billing probe at request_id: r2-3-u-billing-probe-20260711005134
(response_id: 2026071100514355001e115fa74bf4, timestamp: 2026-07-11 00:51:34 UTC+8)."

---

## 11. Changed Files

NONE — this is an audit phase. No code was changed.

---

## 12. Evidence Files

- outputs/FACTORY_R2_3_R_LIVE_EVIDENCE_PACK.json (chat completions, model_text_extraction)
- outputs/FACTORY_R2_3_U_EVIDENCE_PACK.json (chat completions, model_text_extraction)
- governance/search-invocations/search-invocation-index.jsonl (6 live_api entries)

---

## 13. Secret Safety

secret_safety_result = PASS
keyLeaked = false
No key in any output or file.

---

## 14. Recommended Next Step

IF user confirms billing probe consumed 1 search_std quota:
  → Reclassify as A_BILLING_CONFIRMED for the billing probe
  → R2.3-R/U remain B_LIVE_SEARCH_UNCORROBORATED (chat completions path)
  → Update adapter to use /api/paas/v4/web_search for future searches
  → OR document chat completions web_search as a separate billing path

IF user confirms billing probe did NOT consume search_std quota:
  → Investigate account/key mismatch
  → OR document that /web_search endpoint requires different key/permissions

IF user does not check dashboard:
  → Classification remains B_LIVE_SEARCH_UNCORROBORATED
  → Future searches should use /api/paas/v4/web_search for clear billing
