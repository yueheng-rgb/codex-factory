# NATURAL_LANGUAGE_CLEANUP_CONTRACT.md

> Part of: FACTORY-DEFAULT-WORKFLOW-0
> Section: G — Natural Language Cleanup Contract
> Version: 1.0.0

---

## Purpose

Define the safe cleanup protocol triggered by natural-language user requests like "删除该项目缓存". Cleanup must always produce a PLAN first, never execute destructive actions by default, and never delete project source or core evidence.

---

## Trigger Phrases

| Chinese | English |
|---------|---------|
| "删除该项目缓存" | "delete this project's cache" |
| "清理项目" | "clean up the project" |
| "清除 Factory 缓存" | "clear Factory cache" |
| "重置项目状态" | "reset project state" |
| "忘记这个项目" | "forget this project" |

---

## Cleanup Protocol

### Step 1 — Interpret the Request

Map the natural-language request to one of:

| Request | Scope |
|---------|-------|
| "删除缓存" | Factory runtime cache only |
| "清理项目" | Cache + temporary artifacts |
| "重置状态" | Factory state files (runs, events) |
| "忘记项目" | All Factory memory of this project |

### Step 2 — Produce a Cleanup PLAN (Never Execute Immediately)

The response MUST be a PLAN, not an action:

```
## Cleanup Plan for [Project Name]

**Trigger:** [user's original phrase]
**Interpreted Scope:** [scope]
**Timestamp:** [now]

### Items to Remove
| # | Path | Type | Safety |
|---|------|------|--------|
| 1 | [path] | cache | SAFE |
| 2 | [path] | temp | SAFE |

### Items Explicitly PRESERVED
| # | Path | Reason |
|---|------|--------|
| 1 | [project source] | Project source code |
| 2 | [CORE_EVIDENCE] | Core evidence (never auto-delete) |

### Required Confirmation
Do you want to execute this cleanup plan? Type "确认执行" to proceed.
```

### Step 3 — Require Explicit Confirmation

The cleanup MUST NOT proceed until the user explicitly confirms (e.g., "确认执行", "yes execute").

### Step 4 — Execute Only Confirmed Items

Only remove items that were listed and confirmed. Do not remove anything not in the plan.

---

## Hard Safety Boundaries

### NEVER Delete (No Exceptions)

| Category | Examples |
|----------|----------|
| Project source code | `src/`, `*.ts`, `*.py`, `*.js` |
| CORE_EVIDENCE | `governance/`, phase reports |
| User documents | Anything not created by Factory |
| Git history | `.git/` |
| Configuration with secrets | `.env` (even `.env.example` needs confirmation) |

### Require Confirmation

| Category | Examples |
|----------|----------|
| Factory state files | `runs/`, `current-run.json` |
| Build artifacts | `dist/`, `build/`, `node_modules/` |
| Cache files | `.codex-factory/cache/` |
| External conversation spaces | `external-conversation-space/` |

### Safe to Auto-Clean (if in plan)

| Category | Examples |
|----------|----------|
| Stale temp files | `*.tmp`, `*.log` older than session |
| Orphaned harness outputs | Harness subdirectories from closed phases |

---

## Anti-Patterns (Blocked)

| Anti-Pattern | Why Blocked |
|-------------|-------------|
| "删除项目缓存" interpreted as delete project source | Catastrophic misinterpretation |
| Cleanup PLAN treated as already executed | User must confirm |
| Deleting CORE_EVIDENCE by default | Evidence preservation |
| Deleting project files without plan | Unsafe |
| Executing destructive cleanup silently | User sovereignty |
