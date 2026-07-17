# Codex Factory V4.0 — Init Wizard
# Interactive configuration setup. First-run experience.
# Usage: powershell -File runtime/codex-factory-init.ps1

param([switch]$Quick, [switch]$Json)

$ErrorActionPreference = "Stop"
Write-Output "============================================"
Write-Output " Codex Factory V4.0 — Init Wizard"
Write-Output "============================================"
Write-Output ""
Write-Output "This wizard will help you configure Codex Factory."
Write-Output "NO API keys will be collected or stored in config."
Write-Output "API keys go in .env (gitignored, never committed)."
Write-Output ""

$config = @{
    version = "4.0.0"
    providers = @{
        llm = @{ type = "openai"; model = "gpt-4o" }
        search = @{ type = "none" }
        memory = @{ type = "local_snapshot" }
        ci = @{ type = "none" }
    }
    expert_packs = @()
    skill_packs = @()
    knowledge_packs = @()
}

if (-not $Quick) {
    # ── LLM Provider ──
    Write-Output "── Step 1: LLM Provider ──"
    Write-Output "Which LLM do you primarily use?"
    Write-Output "  [1] OpenAI (GPT-4o, GPT-5, etc.) — recommended"
    Write-Output "  [2] DeepSeek (deepseek-v3, deepseek-r1)"
    Write-Output "  [3] Claude (Anthropic)"
    Write-Output "  [4] Qwen (Tongyi Qianwen)"
    Write-Output "  [5] Local (ollama, vLLM, etc.)"
    Write-Output "  [6] Custom endpoint"
    $llmChoice = Read-Host "Enter number (1-6) [1]"
    if (-not $llmChoice) { $llmChoice = "1" }
    switch ($llmChoice) {
        "1" { $config.providers.llm = @{ type="openai"; model="gpt-4o" }; Write-Output "  => OpenAI selected. Set OPENAI_API_KEY in .env" }
        "2" { $config.providers.llm = @{ type="deepseek"; model="deepseek-v3" }; Write-Output "  => DeepSeek selected. Set DEEPSEEK_API_KEY in .env" }
        "3" { $config.providers.llm = @{ type="claude"; model="claude-sonnet-4-20250514" }; Write-Output "  => Claude selected. Set ANTHROPIC_API_KEY in .env" }
        "4" { $config.providers.llm = @{ type="qwen"; model="qwen-max" }; Write-Output "  => Qwen selected. Set QWEN_API_KEY in .env" }
        "5" { $config.providers.llm = @{ type="local"; model="local" }; Write-Output "  => Local selected. No API key needed." }
        "6" { $config.providers.llm = @{ type="custom"; model="custom"; endpoint="" }; Write-Output "  => Custom selected. Configure endpoint in factory.config.json" }
    }

    # ── Search Provider ──
    Write-Output ""
    Write-Output "── Step 2: Search Provider ──"
    Write-Output "Do you need external web search capability?"
    Write-Output "NOTE: GPT/Claude/Gemini have built-in search. External search is optional."
    Write-Output "  [1] None — no external search (DEFAULT, recommended for most users)"
    Write-Output "  [2] GLM/Zhipu — recommended for DeepSeek users who need search"
    Write-Output "  [3] Tavily — general-purpose search API"
    Write-Output "  [4] SerpAPI — Google search results"
    Write-Output "  [5] Custom HTTP endpoint"
    $searchChoice = Read-Host "Enter number (1-5) [1]"
    if (-not $searchChoice) { $searchChoice = "1" }
    switch ($searchChoice) {
        "1" { $config.providers.search = @{ type="none" }; Write-Output "  => Search DISABLED. No external search." }
        "2" { $config.providers.search = @{ type="glm_zhipu"; api_key_env="ZHIPUAI_API_KEY" }; Write-Output "  => GLM/Zhipu selected. Set ZHIPUAI_API_KEY in .env" }
        "3" { $config.providers.search = @{ type="tavily"; api_key_env="TAVILY_API_KEY" }; Write-Output "  => Tavily selected. Set TAVILY_API_KEY in .env" }
        "4" { $config.providers.search = @{ type="serpapi"; api_key_env="SERPAPI_API_KEY" }; Write-Output "  => SerpAPI selected. Set SERPAPI_API_KEY in .env" }
        "5" { $config.providers.search = @{ type="custom_http"; api_key_env="CUSTOM_SEARCH_KEY" }; Write-Output "  => Custom HTTP selected. Configure endpoint manually." }
    }

    # ── Memory Provider ──
    Write-Output ""
    Write-Output "── Step 3: Memory ──"
    Write-Output "Enable trusted memory (local snapshot)?"
    Write-Output "  [1] Yes — local snapshot memory (recommended)"
    Write-Output "  [2] File-based only"
    Write-Output "  [3] Disabled"
    $memChoice = Read-Host "Enter number (1-3) [1]"
    if (-not $memChoice) { $memChoice = "1" }
    switch ($memChoice) {
        "1" { $config.providers.memory = @{ type="local_snapshot" } }
        "2" { $config.providers.memory = @{ type="file_based" } }
        "3" { $config.providers.memory = @{ type="disabled" } }
    }

    # ── CI Provider ──
    Write-Output ""
    Write-Output "── Step 4: CI / Remote Verification ──"
    Write-Output "Enable GitHub Actions for remote artifact verification?"
    Write-Output "  [1] Yes — GitHub Actions (recommended for teams)"
    Write-Output "  [2] Local only — no remote CI"
    $ciChoice = Read-Host "Enter number (1-2) [2]"
    if (-not $ciChoice) { $ciChoice = "2" }
    if ($ciChoice -eq "1") {
        $config.providers.ci = @{ type="github_actions"; remote_verification=$true }
        Write-Output "  => GitHub Actions enabled. Fork the repo to use CI."
    } else {
        $config.providers.ci = @{ type="none"; remote_verification=$false }
    }
}

# ── Write config ──
$config | ConvertTo-Json -Depth 4 | Out-File -FilePath factory.config.json -Encoding utf8
Write-Output ""
Write-Output "============================================"
Write-Output " Configuration saved to: factory.config.json"
Write-Output "============================================"
Write-Output ""
Write-Output "Next steps:"
Write-Output "  1. Set API keys in .env (copy from .env.example)"
Write-Output "  2. Run: powershell -File runtime/codex-factory-doctor.ps1"
Write-Output "  3. Review: factory.config.json"
Write-Output "  4. Start using Codex Factory with your projects!"
Write-Output ""
Write-Output "NOTE: Search is DISABLED by default."
Write-Output "      GPT/Claude users do NOT need external search."
Write-Output "      DeepSeek users may want GLM/Zhipu for search."
