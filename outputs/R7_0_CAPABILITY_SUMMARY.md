# Codex Factory v1.0 — Capability Summary

**Generated:** 2026-07-11

---

## 1. Factory Bootstrap
- **What it does:** Automatically detects project type and triggers the correct workflow before any implementation begins. Enforces the 12-step Project Expertise Flow for complex projects and Factory Lite for simple tasks.
- **Status:** ACTIVE (FROZEN since R2.4)
- **Evidence:** `AGENTS.md` (BOOT-001 gate), `GLOBAL_CODEX_RULES.md`, R6.1 benchmark verification
- **Limitations:** Requires user to be in Factory workspace; does not auto-detect external project directories
- **Files:** `AGENTS.md`, `GLOBAL_CODEX_RULES.md`

## 2. Project Router (APP_TYPE_ROUTER)
- **What it does:** Classifies projects into 7 types: backend-api, fullstack-admin, frontend-app, CLI-tool, mobile-app, game-3d, docs-release
- **Status:** ACTIVE
- **Evidence:** `APP_TYPE_ROUTER.md`, BV3-01 through BV3-10 all show correct routing (100% accuracy)
- **Limitations:** Single-type classification for simple projects; multi-surface routing handled by Project Surface Model
- **Files:** `APP_TYPE_ROUTER.md`, `runtime/project-surface-router.ps1`

## 3. Project Surface Model
- **What it does:** Decomposes complex projects into 10 surface types (api-service, admin-web, public-web, frontend-web, miniapp, mobile-app, threejs-interactive, background-worker, database, docs-release). Generates Project Surface Plans for multi-surface projects.
- **Status:** ACTIVE
- **Evidence:** BV3-02, BV3-05, BV3-06, BV3-09 all show correct multi-surface detection (100% accuracy)
- **Limitations:** Miniapp and mobile-app are design-only surfaces (no runnable starters)
- **Files:** `runtime/project-surface-router.ps1`, `schemas/project-surface-plan.schema.json`, `governance/project-surface-model/`

## 4. Search Pipeline
- **What it does:** Pre-Build Research Gate determines when external search is needed (P0_MUST_SEARCH vs P2_NO_SEARCH). Evidence Pack v2 is the canonical evidence carrier. Quality Gate v5 validates search results.
- **Status:** FROZEN (since R2.4)
- **Evidence:** R2.3-AB baseline, R2.4 integration docs, integrated into Benchmarks BV3-01 through BV3-10
- **Limitations:** Uses canonical search path /api/paas/v4/web_search + search_std; /chat/completions web_search downgraded; Firecrawl is Reader/Extractor candidate only
- **Files:** `runtime/pre-build-research-gate.ps1`, `runtime/search-operating-doctrine.ps1`, `runtime/search-result-quality-gate.ps1`, `runtime/evidence-pack-builder.ps1`

## 5. Evidence Pack
- **What it does:** Structures external research into a verifiable, immutable evidence record that Implementers consume (never search directly)
- **Status:** FROZEN (since R2.4)
- **Evidence:** Evidence Pack v2 schema, integrated into all benchmark pipeline executions
- **Limitations:** Dependent on search pipeline availability
- **Files:** `runtime/evidence-pack-builder.ps1`, `schemas/evidence-pack-v2.schema.json`

## 6. Multi-Agent / Worker / Handoff
- **What it does:** Worker capsules with contracts, freeze manifests, patch ledgers, and handoff protocol. Main Agent/Integrator orchestrates. Verifier checks worker boundaries.
- **Status:** FROZEN (since R2.4)
- **Evidence:** Agent protocol pack reports, worker capsule schema, factory-agent phase reports
- **Limitations:** Multi-agent NOT default mode; workers are opt-in for complex projects
- **Files:** `runtime/agent-loader.ps1`, `runtime/contract-checker.ps1`, `runtime/handoff-validator.ps1`, `governance/multi-agent/`

## 7. Verifier / Evidence Binding
- **What it does:** Automated gate detection checks tests, invariants, reviewers, human audit, and coverage evidence. Evidence Binding attaches verifiable proof to every gate decision (SATISFIED/MISSING/PARTIAL).
- **Status:** ACTIVE
- **Evidence:** R2.14 automated gate detection, BV3-05 through BV3-08 show CRITICAL gates correctly requiring invariants + tests
- **Limitations:** Still partially keyword-based; manual override requires reason; CRITICAL/L_CLASS cannot bypass with no evidence
- **Files:** `runtime/automated-gate-detector.ps1`, `runtime/gate-evidence-binder.ps1`, `runtime/risk-enforcement-gate-v3.ps1`

## 8. Risk Classifier
- **What it does:** Runtime risk profiling from LOW through L_CLASS based on task description, project type, surfaces, keywords, and change scope
- **Status:** ACTIVE
- **Evidence:** 100% accuracy across 9 runnable benchmarks (BV3-01 through BV3-10); performance classifier calibrated in R3.1
- **Limitations:** Keyword-based classification; may need human override for edge cases
- **Files:** `runtime/runtime-risk-classifier.ps1`, `schemas/runtime-risk-profile.schema.json`

## 9. Business Invariant Engine
- **What it does:** Enforces business rules (price_non_negative, inventory_non_negative, status_transition_allowed, archived_entity_not_mutable, etc.) during implementation and verification
- **Status:** ACTIVE
- **Evidence:** 7 ecommerce invariants + 8 SaaS invariants; all validated in runtime testbeds (29+27 tests)
- **Limitations:** Generic invariants only; domain-specific invariants come from Expert Packs
- **Files:** `runtime/business-invariant-engine.ps1`, `schemas/business-invariant.schema.json`, `governance/risk/BUSINESS_INVARIANTS.md`

## 10. External Engine Broker
- **What it does:** Plans, executes, and binds evidence from external tools (semgrep, autocannon, playwright). Supports TOOL_UNAVAILABLE, TOOL_FAILED, CLEAN, FINDINGS_PRESENT states.
- **Status:** ACTIVE
- **Evidence:** 3 engines live (semgrep 1.169.0, autocannon 8.0.0, playwright 1.61.1); all benchmark runs use real engine output
- **Limitations:** CodeQL/k6 not installed; Playwright needs per-project dependency; Firecrawl not live
- **Files:** `runtime/external-engine-broker.ps1`, `runtime/external-engine-registry.ps1`, `runtime/external-tool-availability-check.ps1`

## 11. Expert Pack System
- **What it does:** Loads and activates domain-specific knowledge packs (invariants, benchmarks, documentation) when project type matches pack domain
- **Status:** ACTIVE
- **Evidence:** Both packs (ecommerce, saas-tool) correctly activated in BV3-05 through BV3-08 (100% accuracy)
- **Limitations:** Only 2 packs currently; no miniapp, game, or C/C++ packs yet
- **Files:** `runtime/expert-pack-activation.ps1`, `runtime/expert-pack-loader.ps1`, `governance/expert-packs/`

## 12. Ecommerce Pack + Runtime Validation
- **What it does:** 7 business invariants (price, inventory, status, archived, order total, payment idempotency, refund cap), 29 runtime validation tests
- **Status:** ACTIVE (VALIDATED)
- **Evidence:** 29/29 tests PASS in `testbeds/ecommerce-runtime-validation`; activated correctly in BV3-05, BV3-06, BV3-10
- **Limitations:** Not a production ecommerce system; in-memory store; testbed only
- **Files:** `governance/expert-packs/ecommerce/`, `testbeds/ecommerce-runtime-validation/`

## 13. SaaS Tool Pack + Runtime Validation
- **What it does:** 8 business invariants (tenant isolation, quota, subscription, API key, cost recording, billing idempotency, provider key, plan change), 27 runtime validation tests
- **Status:** ACTIVE (VALIDATED)
- **Evidence:** 27/27 tests PASS in `testbeds/saas-runtime-validation`; activated correctly in BV3-07, BV3-08
- **Limitations:** Not a production SaaS system; in-memory store; testbed only
- **Files:** `governance/expert-packs/saas-tool/`, `testbeds/saas-runtime-validation/`

## 14. Production Readiness Checker
- **What it does:** Evaluates projects across 15 dimensions (env vars, database, migrations, seed data, error handling, rollback, monitoring, CI/CD, deployment, etc.) producing a readiness score and level
- **Status:** ACTIVE
- **Evidence:** Readiness scores: ecommerce 60/PARTIAL, SaaS 84/READY_FOR_STAGING, mini-inventory-admin 60/PARTIAL
- **Limitations:** Max level is READY_FOR_PRODUCTION_REVIEW; does not auto-approve production deployment
- **Files:** `runtime/production-readiness-checker.ps1`, `schemas/production-readiness.schema.json`, `governance/production/`

## 15. Benchmark Suite v3
- **What it does:** 10 benchmarks across all project types and expert packs. Measures surface accuracy, risk accuracy, invariant coverage, engine integration, and readiness.
- **Status:** ACTIVE
- **Evidence:** 10/10 PASS (9 runnable, 1 design-only); metrics at 100% across all dimensions
- **Limitations:** Internal benchmark only; not external authority; design-only benchmarks cannot verify runtime behavior
- **Files:** `outputs/R6_1_benchmark_suite_v3.json`, `outputs/R6_1_capability_matrix_v3.json`

## 16. Regression System
- **What it does:** 114 automated tests across 5 testbeds, plus starter consistency, expert pack loader checks, engine smoke tests, and deprecated direction lock checks
- **Status:** ACTIVE
- **Evidence:** 114/114 PASS (products-api 23, mini-inventory-admin 22, ecommerce 29, SaaS 27, node-api-postgres 13)
- **Limitations:** Tests are local validation, not production monitoring; some require running services
- **Files:** `outputs/R7_0_REGRESSION_COMMAND_INDEX.md`, `runtime/starter-type-consistency-check.ps1`
