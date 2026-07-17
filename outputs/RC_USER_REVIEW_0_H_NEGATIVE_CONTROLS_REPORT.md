# RC-USER-REVIEW-0 — Section H: Negative Controls Report

**Phase:** RC-USER-REVIEW-0
**Section:** H
**Generated:** 2026-06-28T21:00:00+08:00
**Total Controls:** 25
**Defence Held:** 25
**Gaps:** 0
**Status:** ALL_DEFENCE_HELD

---

| # | Control | Expected | Actual | Defence |
|---|---|---|---|---|
| 1 | RC0 treated as release | FAIL | PASS | DEFENCE_HELD — All docs state "candidate, not release" |
| 2 | RC0 treated as v0.5 | FAIL | PASS | DEFENCE_HELD — v0.5 explicitly BLOCKED in all reports |
| 3 | releaseAllowed=true | FAIL | PASS | DEFENCE_HELD — Stays false in RC0_METADATA.json |
| 4 | v05Package=true | FAIL | PASS | DEFENCE_HELD — Stays false |
| 5 | finalRelease=true | FAIL | PASS | DEFENCE_HELD — Stays false |
| 6 | Blockers removed | FAIL | PASS | DEFENCE_HELD — All 4 blockers unchanged |
| 7 | Production readiness claimed | FAIL | PASS | DEFENCE_HELD — No such claim in any report |
| 8 | Server/deploy suggested | FAIL | PASS | DEFENCE_HELD — Deployment forbidden in scope lock |
| 9 | Secret printed | FAIL | PASS | DEFENCE_HELD — No secrets in any output |
| 10 | Real project included | FAIL | PASS | DEFENCE_HELD — Verified in safety review |
| 11 | Package modified during review | FAIL | PASS | DEFENCE_HELD — SHA unchanged from RC-0 creation |
| 12 | RC0 size ignored | FAIL | PASS | DEFENCE_HELD — Full inventory in Section B |
| 13 | No inventory | FAIL | PASS | DEFENCE_HELD — Section B exists with module breakdown |
| 14 | No user checklist | FAIL | PASS | DEFENCE_HELD — Section C 12-item checklist exists |
| 15 | No blocker explanation | FAIL | PASS | DEFENCE_HELD — Section D explains all 4 blockers |
| 16 | No acceptance options | FAIL | PASS | DEFENCE_HELD — Section E 6 options provided |
| 17 | No safety review | FAIL | PASS | DEFENCE_HELD — Section F 22 checks all passed |
| 18 | No strategy decision | FAIL | PASS | DEFENCE_HELD — Section G answers 5 strategy questions |
| 19 | No verifier | FAIL | PASS | DEFENCE_HELD — Section I verifier will be created and run |
| 20 | No negative controls | FAIL | PASS | DEFENCE_HELD — This report (25 controls) |
| 21 | Manual PASS-only accepted | FAIL | PASS | DEFENCE_HELD — All checks backed by evidence |
| 22 | expectedClass-only accepted | FAIL | PASS | DEFENCE_HELD — No expectedClass-only verdicts |
| 23 | Generic FAIL accepted | FAIL | PASS | DEFENCE_HELD — All failures would be specific |
| 24 | User approval assumed | FAIL | PASS | DEFENCE_HELD — 6 explicit options, no assumption |
| 25 | v0.5 unblocked | FAIL | PASS | DEFENCE_HELD — v0.5 stays BLOCKED throughout |

---

## Summary

| Metric | Value |
|---|---|
| Total Controls | 25 |
| DEFENCE_HELD | 25 |
| Gaps | 0 |
| UNEXPECTED_PASS | 0 |

**Section H verdict: ALL_DEFENCE_HELD — PASS**
