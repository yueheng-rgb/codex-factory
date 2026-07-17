# Provider Configuration

Codex Factory supports **pluggable providers** for LLM, search, memory, and CI.

## Quick Start

```powershell
# Interactive setup (recommended)
pwsh -File runtime/codex-factory-init.ps1

# Or on Windows PowerShell
powershell -File runtime/codex-factory-init.ps1

# Check your environment
pwsh -File runtime/codex-factory-doctor.ps1
```

## Provider Presets

| Preset | LLM | Search | Best for |
|---|---|---|---|
| `openai-native` | OpenAI (GPT-4o) | None | Users whose Codex environment already has native search tools |
| `deepseek-glm` | DeepSeek | GLM/Zhipu | DeepSeek users who also need external search |
| `local-only` | Local (ollama) | None | Offline / air-gapped / no-external-API environments |

## Search Provider Options

**Default: `none`** — no external search is enabled by default.

If your Codex environment already has built-in search tools (e.g., native web search), you can keep `search_provider=none`.

If you need external search, choose from:

| Provider | Description | API Key Env Var |
|---|---|---|
| `none` | No external search (default) | — |
| `glm_zhipu` | ZhipuAI GLM search — recommended for DeepSeek users | `ZHIPUAI_API_KEY` |
| `openai_web_search` | OpenAI web search tool | `OPENAI_API_KEY` |
| `tavily` | General-purpose search API | `TAVILY_API_KEY` |
| `serpapi` | Google search results | `SERPAPI_API_KEY` |
| `bing` | Microsoft Bing search | `BING_API_KEY` |
| `custom_http` | Custom HTTP endpoint | `CUSTOM_SEARCH_KEY` |
| `mcp_search` | MCP-based search tool | (per MCP config) |

## Configuration

1. Copy `factory.config.example.json` → `factory.config.json`
2. Edit providers as needed
3. Set API keys in `.env` (copy from `.env.example`) — **never in config**
4. Run `pwsh -File runtime/codex-factory-doctor.ps1` to verify

## Important

- **Search defaults to NONE** — you must explicitly enable it
- **GLM/Zhipu is NOT mandatory** — it is one option among many
- **API keys go in `.env` ONLY** — `.env` is gitignored and never committed
- **DeepSeek users may find GLM/Zhipu useful** for search, but it is a recommendation, not a requirement
