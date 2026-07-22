# Codex Factory — Engineering Reliability Framework for AI Coding Agents

> **Make Codex trustworthy for real software engineering.**
> Not "generate code from scratch" — but "generate code you can verify, trace, and trust."

[V5 自动控制平面](#v5-自动控制平面-preview) · [当前发布状态](#current-release-and-evidence-status) · [快速开始](#v5-quick-start) · [历史验证记录](#historical-verified-results-v342-commit-scoped) · [Architecture](#architecture) · [Limitations](#limitations--non-claims)

---

**New here?** → [V5 中文安装与使用指南](docs/CONTROL_PLANE_V5_GUIDE.zh-CN.md) · [V5 CLI](packages/factory-cli/README.md) · [Legacy Getting Started (V4, historical)](GETTING_STARTED.md)

**30-second pitch:** Codex Factory works with the user's current Codex runtime, adds role-bound skills and source-bound knowledge, decomposes complex projects into task graphs, lets the Codex main Agent dispatch native subagents, and independently verifies results. **Multi-agent and GLM search are optional. No artifact = no PASS. Your knowledge stays local.**

## V5 自动控制平面 (Preview)

V5 把用户记忆中的多 Agent、外接 Conversation Space、GLM 搜索和防假通过路径重新接成一个可安装的本地控制平面。用户只选择功能开关；启用多 Agent 后，由 Codex 主 Agent 自动拆分、派发常驻角色、按需生成临时 Agent、等待/纠偏、续跑验证波次，不要求用户手工开窗口或复制 prompt。

Windows 一次安装：

```powershell
Set-Location C:\Codex_App_Factory
powershell -ExecutionPolicy Bypass -File .\packages\factory-cli\install.ps1 `
  -ProjectRoot C:\Projects\my-app `
  -MultiAgent `
  -Search none `
  -MaxThreads 4

factoryctl doctor --project C:\Projects\my-app --json
```

关键边界：

- 默认继承当前 Codex runtime，GPT 用户可直接使用；兼容 Codex runtime 中的 DeepSeek 用户需以 `doctor` 和小型真实任务验证工具兼容性。
- 多 Agent、GLM 搜索均为 opt-in；搜索 Key 只从 `ZHIPUAI_API_KEY` 或项目本地、已忽略的 `.codex-factory/secrets.env` 读取。
- 只有带来源绑定准入回执的 `trusted_context`、独立验证证据和物理仓库才可作为工作依据；哈希链只证明写入后未被篡改。前端压缩摘要和普通手工追加内容保留为不可信候选。
- Memory Quality V5.1 会按任务和角色自动检索当前、未被替代、来源未漂移的项目知识，并把带条目 ID、来源 SHA-256 的限长摘录绑定进子 Agent Packet。
- 当前 `scope_guard` 会检测漏报和波次级越界写入，但不能提供逐 Agent 作者归因，也不是 OS ACL 或独立 worktree。因此开启多 Agent 时 `doctor` 会诚实返回 `READY_WITH_LIMITATIONS`。
- 原生 Codex 支持昵称候选；Factory 的角色 icon 可用于自己的记录/仪表盘，但不能控制原生子 Agent 头像。

完整命令、各功能用法、知识库、API Key、安全关闭和故障排查见 [V5 中文指南](docs/CONTROL_PLANE_V5_GUIDE.zh-CN.md)。

> [!IMPORTANT]
> 当前权威实现是 [`packages/factory-cli`](packages/factory-cli/) 中的 V5 Preview 源码，以及从该目录当前提交现场生成的 `.tgz`。`dist/codex-factory-v4-capability-package.zip` 的 ZIP、manifest 和 SHA 文本彼此不一致，已明确判定为无效历史制品，不能用于安装、发布或证明当前代码通过。详见 [旧制品告警](dist/LEGACY-ARTIFACTS-INVALID.md)。

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
| **Fake PASS** — agent claims success, but nothing was verified | Physical artifact hashes, real command exit codes and an independent verifier |
| **Missing artifacts** — no stdout, no logs, no receipts | Immutable handoffs, verification receipts and evidence bundles |
| **Weak evidence chain** — "trust me, it works" | Hash-chained Context Space, admission receipts and source-bound evidence |
| **Local results cannot be trusted** — "works on my machine" | Current-commit Windows/Ubuntu CI matrix |
| **Context compression pollution** | External role-bound Context Packets; frontend summaries stay untrusted |
| **No reproducibility** | Locked dependencies, deterministic build and package-content audit |

---

## Current Release and Evidence Status

V5 Preview is the current maintained path. The repository does not treat a report from another commit, a hand-written manifest, or an Agent's statement as proof for the current checkout.

| Item | Current status |
|---|---|
| Authoritative source | [`packages/factory-cli`](packages/factory-cli/) |
| Install guide | [`docs/CONTROL_PLANE_V5_GUIDE.zh-CN.md`](docs/CONTROL_PLANE_V5_GUIDE.zh-CN.md) |
| Reproducible package candidate | Run `npm pack` in `packages/factory-cli`; use the `.tgz` generated from the commit being tested |
| Cross-platform CI definition | [`factory-cli-v5.yml`](.github/workflows/factory-cli-v5.yml), Node 24 on Windows and Ubuntu |
| Legacy V4 ZIP | **INVALID / archive only**; see [`LEGACY-ARTIFACTS-INVALID.md`](dist/LEGACY-ARTIFACTS-INVALID.md) |
| Historical PASS reports | Evidence for their recorded commit/run only; they do not automatically certify current HEAD or V5 |

Verify the current checkout before using or distributing it:

```powershell
Set-Location C:\Codex_App_Factory\packages\factory-cli
npm ci
npm run typecheck
npm test
npm run build
npm pack --dry-run
```

A successful local run proves only that checkout on that machine. A current GitHub Actions run on both matrix platforms is required before making a cross-platform claim.

## V5 Quick Start

Prerequisites: Git, Node.js 24+, npm, and a Codex runtime that supports project-level customization.

```powershell
git clone https://github.com/yueheng-rgb/codex-factory.git C:\Codex_App_Factory
Set-Location C:\Codex_App_Factory
powershell -ExecutionPolicy Bypass -File .\packages\factory-cli\install.ps1 `
  -ProjectRoot C:\Projects\my-app `
  -MultiAgent `
  -Search none `
  -MaxThreads 4

factoryctl doctor --project C:\Projects\my-app --json
factoryctl memory status --project C:\Projects\my-app --json
```

For optional GLM search, initialize with `-Search glm` and provide `ZHIPUAI_API_KEY` through the documented environment or ignored project secret file. Do not put an API key in Factory configuration or commit it.

Factory does **not** implement or certify a DeepSeek provider. It inherits the model/runtime selected in Codex. A developer whose Codex runtime is already compatible with DeepSeek can use Factory, but must verify model access, tool calls and a small real task in that runtime; selecting or writing a `deepseek` label is not proof of compatibility.

See the [V5 Chinese guide](docs/CONTROL_PLANE_V5_GUIDE.zh-CN.md) for feature switches, multi-Agent dispatch, Context Space, skills, knowledge, search, verification, and uninstall steps.

## Historical Verified Results (V3.4.2, commit-scoped)

The following records describe a historical GitHub Actions run. They are retained for traceability, not presented as current release certification.

| Check | Recorded result |
|---|---|
| Snapshot Verifier | `15/15 PASS`, `SNAPSHOT_VERIFIED` |
| products-api Regression | `23/23 PASS` |
| Frozen Trunk Check | `3/3 OK` |
| Classification | `V3_4_2_REMOTE_ARTIFACT_VERIFIED_STRICT` |

Recorded scope: run `29584799436`, commit `6127376`. These results do **not** prove the current HEAD, the V4 ZIP, or the V5 package. Re-run the current workflows and bind any claim to the resulting commit SHA and run ID.

## Legacy V4 Compatibility Notes

The root `runtime/*.ps1`, V4 onboarding text and historical outputs remain for compatibility and audit work. They are not the recommended installation path and must not override a failing V5 check.

- A V4 provider selection was configuration metadata; it did not by itself implement a DeepSeek API provider, endpoint, authentication path or tool-use compatibility.
- The V4 ZIP in `dist/` is invalid because its physical bytes do not match the adjacent release metadata. Keep it only as an audit sample.
- Historical `PASS`, `VERIFIED` and expected test-count text is commit-scoped. It is not an expected result that a modified checkout may copy without rerunning the commands.
- New users should use V5 `factoryctl`; legacy PowerShell commands are for migration or historical diagnosis.

## Legacy Complex Project Workflow (V4.1, historical)

This section records the earlier intended workflow. It is not evidence that the current checkout completed these steps.

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
├── packages/factory-cli/             # Current V5 Preview control plane
│   ├── src/                          # CLI, orchestration, context, knowledge, evidence
│   ├── tests/                        # Current automated contracts
│   ├── install.ps1                   # Windows source installer
│   └── package.json                  # Node 24 package definition
├── docs/CONTROL_PLANE_V5_GUIDE.zh-CN.md
├── .github/workflows/
│   ├── factory-cli-v5.yml            # Current Node 24 Windows + Ubuntu checks
│   └── codex-factory-ci.yml          # Historical V3/V4 testbed workflow
├── runtime/                          # Legacy PowerShell compatibility/audit path
├── outputs/                          # Historical, commit-scoped reports
└── dist/                             # Legacy archives; V4 ZIP is explicitly invalid
```

### Verification Flow

```
Current commit SHA
       │
       ├── Windows / Node 24 ── npm ci ─ typecheck ─ test ─ build ─ pack dry-run
       │
       └── Ubuntu / Node 24 ─── npm ci ─ typecheck ─ test ─ build ─ pack dry-run
                                      │
                                      └── claim is bound to this run + commit only
```

---

## Limitations / Non-Claims

This project is an **engineering reliability framework**, not a commercial product. Please read:

- ❌ **Not a production cloud platform** — no SaaS, no multi-tenant, no payment system
- ❌ **Not a replacement for senior engineers** — it augments, not replaces, human judgment
- ❌ **No real corporate identity** — receipts use self-declared automated signatures
- ❌ **Not a security audit tool** — secret scans are pattern-based, not exhaustive
- ❌ **No Factory-provided DeepSeek provider** — Factory inherits the user's Codex runtime
- ❌ **No published V5 registry release yet** — `5.0.0-preview.1` is installed from source or a locally generated `.tgz`
- ❌ **No trust inheritance from old reports** — historical PASS records certify only their recorded inputs and commit
- ❌ **No fake production approval** — "VERIFIED" means the framework''s own checks passed
- ✅ **Honest about limitations** — current claims require reproducible evidence from the current checkout
- ✅ **Cross-platform CI definition** — V5 checks are defined for Windows and Ubuntu; inspect the current run before claiming success
- ✅ **Open source** — MIT licensed, community contributions welcome

---

## Roadmap

| Phase | Focus |
|---|---|
| **V5 Preview** (current) | Harden control-plane contracts, legacy fail-closed migration, user installation |
| **V5 release candidate** | Current-run cross-platform evidence and consumable release packaging |
| **Later** | Stronger per-Agent isolation/provenance and broader runtime compatibility testing |

---

## 中文简介

Codex Factory 是一个面向 AI 编程助手（Codex / Claude Code / Cursor / Copilot）的**工程可靠性框架**。

它的核心不是"生成代码"，而是解决一个关键问题：
**AI 说"做完了"——你怎么知道它真的做对了？**

通过快照验证、CI 制品溯源、跨机器哈希对比、证据链审计等机制，
Codex Factory 让 AI 编码从"黑盒生成"变成"可验证、可追溯、可信任"的工程实践。

V3.4.2 曾在记录的 commit `6127376`、run `29584799436` 上取得严格远程验证结果；这是历史证据，不等于当前 HEAD、V4 ZIP 或 V5 已自动通过。当前版本请使用 `packages/factory-cli`，并以当前提交的本地命令和 Node 24 Windows/Ubuntu CI 结果为准。

---

## License

MIT License — see [LICENSE](LICENSE) file.

---

## Contributing

This is a personal engineering project. Issues, discussions, and PRs are welcome.
For major changes, please open an issue first to discuss.

---

*Built with Codex. Verified by Codex. Trusted through evidence.*
