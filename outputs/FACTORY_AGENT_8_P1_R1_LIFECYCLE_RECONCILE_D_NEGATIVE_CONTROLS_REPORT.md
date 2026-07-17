# FACTORY-AGENT-8-P1-R1 Lifecycle Reconcile / Negative Controls

**Date:** 2026-06-26T20:02:07.8283141+08:00  
**12 negatives, all covered.**

| # | Fault Manifest | Result |
|---|---------------|--------|
| 1 | Late receipt treated as original native | DETECTED |
| 2 | Original missing gap deleted | DETECTED |
| 3 | BLOCKED_BY_REVIEWER erased | DETECTED |
| 4 | Product code modified | DETECTED |
| 5 | Boyle allowed implementation writes | DETECTED |
| 6 | Boyle close receipt claims product correctness | DETECTED |
| 7 | Boyle handoff marks phase PASS | DETECTED |
| 8 | New agent created | DETECTED |
| 9 | v0.4 ZIP modified | DETECTED |
| 10 | Old FINAL package modified | DETECTED |
| 11 | Lifecycle gap ignored | DETECTED |
| 12 | Agent Count Audit changed without evidence | DETECTED |

No UNEXPECTED_PASS, no FAIL_TARGET_NOT_TRIGGERED, no generic FAIL.
