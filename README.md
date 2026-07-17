# Codex Factory — Engineering Reliability Framework for AI Coding Agents

> **Make Codex trustworthy for real software engineering.**
> Not "generate code from scratch" — but "generate code you can verify, trace, and trust."

[中文简介](#中文简介) · [Quick Start](#quick-start) · [Verified Results](#verified-results) · [Architecture](#architecture) · [Limitations](#limitations)

---

## What is Codex Factory?

Codex Factory is an **open engineering reliability framework** for AI coding agents (Codex / Claude Code / Cursor / Copilot). It solves the trust gap between "AI wrote it" and "we can ship it."

AI coding agents are powerful but unreliable. They:
- Generate code that looks right but has subtle bugs
- Claim "done" with no evidence
- Skip error states, loading states, and edge cases
- Mix security concerns with UI concerns
- Produce artifacts you cannot reproduce or verify

Codex Factory addresses this with a **structured verification pipeline** — not by replacing the agent, but by giving it the guardrails, evidence requirements, and reproducibility checks that professional software engineering demands.

### Core Problem → Solution Map

| Problem | Codex Factory Solution |
|---|---|
| **Fake PASS** — agent claims success, but nothing was verified | Snapshot verifier with strict hash comparison |
| **Missing artifacts** — no stdout, no logs, no receipts | CI artifact traceability with `provider=github_actions` |
| **Weak evidence chain** — "trust me, it works" | Evidence Pack v2 with hash-chained audit trail |
| **Local results cannot be trusted** — "works on my machine" | Cross-machine snapshot comparison + remote CI |
| **Context compression pollution** | Sandbox lifecycle + snapshot-aware resume gate |
| **No reproducibility** | Immutable snapshot manifest + frozen trunk check |

---

## Verified Results (V3.4.2, Real GitHub Actions)

These are **not simulated**. They were verified on a real GitHub Actions Linux runner with strict hash comparison.

| Check | Result | Evidence |
|---|---|---|
| Snapshot Verifier | **15/15 PASS** | `SNAPSHOT_VERIFIED`, `FILE_HASH_MATCH=true` |
| products-api Regression | **23/23 PASS** | Real runner `/home/runner/work/codex-factory/...` |
| Frozen Trunk Check | **3/3 OK** | SHA256-verified: execution-runner, snapshot-verifier, schema |
| CI Job Receipts | **github_actions / remote_generated** | 3 receipts, cross-referenced |
| Secret Scan | **PASS** | Zero real secrets in 4500+ files |
| Cross-Machine Snapshot | **SNAPSHOT_MATCH** | Local ↔ Remote manifest identical |
| Expert Packs | **6/6 loadable** | All domain packs pass schema validation |

> **Final classification: `V3_4_2_REMOTE_ARTIFACT_VERIFIED_STRICT`**
> Run ID: `29584799436` · Commit: `6127376` · [View CI run](https://github.com/yueheng-rgb/codex-factory/actions)

---


## V4.0: Provider Choice & User Onboarding (NEW)

Codex Factory V4.0 puts **you** in control of your AI stack:

### Choose Your Providers
```powershell
# Interactive setup — no API keys collected
powershell -File runtime/codex-factory-init.ps1
```
- **LLM**: OpenAI · DeepSeek · Claude · Qwen · Local · Custom
- **Search**: None (default) · GLM/Zhipu · Tavily · SerpAPI · Custom
- **Memory**: Local snapshot · File-based · Disabled
- **CI**: GitHub Actions · Local only · None

> **Search defaults to NONE.** GPT/Claude have built-in search. No external API required.

### Bring Your Own Knowledge
```powershell
powershell -File runtime/knowledge-pack-manager.ps1 -Action add -Name my-project -Source ./docs
```
Import your docs, API specs, and project rules. Every claim traceable to source.

### Create Skill Packs
```powershell
powershell -File runtime/skill-pack-manager.ps1 -Action create -Name my-domain
```

### Check Your Environment
```powershell
powershell -File runtime/codex-factory-doctor.ps1
```

### Start a New Project
```powershell
powershell -File runtime/project-onboarding-wizard.ps1 -ProjectName my-app
```

## 5-Minute Quick Start

### Prerequisites
- Git, Node.js, npm
- PowerShell 5+ (Windows) or PowerShell Core 7+ (`pwsh`) on Linux/macOS

### Step 1: Clone & Init
```powershell
git clone https://github.com/yueheng-rgb/codex-factory.git
cd codex-factory
pwsh -File runtime/codex-factory-init.ps1
```
Choose your LLM provider, search (default: none), and CI settings. No API keys collected.

### Step 2: Check Environment
```powershell
pwsh -File runtime/codex-factory-doctor.ps1
```

### Step 3: Run the Snapshot Verifier
```powershell
pwsh -File runtime/snapshot-verifier.ps1
```
Expected: `15/15 PASS, SNAPSHOT_VERIFIED`

### Step 4: Add Your Project
```powershell
# Create a skill pack for your domain
pwsh -File runtime/skill-pack-manager.ps1 -Action create-template -Name my-domain

# Import your project knowledge (local only, never uploaded)
pwsh -File runtime/knowledge-pack-manager.ps1 -Action add -Name my-project -Source ./docs
pwsh -File runtime/knowledge-pack-manager.ps1 -Action build-evidence

# Generate project onboarding plan
pwsh -File runtime/project-onboarding-wizard.ps1 -ProjectName my-app
```

### User Path Examples

**DeepSeek + GLM search:**
```powershell
pwsh -File runtime/codex-factory-init.ps1
# Choose: [2] DeepSeek → [2] GLM/Zhipu search
# Set DEEPSEEK_API_KEY + ZHIPUAI_API_KEY in .env
```

**GPT / native search / no external search:**
```powershell
pwsh -File runtime/codex-factory-init.ps1
# Choose: [1] OpenAI → [1] None (search)
# Set OPENAI_API_KEY in .env
```

**Local-only / offline:**
```powershell
pwsh -File runtime/codex-factory-init.ps1
# Choose: [5] Local → [1] None (search) → [3] Disabled (CI)
# No API keys needed.
```

**Existing project onboarding:**
```powershell
pwsh -File runtime/project-onboarding-wizard.ps1 -ProjectName existing-app
pwsh -File runtime/skill-pack-manager.ps1 -Action enable -Name backend-api-design
pwsh -File runtime/skill-pack-manager.ps1 -Action enable -Name auth-permission-security
```

> **No artifact = no PASS.** Every verification claim must be backed by evidence.
> **GLM is optional.** Search defaults to none. You choose your own stack.
> **Skill packs are customizable.** Create your own with `create-template`.
> **Knowledge packs are local only.** Never uploaded, never committed.

Expected output:
```
=== Snapshot Verifier V3.4.2 (Strict) ===
Checks: 15
PASS: 15 | FAIL: 0 | WARN: 0
SNAPSHOT_VERIFIED: True
Overall: SNAPSHOT_VERIFIED
```

### 2. Run a Local Demo

```bash
cd testbeds/products-api
npm install
npm test          # 23 tests should pass
```

### 3. Run GitHub Actions Workflow

1. Fork this repo
2. Go to **Actions** → **Codex Factory CI** → **Run workflow**
3. Select `products-api` testbed → **Run**
4. Download the 3 artifact zips
5. Run verification locally:
   ```powershell
   powershell -File runtime/remote-artifact-verifier.ps1
   powershell -File runtime/cross-machine-snapshot-comparison.ps1
   ```

### 4. Verify a Remote Artifact

After downloading CI artifacts, place them in `artifacts/remote/gh-run-XXX/` and run:
```powershell
powershell -File runtime/remote-artifact-verifier.ps1 -RunId "gh-run-XXX"
```

---


## Complex Project Workflow (V4.1)

From requirement to verified execution plan in one command:

```powershell
# 1. Write your requirement (or use existing docs)
# 2. Run the task decomposition engine
pwsh -File runtime/task-decomposition-engine.ps1 `
  -Requirement ./my-project-requirement.md `
  -OutputDir ./output/my-project

# 3. Review the generated plans
#    - task_graph.json       (tasks + dependencies)
#    - worker_plan.json      (agent assignments)
#    - validation_plan.json  (verification per task)
#    - agent_execution_plan.json (execution order)
```

### What Happens

| Step | Engine Action |
|---|---|
| Project Type Detection | Keywords → `admin-system`, `ecommerce`, `saas`, etc. |
| Risk Classification | P0 (auth/payment) → P3 (docs/styles) with required gates |
| Task Decomposition | Requirement → 8-12 ordered task nodes |
| Skill Pack Matching | Auto-match enabled packs to project type |
| Knowledge Referencing | Evidence pack citations with source_file + source_hash |
| Search Strategy | Provider-aware: respects `search_provider=none` default |
| Validation Plan | Every task has ≥1 method: test, artifact, review, static_check |
| Worker Plan | Main Agent + Integrator + Workers with file boundaries |

> **No artifact = no PASS.** Every task must produce verifiable output.
> **Search defaults to none.** GLM is optional. GPT/Claude can use native search.

## Architecture

```
Codex Factory
├── runtime/              # 90+ verification & governance PowerShell modules
│   ├── snapshot-verifier.ps1        # Strict hash-based snapshot verification
│   ├── execution-runner.ps1         # Immutable execution context
│   ├── evidence-pack-builder.ps1    # Hash-chained evidence packs
│   ├── cross-machine-snapshot-comparison.ps1
│   ├── remote-artifact-verifier.ps1
│   ├── ci-regression-capture.ps1
│   ├── frozen-trunk-check (inline)
│   └── ... (80+ more modules)
├── schemas/              # 57 JSON Schema definitions (ci-receipt, evidence, skill...)
├── governance/           # 1400+ decision records, expert packs, policies, protocols
├── outputs/              # Versioned reports, manifests, claim snapshots (V2.0–V3.4.2)
├── blueprints/           # 7 application type design blueprints
├── starters/             # 7 runnable starter templates
├── skills/               # 9 reusable domain skills
├── harness/              # Test harness, scenarios, verification scripts
├── testbeds/             # 8 runtime-validated testbeds
├── reviews/              # Human review receipts
├── .github/workflows/    # CI pipeline with remote artifact traceability
└── artifacts/            # CI run artifacts, remote verification extracts
```

### Verification Flow

```
Local Dev (Windows)          GitHub Actions (Linux)         Verifier (Any)
─────────────────          ──────────────────────        ───────────────
git push ──────────────►   checkout (LF normalized)
                            │
                            ├─ snapshot-verify ────────►  ci-job-receipt.json
                            │   (pwsh strict verifier)     snapshot-verifier-result.json
                            │   15/15 checks               stdout/stderr logs
                            │
                            ├─ regression ──────────────►  ci-job-receipt.json
                            │   (npm test, vitest)         regression-result.json
                            │   23/23 tests                stdout/stderr logs
                            │
                            └─ frozen-trunk-check ──────►  ci-job-receipt.json
                                (SHA256 verify)            frozen-trunk-result.json
                                                           stdout/stderr logs
                                    │
                            Download artifacts
                                    │
                            ◄── cross-machine comparison ──►  SNAPSHOT_MATCH?
                            ◄── remote artifact verify ────►  REMOTE_ARTIFACT_VERIFIED?
```

---

## Limitations / Non-Claims

This project is an **engineering reliability framework**, not a commercial product. Please read:

- ❌ **Not a production cloud platform** — no SaaS, no multi-tenant, no payment system
- ❌ **Not a replacement for senior engineers** — it augments, not replaces, human judgment
- ❌ **No real corporate identity** — receipts use self-declared automated signatures
- ❌ **Not a security audit tool** — secret scans are pattern-based, not exhaustive
- ❌ **No fake production approval** — "VERIFIED" means the framework''s own checks passed
- ✅ **Honest about limitations** — every claim is backed by reproducible evidence
- ✅ **Cross-platform verification** — LF-normalized via `.gitattributes`
- ✅ **Open source** — MIT licensed, community contributions welcome

---

## Roadmap

| Phase | Focus |
|---|---|
| **V3.5** (current) | Public README, portfolio packaging, internship-ready docs |
| **V3.6** | Container runner (Docker), multi-platform CI matrix |
| **V3.7** | Real external identity (SignPath / keyless signing) |
| **V3.8** | More expert packs: mobile, game-dev, embedded |
| **V4.0** | Public example gallery, community contributions |

---

## 中文简介

Codex Factory 是一个面向 AI 编程助手（Codex / Claude Code / Cursor / Copilot）的**工程可靠性框架**。

它的核心不是"生成代码"，而是解决一个关键问题：
**AI 说"做完了"——你怎么知道它真的做对了？**

通过快照验证、CI 制品溯源、跨机器哈希对比、证据链审计等机制，
Codex Factory 让 AI 编码从"黑盒生成"变成"可验证、可追溯、可信任"的工程实践。

目前已通过真实 GitHub Actions 严格远程验证（15/15 checks, 23/23 tests, SNAPSHOT_VERIFIED）。

---

## License

MIT License — see [LICENSE](LICENSE) file.

---

## Contributing

This is a personal engineering project. Issues, discussions, and PRs are welcome.
For major changes, please open an issue first to discuss.

---

*Built with Codex. Verified by Codex. Trusted through evidence.*
