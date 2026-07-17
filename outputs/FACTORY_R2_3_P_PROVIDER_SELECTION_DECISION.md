# R2.3-P Provider Selection Decision

**Date:** 2026-07-10  
**Status:** BLOCKED_WAITING_FOR_USER_SECRET

---

## Candidate Evaluation (7 providers)

| Rank | Provider | Key Found | Score | Fit | China | Cost |
|:---:|----------|:---:|:---:|:---:|:---:|:---:|
| 1 | **GLM Search (ZhipuAI)** | ❌ | 7* | medium | Full | Low |
| 2 | Tavily Search | ❌ | 5 | high | VPN | Med |
| 3 | Exa Search | ❌ | 5 | high | VPN | Med |
| 4 | Jina Reader | ❌ | 5 | high | Partial | Med |
| 5 | Firecrawl | ❌ | 5 | high | Limited | Med-High |
| 6 | Kimi Search | ❌ | 3 | medium | Full | Low |
| 7 | Brave Search | ❌ | 2 | medium | Limited | Low |

*GLM gets +4 bonus for China accessibility + low cost + existing adapter code. Raw criteria score is 3 (no key, medium fit).

---

## Recommendation: GLM Search (ZhipuAI)

**Rationale:**
- **Only provider with full China accessibility** — no VPN/proxy needed
- **Lowest cost risk** — per-token pricing, free tier available
- **Existing adapter code** — untime/glm-search-adapter.ps1 is production-ready
- **Structured results** — returns URLs, titles, snippets, site names
- **Read-only** — web search tool is inherently read-only
- **Domain filtering** — can restrict to official docs domains

**Tavily** would be the strongest if China accessibility weren't a factor (AI-agent-optimized, excellent coding agent fit).

---

## BLOCKED: No API Key Present

ZHIPUAI_API_KEY and GLM_API_KEY are both unset in all environment scopes (Process, User, Machine).

**To unblock:**

`powershell
# Option A: ZhipuAI GLM (RECOMMENDED)
 = 'your-zhipuai-api-key'

# Option B: Tavily (if VPN available)
 = 'your-tavily-api-key'
`

Then explicitly approve:
`
approve live_search_smoke_test
`

---

## Provider Selection Criteria Applied

| Criteria | GLM | Tavily | Exa | Jina | Firecrawl |
|----------|:---:|:---:|:---:|:---:|:---:|
| API key available | ❌ | ❌ | ❌ | ❌ | ❌ |
| Easy local call | ✅ | ✅ | ✅ | ✅ | ✅ |
| Structured results | ✅ | ✅ | ✅ | ✅ | ✅ |
| Coding agent fit | medium | **high** | **high** | **high** | **high** |
| Official docs search | good | excellent | good | excellent | good |
| Read-only | ✅ | ✅ | ✅ | ✅ | ✅ |
| Cost controllable | **low** | medium | medium | medium | med-high |
| Can sanitize in ledger | ✅ | ✅ | ✅ | ✅ | ✅ |
| Research Intake ready | ✅ | ✅ | ✅ | ✅ | ✅ |
