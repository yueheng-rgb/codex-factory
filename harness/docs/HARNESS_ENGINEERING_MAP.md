**Harness Engineering Map — Phase 6C-T0**

Harness must become self-describing before it can become self-improving.

This document is a structural map of the Codex App Factory Harness. It answers structural questions about directories, scripts, and hard gates so future phases do not rediscover Harness requirements.

---

## 1. What Is Harness?

The Harness is a PowerShell-driven governance and audit framework that orchestrates multi-agent Codex runs, enforces evidence requirements, validates correctness, and produces externally verifiable audit bundles.

Harness is **not**:
- A business project or user-facing application
- A generic CI/CD pipeline
- A real-time orchestrator (it is a batch governance tool)
- A replacement for Codex `spawn_agent` / `resume_agent`

Harness is:
- A governance wrapper around Codex multi-agent capability
- An evidence chain validator
- A closure model enforcer
- An audit bundle generator

---

## 2. Core Directories

| Directory | Role |
|---|---|
| `config/` | Harness configuration (`harness.config.json`). Defines roles, max agents, state files, completion gate criteria. |
| `scripts/` | All governance scripts. The executable heart of Harness. |
| `docs/` | Documentation: engineering map, evidence flow, closure model, failure pattern catalog, self-review docs. |
| `templates/` | Agent prompt templates (`agent-task.md`, `handoff.md`, `project-request.md`). |
| `tests/` | Harness self-tests: evidence gates, final verdict, project-mode enforcement, red-team tests. Includes `fixtures/` for CFP test fixtures and test apps. |
| `runs/` | Per-run directories. Each run has its own RUN_STATE.jsonl, TASKS.json, ACCEPTANCE.json, command-logs, etc. |
| `runtime/` | Active runtime state files (RUN_STATE, TASKS, ACCEPTANCE, OWNERSHIP, RELEASE_MANIFEST). |
| `outputs/` | Final audit bundles (ZIP files) produced per phase. |
| `schemas/` | Machine-readable JSON schemas for audit bundles, run evidence, reports, agent evidence, mailbox. Created in T0. |
| `reports/` | Machine-readable validation reports (inventory, schema validation, bundle layout, SHA256SUMS). Created in T0. |
| `command-logs/` | Captured stdout/stderr/exitCode for validator runs. Created in T0. |

Missing but referenced in evidence flow (not at harness root; appear inside individual run directories):
- `agent-mailbox/` — agent messages and manifest
- `evidence/` — per-run evidence files

---

## 3. Core Scripts

### Hard Gate Scripts (failure = blocked closure)

| Script | Role |
|---|---|
| `validate-state.ps1` | READ-ONLY gate. Checks RUN_STATE, TASKS, ACCEPTANCE. Verifies hash chain, authorization proofs, task verification completeness, control plane lock. Returns `run_passed` or `run_failed`. Cannot write. |
| `validate-bundle-layout.ps1` | Checks that ZIP root has no scripts/docs/tests out of place. Validates required subdirectories. |
| `validate-sha256sums.ps1` | Verifies SHA256SUMS.txt against actual files. Reports mismatches, absolute paths, self-reference. |
| `validate-evidence-gates.ps1` | Mechanical detection of all 12 Codex Failure Patterns (CFP-001 through CFP-012). |
| `finalize-run-verdict.ps1` | Reads command exit codes and validate-state output to produce a machine-readable verdict. |
| `freeze-control-plane.ps1` | Creates CONTROL_PLANE_LOCK.json before Worker start. |
| `token-lease.ps1` | Generates time-limited authorization tokens for task claims. |
| `claim-task.ps1` | Worker claims a task with a valid token. |
| `submit-task.ps1` | Worker submits completed work. |
| `verify-task.ps1` | Validator verifies a submission. |
| `append-hash-event.ps1` | Appends a hash-chained event to RUN_STATE.jsonl. |
| `initialize-run.ps1` | Initializes a new run directory with governance files. |
| `sweep-timeouts.ps1` | Detects stale claims/leases. |
| `task-heartbeat.ps1` | Worker heartbeat to extend lease. |
| `generate-final-report.ps1` | Generates final markdown report from run state. |
| `finalize-run.ps1` | Writes terminal events to RUN_STATE. |
| `external-trust-root.ps1` | Establishes external trust root for authorization. |
| `validate-control-plane.ps1` | Validates control plane lock and token state. |
| `validate-evidence.ps1` | Validates evidence file existence and hashes. |
| `validate-delivery-archive.ps1` | Validates delivery archive completeness. |

### Advisory / Utility Scripts

| Script | Role |
|---|---|
| `harness-path-util.ps1` | Path resolution utility. |
| `install-harness-package.ps1` | Package installation helper. |
| `uninstall-harness-package.ps1` | Package uninstallation helper. |
| `verify-harness-install.ps1` | Installation verification. |
| `invoke-validation-command.ps1` | Command invocation wrapper for capturing logs. |
| `build-phase6c-m-r2.ps1` / `build-phase6c-m-r2-v2.ps1` | Phase-specific build helpers. |

---

## 4. Hard Gates vs Advisory

### Hard Gates (must pass)

These scripts define the minimum closure bar. If any hard gate fails, the phase cannot be marked PASS from audit perspective:

1. `validate-state.ps1` — run_passed
2. `validate-bundle-layout.ps1` — PASS
3. `validate-sha256sums.ps1` — 0 mismatches
4. External sidecar meta matches ZIP digest
5. All referenced evidence files exist in ZIP

### Advisory (informational only)

These provide useful information but do not block closure:

- `harness-inventory-report.json` — structural summary
- `audit-bundle-schema-validation-report.json` — schema compliance check
- Final report text — human-readable narrative (warning: text claims can diverge from machine evidence)

---

## 5. Governance Files

### Per-Run Governance Files (required inside each `runs/<run>/`)

| File | Role |
|---|---|
| `RUN_STATE.jsonl` | Hash-chained event log. Every state transition is an event with eventHash, previousHash, payloadHash. |
| `TASKS.json` | Task definitions with baseCanonicalHash, status, assigned agent. |
| `ACCEPTANCE.json` | Acceptance criteria mapped to tasks. |
| `RUN_PLAN.json` | Optional. Task DAG and execution plan. |
| `TASK_DAG.json` | Optional. Dependency graph. |
| `CONTROL_PLANE_LOCK.json` | Freeze manifest created before Worker start. |
| `RELEASE_MANIFEST.json` | Optional. Release packaging manifest. |
| `OWNERSHIP.json` | Per-agent ownership records. |
| `command-summary.json` | Summary of all command executions with exit codes. |

### Evidence Files (per run)

- `*-stdout.log`, `*-stderr.log`, `*-exitcode.txt` for each command
- `validate-state-*.log` / `.txt`
- `authorization-proofs/` — token proof files
- `SUBMIT_*.json` — submission evidence

---

## 6. Audit Bundle Closure Standard

An audit bundle is **closed** when:

1. `SHA256SUMS.txt` uses relative paths, excludes itself, has 0 mismatches
2. All evidence referenced in reports exists in the bundle
3. `validate-state.ps1` returns `run_passed`
4. External sidecar meta (`<bundle>.zip.meta.json`) records the ZIP`s actual SHA256, size, and entry count
5. ZIP internal report does **not** contain the ZIP`s own final SHA256 (self-reference problem)

Final ZIP is source of audit truth — not the final report text.

---

## 7. Business Projects

Test fixtures under `tests/fixtures/` (e.g., `bookmark-manager-genuine`, `valid-minimal-app`) are **test fixtures only**, not part of Harness itself.

Targets under `C:\Codex_App_Factory\targets\` are **external test projects** used to exercise multi-agent capability. They are not part of the Harness.

---

## 8. Phase Summary

This map was generated during **Phase 6C-T0: Harness Cartography & Audit Schema Freeze**. T0 does not prove new multi-agent capability; it makes the Harness self-describing for future phases.
