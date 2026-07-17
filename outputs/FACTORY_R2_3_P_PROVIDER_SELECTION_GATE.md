# R2.3-P Provider Selection Gate (Single WebSearch Tool)

**Date:** 2026-07-10
**Status:** BLOCKED_WAITING_FOR_USER_SECRET
**Architecture:** Single WebSearch Tool (DIR-010) — no independent Search Agent

---

## Convergence Decision

Search architecture converged to Single WebSearch Tool / Provider Pipeline per DIR-010. Provider selection gate chooses which API backs the single WebSearch Tool.

## Candidate Ranking (Post-Convergence)

| Rank | Provider | Key | Fit | China | Cost | Architecture Fit |
|:---:|----------|:---:|:---:|:---:|:---:|------|
| 1 | **GLM Search** | ❌ | medium | Full | Low | Direct API ✅ |
| 2 | Tavily | ❌ | high | VPN | Med | Direct API ✅ |
| 3 | Jina Reader | ❌ | high | Partial | Med | Extract API ✅ |
| 4 | Exa | ❌ | high | VPN | Med | Direct API ✅ |
| 5 | Firecrawl | ❌ | high | Limited | Med-High | Crawl API ✅ |
| 6 | Brave | ❌ | medium | Limited | Low | Direct API ✅ |
| 7 | Kimi | ❌ | medium | Full | Low | Direct API ✅ |

All candidates compatible with Single WebSearch Tool pattern. None are independent Search Agents.

## Recommendation

**GLM Search (ZhipuAI)** — first choice for Single WebSearch Tool:
- China-accessible without VPN
- Direct API pattern (REST)
- Existing adapter code complete
- Structured results with URLs/snippets
- Low cost, read-only

## Status: BLOCKED

0/7 provider API keys present. To unblock:
`powershell
 = 'your-key'
`
Then state: **approve live_search_smoke_test**
