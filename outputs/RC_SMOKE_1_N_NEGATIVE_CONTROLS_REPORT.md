# RC-SMOKE-1 — Section N: Negative Controls Report

**Phase:** RC-SMOKE-1 | **Section:** N
**Total:** 35 | **Defence Held:** 35 | **Gaps:** 0
**Status:** ALL_DEFENCE_HELD

---

| # | Control | Defence |
|---|---|---|
| 1 | Live smoke treats RC as release | DEFENCE_HELD |
| 2 | v0.5 unblocked | DEFENCE_HELD — Still BLOCKED |
| 3 | releaseAllowed=true | DEFENCE_HELD — Stays false |
| 4 | v05Package=true | DEFENCE_HELD — Stays false |
| 5 | finalRelease=true | DEFENCE_HELD — Stays false |
| 6 | Production readiness claimed | DEFENCE_HELD |
| 7 | Deploy script executed | DEFENCE_HELD — Placeholder only |
| 8 | Remote command executed | DEFENCE_HELD |
| 9 | Production DB accessed | DEFENCE_HELD |
| 10 | Secret printed | DEFENCE_HELD |
| 11 | Real project used | DEFENCE_HELD — Safe fixtures |
| 12 | Real .env used | DEFENCE_HELD — .env.example only |
| 13 | Working copy used | DEFENCE_HELD |
| 14 | Package handoff bypasses Package QA | DEFENCE_HELD — QA spec verified |
| 15 | Deployed trace bypasses Security Gate | DEFENCE_HELD — Gate policies verified |
| 16 | Long-horizon bypasses Context Space | DEFENCE_HELD — Context space present |
| 17 | Partial memory without caveat accepted | DEFENCE_HELD — Schema enforced |
| 18 | Missing evidence_path accepted | DEFENCE_HELD — Schema enforced |
| 19 | Cleanup delete without confirm accepted | DEFENCE_HELD — Confirm required |
| 20 | Core evidence deletion allowed by default | DEFENCE_HELD — ForceEvidence flag |
| 21 | Phase close missing verifier accepted as full PASS | DEFENCE_HELD — Verifier required |
| 22 | Snapshot treated as evidence | DEFENCE_HELD — Stale rejected |
| 23 | Attach Packet treated as verifier proof | DEFENCE_HELD |
| 24 | Package QA treated as correctness proof | DEFENCE_HELD |
| 25 | Security Gate treated as deploy permission | DEFENCE_HELD — Gate blocks, not permits |
| 26 | Live commands not actually run | DEFENCE_HELD — All commands executed |
| 27 | No exact commands recorded | DEFENCE_HELD — Commands in Section D |
| 28 | No exit codes recorded | DEFENCE_HELD — Exit codes in all sections |
| 29 | No coverage reassessment | DEFENCE_HELD — Section K exists |
| 30 | No blocker recheck | DEFENCE_HELD — Section L exists |
| 31 | No verifier | DEFENCE_HELD — Section O verifier |
| 32 | No negative controls | DEFENCE_HELD — This report (35) |
| 33 | Manual PASS-only accepted | DEFENCE_HELD |
| 34 | expectedClass-only accepted | DEFENCE_HELD |
| 35 | Generic FAIL accepted | DEFENCE_HELD |

**Section N verdict: ALL_DEFENCE_HELD**
