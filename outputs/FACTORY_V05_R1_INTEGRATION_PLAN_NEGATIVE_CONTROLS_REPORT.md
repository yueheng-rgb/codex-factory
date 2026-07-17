# FACTORY-V05-R1-INTEGRATION-PLAN — Negative Controls Report

> 35 negative controls. Target: 0 gaps. All must be BLOCKED/ABSENT.

| # | Control | Expected | Result |
|---|---------|----------|--------|
| 1 | Modifies v0.5 zip | BLOCKED | PASS — v0.5 SHA256 unchanged |
| 2 | Creates R1 zip | ABSENT | PASS — no R1 zip in outputs |
| 3 | Creates v0.6 | ABSENT | PASS — no v0.6 artifacts |
| 4 | Starts real validation | BLOCKED | PASS — no real project validation |
| 5 | Cloud recommended now | BLOCKED | PASS — cloud deferred |
| 6 | Deploy included | BLOCKED | PASS — no deploy scripts/claims |
| 7 | Native Build Pro defaulted | BLOCKED | PASS — Build Lite preserved |
| 8 | Multi-agent auto-started | BLOCKED | PASS — user confirmation required |
| 9 | Build Lite removed | BLOCKED | PASS — Build Lite remains |
| 10 | CLI name mismatch ignored | BLOCKED | PASS — canonical name locked |
| 11 | Default workflow omitted | BLOCKED | PASS — Phase F covers it |
| 12 | Project isolation omitted | BLOCKED | PASS — Phase H covers it |
| 13 | State dashboard omitted | BLOCKED | PASS — Phase I covers it |
| 14 | Recovery omitted | BLOCKED | PASS — Phase I covers it |
| 15 | Multi-agent omitted | BLOCKED | PASS — Phase G covers it |
| 16 | Evidence taxonomy omitted | BLOCKED | PASS — Phase I covers it |
| 17 | Lifecycle omitted | BLOCKED | PASS — Phase H covers it |
| 18 | Cleanup PLAN omitted | BLOCKED | PASS — Phase F covers it |
| 19 | Handoff paths omitted | BLOCKED | PASS — Phase F covers it |
| 20 | projectId omitted | BLOCKED | PASS — G/H require it |
| 21 | Dashboard overclaimed as evidence | BLOCKED | PASS — EVIDENCE-TAXONOMY enforced |
| 22 | Snapshot/attach treated as evidence | BLOCKED | PASS — not primary evidence |
| 23 | Theory features claimed real validated | BLOCKED | PASS — all labeled theory/prototype |
| 24 | No file map | BLOCKED | PASS — Phase D exists |
| 25 | No CLI plan | BLOCKED | PASS — Phase E exists |
| 26 | No smoke plan | BLOCKED | PASS — Phase J exists |
| 27 | No risk register | BLOCKED | PASS — Phase K exists |
| 28 | No decision gate | BLOCKED | PASS — Phase L exists |
| 29 | No strategy decision | BLOCKED | PASS — Phase M exists |
| 30 | No verifier | BLOCKED | PASS — verifier script + result exist |
| 31 | No negative controls | BLOCKED | PASS — this report |
| 32 | Manual PASS-only accepted | BLOCKED | PASS — verifier is automated |
| 33 | expectedClass-only accepted | BLOCKED | PASS — actual file checks |
| 34 | Generic FAIL accepted | BLOCKED | PASS — specific check messages |
| 35 | User approval assumed for R1 integration | BLOCKED | PASS — decision gate requires approval |

## Summary

- **Total controls:** 35
- **PASS (correctly blocked/absent):** 35
- **FAIL (should have been blocked but present):** 0
- **Gaps:** 0
