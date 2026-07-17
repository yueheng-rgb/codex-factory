# FACTORY-BUILD-0 / D: Build Harness Workflow Report

> **Phase**: FACTORY-BUILD-0
> **Date**: 2026-06-27

---

## Build Harness Production Pipeline — 9 Stages

`
INTAKE → CLASSIFY → ROUTE → BLUEPRINT → TASK_GRAPH → BUILD → DIAGNOSTIC_GATE → REPAIR → DELIVER
`

### Stage 0: INTAKE
- **In**: User project path/description
- **Do**: Read files, extract requirements, detect greenfield vs existing
- **Out**: Project manifest (type, tech stack, scope)
- **Gate**: Proof-of-Read confirmation

### Stage 1: CLASSIFY
- **In**: Project manifest
- **Do**: Count files/apps, detect auth/DB/API, assess complexity and risk
- **Out**: SIMPLE / MODERATE / COMPLEX + risk level
- **Gate**: Classification confirmed

### Stage 2: ROUTE
- **In**: Classification + user goal
- **Do**: Select Vanilla / Build Lite / Build Pro. If diagnosis-only → skip to Gate.
- **Out**: Mode selection with rationale
- **Gate**: Mode recorded in state file

### Stage 3: BLUEPRINT
- **In**: Requirements + classification
- **Do**: Page tree, API outline, DB schema, permissions, first-version scope
- **Out**: Architecture blueprint
- **Gate**: Completeness check

### Stage 4: TASK_GRAPH
- **In**: Blueprint
- **Do**: Decompose into nodes, dependency order, file ownership, effort estimate
- **Out**: Dependency-ordered task graph
- **Gate**: All blueprint items covered

### Stage 5: BUILD
- **In**: Task graph
- **Do**: SIMPLE→Vanilla, MODERATE→Build Lite, COMPLEX→Build Pro (4-agent)
- **Out**: Implemented codebase
- **Gate**: All nodes complete with evidence

### Stage 6: DIAGNOSTIC_GATE
- **In**: Completed codebase
- **Do**: Readonly checklist (Quick/Student/Full). Flag gaps. NO auto-fix.
- **Out**: Diagnostic report
- **Gate**: 0 critical → DELIVER. Critical → REPAIR.

### Stage 7: REPAIR
- **In**: Gap list
- **Do**: User reviews → approves scope → targeted fixes only
- **Out**: Fixed codebase + re-verified
- **Gate**: Re-run diagnostic

### Stage 8: DELIVER
- **In**: Verified codebase
- **Do**: Handoff packet, state update, run instruction, milestone report
- **Out**: Ready-to-run project
- **Gate**: One-command startup verified

## State File Convention

All state lives under {project}/.codex-factory/:
| File | Content |
|------|---------|
| state.json | Current stage, progress |
| rchitecture-map.json | Blueprint decisions |
| 	ask-graph.json | Work items + status |
| decisions.md | Key decisions log |
| isks.json | Active risks |
| handoff-packet.md | Continuation summary |
