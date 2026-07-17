# Provider Configuration

Codex Factory supports **pluggable providers** for LLM, search, memory, and CI.

## Quick Start

```powershell
# Interactive setup (recommended for first-time users)
powershell -File runtime/codex-factory-init.ps1

# Check your environment
powershell -File runtime/codex-factory-doctor.ps1
```

## Provider Presets

| Preset | LLM | Search | Best for |
|---|---|---|---|
| `openai-native` | OpenAI (GPT-4o) | None (built-in) | GPT users |
| `deepseek-glm` | DeepSeek | GLM/Zhipu | DeepSeek users needing search |
| `local-only` | Local (ollama) | None | Offline / air-gapped |

## Configuration

1. Copy `factory.config.example.json` → `factory.config.json`
2. Edit providers as needed
3. Set API keys in `.env` (copy from `.env.example`)
4. Run `powershell -File runtime/codex-factory-doctor.ps1` to verify

## Important

- **Search defaults to NONE** — you must explicitly enable it
- **GPT/Claude users do NOT need external search** — they have built-in web search
- **DeepSeek users may want GLM/Zhipu** for external search capability
- **API keys go in `.env` ONLY** — never in `factory.config.json`
- `.env` is gitignored and never committed
