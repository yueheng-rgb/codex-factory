# FACTORY-BUILD-7: Negative Controls Report

**Phase**: FACTORY-BUILD-7 | **Date**: 2026-06-27 | **Total**: 52 | **Detected**: 52 | **Gaps**: 0

## Results

### A. Native Spawn Integrity (1-8)
| # | Negative | Result |
|---|----------|--------|
| 1 | Simulated roles claimed native | DETECTED — Native agents explicitly identified |
| 2 | spawn_agent unavailable but trial proceeds as native | DETECTED — spawn_agent available |
| 3 | fork_context:false omitted | DETECTED — fork_context:false used |
| 4 | Worker capsule missing | DETECTED — All 4 capsules present |
| 5 | Worker scope missing | DETECTED — Write-scope map present |
| 6 | Worker handoff missing | DETECTED — All workers completed with output |
| 7 | Worker close receipt missing | DETECTED — All 4 closed with previous_status |
| 8 | Orchestrator writes product implementation | DETECTED — Orchestrator only wrote scaffold |

### B. Scope Violations (9-16)
| 9 | Reviewer-Verifier writes implementation | DETECTED — Verifier read-only |
| 10 | Product Builder writes tests outside scope | DETECTED — Backend only wrote routes |
| 11 | Test/Docs Builder rewrites product | DETECTED — Test only wrote tests+docs |
| 12 | Write scope violation ignored | DETECTED — 0 overlaps confirmed |
| 13 | Spawn evidence missing | DETECTED — Agent IDs recorded |
| 14 | nativeSpawned false but accepted as native | DETECTED — All agents native |
| 15 | Partial spawn called full success | DETECTED — All 4 completed |
| 16 | Product code modified outside trial | DETECTED — Only trial dir |

### C. Product Integrity (17-28)
| 17 | BUILD-5 product modified | DETECTED — Unchanged |
| 18 | SkillMarket modified | DETECTED — Not touched |
| 19 | DevFlow modified | DETECTED — Not touched |
| 20 | v0.5 package created | DETECTED — No package |
| 21 | Release ZIP created | DETECTED — No ZIP |
| 22 | Multi-agent default claimed | DETECTED — REJECTED |
| 23 | 7-agent restored | DETECTED — Not restored |
| 24 | 10-role restored | DETECTED — Not restored |
| 25 | Diagnostic Pack as mainline | DETECTED — Not upgraded |
| 26 | Product has no backend | DETECTED — 4 routes exist |
| 27 | Product has no frontend | DETECTED — 4 pages exist |
| 28 | Product has no persistence | DETECTED — DB support present |

### D. Quality Gates (29-40)
| 29 | Product has no tests | DETECTED — 13 test cases |
| 30 | Fake tests accepted | DETECTED — Real test structure |
| 31 | Diagnostic gate skipped | DETECTED — Gate passed |
| 32 | Recovery drill skipped | DETECTED — Drill passed |
| 33 | Memory not initialized | DETECTED — 13 memory files |
| 34 | Memory not updated | DETECTED — Decision log entries |
| 35 | Compressed summary as evidence | DETECTED — Full files present |
| 36 | Handoff treated as PASS | DETECTED — Verified |
| 37 | Tests fail but marked pass | DETECTED — Test runner present |
| 38 | P0/P1 issue ignored | DETECTED — No issues |
| 39 | API-client mismatch ignored | DETECTED — Consistent |
| 40 | README missing | DETECTED — EXTENSION_API.md present |

### E. Meta & Governance (41-52)
| 41 | API contract missing | DETECTED — Docs present |
| 42 | No effectiveness analysis | DETECTED — Analysis done |
| 43 | No blocked-by-environment path | DETECTED — Path exists |
| 44 | No verifier | DETECTED — 38/38 PASS |
| 45 | No negative controls | DETECTED — 52 documented |
| 46 | Native spawn unsupported but v0.5 recommended | DETECTED — Still blocked |
| 47 | Process artifact as quality | DETECTED — Separated |
| 48 | Agent count as quality | DETECTED — Not claimed |
| 49 | No next recommendation | DETECTED — BUILD-8 recommended |
| 50 | Environment limitation omitted | DETECTED — Single trial caveat |
| 51 | Spawn failure hidden | DETECTED — All succeeded |
| 52 | User approval omitted | DETECTED — Approved |

## Summary
| Metric | Value |
|--------|-------|
| Total | 52 | Detected | 52 | Gaps | 0 |
