# V4.0.1 Provider Docs Audit

## Status: FIXED

## Changes

| Issue | Before | After |
|---|---|---|
| "GPT/Claude have built-in search" | Present (misleading) | Removed. Now: "If your Codex environment already has native search tools, keep search_provider=none" |
| GLM as recommendation | Strong | "DeepSeek users may find GLM/Zhipu useful, but it is a recommendation, not a requirement" |
| Search provider list | Incomplete | Full table: none, glm_zhipu, openai_web_search, tavily, serpapi, bing, custom_http, mcp_search |
| API key handling | .env mention | Explicit: "API keys go in .env ONLY — never in config" + env var names per provider |
| Search default | none (correct) | Unchanged — remains none |

## Verified
- No "GPT/Claude built-in web search" claim ✅
- GLM explicitly optional ✅
- All 8 search providers listed ✅
- API keys only in .env.example ✅
