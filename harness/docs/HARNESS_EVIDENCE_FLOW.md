**Harness Evidence Flow — Phase 6C-T0**

This document describes the 13-step evidence chain from Task Plan to External Audit. Each step defines its input files, output files, validator script, failure mode, and whether it is a hard gate.

---

## Step 1: Task Plan

- **Input**: User project request, acceptance criteria
- **Output**: `RUN_PLAN.json`, `TASK_DAG.json`, `TASKS.json`, `ACCEPTANCE.json`
- **Validator**: Manual review by Orchestrator
- **Failure mode**: Missing tasks, missing dependencies, missing acceptance criteria
- **Hard gate**: Yes — no run can start without TASKS.json and ACCEPTANCE.json

---

## Step 2: Agent Capsule

- **Input**: Assigned task from TASKS.json
- **Output**: Per-agent context files, handoff instructions, task specification
- **Validator**: `validate-state.ps1` checks agent role assignment
- **Failure mode**: Agent role not authorized for task, agent not recorded in OWNERSHIP.json
- **Hard gate**: Yes — agent must be traceable

---

## Step 3: Spawn / Resume Manifest

- **Input**: Agent capsule, task assignment
- **Output**: `AGENT_SPAWN_MANIFEST.json` (records spawn_agent calls and agent IDs)
- **Validator**: `validate-state.ps1` checks authorization proof for task_claimed events
- **Failure mode**: Missing spawn manifest, agent ID drift, missing authorization proof
- **Hard gate**: Yes — task_claimed must have valid authorization proof

---

## Step 4: Workspace / Worktree

- **Input**: Agent spawn, project specification
- **Output**: `WORKTREE_MANIFEST.json`, `AGENT_CAPSULE_MANIFEST.json`, workspace directory
- **Validator**: `validate-state.ps1` checks control-plane freeze and worktree isolation
- **Failure mode**: Missing worktree manifest, no control-plane freeze, builder self-verification
- **Hard gate**: Control-plane freeze required; worktree manifest advisory for now

---

## Step 5: Branch Result / Delta / Files Changed

- **Input**: Agent workspace changes, code modifications
- **Output**: Patch files, `OWNERSHIP.json` with changed files, `baseCanonicalHash`
- **Validator**: `validate-state.ps1` checks submission completeness
- **Failure mode**: Hollow OWNERSHIP (CFP-003), missing changed files, stale baseCanonicalHash
- **Hard gate**: Yes — patch must be bound to baseCanonicalHash

---

## Step 6: Mailbox Messages

- **Input**: Agent handoff messages, inter-agent communication
- **Output**: `agent-mailbox/messages.jsonl`, `agent-mailbox/MAILBOX_MANIFEST.json`, `run/MAILBOX_USAGE_REPORT.json`
- **Validator**: Evidence completeness check
- **Failure mode**: Missing mailbox evidence, no handoff artifacts
- **Hard gate**: No — advisory in current Harness version

---

## Step 7: Submission / Ownership

- **Input**: Completed work, evidence files, patch
- **Output**: `submission.json`, `OWNERSHIP.json` update
- **Validator**: `verify-task.ps1`, `submit-task.ps1` formal entries
- **Failure mode**: Duplicate submission (FR6), missing evidence (FR4), stale hash (FR5)
- **Hard gate**: Yes — submission must be complete and valid

---

## Step 8: Validator Evidence

- **Input**: Builder submission
- **Output**: `validation_started`, `validation_passed`/`validation_failed` events in RUN_STATE.jsonl
- **Validator**: `verify-task.ps1`, `validate-state.ps1` checks authorization proof
- **Failure mode**: Builder self-verification, missing authorization proof, evidence tampering
- **Hard gate**: Yes — Validator must be independent (not same agent as Builder)

---

## Step 9: Project Verification

- **Input**: Validated patches applied to canonical
- **Output**: Unit test results, typecheck results, build results, Playwright results
- **Validator**: `npm run test:unit`, `npm run typecheck`, `npm run build`, `npm run test:playwright`
- **Failure mode**: Tests fail after integration (FR1), conflicts during integration (FR7)
- **Hard gate**: Yes — all tests must pass

---

## Step 10: Evidence Gate

- **Input**: All evidence files, reports, command logs
- **Output**: Evidence gate report (CFP-001 through CFP-012 detection)
- **Validator**: `validate-evidence-gates.ps1`
- **Failure mode**: Report/evidence contradiction (CFP-001), exitCode/verdict disagreement (CFP-002), hollow evidence (CFP-003), etc.
- **Hard gate**: Yes — all 12 CFP gates must pass

---

## Step 11: Final Verdict

- **Input**: Command exit codes, validate-state output, evidence gate report
- **Output**: Machine-readable verdict (PASS / FAIL / PARTIAL)
- **Validator**: `finalize-run-verdict.ps1`
- **Failure mode**: Verdict disagreement with evidence, inconsistent mode handling
- **Hard gate**: Yes — verdict must be machine-derived

---

## Step 12: Bundle Layout

- **Input**: All run evidence, reports, command logs
- **Output**: Audit bundle directory with correct structure
- **Validator**: `validate-bundle-layout.ps1`
- **Failure mode**: Scripts/docs at root, missing required directories
- **Hard gate**: Yes — bundle layout must be valid

---

## Step 13: SHA256SUMS Closure → External Audit

- **Input**: Complete bundle directory, SHA256SUMS.txt with relative paths
- **Output**: `<bundle>.zip`, `<bundle>.zip.meta.json` (external sidecar)
- **Validator**: `validate-sha256sums.ps1`
- **Failure mode**: Hash mismatches, absolute paths in SHA256SUMS, self-referencing SHA256
- **Hard gate**: Yes — 0 mismatches required

---

## Summary Table

| Step | Hard Gate | Key Validator |
|---|---|---|
| 1. Task Plan | Yes | Manual |
| 2. Agent Capsule | Yes | validate-state.ps1 |
| 3. Spawn/Resume Manifest | Yes | validate-state.ps1 |
| 4. Workspace/Worktree | Partial | validate-state.ps1 |
| 5. Branch Result/Delta | Yes | validate-state.ps1 |
| 6. Mailbox Messages | No | Advisory |
| 7. Submission/Ownership | Yes | verify-task.ps1 |
| 8. Validator Evidence | Yes | validate-state.ps1 |
| 9. Project Verification | Yes | npm test / typecheck / build |
| 10. Evidence Gate | Yes | validate-evidence-gates.ps1 |
| 11. Final Verdict | Yes | finalize-run-verdict.ps1 |
| 12. Bundle Layout | Yes | validate-bundle-layout.ps1 |
| 13. SHA Closure | Yes | validate-sha256sums.ps1 |

Final ZIP is source of audit truth — not the final report text.
