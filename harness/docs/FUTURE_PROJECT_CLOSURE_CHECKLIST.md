**Future Project Closure Checklist — Phase 6C-T0-R1**

This document is a machine-checkable checklist that any future project phase must satisfy before being marked CLOSED with PASS.

---

## Pre-Run Checklist (before any Agent starts)

- [ ] `TASKS.json` exists with `baseCanonicalHash` per task
- [ ] `ACCEPTANCE.json` exists with acceptance items mapped to each task
- [ ] `RUN_PLAN.json` or `TASK_DAG.json` exists with dependency graph
- [ ] `CONTROL_PLANE_LOCK.json` is frozen (created before any Worker claims)
- [ ] Authorization trust root is established (external-trust-root.ps1)
- [ ] `RELEASE_MANIFEST.json` exists if release mode
- [ ] `SPEC.md` or project specification is present

---

## During-Run Checklist (per Agent)

- [ ] Each `task_claimed` event has valid authorization proof (token + signature)
- [ ] Builder agent ≠ Validator agent (no self-verification)
- [ ] Each `validation_started` has valid authorization proof
- [ ] Each `task_verified` has valid authorization proof
- [ ] Worker does not directly modify canonical
- [ ] Patch is bound to `baseCanonicalHash`
- [ ] If using spawn_agent/resume_agent: mailbox messages and manifest exist
- [ ] Handoff files exist if agent continuation used

---

## Post-Run Checklist (before final ZIP)

### Command Evidence (stdout + stderr + exitCode for each)

- [ ] `npm ci`
- [ ] `npm run typecheck`
- [ ] `npm run test:unit`
- [ ] `npm run build`
- [ ] `npm run test:playwright` (if project has browser tests)
- [ ] `validate-state.ps1`

### Governance Evidence

- [ ] `RUN_STATE.jsonl` with valid hash chain (GENESIS → terminal event)
- [ ] `validate-state.ps1` returns `run_passed` with 0 errors
- [ ] `CONTROL_PLANE_LOCK.json` present
- [ ] Authorization proofs present for all authorized events
- [ ] `OWNERSHIP.json` non-empty (no hollow evidence)

### Audit Bundle Integrity

- [ ] `SHA256SUMS.txt` uses relative paths, excludes self, 0 mismatches
- [ ] `validate-sha256sums.ps1` → PASS
- [ ] `validate-bundle-layout.ps1` → PASS
- [ ] `validate-audit-bundle-schema.ps1` → PASS
- [ ] `validate-final-zip-self-consistency.ps1` → PASS
- [ ] External sidecar meta (`*.zip.meta.json`) matches ZIP digest

### Report Integrity

- [ ] Final report does not claim untested capabilities
- [ ] Final report distinguishes ENGINEERING_PASS from AUDIT_PASS
- [ ] Final report provides ZIP absolute path
- [ ] Internal reports do not contain ZIP self-SHA256
- [ ] All 12 CFP gates pass

---

## Blocking Conditions (any one → cannot close)

1. `validate-state.ps1` returns `run_failed`
2. `validate-sha256sums.ps1` has mismatches
3. Schema validator report verdict ≠ PASS
4. Missing external sidecar meta
5. Any CFP gate fails
6. Report claims capabilities not proven
7. ZIP not at reported absolute path

---

## Honest Answer

> Will future projects still have problems?

Yes, but the expected failure modes are now explicit and machine-checkable. The biggest remaining risks are long-run stability, external worker pool, approval interruptions, and large-project context drift.
