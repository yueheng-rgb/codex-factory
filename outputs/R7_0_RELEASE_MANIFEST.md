# Codex Factory v1.0 — Release Manifest

**Release:** Codex Factory v1.0
**Date:** 2026-07-11
**Stage:** Stable Foundation Release

---

## Core Rules (4 files)
| Path | Capability | Status |
|------|-----------|--------|
| `AGENTS.md` | Factory Bootstrap Gate (BOOT-001) | ACTIVE |
| `GLOBAL_CODEX_RULES.md` | Global project-building rules | ACTIVE |
| `APP_TYPE_ROUTER.md` | Project type classification (7 types) | ACTIVE |
| `STACK_DECISION_GUIDE.md` | Technology stack decision guide | ACTIVE |

## Runnable Starters (6)
| Path | Type | Tests | Status |
|------|------|-------|--------|
| `runnable-starters/node-api-postgres` | api-service | 13/13 | ACTIVE |
| `runnable-starters/vite-threejs-interactive` | threejs-interactive | typecheck+build | ACTIVE |
| `runnable-starters/vite-react-content-site` | public-web | typecheck+build | ACTIVE |
| `runnable-starters/next-fullstack-admin` | admin-web (Next.js) | — | ACTIVE |
| `runnable-starters/next-saas-ai-tool` | saas-tool (Next.js) | — | ACTIVE |

## Testbeds (3)
| Path | Capability | Tests | Status |
|------|-----------|-------|--------|
| `testbeds/products-api` | Products API CRUD | 23/23 | ACTIVE |
| `testbeds/ecommerce-runtime-validation` | Ecommerce invariants | 29/29 | ACTIVE |
| `testbeds/saas-runtime-validation` | SaaS invariants | 27/27 | ACTIVE |

## Pilots (1)
| Path | Capability | Tests | Status |
|------|-----------|-------|--------|
| `pilots/mini-inventory-admin` | Full pipeline E2E | 22/22 | ACTIVE |

## Expert Packs (10 files)
| Path | Capability | Status |
|------|-----------|--------|
| `governance/expert-packs/expert-pack-registry.json` | Pack registry | ACTIVE |
| `governance/expert-packs/EXPERT_PACK_SYSTEM.md` | System docs | ACTIVE |
| `governance/expert-packs/ecommerce/` | Ecommerce pack (7 invariants) | ACTIVE |
| `governance/expert-packs/saas-tool/` | SaaS pack (8 invariants) | ACTIVE |

## Production Hardening (8 files)
| Path | Capability | Status |
|------|-----------|--------|
| `runtime/production-readiness-checker.ps1` | Readiness checker | ACTIVE |
| `schemas/production-readiness.schema.json` | Readiness schema | ACTIVE |
| `schemas/deployment-manifest.schema.json` | Deployment schema | ACTIVE |
| `governance/production/` | Docs + CI/CD template + example | ACTIVE |

## Search Pipeline — FROZEN (5+ files)
| Path | Capability | Status |
|------|-----------|--------|
| `runtime/pre-build-research-gate.ps1` | Pre-Build Research Gate | FROZEN |
| `runtime/search-operating-doctrine.ps1` | Search doctrine | FROZEN |
| `runtime/search-result-quality-gate.ps1` | Quality Gate v5 | FROZEN |
| `runtime/evidence-pack-builder.ps1` | Evidence Pack v2 | FROZEN |
| `runtime/need-search-detector.ps1` | Search necessity | FROZEN |

## Multi-Agent / Worker — FROZEN
| Path | Capability | Status |
|------|-----------|--------|
| `runtime/agent-loader.ps1` | Agent loader | FROZEN |
| `runtime/contract-checker.ps1` | Worker contract | FROZEN |
| `runtime/handoff-validator.ps1` | Handoff validator | FROZEN |
| `governance/multi-agent/` | Governance docs | FROZEN |

## Risk & Invariant (9 files)
| Path | Capability | Status |
|------|-----------|--------|
| `runtime/runtime-risk-classifier.ps1` | Risk classifier | ACTIVE |
| `runtime/business-invariant-engine.ps1` | Invariant engine | ACTIVE |
| `runtime/risk-enforcement-gate-v3.ps1` | Risk gate v3 | ACTIVE |
| `runtime/automated-gate-detector.ps1` | Gate detector | ACTIVE |
| `runtime/gate-evidence-binder.ps1` | Evidence binder | ACTIVE |
| `schemas/runtime-risk-profile.schema.json` | Risk schema | ACTIVE |
| `schemas/business-invariant.schema.json` | Invariant schema | ACTIVE |
| `schemas/gate-detection-result.schema.json` | Gate detection schema | ACTIVE |
| `schemas/gate-evidence-binding.schema.json` | Evidence binding schema | ACTIVE |

## Project Surface (4+ files)
| Path | Capability | Status |
|------|-----------|--------|
| `runtime/project-surface-router.ps1` | Surface router | ACTIVE |
| `schemas/project-surface-plan.schema.json` | Surface plan schema | ACTIVE |
| `runtime/starter-type-consistency-check.ps1` | Consistency check | ACTIVE |
| `governance/project-surface-model/` | Surface model docs | ACTIVE |

## External Engines (6+ files)
| Path | Capability | Status |
|------|-----------|--------|
| `runtime/external-engine-broker.ps1` | Engine broker | ACTIVE |
| `runtime/external-engine-registry.ps1` | Engine registry | ACTIVE |
| `runtime/external-tool-availability-check.ps1` | Tool availability | ACTIVE |
| `schemas/external-engine.schema.json` | Engine schema | ACTIVE |
| `schemas/external-engine-run-result.schema.json` | Run result schema | ACTIVE |
| `governance/external-engines/` | Engine governance | ACTIVE |

## Expert Pack Runtime (3 files)
| Path | Capability | Status |
|------|-----------|--------|
| `runtime/expert-pack-activation.ps1` | Pack activation | ACTIVE |
| `runtime/expert-pack-loader.ps1` | Pack loader | ACTIVE |
| `schemas/expert-pack.schema.json` | Pack schema | ACTIVE |

## Benchmark Suites (5 files)
| Path | Capability | Status |
|------|-----------|--------|
| `outputs/R6_1_benchmark_suite_v3.json` | Suite v3 (10 benchmarks) | ACTIVE |
| `outputs/R6_1_capability_matrix_v3.json` | Matrix v3 | ACTIVE |
| `outputs/R6_1_COMPLETION_REPORT.md` | Suite v3 report | ACTIVE |
| `outputs/R4_0_benchmark_suite_v2.json` | Suite v2 (archived) | ARCHIVED |
| `outputs/R4_0_capability_matrix_v2.json` | Matrix v2 (archived) | ARCHIVED |

## Release Baselines (5 files)
| Path | Capability | Status |
|------|-----------|--------|
| `outputs/R5_0_FOUNDATION_RC_BASELINE.md` | RC baseline | BASELINE |
| `outputs/R5_0_FOUNDATION_RC_MANIFEST.json` | RC manifest | BASELINE |
| `outputs/R5_0_DEPRECATED_DIRECTIONS_LOCK.md` | Deprecated lock | ACTIVE |
| `outputs/R5_0_KNOWN_RISKS_AND_NON_CLAIMS.md` | Known risks | ACTIVE |
| `outputs/R5_0_REGRESSION_COMMAND_INDEX_V2.json` | Regression index v2 | ACTIVE |

## Engine Status
| Engine | Version | Status |
|--------|---------|--------|
| semgrep | 1.169.0 | AVAILABLE |
| autocannon | 8.0.0 | AVAILABLE |
| playwright | 1.61.1 | AVAILABLE |
| codeql | — | NOT_INSTALLED |
| k6 | — | NOT_INSTALLED |

## Deprecated Directions (10 rules)
All 10 deprecated directions are FINAL LOCKED:
1. Independent Search Agent — FORBIDDEN
2. Dual Search Channel — FORBIDDEN
3. Search Agent as Future Default — FORBIDDEN
4. Implementer direct search — FORBIDDEN
5. chat URL extraction as canonical evidence — FORBIDDEN
6. mock/dry_run mislabeled as live — FORBIDDEN
7. multi-agent default mode — FORBIDDEN
8. external engine bypassing evidence binding — FORBIDDEN
9. Firecrawl replacing canonical search — FORBIDDEN
10. Expert Pack bypassing Risk Gate — FORBIDDEN

---

**Total tracked items: 100+ files across 16 capability domains.**
