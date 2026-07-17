# RC-USER-ACCEPTANCE-0 — Section B: RC0 Acceptance Summary

**Phase:** RC-USER-ACCEPTANCE-0 | **Section:** B | **Status:** COMPLETE

## RC0 Identity
| Field | Value |
|---|---|
| Package | `codex-factory-core-v0.9.0-pre-RC0.zip` |
| SHA256 | A058FD67A02B13AAB010040905FA1D471050F9CB7A4A07EB3C5B9C5DB9240EF6 |
| Size | 3.2 MB, 2,755 entries |
| Type | RELEASE_CANDIDATE |

## Evidence Chain
| Phase | Verdict | Key Result |
|---|---|---|
| FACTORY-RELEASE-CANDIDATE-0 | 45/45 PASS | RC package created, all gates preserved |
| RC-USER-REVIEW-0 | 26/26 PASS | User inspected, chose Option 1 |
| RC-SMOKE-0 | 31/31 PASS | Extraction clean, CLI works, gates correct |

## Smoke Results Summary
| Area | Result |
|---|---|
| Extraction | 2,735 files, 227 dirs, SHA verified |
| CLI | status/agents/watch: exit 0; verify: exit 1 (expected) |
| Security/Deploy Gate | Triggers for deployed-trace |
| Package QA | Required for final handoff (not triggered for RC) |
| Context Space | Required for long-horizon |
| Memory Quality | 8/8 policy tests pass |
| Cleanup | PLAN default, DELETE confirm, CORE_EVIDENCE protected |
| Phase Close | Verifier required, stale snapshot rejected |
| Forbidden Content | 11/11 CLEAN |
| Negative Controls | 38/38 ALL_DEFENCE_HELD |

## Remaining Blockers
| Blocker | Status |
|---|---|
| BLOCK-001 | STRONG_PARTIAL_EVIDENCE |
| BLOCK-002 | ACTIVE |
| BLOCK-003 | ACTIVE |
| BLOCK-004 | ACTIVE |
| v0.5 | BLOCKED |

**Section B verdict: COMPLETE**
