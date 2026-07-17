# Codex Factory v1.0 — Release Notes

**Release Date:** 2026-07-11
**Codename:** Foundation
**Stage:** Stable Foundation Release

---

## Overview

Codex Factory v1.0 is the first stable foundation release of the Codex Factory
platform — a systems engineering framework that governs how AI coding agents
build, verify, and deliver software projects.

v1.0 bundles the Foundation RC (R5.0) baseline with the Benchmark Suite v3 (R6.1),
providing a validated, measured, and documented platform for AI-assisted
software engineering.

**This is NOT a final product.** v1.0 is a foundation for continued expansion.

---

## What Codex Factory Does

Codex Factory provides 16 integrated capabilities:

1. **Factory Bootstrap** — Automatic project-type detection and workflow routing
2. **Project Router (APP_TYPE_ROUTER)** — Classification into 7 project types
3. **Project Surface Model** — Multi-surface project decomposition (10 surface types)
4. **Search Pipeline** — Pre-Build Research Gate + Evidence Pack v2 + Quality Gate v5
5. **Evidence Pack** — Structured research evidence for implementation decisions
6. **Multi-Agent System** — Worker capsules, handoff protocol, task graph, integrator
7. **Verifier + Evidence Binding** — Automated verification with evidence-backed verdicts
8. **Risk Classifier** — Runtime risk profiling (LOW through L_CLASS)
9. **Business Invariant Engine** — Enforceable business rules (price, inventory, status, etc.)
10. **External Engine Broker** — Tool planning, execution, and evidence binding (semgrep, autocannon, playwright)
11. **Expert Pack System** — Domain-specific knowledge packs with invariants and benchmarks
12. **Ecommerce Pack** — 7 invariants, 29 tests, runtime validated
13. **SaaS Tool Pack** — 8 invariants, 27 tests, runtime validated
14. **Production Readiness Checker** — 15-dimension readiness assessment
15. **Benchmark Suite v3** — 10 benchmarks, 100% pass, capability matrix
16. **Regression System** — 114 tests across 5 testbeds

---

## Key Metrics

| Metric | Value |
|--------|-------|
| Regression tests | **114/114 PASS** |
| Benchmarks | **10/10 PASS** |
| Expert packs | **2 validated** (ecommerce, saas-tool) |
| Runnable starters | **6** |
| Engines available | **3** (semgrep, autocannon, playwright) |
| Runtime scripts | **65** |
| Schemas | **38** |
| Surface accuracy | **100%** |
| Risk classifier accuracy | **100%** |
| Engine plan accuracy | **100%** |

---

## What Changed from Foundation RC

- Ecommerce Expert Pack with 29-test runtime validation
- SaaS Tool Expert Pack with 27-test runtime validation
- Production Hardening Foundation (readiness checker, CI/CD template, deployment manifest)
- Benchmark Suite v3 (10 benchmarks, full capability matrix)
- Playwright engine now AVAILABLE (was TOOL_FAILED)
- autocannon port now configurable (was hardcoded)
- 114 tests across 5 testbeds (up from 101)

---

## Known Limitations

- Not a production deployment system
- In-memory stores in testbeds (not production databases)
- CodeQL and k6 not yet live
- Playwright needs per-project dependency setup
- Small-scale load smoke ≠ production capacity proof
- Complex multi-surface projects still need human audit

---

## What v1.0 Is NOT

- NOT a final version
- NOT a production deployment orchestrator
- NOT a replacement for senior engineering judgment
- NOT an external benchmark authority
- NOT a "production-ready" claim for any specific project

---

## Getting Started

1. Place your project in or point Codex to `C:\Codex_App_Factory`
2. Factory Bootstrap runs automatically on any new task
3. For complex projects, follow the Project Expertise Flow (12 steps)
4. Run `.\runtime\pre-build-research-gate.ps1` before any external-dependency work
5. Check `outputs/R7_0_REGRESSION_COMMAND_INDEX.md` for all test commands

---

## Next Steps

See `outputs/R7_0_V1X_ROADMAP.md` for the v1.x roadmap.
