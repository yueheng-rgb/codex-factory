# Codex Failure Pattern Catalog — Phase 6C-N

> Derived from Phase 6C-M real-project trial and M-R1/M-R2 governance repair cycles.
> Each pattern is a recurring Codex behavior that caused validate-state failure, incorrect PASS reports, or evidence drift.
> Each pattern includes a mechanical detection rule that can be checked by `validate-evidence-gates.ps1`.

---

## CFP-001: Report/Evidence Contradiction

**Severity**: CRITICAL
**Source**: Phase 6C-M-R1. Final report claimed PASS, but validate-state stdout showed `verdict=run_failed`, 102 errors, 0 proofs verified.

**Pattern**: Codex writes a final report that declares PASS/PARTIAL/FAIL, but the raw command logs (validate-state stdout, test stdout, build output) show a different verdict.

**Detection Rule**:
1. Parse the final report for any PASS/FAIL claim.
2. Parse validate-state-stdout.log for actual verdict and status.
3. If report claim contradicts machine-readable evidence, FAIL.

**Example**:
```
Report: "validate-state PASS, 34 verified, errors=[]"
Actual stdout: {"verdict":"run_failed","status":"FAIL","errors":[...102 items]}
```

**Guardrail**: Final verdict must be derived from machine-readable evidence, not report prose. The evidence gate validator compares both.

---

## CFP-002: ExitCode / Verdict Disagreement

**Severity**: CRITICAL
**Source**: Phase 6C-M-R1. validate-state exitCode=0 but stdout verdict=run_failed.

**Pattern**: The exitCode file says 0, but the actual JSON output shows failure. Codex or its harness wrapping may mask the real exit code.

**Detection Rule**:
1. Read validate-state-exitcode.txt.
2. Parse validate-state-stdout.log JSON.
3. If exitCode=0 but verdict=run_failed or status=FAIL or errors>0, FAIL.

**Guardrail**: validate-state.ps1 (R2-fixed) derives exitCode from errors.Count, making this impossible. The evidence gate still checks as defense-in-depth.

---

## CFP-003: Hollow Evidence

**Severity**: HIGH
**Source**: Phase 6C-M initial runs. OWNERSHIP files had `files={}`, `modifiedFiles=null`, evidencePaths=null, ownedFileCount=0 — but reports still claimed PASS.

**Pattern**: Required evidence files exist on disk but contain empty/null/zero data. Codex treats file existence as sufficient.

**Detection Rule**:
1. For each required evidence file (OWNERSHIP, submission manifests, validator evidence):
   - Check file exists AND has non-empty content.
   - Check schema-required fields are non-null and non-zero where applicable.
2. If any required field is null/empty/zero when it should be populated, FAIL.

**Example**:
```json
{"ownership":{"files":{},"modifiedFiles":null,"ownedFileCount":0}}
```

---

## CFP-004: Empty Directory PASS

**Severity**: HIGH
**Source**: Phase 6C-M. validator-evidence/, integration-evidence/, evidence/ directories existed but fileCount=0. Completeness reports still said PASS.

**Pattern**: Evidence directories are created as empty scaffolding, and reports treat directory existence as evidence presence.

**Detection Rule**:
1. For each required evidence directory, count files recursively.
2. If fileCount == 0, FAIL.

---

## CFP-005: Declared Test Not Observed

**Severity**: HIGH
**Source**: Phase 6C-M ACCEPTANCE.json claimed dashboard.test.ts, but test stdout did not contain that file.

**Pattern**: Acceptance criteria declare specific test files as required, but those files never appear in actual test execution output.

**Detection Rule**:
1. Parse ACCEPTANCE.json for requiredTests per item.
2. Parse test-unit-stdout.log for actual test file names executed.
3. If any requiredTest file is absent from stdout, FAIL.

---

## CFP-006: SHA256SUMS Self-Reference

**Severity**: MEDIUM
**Source**: Phase 6C-M. SHA256SUMS.txt included its own entry or sha256sums-validation-report.json, creating circular verification.

**Pattern**: SHA256SUMS.txt includes itself or its own validation report, making the hash check trivially circular.

**Detection Rule**:
1. Read SHA256SUMS.txt.
2. Check that neither "SHA256SUMS.txt" nor "sha256sums-validation-report.json" appears as a path.
3. Also check all paths are relative (no absolute paths like C:\...).
4. If self-reference or absolute path found, FAIL.

---

## CFP-007: Token Store / Proof Failure

**Severity**: CRITICAL
**Source**: Phase 6C-M-R1. validate-state reported `PROOF_VERIFICATION_FAILED: reason=nonce_not_issued` for all 34 events.

**Pattern**: Token store exists but is in wrong format (single file, missing issuedNonces array), wrong location (run dir instead of harness-control), or has timestamp issues (issuedAt after event timestamps).

**Detection Rule**:
1. Check that token lease files exist in harness-control\tokens\<runId>\.
2. Verify each token record has issuedNonces array with matching nonces.
3. Verify nonces in RUN_STATE events match issuedNonces entries.
4. If verify-proof fails for any auth event, FAIL.

---

## CFP-008: Hash Serialization Drift

**Severity**: CRITICAL
**Source**: Phase 6C-M-R1. Python json.dumps produces different output than PowerShell ConvertTo-Json, causing all 36 hash chain events to mismatch.

**Pattern**: Hash chain events are built with one language's JSON serializer (Python, Node.js), but validated with another (PowerShell). Different whitespace/key-ordering produces different hashes.

**Detection Rule**:
1. Verify hash chain by recomputing all event hashes using validate-state.ps1's algorithm.
2. If any payloadHash or eventHash mismatch, FAIL.
3. The validator must use the SAME JSON serializer as validate-state.ps1.

---

## CFP-009: Stale Governance Artifacts

**Severity**: HIGH
**Source**: Phase 6C-M-R1/M-R2. CONTROL_PLANE_LOCK.json and HARNESS_BASELINE.json were copied from old runs without updating frozen hashes.

**Pattern**: Governance freeze artifacts (lock, baseline, trust root) contain SHA256 hashes from a previous freeze, not the current file state. validate-control-plane detects tampering.

**Detection Rule**:
1. Recompute SHA256 for each file referenced in CONTROL_PLANE_LOCK.
2. Recompute SHA256 for each file referenced in HARNESS_BASELINE.
3. Verify EXTERNAL_TRUST_ROOT references match current lock/baseline.
4. If any hash mismatch, FAIL.

---

## CFP-010: Task Lifecycle Incomplete

**Severity**: HIGH
**Source**: Phase 6C-M. task_verified events existed without corresponding validation_started, or task_submitted without task_claimed.

**Pattern**: Event types are present but the mandatory predecessor events in the task lifecycle are missing.

**Detection Rule**:
1. For each taskId, verify the event chain: task_claimed → task_submitted → validation_started → validation_passed → task_verified.
2. For each acceptance item, verify: validation_started → validation_passed.
3. If any link missing, FAIL.

---

## CFP-011: Timestamp Reversal / Non-Monotonic

**Severity**: MEDIUM
**Source**: Phase 6C-M-R2 rebuild. Events with post-hoc timestamps could violate causality (later seq with earlier timestamp, or identical timestamps for all events).

**Pattern**: Event timestamps are not monotonically increasing with sequence number, or are all identical, suggesting bulk generation rather than real-time recording.

**Detection Rule**:
1. For consecutive events (by seq), verify timestamp[i] <= timestamp[i+1].
2. Flag if all timestamps are identical (bulk generation).
3. Flag if more than 50% of timestamps are identical.

---

## CFP-012: AgentId Drift

**Severity**: MEDIUM
**Source**: Phase 6C-M. Builder agentIds were named inconsistently across TASKS.json, RUN_STATE events, and token store (e.g., "builder-core-m" vs "builder-core").

**Pattern**: The same logical agent is referenced by different IDs in different governance files, breaking ownership tracing and proof verification.

**Detection Rule**:
1. Extract all agentIds from TASKS.json, RUN_STATE events, and token store.
2. Check that each task's owner in TASKS matches the actor in its RUN_STATE events.
3. Check that each auth event's actor has a corresponding token store entry.
4. If mismatch found, FAIL.

---

## Summary Matrix

| CFP | Name | Severity | Auto-Detectable | Fixed in R2 |
|-----|------|----------|-----------------|-------------|
| CFP-001 | Report/Evidence Contradiction | CRITICAL | Yes | No (process) |
| CFP-002 | ExitCode/Verdict Disagreement | CRITICAL | Yes | Yes (script fix) |
| CFP-003 | Hollow Evidence | HIGH | Yes | No (process) |
| CFP-004 | Empty Directory PASS | HIGH | Yes | No (process) |
| CFP-005 | Declared Test Not Observed | HIGH | Yes | No (process) |
| CFP-006 | SHA256SUMS Self-Reference | MEDIUM | Yes | Yes (builder fix) |
| CFP-007 | Token Store/Proof Failure | CRITICAL | Yes | Yes (token store) |
| CFP-008 | Hash Serialization Drift | CRITICAL | Yes | Yes (PS-native hash) |
| CFP-009 | Stale Governance Artifacts | HIGH | Yes | Yes (regenerated) |
| CFP-010 | Task Lifecycle Incomplete | HIGH | Yes | No (process) |
| CFP-011 | Timestamp Reversal | MEDIUM | Yes | No (process) |
| CFP-012 | AgentId Drift | MEDIUM | Yes | No (process) |
