# Codex App Factory — Phase 6A Harness

## Purpose
Multi-agent orchestration harness with **independent verification**.
No agent can self-declare PASS. Only the Validator (validate-state.ps1) decides.

## Architecture

```
harness/
├─ config/harness.config.json      # Harness configuration
├─ templates/                       # Project request, task, handoff templates
├─ runtime/                         # Shared state (SPEC, ACCEPTANCE, TASKS, OWNERSHIP)
├─ scripts/                         # Core orchestration scripts
│  ├─ initialize-run.ps1           # Create new run
│  ├─ claim-task.ps1               # Agent claims a task
│  ├─ submit-task.ps1              # Agent submits candidate_complete
│  ├─ validate-state.ps1           # THE UNFAKEABLE PASS GATE
│  ├─ validate-evidence.ps1        # Evidence trail validator
│  └─ validate-delivery-archive.ps1 # ZIP round-trip gate
└─ runs/                            # Per-run directories with evidence
```

## Five-Role Model (Phase 6A)

| Role | Description | Max per run |
|---|---|---|
| Orchestrator | Master control, task assignment | 1 |
| Spec Agent | Requirements & acceptance criteria | 1 |
| Builder Agent | Feature implementation | 1 (expandable) |
| Test Agent | Independent verification | 1 |
| Release Agent | Final packaging & round-trip | 1 |

## Unfakeable Completion

Only `validate-state.ps1` can write `run_passed` or `run_failed`.

Agents can only submit `candidate_complete`.

PASS requires:
1. All required acceptance items pass
2. All tasks verified
3. No unclosed validation_started
4. No builder self-verification
5. All evidence files exist
6. ZIP round-trip passes
7. No manual remediation

## Quick Start

```powershell
# Initialize a new run
.\scripts\initialize-run.ps1 -RunId "run-001" -ProjectName "my-app"

# (Agents generate and populate TASKS.json, ACCEPTANCE.json in the run dir)

# Run the validator
.\scripts\validate-state.ps1 -RunDir ".\runs\run-001"
```

## Current Phase
**6A** — Harness skeleton, state protocol, single-builder flow.
No multi-agent auto-claiming yet.
