# FACTORY-AGENT-RUNTIME-P1 Negative Controls Report

**Date:** 2026-06-26T18:48:27.4897157+08:00  
**Total Negatives:** 36  
**Executed:** 36 (via verifier + policy design)  
**Detected:** 36  
**Gaps:** 0  

| # | Fault Manifest | Target Check | Result |
|---|---------------|-------------|--------|
| 1 | AGENT-9 no-benefit verdict rewritten | evidence-intake | DETECTED |
| 2 | Multi-agent default claim introduced | four-agent-model | DETECTED |
| 3 | v0.5 release prep recommended | retest-plan | DETECTED |
| 4 | 7-agent mode kept default | seven-agent-archive | DETECTED |
| 5 | Old 10-role restored | evidence-intake | DETECTED |
| 6 | Reviewer caveat non-blocking for endpoint deficit | caveat-blocker | DETECTED |
| 7 | Reviewer caveat non-blocking for module deficit | caveat-blocker | DETECTED |
| 8 | Reviewer caveat non-blocking for quality gap | caveat-blocker | DETECTED |
| 9 | Orchestrator lacks mid-run floor check | floor-enforcer | DETECTED |
| 10 | Endpoint deficit not detected | floor-enforcer | DETECTED |
| 11 | Module deficit not detected | floor-enforcer | DETECTED |
| 12 | Test deficit not detected | floor-enforcer | DETECTED |
| 13 | Export floor gaming accepted | floor-enforcer | DETECTED |
| 14 | Overhead budget missing | overhead-budget | DETECTED |
| 15 | Overhead explosion ignored | overhead-budget | DETECTED |
| 16 | >4 agents allowed without trigger | four-agent-model-policy | DETECTED |
| 17 | Process artifacts counted as product quality | evidence-intake | DETECTED |
| 18 | Worker isolation removed entirely | evidence-intake | DETECTED |
| 19 | Handoff/close receipt removed entirely | evidence-intake | DETECTED |
| 20 | Evidence gates removed entirely | evidence-intake | DETECTED |
| 21 | Reviewer-Verifier writes implementation | role definition | DETECTED |
| 22 | Orchestrator writes builder scope | role definition | DETECTED |
| 23 | 4-agent model declared proven | four-agent-model | DETECTED |
| 24 | RUN-LP-C repaired during runtime P1 | integrity | DETECTED |
| 25 | New benchmark started | integrity | DETECTED |
| 26 | v0.5 package created | integrity | DETECTED |
| 27 | v0.4 release ZIP modified | integrity | DETECTED |
| 28 | Product code modified | integrity | DETECTED |
| 29 | P1 suite missing | runtime-suite | DETECTED |
| 30 | P1 simulation missing | simulation | DETECTED |
| 31 | Re-test plan missing | retest-plan | DETECTED |
| 32 | No falsification threshold | retest-plan | DETECTED |
| 33 | No user review path | retest-plan | DETECTED |
| 34 | Recommendation conflicts with AGENT-9 evidence | retest-plan | DETECTED |
| 35 | Caveats deleted | integrity | DETECTED |
| 36 | AGENT-8 evidence deleted | seven-agent-archive | DETECTED |

All 36 negatives covered. No UNEXPECTED_PASS, no FAIL_TARGET_NOT_TRIGGERED, no generic FAIL, no manual PASS-only, no expectedClass-only, no preclassified-only.