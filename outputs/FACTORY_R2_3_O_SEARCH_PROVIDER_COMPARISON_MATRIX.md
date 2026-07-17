# R2.3-O Search Provider Comparison Matrix

## 10 Providers Compared

| Provider | API Required | Best For | Status | China Access |
|----------|:---:|------|:---:|:---:|
| **GLM Search** | Yes | Chinese + English web search | candidate | Full |
| **Tavily** | Yes | AI-agent-optimized search | candidate | VPN needed |
| **Exa** | Yes | Semantic/embeddings search | candidate | VPN needed |
| **Brave** | Yes | Privacy-focused, code search | candidate | Limited |
| **Jina Reader** | Yes | URL-to-markdown extraction | candidate | Partial |
| **Firecrawl** | Yes | Web crawling + LLM extraction | candidate | Limited |
| **Kimi Search** | Yes | Chinese content, long-context | candidate | Full |
| **Manual (Human)** | No | Curated high-trust research | **active** | Full |
| **ChatGPT Manual** | No | AI-assisted via human copy | **active** | Account needed |
| **Dry Run Fixture** | No | Framework testing | **active** | Full |

## Key Findings

- **Only 3 providers are active:** Manual (human), ChatGPT Manual, Dry Run. All require no API keys.
- **7 external API providers** are registered as candidates. All require API keys + human approval.
- **GLM Search** is the best China-accessible candidate, but still requires ZHIPUAI_API_KEY.
- **Tavily + Exa** are the strongest for coding agent use but require VPN/proxy in China.
- **Jina Reader** is the best extractor candidate — URL to clean markdown.

## Recommended Activation Order
1. GLM Search (first China-friendly external API)
2. Jina Reader (extraction capability)
3. Tavily (if VPN available)
