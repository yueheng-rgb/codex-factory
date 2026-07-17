# FACTORY-BUILD-PACK-STAGING-P7 — G: A/B Comparison Evidence Design

**Timestamp:** 2026-06-28T17:20:00+08:00
**Purpose:** BLOCK-001 prep — DESIGN only, not execution.

---

## Design: Matched Project Pair

| | RUN-A (Vanilla) | RUN-B (Factory) |
|---|-----------------|-----------------|
| Factory installed | No | Yes |
| Build Lite | No | Yes (default) |
| Security Gate | No | Yes (for deployed) |
| Package QA | No | Yes (for handoff) |
| Context Space | No | Available |
| Test Repair Policy | No | Active |
| Starting prompt | Identical | Identical |
| Project spec | Same | Same |

---

## Metrics

- Time to first code
- Design iterations needed
- Safety violations caught
- User interventions required
- Final output quality

---

## Fairness Controls

1. Identical starting prompt for both runs
2. Same project specification
3. No hidden Factory context leaked to vanilla run
4. No pre-warmed context for Factory run
5. Fresh sessions for both
6. User does not manually inject Factory knowledge into vanilla run

---

**Status:** DESIGN_COMPLETE — This does NOT prove Factory superiority. Execution needed for evidence.
