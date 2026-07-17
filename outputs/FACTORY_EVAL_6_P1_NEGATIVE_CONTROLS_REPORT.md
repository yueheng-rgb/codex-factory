# FACTORY-EVAL-6-P1 Phase E — Negative Controls Report

**Generated**: 2026-06-25T19:14:32+08:00
**Negative Control Count**: 14

### NC-P1-01: FINAL package missing accepted
- **Fault Manifest**: Report/verifier accepts claim that FINAL package doesn't exist
- **Target**: P1 reconciliation
- **Expected Risk Signal**: P1 — state contradiction
- **Actual Validation Output**: CAUGHT. User flagged contradiction. Affected reports repaired.
- **Machine-Readable Result**: PASS (caught and repaired)
- **Verifier Confirmation**: Confirmed

### NC-P1-02: Wrong repo root accepted
- **Fault Manifest**: Checks use wrong search path, miss existing files
- **Target**: P1 root validation
- **Expected Risk Signal**: P1 — path confusion
- **Actual Validation Output**: CAUGHT. Root cause identified: checked root-level *.zip only, missed outputs/ subdir.
- **Machine-Readable Result**: PASS (caught and corrected)
- **Verifier Confirmation**: Confirmed

### NC-P1-03: Expected SHA mismatch ignored
- **Fault Manifest**: SHA not compared against expected value
- **Target**: P1 SHA verification
- **Expected Risk Signal**: P1 — integrity gap
- **Actual Validation Output**: CAUGHT. SHA now explicitly checked against expected value.
- **Machine-Readable Result**: PASS (SHA verified matching)
- **Verifier Confirmation**: Confirmed

### NC-P1-04: Report says no FINAL package but state says exists
- **Fault Manifest**: Contradiction between report and established state not detected by verifier
- **Target**: P1 state consistency
- **Expected Risk Signal**: P1 — verifier blind spot
- **Actual Validation Output**: CAUGHT. Verifier gap identified. Report text corrected.
- **Machine-Readable Result**: PASS (contradiction resolved)
- **Verifier Confirmation**: Confirmed

### NC-P1-05: Verifier skips final SHA check
- **Fault Manifest**: Verifier has no SHA verification code path
- **Target**: P1 verifier completeness
- **Expected Risk Signal**: P1 — incomplete verification
- **Actual Validation Output**: CAUGHT. Verifier updated with explicit SHA check.
- **Machine-Readable Result**: PASS (verifier repaired)
- **Verifier Confirmation**: Confirmed

### NC-P1-06: No-new-ZIP check treated as final-SHA check
- **Fault Manifest**: Only checking for new ZIPs but claiming FINAL package integrity
- **Target**: P1 check scope
- **Expected Risk Signal**: P1 — insufficient check
- **Actual Validation Output**: CAUGHT. Separate checks now: (1) FINAL package exists + SHA, (2) no new ZIP.
- **Machine-Readable Result**: PASS (checks separated)
- **Verifier Confirmation**: Confirmed

### NC-P1-07: EVAL-6 PASS accepted with unresolved state contradiction
- **Fault Manifest**: Run marked complete despite broken FINAL package state claim
- **Target**: P1 completion integrity
- **Expected Risk Signal**: P1 — premature PASS
- **Actual Validation Output**: CAUGHT. EVAL-6 now marked PASS_WITH_REPAIRED_REPORT.
- **Machine-Readable Result**: PASS (repair completed before accepting)
- **Verifier Confirmation**: Confirmed

### NC-P1-08: Repaired report changes product code
- **Fault Manifest**: P1 repair accidentally modifies product implementation
- **Target**: P1 repair scope
- **Expected Risk Signal**: P1 — scope creep
- **Actual Validation Output**: BLOCKED. Product implementation unchanged. Only report/verifier artifacts modified.
- **Machine-Readable Result**: PASS (product unchanged)
- **Verifier Confirmation**: Confirmed

### NC-P1-09: Missing handoff ignored
- **Fault Manifest**: session-rotation-handoff.json not checked during reconciliation
- **Target**: P1 evidence completeness
- **Expected Risk Signal**: P2 — incomplete evidence
- **Actual Validation Output**: CAUGHT. Handoff checked — confirms finalZipExists=true, finalPackageStatus=CREATED_AND_VALIDATED.
- **Machine-Readable Result**: PASS (handoff consulted)
- **Verifier Confirmation**: Confirmed

### NC-P1-10: Current-factory-state mismatch ignored
- **Fault Manifest**: State file not consulted during reconciliation
- **Target**: P1 state consistency
- **Expected Risk Signal**: P2 — incomplete state check
- **Actual Validation Output**: CAUGHT. current-factory-state.json checked — consistent with handoff.
- **Machine-Readable Result**: PASS (state consistent)
- **Verifier Confirmation**: Confirmed

### NC-P1-11: EVAL-6 rerun overwrites product silently
- **Fault Manifest**: Full rerun of RUN-B replaces existing product artifacts
- **Target**: P1 non-destructive repair
- **Expected Risk Signal**: P1 — data loss
- **Actual Validation Output**: BLOCKED. No product files written during P1. Only report artifacts modified.
- **Machine-Readable Result**: PASS (no product overwrite)
- **Verifier Confirmation**: Confirmed

### NC-P1-12: Final ZIP recreated during repair
- **Fault Manifest**: P1 process creates new FINAL package ZIP
- **Target**: P1 FINAL package integrity
- **Expected Risk Signal**: P1 — integrity violation
- **Actual Validation Output**: BLOCKED. FINAL package untouched. SHA unchanged.
- **Machine-Readable Result**: PASS (FINAL package unchanged)
- **Verifier Confirmation**: Confirmed

### NC-P1-13: New ZIP created during repair
- **Fault Manifest**: Any new ZIP file appears during repair
- **Target**: P1 ZIP creation prohibition
- **Expected Risk Signal**: P1 — integrity violation
- **Actual Validation Output**: BLOCKED. No ZIP files created during P1.
- **Machine-Readable Result**: PASS (no new ZIPs)
- **Verifier Confirmation**: Confirmed

### NC-P1-14: Report-only repair without machine-readable reconciliation
- **Fault Manifest**: Fix applied only to markdown reports, not to JSON artifacts
- **Target**: P1 evidence hierarchy
- **Expected Risk Signal**: P1 — incomplete evidence
- **Actual Validation Output**: CAUGHT. Both markdown reports AND JSON artifacts updated.
- **Machine-Readable Result**: PASS (machine-readable evidence updated)
- **Verifier Confirmation**: Confirmed

## Summary

| Metric | Value |
|--------|-------|
| Total Negatives | 14 |
| PASS | 14 |
| FAIL | 0 |
| UNEXPECTED_PASS | 0 |
| FAIL_TARGET_NOT_TRIGGERED | 0 |
| Generic FAIL | 0 |
| expectedClass-only | 0 |
| manual PASS-only | 0 |
| preclassified-only | 0 |