# FACTORY-CONTEXT-SPACE-MOUNT-TRIAL-R1 — Mount Trial Re-Run Simulation Report

**Date**: 2026-06-28
**Sub-step**: G — Simulation

---

## Simulation Scenarios

| # | Scenario | Expected | Result |
|---|----------|----------|--------|
| SIM-001 | New window after Context-Space-0 complete → shows completed, not pending | FRESH, completed shown | PASS |
| SIM-002 | Attach packet tries to continue E-N → blocked, STALE detected | STALE, E-N blocked | PASS |
| SIM-003 | Legacy rotation warning appears → archived unless active blocker | Archived, not active blocker | PASS |
| SIM-004 | v0.5 ready claim → rejected | DG-004 blocks | PASS |
| SIM-005 | Build Pro default claim → rejected | FROZEN-002, DG-003 | PASS |
| SIM-006 | Package QA as proof → rejected | FROZEN-004 | PASS |
| SIM-007 | Current next phase requested → returns P1 or REALWORLD-2-P1, not E-N | P1/REALWORLD-2-P1 returned | PASS |
| SIM-008 | Compressed summary claims old state → TIER-4 rejected, phase-ledger overrides | TIER-4 rejected | PASS |

## Verdict

**8/8 simulation scenarios PASS. Mount v0.2.0 correctly handles stale state, legacy risks, blocked claims, and correct next-phase recommendations.**
