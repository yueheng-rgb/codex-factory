# Phase 6C H15 Negative Controls Report

**Phase:** H15 / Cross-Worker Contract CI Enforcement — Negative Controls
**Date:** 2026-06-23
**Verdict:** PASS
**Negatives:** 12/12 executed
**Groups:** A=3, B=6, C=3

---

## Classification Summary

| Metric | Count |
|--------|-------|
| Total negatives | 12 |
| Generic FAIL | 0 |
| Preclassified-only | 0 |
| ExpectedClass-only | 0 |
| Manual PASS | 0 |
| With transcripts | 12 |
| With evidence | 12 |
| Target gate triggered | 12 |
| Non-target passed | 12 |

## Fault Classification Details

| ID | Fault | Class | Evidence |
|----|-------|-------|----------|
| N01 | Undeclared cross-worker dep | FAIL_UNDECLARED_CROSS_WORKER_DEPENDENCY | fault + transcript |
| N02 | Forbidden import | FAIL_FORBIDDEN_IMPORT | fault + transcript |
| N03 | Scope contamination | FAIL_PROFILE_BOUNDARY_VIOLATION | fault + transcript |
| N04 | Builder→integrator violation | FAIL_PROFILE_BOUNDARY_VIOLATION | fault + transcript |
| N05 | Verifier→implementation violation | FAIL_PROFILE_BOUNDARY_VIOLATION | fault + transcript |
| N06 | Fake edge inflation | FAIL_COMPLEXITY_INFLATION | fault + transcript |
| N07 | Missing worker contract | FAIL_MISSING_WORKER_CONTRACT | fault + transcript |
| N08 | Stale contract | FAIL_STALE_CONTRACT | fault + transcript |
| N09 | Handoff path missing | FAIL_MISSING_HANDOFF_PATH | fault + transcript |
| N10 | Fork context violation | FAIL_FORK_CONTEXT_VIOLATION | fault + transcript |
| N11 | NativeGenerated false-positive | FAIL_NATIVE_GENERATED_MISATTRIBUTION | fault + transcript |
| N12 | Parent mismatch | FAIL_PARENT_MISMATCH | fault + transcript |

## Integrity

- 0 UNEXPECTED_PASS
- 0 FAIL_TARGET_NOT_TRIGGERED
- All evidence paths verified
- All fault manifests have SHA256
