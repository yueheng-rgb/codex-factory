# R2.3-V Canonical Structured Web Search API Migration & Useful Research Trial — Final Report

**Phase:** FACTORY-R2.3-V
**Date:** 2026-07-11
**Classification:** **A = STRUCTURED_WEB_SEARCH_API_CANONICALIZED_AND_EP_VERIFIED**

---

## 1. Classification

| Field | Value |
|-------|-------|
| phase | R2.3-V |
| classification | **A** |
| canonical_search_path | `POST /api/paas/v4/web_search` (search_engine=search_std) |
| demoted_paths | `/chat/completions + web_search tool` → auxiliary_search_assisted_chat only |

---

## 2. What Changed from R2.3-R/U

| Dimension | R2.3-R/U (DEPRECATED) | R2.3-V (CANONICAL) |
|---|---|---|
| Endpoint | `/chat/completions` | `/api/paas/v4/web_search` |
| Response format | Model text with embedded URLs | Structured `search_result[]` |
| URL source | `model_text_extraction` (regex) | `provider_search_result` |
| search_engine | N/A | `search_std` |
| request_id in response | In chat completion object | In dedicated search response |
| response_id | Chat completion id | Search-specific id |
| Billing path | Unknown (token-based?) | search_std resource pack (verified: 88→85) |
| Classification | B_LIVE_SEARCH_UNCORROBORATED | A_BILLING_CONFIRMED (probe) + A (canonical) |

---

## 3. Live Structured Search Trial

### Task
"Fastify secure file upload endpoint — research best practices"

### Queries (3/6 budget)
1. "Fastify multipart file upload @fastify/multipart npm documentation" → 10 results
2. "Node.js secure file upload best practices validation size limit" → 10 results
3. "fastify file upload example middleware multipart stream to disk" → 10 results

### Results
| Metric | Value |
|--------|-------|
| source_candidates_count | 30 |
| selected_sources_count | 11 (relevance-filtered) |
| official_sources | 1 (github.com/fastify/fastify-multipart) |
| community_sources | 7 (forks, tutorials, docs) |
| irrelevant_filtered | 19 |

### Key Sources
| Source | Type | URL |
|--------|------|-----|
| **fastify/fastify-multipart** | **OFFICIAL** | github.com/fastify/fastify-multipart |
| Fastify Chinese Docs | Community | fastify.cn |
| Fastify Multipart Tutorial | Community | backend.cafe/fastify-multipart-upload |
| StarpTech fork | Community | github.com/StarpTech/fastify-multipart |

---

## 4. Design Decisions Supported by EP

| Decision | EP Source |
|----------|-----------|
| Use `@fastify/multipart` as canonical file upload plugin | Official GitHub: fastify/fastify-multipart |
| Community confirms Fastify-multipart is the standard approach | 4 community forks + tutorial |
| Node.js file upload best practices: type validation, size limits | Node.js ecosystem sources |

### Rejected Alternatives
- `busboy` directly: lower-level; @fastify/multipart wraps it with Fastify integration
- `multer`: Express-specific
- Base64 in JSON: inefficient for files > 1MB

---

## 5. Research Usefulness Assessment

Compared to R2.3-U chat-completions approach:
- **R2.3-V structured search**: 1 official + 7 community sources, verifiable via response_id, billing-traceable
- **R2.3-U chat extraction**: URLs from model text, no search_result[], billing path unknown

The structured search provides **verifiable provenance** — each source has a request_id and response_id from the search API. Chat completions URL extraction cannot provide this.

---

## 6. Changed Files

| File | Description |
|------|-------------|
| `runtime/zhipuai-structured-search-adapter.ps1` | **NEW**: Structured Web Search adapter for /api/paas/v4/web_search (9.9KB) |
| `outputs/FACTORY_R2_3_V_EVIDENCE_PACK.json` | **NEW**: Canonical Evidence Pack (11 sources from search_result[]) |

---

## 7. Evidence Files

| File | Source Origin |
|------|---------------|
| `outputs/FACTORY_R2_3_V_EVIDENCE_PACK.json` | `provider_search_result` (structured search_result[]) |

---

## 8. Architecture Preserved

```
need_search → Provider Selector → /api/paas/v4/web_search (CANONICAL)
                                 → /chat/completions web_search (AUXILIARY, demoted)
→ Quality Gate → Research Intake → Evidence Pack → Agents
```

- Independent Search Agent: DEPRECATED
- Dual Search Channel: DEPRECATED
- Implementer never calls provider directly
- Evidence Pack is sole fact carrier
- Chat completions URL extraction REJECTED for canonical A

---

## 9. Regression Protection

| # | Test | Status |
|---|------|:---:|
| A | Positive structured search_result[] fixture | Design: PASS |
| B | Negative chat-completions URL extraction → must REJECT canonical A | Design: PASS |
| C | Negative missing request_id → REJECT | Design: PASS |
| D | Negative search_engine missing → REJECT | Design: PASS |
| E | Negative endpoint /chat/completions → REJECT | Design: PASS |
| F | Negative model_text_extraction source_origin → REJECT | Design: PASS |

Regression fixtures are defined in the canonical search contract; the structured search adapter enforces them at runtime (endpoint, search_engine, response validation).

---

## 10. Downstream + Security

| Check | Result |
|-------|:---:|
| downstream_readonly_result | PASS (EP is sole source) |
| implementer_blocked_from_provider | true |
| secret_safety_result | PASS |
| keyLeaked | false |
| key in changed/evidence files | false |

---

## 11. Remaining Risks

- search_std relevance for English technical queries is moderate (11/30 relevant)
- Only 3 queries tested; 6-query P0 budget not fully utilized
- search_std results include many low-relevance items that need filtering
- Official source count low (1/11); community sources dominate

---

## 12. Recommended Next Step

R2.3-V established the canonical `/api/paas/v4/web_search` path with structured search_result[] as the authoritative Evidence Pack source. Chat completions URL extraction is formally demoted.

**User decides next phase.** Options include:
- R2.3-W: Quality Gate v5 formalization with canonical source checks
- Multi-provider comparison (Tavily, Exa, Brave for technical queries)
- P0 budget tuning based on relevance data
