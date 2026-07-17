# FACTORY-BUILD-0 / E: Build Agent Model Report

> **Phase**: FACTORY-BUILD-0
> **Date**: 2026-06-27

---

## Principle

**Multi-agent is CONDITIONAL, not default.** Agent count scales with project complexity. Vanilla (single agent) remains the default for all projects unless complexity demands more.

## Three Tiers

### Tier 1: Vanilla (Single Agent) — DEFAULT

| Property | Value |
|----------|-------|
| Complexity | SIMPLE |
| Agent Count | 1 |
| Trigger | Default for all projects |

**Rules**:
- Single Codex agent does everything
- Harness provides intake/classify/blueprint/task-graph as guidance documents
- Diagnostic Gate runs after build
- No spawn_agent calls

### Tier 2: Build Lite (Single Agent + Harness) — CONDITIONAL

| Property | Value |
|----------|-------|
| Complexity | MODERATE |
| Agent Count | 1 |
| Trigger | 10-100 files, auth, DB, 2+ apps |

**Rules**:
- Single agent with harness-guided phased execution
- Harness enforces stage gates between phases
- State file persists across session boundaries
- Diagnostic Gate after each major phase

### Tier 3: Build Pro (4-Agent P1) — EXPERIMENTAL, CONDITIONAL

| Property | Value |
|----------|-------|
| Complexity | COMPLEX (>100 files, auth, DB, 3+ apps) |
| Agent Count | 4 |
| Trigger | Financial/compliance risk or explicit user request |

**Agent Roles**:
| Agent | Role | Scope |
|-------|------|-------|
| Agent 1 | Architect | Blueprint + task graph generation |
| Agent 2 | Backend | Server, API, DB implementation |
| Agent 3 | Frontend | UI, routing, state management |
| Agent 4 | Verifier | Diagnostic Gate, integration check, negative controls |

**Allocation Rules**:
- **Disjoint write scopes**: No two agents write to the same file
- **State file governed**: All agents read/write through .codex-factory/state.json
- **Integration gate**: Agent 4 validates cross-agent API contracts
- **Handoff protocol**: Each agent produces a completion receipt

## Forbidden Patterns

- Multi-agent as default for simple projects
- 7-agent legacy mode (CUT)
- 10-role model (CUT)
- Agent count exceeding project complexity need
- Overlapping write scopes
- Multi-agent without state file governance
