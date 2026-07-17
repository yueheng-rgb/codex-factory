# Harness Rules

## Architecture

The Harness is a governed multi-agent factory for Codex. It wraps `spawn_agent` with:
- Token-based authorization with event-time proofs
- Cryptographic RUN_STATE hash chain
- Builder/Validator/Integrator role separation
- Dual engineering + governance verification

## Agent Roles

### Orchestrator
- Creates runs, issues tokens, freezes control plane
- Manages TASK_DAG, TASKS.json, ACCEPTANCE.json
- Runs sweeps for timeout detection
- Initiates re-dispatch for timed-out tasks

### Builder
- Claims tasks with valid tokens
- Works only within allowedPaths
- Submits evidence (stdout, stderr, exitCode)
- Cannot self-verify

### Validator
- Independent from Builder
- Uses test-agent role
- Validates submission evidence
- Generates validation_started, validation_passed, task_verified

### Integrator
- Applies verified patches
- Checks baseCanonicalHash
- Records integration evidence

## Scripts

| Script | Purpose |
|--------|---------|
| initialize-run.ps1 | Create new run directory and baseline |
| freeze-control-plane.ps1 | Lock harness scripts for run duration |
| external-trust-root.ps1 | Freeze external trust baseline |
| token-lease.ps1 | Issue, validate, sign authorization tokens |
| claim-task.ps1 | Builder claims a task |
| submit-task.ps1 | Builder submits completed work |
| verify-task.ps1 | Validator verifies a submission |
| invoke-validation-command.ps1 | Run validation with proof generation |
| task-heartbeat.ps1 | Builder sends heartbeat |
| sweep-timeouts.ps1 | Detect and re-dispatch timed-out tasks |
| append-hash-event.ps1 | Append event to RUN_STATE hash chain |
| validate-state.ps1 | Full governance verification |
| validate-control-plane.ps1 | Verify control plane integrity |
| validate-evidence.ps1 | Verify evidence file hashes |
| validate-delivery-archive.ps1 | Verify ZIP structure |

## Key Files

| File | Purpose |
|------|---------|
| TASKS.json | Task definitions and status |
| ACCEPTANCE.json | Acceptance criteria |
| TASK_DAG.json | Task dependency graph |
| RUN_PLAN.json | Execution plan |
| RUN_STATE.jsonl | Hash-chained event log |
| CONTROL_PLANE_LOCK.json | Frozen harness baseline |
| RELEASE_MANIFEST.json | Release metadata |
| OWNERSHIP.json | Task ownership tracking |
| HARNESS_BASELINE.json | Initial harness state |
