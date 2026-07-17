# Search Engine Connection Reality Check

**Date:** 2026-07-10  
**Classification:** **B — LIVE_PROVIDER_READY_NOT_EXECUTED**

---

## Q1: API Keys — 0/7 Present

| Provider | Key Variable | Process | User | Machine |
|----------|-------------|:---:|:---:|:---:|
| GLM (ZhipuAI) | ZHIPUAI_API_KEY | ❌ | ❌ | ❌ |
| GLM (alt) | GLM_API_KEY | ❌ | ❌ | ❌ |
| Tavily | TAVILY_API_KEY | ❌ | ❌ | ❌ |
| Exa | EXA_API_KEY | ❌ | ❌ | ❌ |
| Brave | BRAVE_SEARCH_API_KEY | ❌ | ❌ | ❌ |
| Firecrawl | FIRECRAWL_API_KEY | ❌ | ❌ | ❌ |
| Jina | JINA_API_KEY | ❌ | ❌ | ❌ |

**Result:** Zero API keys across all scopes. No non-example .env files found.

---

## Q2: Live API Invocations — 0 Successful

| Metric | Count |
|--------|:---:|
| Total search invocation entries | 82 |
| live_api mode entries | 9 |
| live_api + ALLOW_WITH_CONTROLS | **0** |
| live_api + secretPresent=true | **0** |
| live_api + resultCount > 0 | **0** |

All 9 live_api entries are either REJECT (3 — permission gate) or PENDING_HUMAN (6 — no human approval). All have secretPresent=false and esultCount=0.

---

## Q3: Real Outbound Request — 0

- Adapter contains Invoke-RestMethod code and open.bigmodel.cn URL — but this code path was **never triggered** with a real API key
- No curl, no SDK, no provider response data exists
- Simulation scenario S06 used a fake key (	est-key-real-abcdef123456) which caused the real HTTP call to fail → caught by try/catch → downgraded to dry_run

---

## Q4: Evidence Search Loop Source — manual + dry_run ONLY

- iterative-search-loop.ps1 invokes GLM search with -DryRunOnly True — always uses mock fixture data
- All 82 ledger entries are mode=manual (39) or mode=dry_run (34) or mode=live_api with REJECT/PENDING (9)
- Simulation 12/12 PASS — all scenarios use manual or dry_run data
- **Zero** evidence packs contain data from a real search engine API

---

## Q5: Report Overstatements — 0 Active Claims

All 5 "First Real API" hits are in deprecated/deferred context:
- FACTORY_R2_3_O_DIRECTION_RECONCILIATION_REPORT.md — deprecated direction table (historical evidence)
- FACTORY_R2_3_O_NEXT_PHASE_RECOMMENDATION.md — listed as "deferred/deprecated" with explicit NOT instruction
- Main R2.3-O report correctly states: "live_api gated", "NOT production", "local-first", "dry_run/manual operational", "no external API connected"

---

## Classification: B — LIVE_PROVIDER_READY_NOT_EXECUTED

**Evidence:**
- ✅ Adapter framework with 3-mode support (manual, dry_run, live_api code paths)
- ✅ 10-provider comparison matrix registered
- ✅ Tool Permission Gate, Quality Gate, Evidence Pack, Iterative Loop — all operational
- ✅ 82 invocation ledger entries (all manual/dry_run/gated)
- ❌ Zero API keys across 7 providers
- ❌ Zero real outbound requests
- ❌ Zero real provider responses
- ❌ Zero live_api + ALLOW_WITH_CONTROLS entries
- ❌ Zero secretPresent=true entries

**What this means:**
- The Factory has a complete **search framework**, not a connected search engine
- All search results come from **manual input** or **dry_run mock fixtures**
- The live_api code path exists but is correctly gated behind API key + human approval
- This is the correct and intended state for local-first Factory operation

---

## Required Report Corrections

**None needed.** Current R2.3-O reports already correctly state:
- "live_api gated" ✅
- "NOT production search capability" ✅
- "local-first, dry_run/manual operational" ✅
- "No external APIs connected" ✅

**For future phases:** If/when user provides an API key and approves live_api, documentation must be updated from "Search Framework Ready" to "Live Search Connected" with specific provider, date, and evidence.
