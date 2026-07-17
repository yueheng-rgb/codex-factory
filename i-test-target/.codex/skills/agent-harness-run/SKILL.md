---
name: agent-harness-run
description: |
  Governed multi-agent project execution through the Harness. Use when the user asks to run a project through the Harness, execute governed builds, run multi-agent task pipelines, or produce auditable build evidence. Triggers on phrases like "run through harness", "harness build", "governed run", "multi-agent task", "audit bundle", "validate-state".
---

# Agent Harness Run

Execute governed project runs through the Codex App Factory Harness.

## When to Use
- User wants a governed, auditable project build
- Multi-agent task decomposition with independent verification
- Audit-ready evidence bundle generation

## Workflow

### 1. Initialize
Run `scripts/initialize-run.ps1` to create a run directory. Then freeze the control plane and external trust root.

### 2. Decompose
Break the project into tasks in TASKS.json with dependency structure. Define acceptance criteria in ACCEPTANCE.json.

### 3. Execute
For each task (respecting dependencies):
- **Builder** claims task with token
- Builder works within allowedPaths only
- Builder submits evidence (stdout/stderr/exitCode)
- **Validator** (independent, test-agent role) validates submission
- Validator generates validation_started/passed events
- Validator generates task_verified

### 4. Integrate
Integrator applies verified patches, checking baseCanonicalHash.

### 5. Govern
Run `validate-state.ps1` for final governance verification.

## Hard Rules
- Builder cannot self-verify (enforced by role check)
- No direct canonical modification (enforced by allowedPaths)
- Every state transition requires token authorization proof
- All commands must capture stdout/stderr/exitCode
- validate-state PASS does not equal engineering PASS
- Never claim untested capabilities in reports
