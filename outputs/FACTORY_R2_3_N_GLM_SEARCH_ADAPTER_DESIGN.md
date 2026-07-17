# R2.3-N GLM Search Adapter Design

## Provider: ZhipuAI GLM-4 with Web Search

The GLM Search Adapter wraps ZhipuAI's GLM-4 model with web search tool capability. It is the first external_api provider registered in Codex Factory — candidate/framework status only; live API code path is gated behind API key + human approval and has NOT been executed.

### API Endpoint
POST https://open.bigmodel.cn/api/paas/v4/chat/completions

### Authentication
API key via Authorization: Bearer <key> header. Key sourced from ZHIPUAI_API_KEY or GLM_API_KEY environment variable.

### Request Format
`json
{
  "model": "glm-4-flash",
  "messages": [{"role": "user", "content": "<query>"}],
  "tools": [{"type": "web_search", "web_search": {"enable": true, "search_query": "<query>"}}],
  "max_tokens": 4096,
  "temperature": 0.1
}
`

### Response Processing
The adapter extracts web search results from esponse.choices[].message.tool_calls[] where type=web_search. Each result is normalized to: title, url, snippet, siteName, sourceType, trustIndicator.

### Tool Registry Entry
- **toolId:** TOOL-GLM-SEARCH-001
- **type:** external_search
- **networkBoundary:** external_api (level 4)
- **requiredSecrets:** true
- **humanConfirmationRequired:** true
- **allowedAgents:** RSRC-001, LIB-001
- **forbiddenAgents:** IMPL-FE-001, IMPL-BE-001, IMPL-DB-001
- **riskLevel:** medium
- **status:** candidate (pending first live API call (NOT YET EXECUTED; requires ZHIPUAI_API_KEY env var + explicit human approval))

### Provider Assessment
- **Capability:** Real-time web search with structured results and domain filtering
- **Strengths:** Fast, structured, domain-aware, supports Chinese + English
- **Weaknesses:** Requires API key, results quality varies, not multimodal
- **Freshness:** Real-time
- **Citation:** URLs included in results
- **Trust Limit:** AVAILABLE (not TRUSTED, not VERIFIED)
- **Can be direct source:** false — must pass quality gate + human review
