# FACTORY-CONTEXT-LEDGER-RECONCILIATION-0 — Negative Controls Report

**Date**: 2026-06-29
**Phase**: FACTORY-CONTEXT-LEDGER-RECONCILIATION-0

---

## Negative Controls (24 items)

| # | Control | Expected | Actual | Verdict |
|---|---------|----------|--------|---------|
| 1 | phase-ledger still ends at P6-R1 | FAIL (must extend to USER-HANDOFF-R1) | Extended to USER-HANDOFF-R1 | PASS |
| 2 | conversation-space still lists only P4 | FAIL | Rebuilt with 31 groups | PASS |
| 3 | direction-guard still recommends P7 | FAIL | Fixed to REAL-VALIDATION-READINESS-0 | PASS |
| 4 | active-thread shows stale phase | FAIL | Aligned to REAL-VALIDATION-READINESS-0 | PASS |
| 5 | mount.ps1 reports STALE | FAIL | FRESH (0 warnings) | PASS |
| 6 | Attach Packet omits v0.5 release phases | FAIL | Includes all 27 phases | PASS |
| 7 | Attach Packet omits theory phases | FAIL | Includes all 7 theory phases | PASS |
| 8 | Attach Packet omits R1 integration phases | FAIL | Includes all R1 phases | PASS |
| 9 | Attach Packet omits USER-HANDOFF-R1 | FAIL | USER-HANDOFF-R1 is lastCompletedPhase | PASS |
| 10 | Snapshot not regenerated | FAIL | SNAP-FW-20260629-134200 generated | PASS |
| 11 | Chat summary used as evidence | FAIL | All evidence from verifier JSON files | PASS |
| 12 | RISK-CS-002 (TCM keys) removed | FAIL | Preserved as active blocker | PASS |
| 13 | v0.6 created | FAIL | No v0.6 | PASS |
| 14 | Real validation started | FAIL | Only READINESS-0 sub-step A exists | PASS |
| 15 | Cloud/deploy triggered | FAIL | No cloud/deploy | PASS |
| 16 | Release ZIP modified | FAIL | No modification | PASS |
| 17 | Phase-ledger entries lack evidence paths | FAIL | All entries reference verifier JSONs | PASS |
| 18 | Phase-ledger entries use chat summaries | FAIL | All entries reference file evidence | PASS |
| 19 | direction-guard DG rules broken | FAIL | All 13 DG rules preserved | PASS |
| 20 | Frozen conclusions altered | FAIL | All 4 FROZEN + 1 RETIRED preserved | PASS |
| 21 | Mount count not incremented | FAIL | Mount count 14→16 | PASS |
| 22 | Phase count inflated (duplicates) | FAIL | 72 unique phases (27 added, 45 existing) | PASS |
| 23 | Original phase-ledger overwritten | FAIL | Backup created before append | PASS |
| 24 | REAL-VALIDATION-READINESS-0 continued | FAIL | B-I still pending, per user instruction | PASS |

## Verdict

**24/24 PASS — 0 gaps**
