# R2.3-P Live Search Provider Smoke Test Report

**Date:** 2026-07-10
**Status:** **BLOCKED_WAITING_FOR_USER_SECRET**

---

## Pre-Flight Gates

| Gate | Status | Detail |
|------|:---:|------|
| Provider Selection | COMPLETE | GLM Search selected |
| Secret Gate | BLOCKED | 0/7 provider API keys |
| Human Approval | BLOCKED | No approval received |
| Tool Permission Gate | PENDING | Needs key + approval |

---

## Secret Gate Detail

| Provider | Env Var(s) | Status |
|----------|-----------|:---:|
| GLM Search | ZHIPUAI_API_KEY / GLM_API_KEY | NOT SET |
| Tavily | TAVILY_API_KEY | NOT SET |
| Exa | EXA_API_KEY | NOT SET |
| Brave | BRAVE_SEARCH_API_KEY | NOT SET |
| Jina | JINA_API_KEY | NOT SET |
| Firecrawl | FIRECRAWL_API_KEY | NOT SET |

All scopes: Process, User, Machine.

---

## Planned Smoke Test

**Query:** "Next.js official documentation routing handler App Router"

**Pipeline:** Secret Gate -> Human Approval -> Tool Permission Gate -> GLM Search (live_api) -> Quality Gate -> Research Intake -> Evidence Pack -> Ledger

**Expected ledger entry:** mode=live_api, decision=ALLOW_WITH_CONTROLS, secretPresent=true, resultCount>0

---

## Classification

**Current:** B: LIVE_PROVIDER_READY_NOT_EXECUTED

**After unblock:** C: LIVE_SEARCH_CONNECTED_SMOKE_ONLY (one low-risk public query only)

---

## To Unblock

`powershell
 = 'your-zhipuai-api-key'
`
Then state: **approve live_search_smoke_test**
