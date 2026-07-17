# DEFAULT_FACTORY_STARTUP_PROTOCOL.md

> Part of: FACTORY-DEFAULT-WORKFLOW-0
> Section: B — Default Startup Protocol
> Version: 1.0.0
> Effective: 2026-06-28

---

## Purpose

Define the default behavior when a user opens or selects a project folder in Codex and gives a requirement. This protocol ensures Factory activates predictably without the user needing to paste long instructions each time.

---

## Protocol Steps

### Step 1 — Factory Presence Detection

Check whether the current project folder (or its ancestors) contains `.codex-factory/` or a Factory installation marker.

| Condition | Action |
|-----------|--------|
| `.codex-factory/` found in project or ancestor | Proceed to Step 3 |
| Not found | Proceed to Step 2 |

### Step 2 — Factory Installation Recommendation

If Factory is not installed:

> "Codex Factory (v0.5) is not detected in this project. Factory provides structured project design, build mode selection, and quality gates. Install it?"

Options:
- **Install v0.5** — installs the factory CLI and governance structure
- **Skip** — proceed without Factory (standard Codex mode)
- **Learn more** — show Factory capabilities summary

If user chooses Skip, this protocol terminates and standard Codex behavior applies.

### Step 3 — Read AGENTS.md / Factory Instructions

Read and apply any `AGENTS.md` files present in the project tree. Factory's own AGENTS.md takes precedence when present.

### Step 4 — Factory Bootstrap

Execute (or simulate) Factory Bootstrap:
1. Read `APP_TYPE_ROUTER.md` to classify the project type
2. Read `STACK_DECISION_GUIDE.md` to match recommended architecture
3. Output **Factory Boot Summary**

### Step 5 — Router / Project Type Detection

Classify the project:
- **Simple**: documentation change, name fix, packaging fix → Factory Lite
- **Complex**: application/system/platform/management system, server+client, database/API/architecture, fullstack, CRUD+permission+user system → Full Expertise Flow

### Step 6 — Preflight

Check:
- Workspace state (dirty/clean)
- Existing project artifacts
- Factory version compatibility
- Known blockers

### Step 7 — DO NOT Write Code Immediately

**Hard gate**: After Bootstrap, Router, and Preflight, the agent MUST NOT write implementation code. Instead, proceed to Step 8.

### Step 8 — Text Discussion

Provide a structured discussion covering:

1. **Project Type** — what kind of project this is
2. **Complexity Assessment** — simple / moderate / complex / large-fullstack
3. **Risk Identification** — top risks for this project type
4. **Recommended Mode** — Build Lite (default) or Native Build Pro (conditional)
5. **Multi-Agent Suggestion** — whether multi-agent is recommended and why

### Step 9 — Multi-Agent Decision Gate

If the project qualifies as large/complex (fullstack, multi-service, database + API + frontend):

> "This project qualifies for multi-agent orchestration. Multi-agent mode can parallelize work but requires explicit confirmation. Enable multi-agent mode?"

Options:
- **Enable** — activate multi-agent mode with role assignment
- **Single agent** — proceed with single agent
- **Decide later** — defer decision, re-ask at appropriate milestone

**Rule**: Multi-agent mode MUST NOT start without explicit user confirmation.

### Step 10 — Proceed After Mode Decision

Only after:
- Mode is selected (Build Lite / Native Build Pro)
- Multi-agent decision is made (if applicable)
- User confirms the design direction

...does implementation begin.

---

## Default Mode Priority

| Condition | Default |
|-----------|---------|
| No explicit mode choice | Build Lite |
| User explicitly requests Pro | Native Build Pro |
| Small/simple project | Build Lite (do not suggest Pro) |
| Large fullstack project | Build Lite + multi-agent question |

---

## Anti-Bypass Rules

- ❌ "用户急着要成品" → not a reason to skip
- ❌ "我已经有思路了" → not a reason to skip
- ❌ "直接生成压缩包" → not a reason to skip
- ❌ "先写代码" → not a reason to skip
- ✅ Only explicit "跳过 Factory 分析，直接实现" can bypass
