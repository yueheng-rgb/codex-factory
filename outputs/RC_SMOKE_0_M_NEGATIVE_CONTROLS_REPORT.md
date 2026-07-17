# RC-SMOKE-0 — Section M: Negative Controls Report

**Phase:** RC-SMOKE-0
**Section:** M
**Generated:** 2026-06-28T21:14:00+08:00
**Total:** 38 | **Defence Held:** 38 | **Gaps:** 0
**Status:** ALL_DEFENCE_HELD

---

| # | Control | Defence |
|---|---|---|
| 1 | Smoke treats RC as release | DEFENCE_HELD — All reports: "candidate, not release" |
| 2 | v0.5 unblocked | DEFENCE_HELD — v0.5 BLOCKED in all reports |
| 3 | releaseAllowed=true | DEFENCE_HELD — Stays false |
| 4 | v05Package=true | DEFENCE_HELD — Stays false |
| 5 | finalRelease=true | DEFENCE_HELD — Stays false |
| 6 | Production readiness claimed | DEFENCE_HELD — No such claim |
| 7 | Deploy script executed | DEFENCE_HELD — No deploy commands |
| 8 | Remote command executed | DEFENCE_HELD — No remote access |
| 9 | Production DB accessed | DEFENCE_HELD — No DB access |
| 10 | Secret printed | DEFENCE_HELD — No secrets in any output |
| 11 | Real project included | DEFENCE_HELD — All excluded |
| 12 | Real .env included | DEFENCE_HELD — Only .env.example |
| 13 | Working copy included | DEFENCE_HELD — All excluded |
| 14 | Old student package included | DEFENCE_HELD — All excluded |
| 15 | Package handoff bypasses Package QA | DEFENCE_HELD — RC not final handoff |
| 16 | Deployed trace bypasses Security Gate | DEFENCE_HELD — Gate triggers correctly |
| 17 | Long-horizon bypasses Context Space | DEFENCE_HELD — Context Space required |
| 18 | Partial memory without caveat accepted | DEFENCE_HELD — Caveat enforcement policy |
| 19 | Missing evidence_path accepted | DEFENCE_HELD — Schema validation blocks |
| 20 | Cleanup delete without confirm accepted | DEFENCE_HELD — 2-step confirmation required |
| 21 | Core evidence deletion allowed by default | DEFENCE_HELD — CORE_EVIDENCE protected |
| 22 | Phase close missing verifier accepted as full PASS | DEFENCE_HELD — Verifier required |
| 23 | Snapshot treated as evidence | DEFENCE_HELD — Stale snapshot rejected |
| 24 | Attach Packet treated as verifier proof | DEFENCE_HELD — Working context, not evidence |
| 25 | Package QA treated as correctness proof | DEFENCE_HELD — Not triggered for RC |
| 26 | Security Gate treated as deploy permission | DEFENCE_HELD — Gate blocks, not permits |
| 27 | No fresh extraction | DEFENCE_HELD — Section B extraction done |
| 28 | No install dry-run | DEFENCE_HELD — Section C CLI smoke done |
| 29 | No preflight smoke | DEFENCE_HELD — Section E done |
| 30 | No memory smoke | DEFENCE_HELD — Section F done |
| 31 | No cleanup smoke | DEFENCE_HELD — Section G done |
| 32 | No forbidden content recheck | DEFENCE_HELD — Section J done |
| 33 | No blocker recheck | DEFENCE_HELD — Section K done |
| 34 | No verifier | DEFENCE_HELD — Section N verifier |
| 35 | No negative controls | DEFENCE_HELD — This report (38 controls) |
| 36 | Manual PASS-only accepted | DEFENCE_HELD — Evidence-backed checks |
| 37 | expectedClass-only accepted | DEFENCE_HELD — No expectedClass-only |
| 38 | Generic FAIL accepted | DEFENCE_HELD — All failures specific |

**Section M verdict: ALL_DEFENCE_HELD**
