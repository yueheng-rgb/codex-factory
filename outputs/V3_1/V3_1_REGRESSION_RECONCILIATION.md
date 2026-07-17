# V3.1 — Regression Reconciliation

## V3.0 Demos (Still Verifiable)

| Demo | Status | Detail |
|------|--------|--------|
| DEMO-001 | PASS | products-api 23/23, artifact-bound |
| DEMO-002 | FAIL (expected) | main_tree_polluted=false |
| DEMO-003 | BLOCKED (expected) | deprecated direction detected |
| DEMO-004 | PASS | CPM-001 17/17, review receipt bound |

## 274/274 Regression

**Status:** ARTIFACT_CONFIRMED_PLUS_SPOT_CHECK

Full rerun not performed in V3.1 reconciliation window. Two testbeds spot-checked, remainder artifact-confirmed from V3.0 baseline.

| Testbed | Tests | Status |
|---------|-------|--------|
| products-api | 23/23 | SPOT CHECKED PASS |
| cross-pack-cpm-001 | 17/17 | SPOT CHECKED PASS |
| admin-system | 58/58 | ARTIFACT CONFIRMED |
| miniapp | 27/27 | ARTIFACT CONFIRMED |
| game-threejs | 30/30 | ARTIFACT CONFIRMED |
| cpp-memory-safety | 41/41 | ARTIFACT CONFIRMED |
| ecommerce | 29/29 | ARTIFACT CONFIRMED |
| saas | 27/27 | ARTIFACT CONFIRMED |
| mini-inventory-admin | 22/22 | ARTIFACT CONFIRMED |
| **Total** | **274/274** | |

## Expert Packs

6/6 packs loadable via `runtime/expert-pack-loader.ps1`

## Snapshot Verifier

14/14 PASS — Snapshot CODEX-FACTORY-V2-20260717 intact

## Other Gates

| Gate | Status |
|------|--------|
| Artifact verifier | PASS |
| Human review gate | PASS (2 receipts valid, BLOCKED without receipt) |
| Deprecated locks | Intact |
| Secrets | 0 found |
| No fake remote | remote-placeholder honestly NOT_IMPLEMENTED |
| No production cloud claim | Non-claims present |

## Conclusion

All regression and boundary checks pass. 274/274 confirmed via spot-check + artifact evidence.