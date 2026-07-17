# Harness Project Factory Guide

> **Phase**: Phase 6C-U2-A | **Date**: 2026-06-20
> **Purpose**: Turn the single-use U1 process into a reusable, templated Project Factory.

---

## 1. How to Write a Project Request

A project request is a JSON file that describes a 2+ Worker project. Write one at `factory/examples/<your-project>.project.json` or anywhere on disk.

### Required fields

| Field | Type | Description |
|-------|------|-------------|
| `projectName` | string | Short unique name for this project |
| `runId` | string | Run identifier (e.g., `u2-b-my-run`) |
| `workers` | array | 2+ worker definitions (see below) |
| `acceptance` | array | 2+ acceptance criteria |
| `forbiddenPaths` | array | Paths workers must not write to |

### Worker definition

| Field | Type | Description |
|-------|------|-------------|
| `workerId` | string | e.g., `worker-1` |
| `description` | string | Human-readable role summary |
| `ownedPaths` | array | Files this worker exclusively owns |
| `taskDescription` | string | What the worker must implement |
| `acceptanceDescription` | string | How success is measured |
| `exports` | array | Functions/interfaces this worker provides |
| `imports` | array | Functions/interfaces this worker consumes |

### Export definition

| Field | Type | Description |
|-------|------|-------------|
| `interfaceId` | string | Globally unique ID (e.g., `module.utils.formatDate`) |
| `name` | string | Function name |
| `file` | string | Source file path |
| `signature` | object | `{ kind, params[], returns }` |

### Import definition

| Field | Type | Description |
|-------|------|-------------|
| `interfaceId` | string | Must match an export's `interfaceId` |
| `name` | string | Function name as imported |
| `fromWorkerId` | string | Which Worker provides this |
| `file` | string | Source file where it lives |

### Example

See `factory/examples/tiny-typescript-service.project.json` for a complete 2-Worker example.

---

## 2. How to Generate a Run Skeleton

### One-click

```powershell
.\scripts\new-project-run.ps1 -ProjectRequest .\factory\examples\tiny-typescript-service.project.json -RunId my-run
```

This runs validation then materialization in sequence.

### Step-by-step

```powershell
# Validate first
.\scripts\validate-project-request.ps1 -ProjectRequest .\factory\examples\tiny-typescript-service.project.json

# Then materialize
.\scripts\materialize-project-run.ps1 -ProjectRequest .\factory\examples\tiny-typescript-service.project.json -RunId my-run
```

### What gets generated

```
runs/<runId>/
  TASKS.json              — Task definitions for each worker
  ACCEPTANCE.json          — Acceptance criteria with gates
  OWNERSHIP.json           — Per-worker ownership map + forbidden paths
  interface-contract.lock.json — Locked interface contract
  README.md                — Run overview
  prompts/
    worker-1-prompt.md     — Filled prompt for Worker 1
    worker-2-prompt.md     — Filled prompt for Worker 2
  workspace/
    worker-1/src/          — Empty, ready for Worker 1 output
    worker-2/src/          — Empty, ready for Worker 2 output
  worker-interface-manifests/  — To be filled by Workers
  source-derived-interface-manifests/ — To be filled by extractor
  canonical-integrated/src/ — Integrated output
  reports/                 — Run reports
```

---

## 3. How Each Worker Should Read Their Prompt

Each worker prompt (`prompts/worker-N-prompt.md`) contains:

1. **Project Context** — What project/run/phase this is
2. **Task Assignment** — Concrete task ID and description
3. **Files You Own** — Exactly which files are yours
4. **Interfaces You Must Provide** — Exported function names and signatures
5. **Interfaces You May Import** — What you can import from other Workers
6. **Contract Lock** — Warning not to change signatures
7. **OWNERSHIP Boundaries** — What you must NOT write to
8. **Acceptance Criteria** — How your work will be judged
9. **Required Deliverables** — Source files + manifests

The worker produces:
- Source file(s) in their workspace
- `worker-interface-manifest.json` listing actual exports
- `worker-implementation-manifest.json` listing files produced

---

## 4. How the Contract Lock is Generated

The contract lock (`interface-contract.lock.json`) is derived from the project request:

1. Each worker's `exports` become contract `interfaces`
2. Each export's `signature` is frozen (params + return type)
3. Consumer relationships are computed from `imports`
4. `locked: true` is set at generation time

Once locked, no Worker may change function names or signatures. The interface drift detector (U0/C) compares actual exports against this lock.

---

## 5. How Ownership is Generated

Ownership is derived from the project request's `ownedPaths` and `forbiddenPaths`:

- Each worker exclusively owns their `ownedPaths`
- Each worker is forbidden from writing to any other worker's paths
- All workers are forbidden from writing to `canonical-integrated/`
- The `OWNERSHIP.json` is enforced by `validate-state.ps1` during execution

---

## 6. How Acceptance Criteria are Generated

Each `acceptance` entry from the project request becomes an acceptance criterion with:

- **taskIds** — Which tasks must satisfy this criterion
- **requiredEvidence** — What evidence must be present (source_output, interface_manifest, validate_state_output)
- **gateChecks** — Which gates must pass (contractLock, interfaceDrift, manifestHonesty, hashChain, tokenProofs, integrationGate)

---

## 7. How to Enter a Real spawn Run

After the run skeleton is generated:

1. **Orchestrator** reads `TASKS.json` and `interface-contract.lock.json`
2. **Orchestrator** spawns Workers via `spawn_agent` with generated prompts
3. **Workers** produce source files + manifests in their workspaces
4. **Validator** runs `validate-state.ps1` + drift detection + integration gate
5. **Orchestrator** integrates patches into `canonical-integrated/`
6. **Harness** produces final audit bundle with SHA256SUMS + sidecars

The skeleton is ready for any future U2-B real run.

---

## 8. What Cannot Be Manually Faked

The following must come from real `spawn_agent` Worker execution:

| Artifact | Why not fakeable |
|----------|-----------------|
| `worker-interface-manifest.json` | Must match actual `src/*.ts` exports; drift detector checks |
| `worker-implementation-manifest.json` | Must list actual files; SHA256SUMS checked |
| `source-derived-interface-manifests/` | Extracted from actual source by script |
| `spawn-agent-evidence.json` | Contains token proofs, hash events from real run |
| `RUN_STATE.jsonl` | Hash-chained event log; validate-state verifies chain integrity |
| `canonical-integrated/src/*.ts` | Must compile + pass integration tests |

---

## 9. How Interface Drift is Handled

If a Worker's actual exports don't match the contract:

1. **Interface drift detector** (`detect-interface-drift.ps1`) flags mismatches
2. **Integration gate** blocks progress
3. **Orchestrator** creates a **rework request** (`create-rework-request.ps1`)
4. **Worker** fixes and resubmits
5. **Validator** re-verifies

See Phase 6C-U0/C and U0/F for the drift detection and rework infrastructure.

---

## 10. How Rework is Handled

If a Worker's output fails validation:

1. `ACCEPTANCE.json` status for that task is set to `rework_required`
2. Rework request created with specific failures listed
3. Worker receives rework prompt with exact issues
4. Worker resubmits; drift detector runs again
5. If still failing after rework cycle, run is marked `run_failed` with `REWORK_NO_RESOLUTION`

---

## 11. How to Finally Package an Audit Bundle

After all Workers complete and all gates pass:

```powershell
# Finalize the run
.\scripts\finalize-run.ps1 -RunDir runs/<runId>

# Validate state
.\scripts\validate-state.ps1 -RunDir runs/<runId>

# Package audit bundle (see T0-R3 / U1-D style)
# ... bundle packaging scripts ...
```

The final ZIP must be immutable after creation, with external self-check sidecar.

---

## Reference: Factory Files

| Path | Purpose |
|------|---------|
| `factory/templates/project-request.template.json` | Blank project request template |
| `factory/templates/task.template.json` | Task definition template |
| `factory/templates/acceptance.template.json` | Acceptance criteria template |
| `factory/templates/interface-contract.template.json` | Contract lock template |
| `factory/templates/ownership.template.json` | Ownership map template |
| `factory/templates/worker-prompt.template.md` | Worker prompt template |
| `factory/templates/final-report.template.md` | Final report template |
| `factory/examples/tiny-typescript-service.project.json` | Complete example |
| `scripts/validate-project-request.ps1` | Project request validator |
| `scripts/materialize-project-run.ps1` | Run skeleton materializer |
| `scripts/new-project-run.ps1` | One-click validate + materialize |
