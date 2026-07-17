# Agent Execution Runtime (V4.2)

## What It Is

The Agent Execution Runtime converts V4.1/V4.1.1 task decomposition outputs
(`agent_execution_plan.json`, `task_graph.json`, `worker_plan.json`) into an
executable multi-agent run workspace with worker capsules, handoff protocol,
artifact collection, validation, integration checks, and execution receipts.

**This is NOT a fully autonomous multi-agent platform.** V4.2 is a structured
execution runtime that provides the scaffolding, boundaries, and verification
gates needed for reliable multi-agent (or multi-Codex-window) project execution.

## Core Concepts

### Run Workspace
Each execution creates a `runs/<run_id>/` directory with:
- `execution-run.json` — run metadata, plan hashes, status
- `input/` — copies of input plan files (sealed at start)
- `worker-capsules/` — per-worker assignment files
- `handoffs/` — worker-to-integrator handoff files
- `artifacts/` — collected output artifacts + artifact-index.json
- `validation/` — per-task validation results
- `integration/` — integrator cross-worker checks
- `execution-receipt.json` — final signed receipt

### Execution Modes

| Mode | Description | Auto-complete? |
|------|-------------|----------------|
| `manual` (default) | Generate capsules + handoff templates. User dispatches to Codex windows manually. | No |
| `local-script` | Run local validation scripts and artifact checks only. No code generation. | No |
| `agent-adapter` | Reserved for future spawn_agent integration. Currently NOT_CONFIGURED. | No |

### Worker Capsule
Each worker receives a capsule defining:
- Assigned tasks with IDs
- Allowed files (write boundary)
- Forbidden files (must not touch)
- Required output artifacts
- Validation methods
- Completion criteria
- Forbidden actions

### Handoff Protocol
When a worker completes, they produce a handoff JSON file containing:
- Status (COMPLETED/PARTIAL/BLOCKED/FAILED)
- Files changed
- Artifacts produced
- Test results
- Blockers and assumptions
- Handoff notes for the next agent

### The Rule: No Artifact = No PASS
Every task must produce a verifiable artifact. Validation gates check that
artifacts exist, are non-empty, and match the worker's claims. A missing
artifact is a blocking issue — never a PASS.

## CLI Commands

| Command | Description |
|---------|-------------|
| `start` | Create run workspace from agent_execution_plan |
| `status` | Show run status (handoffs, artifacts, workers) |
| `create-handoff-template` | Generate a handoff JSON template for a worker |
| `validate-handoff` | Check a handoff for completeness and boundary violations |
| `collect-artifacts` | Scan handoffs and build artifact index |
| `validate` | Run per-task validation against the validation plan |
| `integrate` | Run cross-worker integration checks |
| `close` | Generate final execution receipt |

## Quick Start

```powershell
# 1. Decompose a project (V4.1.1)
powershell -File runtime/task-decomposition-engine.ps1 `
  -Requirement examples/task-decomposition/admin-system-requirement.md `
  -OutputDir outputs/V4_1/demo-admin-system

# 2. Create an execution run (V4.2)
powershell -File runtime/agent-execution-runtime.ps1 `
  -Command start -PlanDir outputs/V4_1/demo-admin-system

# 3. Create handoff templates for each worker
powershell -File runtime/agent-execution-runtime.ps1 `
  -Command create-handoff-template -RunId <run-id> -WorkerId worker-backend

# 4. (User dispatches capsules to Codex windows; workers produce handoffs)

# 5. Validate and collect
powershell -File runtime/agent-execution-runtime.ps1 -Command collect-artifacts -RunId <run-id>
powershell -File runtime/agent-execution-runtime.ps1 -Command validate -RunId <run-id>
powershell -File runtime/agent-execution-runtime.ps1 -Command integrate -RunId <run-id>
powershell -File runtime/agent-execution-runtime.ps1 -Command close -RunId <run-id>
```

## How to Use Manual Mode

1. Run `start` to create the run workspace
2. Copy each `worker-capsules/<worker>-capsule.json` to a separate Codex window
3. Each worker works on their assigned tasks within their file boundaries
4. When done, the worker fills in their handoff template
5. Run `validate-handoff` on each handoff
6. Run `collect-artifacts`, `validate`, `integrate`, `close` sequentially

## Non-Claims

- Manual mode does NOT auto-complete workers
- Agent-adapter is NOT_CONFIGURED (reserved for future)
- EXECUTION_VERIFIED requires all handoffs COMPLETED + all artifacts present +
  validation PASS + integration READY
- This is NOT a production multi-agent SaaS platform
- No fake PASS — missing artifact always blocks
