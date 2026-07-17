# Build Mode — Agent Build Protocol

> Defines how agents execute builds. Multi-agent is CONDITIONAL, not default.

## Default: Single Agent (Vanilla)

All projects default to single-agent execution unless complexity demands more.

Rules:
- One Codex agent executes all task graph nodes
- Harness provides intake/classify/blueprint/task-graph as guidance
- Diagnostic Gate runs after build
- State file updated after each stage

## Conditional: BUILD_PRO_4_AGENT

Only for HIGH_RISK projects. Requires explicit user approval. Never automatic.

### Agent Roles

| Agent | Role | Write Scope |
|-------|------|------------|
| Agent 1 | Architect | Blueprint + task graph generation |
| Agent 2 | Backend | Server, API, DB, auth implementation |
| Agent 3 | Frontend | UI, routing, state management |
| Agent 4 | Verifier | Diagnostic Gate, integration check, negative controls |

### Allocation Rules

1. DISJOINT WRITE SCOPES: No two agents write to the same file
2. STATE FILE GOVERNED: All agents read/write through `.codex-factory/state.json`
3. INTEGRATION GATE: Agent 4 validates cross-agent contracts
4. HANDOFF RECEIPT: Each agent produces completion receipt

### Forbidden Patterns

- Multi-agent for simple/medium projects
- 7-agent legacy mode (CUT)
- 10-role model (CUT)
- Overlapping write scopes
- Multi-agent without state file governance
- Agent count exceeding complexity need
