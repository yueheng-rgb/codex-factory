# FACTORY-PROJECT-ISOLATION-0 — N: Negative Controls Report

> Phase: FACTORY-PROJECT-ISOLATION-0
> Section: N — Negative Controls
> Date: 2026-06-29

---

## Negative Controls (31)

| # | ID | Description | Status |
|---|-----|------------|--------|
| 1 | NC-01 | Project A context mounted for Project B | ✅ PASS |
| 2 | NC-02 | Archived project default mounted | ✅ PASS |
| 3 | NC-03 | Frozen project updated | ✅ PASS |
| 4 | NC-04 | Deleted project mounted | ✅ PASS |
| 5 | NC-05 | Changed fingerprint accepted silently | ✅ PASS |
| 6 | NC-06 | Cleanup deletes wrong project cache | ✅ PASS |
| 7 | NC-07 | Core evidence from other project deleted | ✅ PASS |
| 8 | NC-08 | Agent output accepted with wrong projectId | ✅ PASS |
| 9 | NC-09 | Project-specific risk transferred as global | ✅ PASS |
| 10 | NC-10 | Project-specific blocker transferred as global | ✅ PASS |
| 11 | NC-11 | Working copy shared across projects silently | ✅ PASS |
| 12 | NC-12 | Final handoff omits projectId | ✅ PASS |
| 13 | NC-13 | Phase report omits projectId | ✅ PASS |
| 14 | NC-14 | Verifier omits projectId | ✅ PASS |
| 15 | NC-15 | Global policy blocked incorrectly | ✅ PASS |
| 16 | NC-16 | User preference blocked incorrectly | ✅ PASS |
| 17 | NC-17 | Unknown project accepted without confirmation | ✅ PASS |
| 18 | NC-18 | Migrated project redirects silently without confirmation | ✅ PASS |
| 19 | NC-19 | v0.5 zip modified | ✅ PASS |
| 20 | NC-20 | New release created | ✅ PASS |
| 21 | NC-21 | v0.6 created | ✅ PASS |
| 22 | NC-22 | Cloud recommended now | ✅ PASS |
| 23 | NC-23 | Production deploy included | ✅ PASS |
| 24 | NC-24 | Real project validation started | ✅ PASS |
| 25 | NC-25 | No simulation | ✅ PASS |
| 26 | NC-26 | No strategy decision | ✅ PASS |
| 27 | NC-27 | No verifier | ✅ PASS |
| 28 | NC-28 | No negative controls | ✅ PASS |
| 29 | NC-29 | Manual PASS-only accepted | ✅ PASS |
| 30 | NC-30 | expectedClass-only accepted | ✅ PASS |
| 31 | NC-31 | Generic FAIL accepted | ✅ PASS |

---

## Summary

- **Total controls**: 31
- **PASS**: 31
- **FAIL**: 0
- **Gaps**: 0

All negative controls are blocked by protocols, schemas, and gates defined in sections A-M of FACTORY-PROJECT-ISOLATION-0.
