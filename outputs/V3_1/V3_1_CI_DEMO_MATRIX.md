# V3.1 — CI Demo Matrix

**Version:** V3.1-CI-DEMO-MATRIX-v2  
**Total Demos:** 6 (5 required + 1 bonus negative control)

| # | Pipeline | Demo ID | Result | Expected | Detail |
|---|----------|---------|--------|----------|--------|
| 1 | Green CI | CI-001 | **PASS** | PASS | products-api 23/23, synced, receipt valid |
| 2 | Failed CI | CI-002B | **FAIL** | FAIL | exit=1, artifacts retained, gate blocks |
| 3 | Missing Artifact | CI-003 | **BLOCKED** | BLOCKED | no source = no artifacts = no PASS |
| 4 | CRITICAL Review | V3_1-CRITICAL | **BLOCKED→ALLOWED** | BLOCKED then ALLOWED_FOR_REVIEW | CPM-001 17/17 + signed_local_receipt |
| 5 | Remote Unavailable | V3_1-REMOTE | **BLOCKED** | BLOCKED | REMOTE_RUNNER_NOT_CONFIGURED |
| 6 | Deprecated Block *(bonus)* | CI-004 | **BLOCKED** | BLOCKED | Firecrawl canonical search blocked |

## Summary

| Metric | Count |
|--------|-------|
| Required pipelines | 5 |
| Delivered | 6 (5 + 1 bonus) |
| PASS | 1 |
| FAIL (expected) | 1 |
| BLOCKED (expected) | 3 |
| BLOCKED→ALLOWED_FOR_REVIEW | 1 |

## Key Behaviors Verified

- **Green CI** produces artifacts, syncs to store, receipt valid
- **Failed CI** captures failure without polluting, gate would block release
- **Missing artifact** is BLOCKED (not PASS)
- **CRITICAL without receipt** is BLOCKED; with signed_local_receipt = ALLOWED_FOR_REVIEW
- **Remote unavailable** is honestly BLOCKED, not faked
- **Deprecated pattern** is caught by snapshot-aware resume gate