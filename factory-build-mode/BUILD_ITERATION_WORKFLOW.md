# Build Mode — Build Iteration Workflow

> Describes the full lifecycle of a build, including continuation and repair loops.

## Primary Flow

```
INTAKE → CLASSIFY → ROUTE → BLUEPRINT → TASK_GRAPH → BUILD → DIAGNOSTIC_GATE → DELIVER
```

## Repair Loop

```
DIAGNOSTIC_GATE (gaps found)
  → User reviews gaps
  → User approves repair scope
  → REPAIR (targeted fixes only)
  → DIAGNOSTIC_GATE (re-verify)
  → DELIVER (if clean)
```

## Continuation Loop

```
Session 1: INTAKE → CLASSIFY → ROUTE → BLUEPRINT
  → Save state to .codex-factory/
  → Generate handoff-packet.md

Session 2 (new Codex window):
  → Read handoff-packet.md
  → Read state.json
  → Resume from TASK_GRAPH
  → Continue through DELIVER
```

## Build → Extend Loop

```
DELIVER (v1 done)
  → User wants new features
  → New INTAKE (extend mode)
  → Complexity re-evaluation
  → Continue from appropriate stage
```

## State Persistence

Every stage transition writes to `.codex-factory/state.json`.
Before session end: generate fresh `handoff-packet.md`.
Startup: read handoff → state → resume.

## Emergency Stop

If critical issue found at any stage:
1. Record in `.codex-factory/risks.json`
2. Update state to BLOCKED
3. Generate handoff with BLOCKED status
4. Report to user with specific blocking issue
