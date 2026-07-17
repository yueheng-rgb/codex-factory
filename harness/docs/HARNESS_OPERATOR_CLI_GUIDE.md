# Harness Operator CLI Guide

> **Phase**: Phase 6C-U3-A | **Date**: 2026-06-20
> **Purpose**: Unified Operator CLI for the Project Factory workflow.

---

## 1. What is the Operator CLI?

`invoke-project-factory.ps1` is a single entry point that wraps all Project Factory operations. Instead of running individual scripts, the Operator uses one CLI with modes.

## 2. How to Run Preflight

```powershell
.\scripts\invoke-project-factory.ps1 -Mode Preflight -ProjectRequest .\factory\examples\tiny-typescript-service.project.json -RunId my-run
```

**Checks**:
- Project request exists
- All required scripts exist
- Factory templates exist (≥7)
- Closed artifacts (T0-R3, U1, U2 ZIPs) exist
- No run directory collision (unless `-Force`)
- Project request validation passes

**Output**: `outputs/<RunId>-preflight-report.json`

**Exit 0**: All checks pass. Next: `-Mode Materialize`.

## 3. How to Run Materialize

```powershell
.\scripts\invoke-project-factory.ps1 -Mode Materialize -ProjectRequest .\factory\examples\tiny-typescript-service.project.json -RunId my-run
```

**Actions**:
- Runs `validate-project-request.ps1`
- Runs `materialize-project-run.ps1`
- Verifies generated artifacts

**Output**: `runs/<RunId>/` + `outputs/<RunId>-materialization-report.json`

**Requirements**: Does NOT run spawn_agent. Does NOT create Worker source outputs. Contract is locked.

## 4. How to Generate a PromptPack

```powershell
.\scripts\invoke-project-factory.ps1 -Mode PromptPack -RunId my-run
```

**Actions**: Collects both worker prompts, contract summary, and ownership summary into a single markdown file.

**Output**: `outputs/<RunId>-worker-prompt-pack.md`

## 5. How to Hand Off Prompt Pack to Real Workers

The prompt pack contains:
1. Full Worker 1 prompt (copy into spawn_agent call)
2. Full Worker 2 prompt (copy into spawn_agent call)
3. Contract summary
4. Ownership rules
5. Exact next steps

**Procedure**:
1. Read `outputs/<RunId>-worker-prompt-pack.md`
2. Copy Worker 1 prompt block → `spawn_agent` call
3. Copy Worker 2 prompt block → `spawn_agent` call (in parallel)
4. After Workers complete, save outputs to `runs/<RunId>/workspace/worker-N/src/`
5. Run `-Mode GateCheck`
6. Run `-Mode Status`

## 6. GateCheck When No Worker Outputs Exist

```powershell
.\scripts\invoke-project-factory.ps1 -Mode GateCheck -RunId my-run
```

If Worker outputs don't exist: returns `WAITING_FOR_WORKER_OUTPUTS`. This is **NOT a failure** — it correctly indicates Workers haven't been run yet.

If Worker outputs exist: runs honesty, drift, and other gate checks.

## 7. Status Machine

| Status | Meaning | Next Action |
|--------|---------|-------------|
| `MATERIALIZED_WAITING_FOR_WORKERS` | Skeleton ready, no Worker outputs | Run spawn_agent Workers |
| `WORKER_OUTPUTS_PRESENT_NO_SPAWN_EVIDENCE` | Worker code exists, no spawn proof | Create spawn evidence |
| `WORKERS_COMPLETED_WAITING_VALIDATION` | Ready for validate-state | Run validate-state.ps1 |
| `RUN_PASSED` | All gates passed | Proceed to negatives or audit bundle |
| `RUN_FAILED` | Validation failed | Check errors, fix, retry |

## 8. What Cannot Be Faked

| Artifact | Why |
|----------|-----|
| Worker source outputs | Must come from real spawn_agent |
| spawn-agent-evidence.json | Must record real agent IDs |
| RUN_STATE.jsonl | Must have valid hash chain |
| validate-state run_passed | Must pass all gate checks |
| Gate PASS reports | Must be computed from real outputs |

The Operator CLI correctly returns `WAITING` status when these are missing — it never pretends completion.

## 9. When to Enter a Real spawn_agent Run

After `PromptPack` is generated and `Status` shows `MATERIALIZED_WAITING_FOR_WORKERS`:
1. Hand off prompts to Orchestrator
2. Orchestrator spawns 2 Workers in parallel
3. Workers produce source files
4. Operator saves outputs to workspace
5. Run `GateCheck` → `Status` → `validate-state`

## 10. When to Enter Negative Controls

After a positive run achieves `RUN_PASSED`:
1. Clone the positive run to 3 negative directories
2. Inject failures (drift, isolation, no-rework)
3. Run validate-state on each
4. Verify all fail for intended reasons

## 11. When to Package Final Audit Bundle

After positive run + negative controls are complete:
1. Create staging directory with all evidence
2. Generate SHA256SUMS
3. Create immutable ZIP
4. Create external self-check and meta sidecars
5. Run verifier

## 12. Common Failures and Handling

| Failure | Cause | Fix |
|---------|-------|-----|
| Preflight BLOCKED | Run dir already exists | Use `-Force` or pick new RunId |
| Preflight FAIL | Missing script/template | Check harness installation |
| GateCheck WAITING | No Worker outputs yet | Run spawn_agent Workers |
| INTERFACE_DRIFT_FAIL | Worker changed function name | Rework Worker to match contract |
| WORKSPACE_ISOLATION_FAIL | Worker wrote cross-workspace | Remove cross-workspace writes |
| REWORK_NO_RESOLUTION | Blocking rework not resolved | Create resolution in rework-resolutions/ |

---

## Reference: All CLI Modes

| Mode | Requires | Creates | Spawns Agents? |
|------|----------|---------|----------------|
| `Preflight` | `-ProjectRequest` | preflight report | No |
| `Materialize` | `-ProjectRequest` | run skeleton | No |
| `PromptPack` | (none beyond -RunId) | prompt pack .md | No |
| `GateCheck` | (none beyond -RunId) | gate check report | No |
| `Status` | (none beyond -RunId) | status report | No |
| `CleanPreview` | (none beyond -RunId) | preview report | No |
