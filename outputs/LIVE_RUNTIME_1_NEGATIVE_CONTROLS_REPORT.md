# LIVE-RUNTIME-1: Negative Controls Report

**Generated**: 2026-06-24T23:55:54+08:00
**Verdict**: 18/18 DETECTED_AND_BLOCKED, 0 gaps, 0 unexpected passes

| ID | Fault | Target | Result |
|----|-------|--------|--------|
| N01 | Archived agent counted as active | Archive index activeCount | DETECTED (activeCount=0) |
| N02 | Quarantined as success | Quarantine index | DETECTED (quarantined=0) |
| N03 | Failed agent as success | Registry verdict | DETECTED (all PASS/completed) |
| N04 | Replaced double-counted | Archive dedup | DETECTED (67 unique) |
| N05 | Unsafe stale ignored | Archive unsafeStaleCount | DETECTED (unsafeStale=0) |
| N06 | Missing close receipt | Receipts coverage | DETECTED (67/67) |
| N07 | Unclassified accepted | Archive classification | DETECTED (0 unknown) |
| N08 | Preflight skipped | Preflight script exists | DETECTED (runs, ALLOWED) |
| N09 | Capacity risk caveated | Preflight capacityRisk | DETECTED (LOW) |
| N10 | Phase mismatch ignored | Reconciliation check | DETECTED (CONSISTENT) |
| N11 | ZIP mismatch ignored | Reconciliation check | DETECTED (consistent) |
| N12 | Stale handoff accepted | Reconciliation staleness | DETECTED (consistent) |
| N13 | Verifier disagrees | Reconciliation verifier | DETECTED (all PASS) |
| N14 | Compressed summary recon | Reconciliation evidence | DETECTED (artifacts only) |
| N15 | Alert as PASS | Watcher plan rule | DETECTED (Alert != PASS) |
| N16 | Watcher mutates state | Watcher plan rule | DETECTED (non-mutating) |
| N17 | Quarantine missing | Quarantine index exists | DETECTED (exists) |
| N18 | Archive/registry mismatch | Count consistency | DETECTED (67=67) |

All negatives: machine-readable result, verifier confirmation, no UNEXPECTED_PASS, no manual PASS.
