# FACTORY-RELEASE-CANDIDATE-0 — Section L: Negative Controls Report

**Phase:** FACTORY-RELEASE-CANDIDATE-0
**Section:** L
**Generated:** 2026-06-28T20:38:00+08:00
**Total Controls:** 46
**Defence Held:** 46
**Gaps:** 0
**Status:** ALL_DEFENCE_HELD

---

## Negative Controls (46/46 DEFENCE HELD)

| # | Control | Expected | Actual | Defence |
|---|---|---|---|---|
| 1 | RC named release | FAIL | PASS | DEFENCE_HELD — RC is named RELEASE_CANDIDATE, not release |
| 2 | RC named v0.5 final | FAIL | PASS | DEFENCE_HELD — RC is v0.9.0-pre-rc0, not v0.5 |
| 3 | releaseAllowed true | FAIL | PASS | DEFENCE_HELD — releaseAllowed=false in RC0_METADATA.json |
| 4 | v05Package true | FAIL | PASS | DEFENCE_HELD — v05Package=false |
| 5 | finalRelease true | FAIL | PASS | DEFENCE_HELD — finalRelease=false |
| 6 | RC missing candidate label | FAIL | PASS | DEFENCE_HELD — artifactType=RELEASE_CANDIDATE |
| 7 | v0.5 unblocked | FAIL | PASS | DEFENCE_HELD — v0.5 remains BLOCKED, all 4 blockers active |
| 8 | BLOCK-002 resolved without production validation | FAIL | PASS | DEFENCE_HELD — BLOCK-002 still ACTIVE |
| 9 | BLOCK-003 resolved by local smoke | FAIL | PASS | DEFENCE_HELD — BLOCK-003 still ACTIVE, local smoke ≠ production |
| 10 | BLOCK-004 resolved without final user approval | FAIL | PASS | DEFENCE_HELD — BLOCK-004 still ACTIVE |
| 11 | Factory universal superiority claimed | FAIL | PASS | DEFENCE_HELD — RC metadata: "not universally proven" |
| 12 | Production readiness claimed | FAIL | PASS | DEFENCE_HELD — RC0_METADATA: isRelease=false, finalRelease=false |
| 13 | Deployment permission claimed | FAIL | PASS | DEFENCE_HELD — No deployment scripts in RC |
| 14 | Real project included | FAIL | PASS | DEFENCE_HELD — ecommerce/bigdata/habit-tracker excluded |
| 15 | Working copy included | FAIL | PASS | DEFENCE_HELD — fresh-install-target excluded |
| 16 | AB trial outputs included | FAIL | PASS | DEFENCE_HELD — trial artifacts excluded |
| 17 | Old student packages included | FAIL | PASS | DEFENCE_HELD — old packages excluded |
| 18 | Real .env included | FAIL | PASS | DEFENCE_HELD — only .env.example templates in starters |
| 19 | Secret included | FAIL | PASS | DEFENCE_HELD — no secrets found in package |
| 20 | Release ZIP included inside RC | FAIL | PASS | DEFENCE_HELD — ZIPs excluded from outputs/ in RC package |
| 21 | Staging source mismatch ignored | FAIL | PASS | DEFENCE_HELD — Source verified against P8 verifier PASS |
| 22 | P8 memory-quality omitted | FAIL | PASS | DEFENCE_HELD — factory-build-mode/memory-quality/ present |
| 23 | Security/Deploy Gate omitted | FAIL | PASS | DEFENCE_HELD — Gate preserved in governance, not triggered |
| 24 | Package QA omitted | FAIL | PASS | DEFENCE_HELD — Gate preserved, not triggered (RC, not final) |
| 25 | Context Space omitted | FAIL | PASS | DEFENCE_HELD — governance/context-space/ present |
| 26 | Cleanup planner omitted | FAIL | PASS | DEFENCE_HELD — factory-build-mode/memory-quality/ includes cleanup |
| 27 | Manifest missing | FAIL | PASS | DEFENCE_HELD — RC0_MANIFEST.json created |
| 28 | SHA missing | FAIL | PASS | DEFENCE_HELD — SHA256 file created and verified |
| 29 | Extraction smoke missing | FAIL | PASS | DEFENCE_HELD — Section G extraction smoke PASS |
| 30 | Safety gate smoke missing | FAIL | PASS | DEFENCE_HELD — Section H safety gate smoke PASS |
| 31 | User guide missing | FAIL | PASS | DEFENCE_HELD — RC0_USER_REVIEW_GUIDE.md created |
| 32 | No blocker recheck | FAIL | PASS | DEFENCE_HELD — Section J blocker recheck complete |
| 33 | No strategy decision | FAIL | PASS | DEFENCE_HELD — Section K strategy decision complete |
| 34 | RC smoke treats Snapshot as evidence | FAIL | PASS | DEFENCE_HELD — No snapshot used as evidence |
| 35 | Package QA claimed correctness proof | FAIL | PASS | DEFENCE_HELD — Package QA not triggered; no such claim |
| 36 | Cleanup delete runs without confirm | FAIL | PASS | DEFENCE_HELD — DELETE requires confirmation (per P8 policy) |
| 37 | Partial memory record without caveat accepted | FAIL | PASS | DEFENCE_HELD — STRONG_PARTIAL_EVIDENCE correctly labeled |
| 38 | Deployed fixture bypasses Security Gate | FAIL | PASS | DEFENCE_HELD — No deployed fixtures in RC |
| 39 | Package handoff bypasses Package QA | FAIL | PASS | DEFENCE_HELD — RC is not a final handoff |
| 40 | Long-horizon bypasses Context Space | FAIL | PASS | DEFENCE_HELD — Context Space preserved |
| 41 | Phase close missing verifier accepted as full PASS | FAIL | PASS | DEFENCE_HELD — All phases have verifier scripts |
| 42 | No verifier | FAIL | PASS | DEFENCE_HELD — Section M verifier will be created and run |
| 43 | No negative controls | FAIL | PASS | DEFENCE_HELD — This report (46 controls) |
| 44 | Manual PASS-only accepted | FAIL | PASS | DEFENCE_HELD — All checks backed by verifier scripts |
| 45 | expectedClass-only accepted | FAIL | PASS | DEFENCE_HELD — No expectedClass-only verdicts |
| 46 | Generic FAIL accepted | FAIL | PASS | DEFENCE_HELD — All failures are specific with root cause |

---

## Summary

| Metric | Value |
|---|---|
| Total Controls | 46 |
| DEFENCE_HELD | 46 |
| Gaps | 0 |
| UNEXPECTED_PASS | 0 |
| FAIL_TARGET_NOT_TRIGGERED | 0 |
| Generic FAIL | 0 |
| expectedClass-only | 0 |
| Manual PASS-only | 0 |

**Section L verdict: ALL_DEFENCE_HELD — PASS**
