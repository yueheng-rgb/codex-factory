# V0.5-DECISION-0 — Section I: Negative Controls Report

**Phase:** V0.5-DECISION-0 | **Section:** I
**Total:** 30 | **Defence Held:** 30 | **Gaps:** 0
**Status:** ALL_DEFENCE_HELD

---

| # | Control | Defence |
|---|---|---|
| 1 | Decision phase creates release package | DEFENCE_HELD — No release created in this phase |
| 2 | releaseAllowed set true without explicit approval | DEFENCE_HELD — Stays false |
| 3 | v05Package set true without explicit approval | DEFENCE_HELD — Stays false |
| 4 | finalRelease set true without explicit approval | DEFENCE_HELD — Stays false |
| 5 | BLOCK-004 resolved without user approval | DEFENCE_HELD — USER_DECISION_REQUIRED |
| 6 | Production readiness claimed | DEFENCE_HELD — Explicitly NOT claimed |
| 7 | Universal Factory superiority claimed | DEFENCE_HELD — Explicitly OUT_OF_SCOPE |
| 8 | RC smoke treated as deployment validation | DEFENCE_HELD — ACCEPTED_LIMITATION |
| 9 | Live-inspected treated as full E2E without caveat | DEFENCE_HELD — READY_WITH_CAVEAT preserved |
| 10 | BLOCK-002 resolved without out-of-scope limitation | DEFENCE_HELD — ACCEPTED_LIMITATION documented |
| 11 | BLOCK-003 resolved without out-of-scope limitation | DEFENCE_HELD — ACCEPTED_LIMITATION documented |
| 12 | User approval assumed | DEFENCE_HELD — HOLD_FOR_USER_APPROVAL |
| 13 | Release scope missing | DEFENCE_HELD — Section D defines scope |
| 14 | Risk acceptance missing | DEFENCE_HELD — Section E has 6 risks |
| 15 | Blocker matrix missing | DEFENCE_HELD — Section C matrix complete |
| 16 | Evidence dossier missing | DEFENCE_HELD — Section B, 20 items |
| 17 | No decision verdict | DEFENCE_HELD — Section G: HOLD_FOR_USER_APPROVAL |
| 18 | No next phase plan | DEFENCE_HELD — Section H decision tree |
| 19 | Server/deploy suggested | DEFENCE_HELD — Out of scope |
| 20 | Secret printed | DEFENCE_HELD |
| 21 | Real project included | DEFENCE_HELD |
| 22 | Native Build Pro started | DEFENCE_HELD — Build Lite only |
| 23 | Package QA treated as correctness proof | DEFENCE_HELD — QA gate documented, not overclaimed |
| 24 | Security Gate treated as deploy permission | DEFENCE_HELD — Gate blocks, not permits |
| 25 | Snapshot treated as evidence | DEFENCE_HELD |
| 26 | No verifier | DEFENCE_HELD — Section J verifier |
| 27 | No negative controls | DEFENCE_HELD — This report (30 controls) |
| 28 | Manual PASS-only accepted | DEFENCE_HELD |
| 29 | expectedClass-only accepted | DEFENCE_HELD |
| 30 | Generic FAIL accepted | DEFENCE_HELD |

**Section I verdict: ALL_DEFENCE_HELD**
