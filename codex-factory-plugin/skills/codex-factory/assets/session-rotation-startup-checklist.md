# Session Rotation Startup Checklist

> **Category**: bootstrap | **Stability**: stable
>
> Run this checklist at the start of EVERY new session/window in a Codex Factory project.
> Each item must be confirmed before work begins.

---

## Mandatory Startup Sequence

### 1. Run Factory Verification

- [ ] Run `factoryctl verify`:
  ```powershell
  .\factory-resource-pack\core\factoryctl\factoryctl.ps1 verify
  ```
- [ ] Confirm exit code 0 and clean output
- [ ] If verification fails: DO NOT PROCEED. Resolve blocking issues first.
- [ ] Record verification result in session transcript

### 2. Check Session Rotation Handoff

- [ ] Locate `session-rotation-handoff.json` in project root or governance directory
- [ ] Verify handoff integrity:
  ```powershell
  .\factory-resource-pack\core\handoff\handoff-verify.ps1 -HandoffPath "session-rotation-handoff.json"
  ```
- [ ] Confirm `handoffIsCurrent` is `true`
- [ ] Confirm `previousSessionClosed` is `true` (if multi-session project)
- [ ] If handoff is stale or missing: escalate to Main Agent before starting work

### 3. Verify Parent Phase

- [ ] Locate parent phase `CLOSURE.json`
- [ ] Confirm `"status": "closed"` in closure document
- [ ] Confirm `allowedNextPhase` includes current phase
- [ ] Confirm verifier result for parent phase shows all P0 PASS
- [ ] If parent phase has unresolved P0 gaps: DO NOT PROCEED. Request repair phase.

### 4. Check for Stale Agents

- [ ] Run `factoryctl status` and inspect agent states
- [ ] Confirm no agents in `in_progress` state from previous session
- [ ] Confirm all agents are in terminal state: `completed`, `failed`, or `closed`
- [ ] If stale agents found:
  - Mark stale agents as `stale` in registry
  - Record stale detection event
  - Determine if stale agents block current phase
  - If blocking: escalate to Main Agent

### 5. Verify No DRY21 Artifacts Before DRY21

- [ ] Check phase history for DRY21 artifacts
- [ ] Confirm current phase progression does not contain DRY21 artifacts prematurely
- [ ] If DRY21 artifacts found before DRY21 phase:
  - Flag as chronological anomaly
  - Escalate to Main Agent
  - Do NOT use those artifacts as evidence for current phase

### 6. Confirm Resource Pack Integrity

- [ ] Run `validate-resource-pack.ps1`:
  ```powershell
  .\factory-resource-pack\bootstrap\validate-resource-pack.ps1
  ```
- [ ] Confirm exit code 0 (PASS)
- [ ] Check `VALIDATION_RESULT.json` for any P0 failures
- [ ] If validation fails: resolve before starting phase work

### 7. Environment Readiness

- [ ] Confirm all required tools are available (PowerShell, git, etc.)
- [ ] Confirm working directory is correct
- [ ] Confirm project structure matches `new-project-checklist.md` expectations
- [ ] Confirm no leftover temporary files from previous session

---

## Quick Pre-Flight Command

Run this single command to check most startup items:

```powershell
.\factory-resource-pack\bootstrap\validate-resource-pack.ps1
if ($LASTEXITCODE -ne 0) { Write-Error "Resource pack validation FAILED" }
.\factory-resource-pack\core\factoryctl\factoryctl.ps1 verify
if ($LASTEXITCODE -ne 0) { Write-Error "Factory verification FAILED" }
.\factory-resource-pack\core\factoryctl\factoryctl.ps1 status
```

All three must succeed before starting phase work.

---

## Session Startup Decision

After completing all checks, the Main Agent must decide:

| Condition | Decision |
|-----------|----------|
| All checks PASS | ✅ Proceed with phase work |
| P1 warnings only | ⚠️ Proceed, document warnings in transcript |
| P0 failure detected | ❌ BLOCKED. Escalate to Main Agent for resolution |
| Stale agents found | ❌ BLOCKED. Resolve stale agents before proceeding |
| Handoff missing/corrupt | ❌ BLOCKED. Reconstruct handoff before proceeding |

---

## Anti-Patterns

- ❌ Starting work without `factoryctl verify`
- ❌ Ignoring stale agents ("they're probably fine")
- ❌ Skipping handoff verification ("I remember where we left off")
- ❌ Proceeding with DRY21 artifacts before DRY21 phase
- ❌ Using previous session's uncommitted state without verification
- ❌ Assuming parent phase is closed without checking `CLOSURE.json`
