# Phase 6C DRY19-B Live Negative Controls Report

**Verdict**: PASS  
**Verifier**: scripts/phase6c-dry19-b-live-negative-controls-verify.ps1  
**Exit Code**: 0  
**Check Count**: 30/30 PASS

---

## Parent Positive Recheck

Parent source hash: `33D373B8...` unchanged. All 8 scenarios PASS. H11 directness EXACT/STRONG.

---

## Task Queue Execution

DRY19-B task: `executionStarted=true`, `status=done`, owner=skeptic.

---

## Negative Count

| Group | Count | Type |
|-------|-------|------|
| A | 6 | Control negatives |
| B | 8 | Target-gate policy |
| C | 7 | Target-gate evidence |
| **Total** | **21** | |

---

## Negative Classification Table

| Classification | Count |
|----------------|-------|
| FAIL_TARGET_GATE | 15 |
| FAIL_MISSING_EVIDENCE | 3 |
| FAIL_CONTRACT_DRIFT | 2 |
| FAIL_PROFILE_BOUNDARY_VIOLATION | 1 |

0 preclassified-only. 0 generic FAIL.

---

## TargetScenarioId/Directness Summary

All 15 target-gate negatives (B1-B8, C1-C7) have targetScenarioId. All classify FAIL_TARGET_GATE. H11 alias map maintained at 0 WEAK/PARTIAL.

---

## Evidence Summary

Every negative has: fault-manifest.json, before/after SHA256, command.txt, transcript.log, exitCode.txt, acceptance-run.json, negative-classification.json, live-negative-evidence.json.

---

## Parent Mutation

None detected. Parent source hash `33D373B8...` unchanged after all 21 negatives.

---

## Confirmations

- No preclassified-only negatives
- No generic FAIL classifications
- Report sanitizer passes
- No final ZIP
- Closed reports unchanged
- DRY2-C through DRY13-C remain paused
