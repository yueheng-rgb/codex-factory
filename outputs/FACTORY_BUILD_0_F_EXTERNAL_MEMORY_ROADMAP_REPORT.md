# FACTORY-BUILD-0 / F: External Memory Roadmap Report

> **Phase**: FACTORY-BUILD-0
> **Date**: 2026-06-27

---

## The Problem

Codex windows have no persistent memory. Complex projects span multiple sessions. Without external memory, each new window starts from zero — losing architecture decisions, task progress, risks, and context.

## The Solution: File-Based State MVP

All project state lives under {project}/.codex-factory/ — a portable directory of structured files that any Codex window can read.

### Phase 1 — File-Based State (BUILD-2 Target)

| File | Content | Purpose |
|------|---------|---------|
| state.json | Current stage, completed stages, mode, last action | Single source of truth |
| rchitecture-map.json | Pages, APIs, DB tables, permissions, tech stack | Architecture persists |
| equirement-map.json | Original + derived requirements, traceability | Requirements don't get lost |
| 	ask-graph.json | Task nodes, status, dependencies, ownership | Work remaining always visible |
| decisions.md | Key decisions with rationale and date | Why was this choice made? |
| isks.json | Active risks, mitigations, status | Don't forget known risks |
| handoff-packet.md | Condensed state for new Codex window | One file to resume |
| diagnostic-results/ | Diagnostic Gate outputs per run | Audit trail |

### Retrieval Mechanism

- scripts/factory-state-retrieve.ps1 — reads all state files, outputs summary
- New Codex window reads handoff-packet.md first, then state.json, then resumes

### Phase 2 — Structured External DB (Future)

- SQLite or Supabase-backed state store
- Queryable decision log with embeddings
- Cross-project pattern library
- Agent performance metrics

### Phase 3 — Cloud Knowledge Recovery (Future)

- Cloud-synced state for multi-machine development
- Shared knowledge base across users
- Learned patterns from past complex projects

## Continuation Protocol

| Moment | Action |
|--------|--------|
| **Startup** | Read handoff-packet.md → state.json → resume current stage |
| **Mid-session** | After each stage: update state.json, append decisions.md |
| **Handoff** | Before session end: generate fresh handoff-packet.md |
| **Verification** | Startup verify: state files exist and are consistent |
