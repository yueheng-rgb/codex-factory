# PHASE 6C — H23-A / Release Candidate Inventory

**Status**: PASS
**Assets**: 13 classified — 7 CORE_RC, 4 EXPERIMENTAL_RC, 2 EXCLUDED

## Core Candidates (7)
| # | Asset | Path | Final Package? |
|---|-------|------|---------------|
| CORE-01 | factory-resource-pack | factory-resource-pack/ | Yes |
| CORE-02 | factoryctl scripts | scripts/factoryctl.ps1 | Yes |
| CORE-03 | governance state | governance/factory-state/ | Yes |
| CORE-04 | P0/P1/P2 policy | governance/policies/ | Yes |
| CORE-05 | worker contract schema | governance/schemas/ | Yes |
| CORE-06 | bootstrap validation | factory-resource-pack/bootstrap/ | Yes |
| CORE-07 | negative fixture templates | scripts/phase6c-*-negative-controls | Yes |

## Experimental Candidates (4)
| # | Asset | Requires Future Test? |
|---|-------|----------------------|
| EXP-01 | codex-factory-plugin | Yes — live install/sync |
| EXP-02 | MCP factory verifier | Yes — live MCP server |
| EXP-03 | monitoring prototype | Yes — scheduled runtime |
| EXP-04 | automation templates | Yes — scheduled runtime |

## Excluded (2)
| # | Asset | Reason |
|---|-------|--------|
| DEP-01 | scoring systems | H18-A0 gate |
| DEP-02 | failure-router | Not runnable core |

## Verdict: PASS
