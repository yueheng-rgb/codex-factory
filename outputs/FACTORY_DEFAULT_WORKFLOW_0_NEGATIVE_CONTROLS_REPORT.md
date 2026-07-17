# FACTORY-DEFAULT-WORKFLOW-0 — N: Negative Controls Report

> Phase: FACTORY-DEFAULT-WORKFLOW-0
> Section: N — Negative Controls
> Date: 2026-06-28

---

## Negative Controls (30)

Each control defines a behavior that MUST NOT happen. All controls must PASS (i.e., the negative behavior is blocked).

| # | ID | Description | Status |
|---|----|------------|--------|
| 1 | NC-01 | User requirement bypasses Bootstrap | ✅ PASS |
| 2 | NC-02 | Code written before discussion | ✅ PASS |
| 3 | NC-03 | Large project does not ask multi-agent question | ✅ PASS |
| 4 | NC-04 | Multi-agent starts without user confirmation | ✅ PASS |
| 5 | NC-05 | Native Build Pro made default | ✅ PASS |
| 6 | NC-06 | Multi-agent made universal default | ✅ PASS |
| 7 | NC-07 | Build Lite removed | ✅ PASS |
| 8 | NC-08 | Cleanup deletes files without PLAN | ✅ PASS |
| 9 | NC-09 | Cleanup deletes project source | ✅ PASS |
| 10 | NC-10 | Cleanup deletes CORE_EVIDENCE by default | ✅ PASS |
| 11 | NC-11 | "删除项目缓存" interpreted as delete project source | ✅ PASS |
| 12 | NC-12 | Final handoff omits paths | ✅ PASS |
| 13 | NC-13 | Unknown path omitted instead of UNKNOWN_WITH_REASON | ✅ PASS |
| 14 | NC-14 | CLI name mismatch ignored | ✅ PASS |
| 15 | NC-15 | Cloud recommended now | ✅ PASS |
| 16 | NC-16 | Server/domain recommended now | ✅ PASS |
| 17 | NC-17 | Production deploy included | ✅ PASS |
| 18 | NC-18 | State dashboard defined as web app requirement immediately | ✅ PASS |
| 19 | NC-19 | Agent ledger omitted | ✅ PASS |
| 20 | NC-20 | Agent outputs anonymous | ✅ PASS |
| 21 | NC-21 | No simulation | ✅ PASS |
| 22 | NC-22 | No strategy decision | ✅ PASS |
| 23 | NC-23 | v0.5 zip modified | ✅ PASS |
| 24 | NC-24 | New release created | ✅ PASS |
| 25 | NC-25 | v0.6 created | ✅ PASS |
| 26 | NC-26 | No verifier | ✅ PASS |
| 27 | NC-27 | No negative controls | ✅ PASS |
| 28 | NC-28 | Manual PASS-only accepted | ✅ PASS |
| 29 | NC-29 | expectedClass-only accepted | ✅ PASS |
| 30 | NC-30 | Generic FAIL accepted | ✅ PASS |

---

## Additional Negative Controls (Bonus)

| # | ID | Description | Status |
|---|----|------------|--------|
| 31 | NC-31 | Factory Bootstrap skipped due to "user urgency" | ✅ PASS |
| 32 | NC-32 | Multi-agent silently bypasses user confirmation for large projects | ✅ PASS |
| 33 | NC-33 | Cleanup PLAN treated as already executed | ✅ PASS |
| 34 | NC-34 | Theoretical rules treated as verified functionality | ✅ PASS |
| 35 | NC-35 | Phase split into micro-stages | ✅ PASS |

---

## Summary

- **Total controls**: 35
- **PASS**: 35
- **FAIL**: 0
- **Gaps**: 0

All negative controls are blocked by the protocols, contracts, and gates defined in sections A-M of FACTORY-DEFAULT-WORKFLOW-0.
