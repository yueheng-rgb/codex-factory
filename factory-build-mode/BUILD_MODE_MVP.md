# Build Mode MVP — Full Workflow

> The Build Harness control plane. This document describes the complete pipeline.

---

## Pipeline Overview

```
[0] INTAKE ──> [1] CLASSIFY ──> [2] ROUTE ──> [3] BLUEPRINT
                                                  │
[8] DELIVER <── [7] REPAIR <── [6] DIAGNOSTIC <── [4] TASK_GRAPH
                                        │              │
                                        └── [5] BUILD <─┘
```

## Stage 0: INTAKE

User provides project requirements or project path. System reads and produces a project manifest.

**Input**: User description or project path
**Output**: `intake.json` — project manifest
**Template**: `templates/project-intake.template.json`
**Policy**: Proof-of-Read confirmation required before proceeding

## Stage 1: CLASSIFY

System analyzes intake manifest to determine complexity.

**Input**: `intake.json`
**Output**: `classification.json` — complexity level + risk assessment
**Policy**: `policies/complexity-classifier-policy.json`
**Levels**: SMALL, MEDIUM, LARGE, LONG_HORIZON, HIGH_RISK

## Stage 2: ROUTE

System selects execution mode based on complexity and user goal.

**Input**: `classification.json` + user goal
**Output**: `mode-selection.json` — selected mode with rationale
**Policy**: `policies/mode-selector-policy.json`
**Modes**: VANILLA_BUILD, BUILD_LITE, BUILD_REVIEWER, BUILD_CONTINUATION, BUILD_PRO_4_AGENT, DIAGNOSTIC_ONLY

## Stage 3: BLUEPRINT

System generates architecture blueprint.

**Input**: `intake.json` + `classification.json`
**Output**: `blueprint.json` — pages, APIs, DB schema, permissions
**Template**: `templates/blueprint.template.json`

## Stage 4: TASK_GRAPH

System decomposes blueprint into dependency-ordered tasks.

**Input**: `blueprint.json`
**Output**: `task-graph.json` — tasks with dependencies and file ownership
**Template**: `templates/task-graph.template.json`

## Stage 5: BUILD

Codex executes tasks according to selected mode.

**Input**: `task-graph.json` + mode
**Output**: Implemented codebase
**Protocol**: `BUILD_AGENT_PROTOCOL.md`

## Stage 6: DIAGNOSTIC_GATE

Diagnostic Pack runs readonly quality check.

**Input**: Completed codebase
**Output**: Diagnostic report with gap list
**Integration**: `DIAGNOSTIC_GATE.md`
**Rule**: STOP after diagnostic. No auto-repair.

## Stage 7: REPAIR

User-approved targeted fixes for diagnostic findings.

**Input**: Diagnostic gap list + user approval
**Output**: Fixed codebase + re-verified
**Rule**: Only fix explicitly approved items

## Stage 8: DELIVER

Generate handoff packet, update state, produce run instruction.

**Input**: Verified codebase
**Output**: Handoff packet + milestone report + run command
**Template**: `memory-templates/handoff-packet.template.md`

## State File Convention

All state under `{project}/.codex-factory/`:

| File | Stage Written | Purpose |
|------|--------------|---------|
| `state.json` | All stages | Current stage, progress |
| `intake.json` | Stage 0 | Project manifest |
| `classification.json` | Stage 1 | Complexity result |
| `mode-selection.json` | Stage 2 | Selected mode |
| `blueprint.json` | Stage 3 | Architecture |
| `task-graph.json` | Stage 4 | Work plan |
| `decisions.md` | Stages 2-5 | Key decisions |
| `risks.json` | Stages 2-5 | Active risks |
| `diagnostic-result.json` | Stage 6 | Gate results |
| `handoff-packet.md` | Stage 8 | Continuation |

## Execution Modes

| Mode | Complexity | Agents | Default? |
|------|-----------|--------|----------|
| VANILLA_BUILD | SMALL | 1 (Vanilla) | YES |
| BUILD_LITE | MEDIUM | 1 + harness | CONDITIONAL |
| BUILD_REVIEWER | LARGE | 1 + Reviewer-Verifier | CONDITIONAL |
| BUILD_CONTINUATION | LONG_HORIZON | 1 + state management | CONDITIONAL |
| BUILD_PRO_4_AGENT | HIGH_RISK | 4 (conditional) | NO |
| DIAGNOSTIC_ONLY | Any | 1 (diagnostic only) | User choice |
