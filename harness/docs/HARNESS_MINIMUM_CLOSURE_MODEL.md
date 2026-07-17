**Harness Minimum Closure Model — Phase 6C-T0**

This document defines what it means for a phase to be closed, and distinguishes between engineering passes, audit passes, and partial closures.

---

## 1. Three PASS Types

### ENGINEERING_PASS

The system produced the expected behavior. Commands ran, tests passed, agents performed tasks correctly.

**Criteria**:
- `validate-state.ps1` returns `run_passed`
- Unit tests pass
- Typecheck passes
- Build succeeds

**Limitations**:
- ENGINEERING_PASS does not guarantee audit bundle completeness
- A phase with ENGINEERING_PASS but incomplete audit bundle = PARTIAL from external audit perspective

### AUDIT_PASS

The audit bundle is complete and externally verifiable. All evidence referenced in reports exists in the ZIP. SHA256SUMS has 0 mismatches.

**Criteria** (all must be true):
1. `validate-state.ps1` returns `run_passed`
2. `validate-sha256sums.ps1` returns 0 mismatches, 0 absolute paths
3. `validate-bundle-layout.ps1` returns PASS
4. External sidecar meta (`*.zip.meta.json`) exists and matches ZIP digest
5. Every evidence file referenced in any report/machine-output exists in the ZIP
6. ZIP internal report does NOT contain the ZIP`s own final SHA256
7. SHA256SUMS.txt uses relative paths
8. No Codex Failure Pattern (CFP-001 through CFP-012) detected

### PASS_WITH_BOUNDARY_NOTES

The phase passes core criteria but has documented, bounded limitations that do not invalidate the result.

**Examples of acceptable boundary notes**:
- "Mailbox evidence is advisory, not included" (mailbox is not a hard gate)
- "Worktree manifest advisory only, not required for closure"
- "Playwright not run for this phase because project has no browser tests"
- "Orchestrator replacement occurred after integration_completed, not during active task execution"

**What boundary notes must NOT do**:
- Hide missing hard-gate evidence
- Claim untested capabilities as proven
- Contradict machine-readable evidence

---

## 2. PARTIAL

A phase is PARTIAL when:

- Core engineering may be correct (ENGINEERING_PASS)
- But audit bundle is incomplete, missing referenced evidence, or has SHA256 mismatches
- OR a hard-gate validator fails

**Examples**:
- S2: Engineering claims valid but ZIP missing governance reports, mailbox, manifests
- Any phase where validate-state.ps1 returns run_failed
- Any phase where SHA256SUMS has mismatches

---

## 3. FAIL

A phase is FAIL when:

- Core engineering is broken (validate-state returns run_failed)
- Evidence is fabricated or tampered
- CFP-001 through CFP-012 reveal actual contradictions
- Canonical was corrupted

---

## 4. Minimum Closure Checklist

For a phase to be marked CLOSED with PASS:

### Machine-Readable Gates

- [ ] `validate-state.ps1` → run_passed
- [ ] `validate-bundle-layout.ps1` → PASS
- [ ] `validate-sha256sums.ps1` → 0 mismatches
- [ ] `validate-evidence-gates.ps1` → all 12 CFP gates pass
- [ ] `finalize-run-verdict.ps1` → PASS verdict

### Evidence Completeness

- [ ] All command logs: stdout, stderr, exitCode for each command run
- [ ] RUN_STATE.jsonl with valid hash chain
- [ ] TASKS.json
- [ ] ACCEPTANCE.json
- [ ] CONTROL_PLANE_LOCK.json
- [ ] Authorization proofs for task_claimed, validation_started, task_verified events
- [ ] Project verification evidence (test results, typecheck, build)

### Audit Bundle Integrity

- [ ] SHA256SUMS.txt uses relative paths, excludes self
- [ ] External sidecar meta exists and matches ZIP
- [ ] ZIP internal report references "external sidecar metadata" for final digest
- [ ] No absolute paths in SHA256SUMS.txt
- [ ] No missing files referenced in reports

### Report Integrity

- [ ] Report does not claim untested capabilities
- [ ] Report acknowledges limitations honestly
- [ ] Report distinguishes ENGINEERING_PASS from AUDIT_PASS when applicable
- [ ] Report provides ZIP absolute path for external audit

---

## 5. Closure Declaration Rules

To write `Phase X: PASS`, ALL hard-gate validators must pass AND audit bundle must be complete.

To write `Phase X: CLOSED`, the audit bundle must be externally verifiable with PASS status.

To write `Phase X: PARTIAL`, document specifically which gates failed or which evidence is missing.

Never write PASS if any of the following are true:
- SHA256SUMS has mismatches
- Bundle layout fails validator
- Evidence referenced in reports is missing from ZIP
- CFP gates detect contradictions
- Report claims untested capabilities
- External sidecar meta missing or mismatched

---

## 6. Self-Reference Rule

The ZIP internal report must NEVER include the ZIP`s own final SHA256 as proof of closure. This is a self-reference hashing problem.

Instead:
- ZIP internal report: "Final bundle digest is recorded in external sidecar metadata."
- External sidecar: `<bundle>.zip.meta.json` contains the actual SHA256, size, entryCount

---

## 7. Final ZIP Is Audit Truth

The final report text file is advisory. The ZIP is the audit truth.

If the report says PASS but the ZIP is missing evidence, the phase is PARTIAL.
If the report says PASS but SHA256SUMS has mismatches, the phase is PARTIAL.
If the report says PASS but validate-state returns run_failed, the phase is FAIL.
