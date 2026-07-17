# FACTORY-CONTEXT-SPACE-P4-R1 — Negative Controls Report

**Date**: 2026-06-28
**Sub-step**: F

---

| NC | Fault | Target Check | Result |
|----|-------|-------------|--------|
| NC-01 | Only 16 snapshots accepted | 24-snapshot minimum check | BLOCKED |
| NC-02 | Missing FW level accepted | 6-type coverage check | BLOCKED |
| NC-03 | Missing CD level accepted | 6-type coverage check | BLOCKED |
| NC-04 | Missing RSK level accepted | 6-type coverage check | BLOCKED |
| NC-05 | Missing RD level accepted | 6-type coverage check | BLOCKED |
| NC-06 | Missing NBP level accepted | 6-type coverage check | BLOCKED |
| NC-07 | Missing QA level accepted | 6-type coverage check | BLOCKED |
| NC-08 | Benchmark result omits generated snapshot | All-snapshots-in-results check | BLOCKED |
| NC-09 | Verifier does not check count | Hardened V05 | BLOCKED |
| NC-10 | BALANCED default claimed without FW evidence | FW benchmark must exist | BLOCKED |
| NC-11 | ULTRA_COMPACT allowed for autonomous continuation | Compression policy check | BLOCKED |
| NC-12 | Cloud recommended prematurely | CLOUD_DEFERRED check | BLOCKED |

**12/12 BLOCKED. 0 UNEXPECTED_PASS. 0 FAIL_TARGET_NOT_TRIGGERED.**
