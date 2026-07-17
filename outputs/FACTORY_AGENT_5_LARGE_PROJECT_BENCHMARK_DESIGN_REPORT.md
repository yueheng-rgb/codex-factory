# FACTORY-AGENT-5 Large Project Benchmark Design Report

**Verdict**: **PASS**  
**Verifier**: 33/33  
**Negatives**: 40/40 (detected=40, gaps=0)

## Summary

FACTORY-AGENT-5 designed a comprehensive large-project benchmark blueprint comparing Vanilla Codex, v0.4 Factory Lite, and v0.5 Agent Company Mode. No implementation started. The benchmark is large enough to expose single-agent simplification and integration pressure, but bounded to be completable.

## Benchmark: OpsFlow Enterprise Lite

| Attribute | Value |
|---|---|
| Modules | 13 |
| Requirements | 40 |
| Cross-module dependencies | 10 |
| Complexity floors | 8 metrics (80+ files, 300+ exports, 40+ endpoints, 15+ DB tables) |

## Three-Run Comparison

| Run | Name | Key Constraint |
|---|---|---|
| RUN-LP-A | Vanilla Codex | No Factory mechanisms |
| RUN-LP-B | v0.4 Factory Lite | Verifier only, single-agent |
| RUN-LP-C | v0.5 Agent Company | 8 agents, capsules, anti-deception |

## v0.5 Agent Configuration (RUN-LP-C)

| Role | Count | Modules |
|---|---|---|
| Orchestrator | 1 | Task graph, spawn, closure |
| Architect | 1 | Module decomposition, API contracts |
| Builder | 4 | 4 scope groups (3-4 modules each) |
| Integration Lead | 1 | Cross-module merge |
| Reviewer | 1 | Code review, drift detection |
| Verifier | 1 | SHA256, evidence, close receipts |
| Integrity Checker | 1 | Anti-deception, scope audit |

## Evaluation Dimensions

| Dimension | Weight |
|---|---|
| Feature completeness | 25% |
| Architecture integrity | 20% |
| Defect count | 20% |
| Code quality | 15% |
| Process overhead | 10% |
| Evidence quality | 10% |

## Success Thresholds

- **MULTI_AGENT_BENEFIT_CONFIRMED**: v0.5 > v0.4 AND v0.5 > Vanilla, no hidden fallback, all gates pass
- **MULTI_AGENT_NO_BENEFIT**: v0.5 score <= v0.4 or Vanilla, or hidden fallback, or gate failure
- **INCONCLUSIVE**: Runs not comparable, evaluator lacks evidence, external factors

## Recommendation

**FACTORY-AGENT-6 / Large Project Vanilla Baseline** — begin with RUN-LP-A (Vanilla Codex, no Factory).
