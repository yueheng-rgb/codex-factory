# Codex Factory v2.0 — Capability Summary

> **Release:** v2.0.0 | **Date:** 2026-07-12 | **NOT a production system**

---

## 1. Bootstrap / Router

**What it does:** Factory Bootstrap enforces pre-build discipline. APP_TYPE_ROUTER classifies
projects into 7 types (fullstack-admin, backend-api, CLI, frontend, threejs-interactive,
content-site, miniapp). STACK_DECISION_GUIDE matches recommended stacks.

**Evidence:** AGENTS.md §0, APP_TYPE_ROUTER.md, STACK_DECISION_GUIDE.md
**Status:** IMPLEMENTED_AND_VERIFIED — frozen since R2.0
**Limitation:** Router handles single-type; Project Surface Model handles multi-surface combos

---

## 2. Canonical Search / Evidence Pack

**What it does:** /api/paas/v4/web_search + search_std is the canonical search path.
Pre-Build Research Gate classifies tasks as P0_MUST_SEARCH or P2_NO_SEARCH_REQUIRED.
Evidence Pack v2 is the only fact carrier. Quality Gate v5 validates evidence.

**Evidence:** runtime/pre-build-research-gate.ps1, runtime/search-gate.ps1, governance/search/
**Status:** IMPLEMENTED_AND_VERIFIED — frozen since R2.3-AB
**Limitation:** Firecrawl is a Reader/Extractor candidate, NOT canonical search

---

## 3. Trusted Memory / Compression Defense

**What it does:** Trusted Project State Store maintains source-of-truth state. Memory Admission
Gate validates context before committing. Compression Summary Verifier detects corrupted
summaries (e.g., deprecated directions, stale metrics). Resume Gate blocks corrupted resumes.

**Evidence:** runtime/trusted-project-state-store.ps1, runtime/memory-admission-gate.ps1,
runtime/compression-summary-verifier.ps1, runtime/stale-context-detector.ps1, runtime/resume-gate.ps1
**Status:** IMPLEMENTED_AND_VERIFIED — 5/5 negative controls PASS
**Limitation:** Keyword-based stale detection; requires manual state initialization

---

## 4. Expert Pack System

**What it does:** Loads domain-specific expert packs (invariants, benchmarks, risk rules).
Activation flow activates packs for a given task based on project surfaces and risk profile.

**Evidence:** runtime/expert-pack-loader.ps1, runtime/expert-pack-activator.ps1,
schemas/expert-pack.schema.json
**Packs:** admin-system (6 invariants), ecommerce (6 invariants), saas-tool (4 invariants)
**Status:** IMPLEMENTED_AND_VERIFIED — 3 packs validated in real mission
**Limitation:** Packs are additive; no conflict resolution between overlapping packs

---

## 5. Ecommerce Pack

**What it does:** Domain invariants for ecommerce: price_non_negative, inventory_non_negative,
stock_delta_must_be_audited, archived_product_not_sellable, admin_required_for_price_change,
status_transition_allowed.

**Evidence:** governance/expert-packs/ecommerce-pack.json, testbeds/products-api/business-invariants.json
**Status:** IMPLEMENTED_AND_VERIFIED — 29/29 runtime tests PASS
**Limitation:** NOT a complete ecommerce system; testbed only

---

## 6. SaaS Tool Pack

**What it does:** Domain invariants for SaaS: tenant_data_isolation, subscription_status_controls_access,
usage_quota_non_negative, quota_decrement_must_be_atomic.

**Evidence:** governance/expert-packs/saas-tool-pack.json, testbeds/saas-runtime-validation/
**Status:** IMPLEMENTED_AND_VERIFIED — 27/27 runtime tests PASS
**Limitation:** NOT a complete SaaS product; Dockerfile/env provided but in-memory store

---

## 7. Admin System Pack

**What it does:** Domain invariants for admin systems: admin_required_for_admin_routes,
role_permission_must_be_enforced, ordinary_admin_cannot_escalate_role,
destructive_action_requires_confirmation, deleted_record_not_listed_by_default,
status_transition_allowed, protected_fields_cannot_be_modified_without_permission,
batch_operation_must_be_scoped, audit_log_required_for_sensitive_actions,
export_requires_permission, import_requires_validation, pagination_limit_enforced,
search_filter_must_be_whitelisted.

**Evidence:** governance/expert-packs/admin-system-pack.json, testbeds/admin-system-runtime-validation/
**Status:** IMPLEMENTED_AND_VERIFIED — 58/58 runtime tests PASS
**Limitation:** NOT a complete production admin dashboard

---

## 8. Business Invariant Engine

**What it does:** Generates structured invariant specs from risk profiles. Invariants are
structured as id + condition + severity + test requirement. Verifier reads invariants to
validate enforcement.

**Evidence:** runtime/business-invariant-engine.ps1, schemas/business-invariant.schema.json
**Status:** IMPLEMENTED_AND_VERIFIED — 16 invariants across 3 packs, all enforced
**Limitation:** Invariant generation is rule-based, not learned

---

## 9. Multi-Agent Worker / Handoff / Integrator

**What it does:** Worker capsules isolate agent scopes. Worker contracts enforce boundaries.
Handoff protocol transfers artifacts. Integrator merges worker outputs. Verified in real mission
with 3 workers, disjoint scopes, zero conflicts.

**Evidence:** governance/contracts/, governance/agent/worker-handoff.schema.json,
missions/inventory-subscription-admin/worker-capsules/
**Status:** IMPLEMENTED_AND_VERIFIED — frozen since R2.6; validated in v2.0-RC mission
**Limitation:** Multi-agent NOT default mode; stress test was simulated

---

## 10. Verifier / Evidence Binding

**What it does:** Verifier checks implementation against design, invariants, tests, and risk gates.
Evidence Binding attaches proof to every gate decision (SATISFIED/MISSING/PARTIAL/NOT_APPLICABLE).
Automated Gate Detector auto-detects tests, invariants, reviewers, audit receipts.

**Evidence:** runtime/verifier.ps1, runtime/automated-gate-detector.ps1, runtime/gate-evidence-binder.ps1
**Status:** IMPLEMENTED_AND_VERIFIED — frozen since R2.14
**Limitation:** Evidence detection is file-based, not semantic

---

## 11. External Engine Registry v2

**What it does:** Manages external tools (semgrep, autocannon, playwright, codeql, k6, firecrawl-reader).
Engine Broker plans, executes, and parses tool output. Tool unavailability is documented as
SKIPPED_WITH_REASON or TOOL_UNAVAILABLE — never fake PASS.

**Evidence:** runtime/engine-registry.ps1, runtime/engine-broker.ps1, outputs/V1_3_ENGINE_RELIABILITY_MATRIX.json
**Status:** IMPLEMENTED_AND_VERIFIED — semgrep/autocannon/playwright available; codeql/k6/firecrawl unavailable
**Limitation:** No cloud/CI engine runner; local-only

---

## 12. Audit Trail / Evidence Hash Chain

**What it does:** Sequential audit ledger with hash chain integrity. Report Drift Detector finds
inconsistencies between reports and ledger. Every significant event is timestamped and chained.

**Evidence:** runtime/audit-ledger.ps1, runtime/evidence-hash-chain.ps1, runtime/report-drift-detector.ps1
**Status:** IMPLEMENTED_AND_VERIFIED — hash chain integrity verified
**Limitation:** Local file only; not distributed

---

## 13. Production Readiness / Production-Like Delivery

**What it does:** Dockerfile, docker-compose.yml, .env.example templates. Readiness assessments
for each project with score and top gaps. READY_FOR_STAGING ≠ READY_FOR_PRODUCTION.

**Evidence:** testbeds/saas-runtime-validation/Dockerfile, outputs/V1_3_TRUST_CLOSURE_REPORT.md
**Status:** IMPLEMENTED_AND_VERIFIED — no project claimed as production-ready
**Limitation:** Templates only; no CI/CD pipeline; no cloud deployment

---

## 14. Benchmark Suite v3

**What it does:** Systematic capability measurement across project types, surfaces, risk levels,
invariants, engines. Capability Closure Matrix maps every capability to evidence.

**Evidence:** CODEX_BENCHMARK_SUITE.md, benchmark/, outputs/V1_3_CAPABILITY_CLOSURE_MATRIX.json
**Status:** IMPLEMENTED_AND_VERIFIED — multi-version benchmark suite
**Limitation:** Design-only benchmarks for types without runnable starters

---

## 15. Real Project Mission Trial

**What it does:** End-to-end Factory pipeline validation on a real mission project
(inventory-subscription-admin) with all 3 Expert Packs active, 16 invariants enforced,
multi-agent execution, compression defense, and full audit trail.

**Evidence:** missions/inventory-subscription-admin/, outputs/V2_0_RC_MISSION_TRIAL_REPORT.md
**Status:** IMPLEMENTED_AND_VERIFIED — 38/38 PASS, 10/10 negative controls BLOCKED
**Limitation:** In-memory store; no real auth; admin-web surface is API-only

---

## 16. Regression System

**What it does:** 210 tests across 7 projects (Products API, Mini Inventory Admin, Ecommerce
Runtime, SaaS Runtime, Admin System Runtime, Node API Starter, Mission Project). All PASS.

**Evidence:** outputs/V2_0_REGRESSION_COMMAND_INDEX.md
**Status:** IMPLEMENTED_AND_VERIFIED — 210/210 ALL PASS
**Limitation:** No CI runner; manual execution only

---

## Files Reference

| Capability | Key Files |
|-----------|----------|
| Bootstrap/Router | AGENTS.md, APP_TYPE_ROUTER.md, STACK_DECISION_GUIDE.md |
| Search | runtime/pre-build-research-gate.ps1, runtime/search-gate.ps1 |
| Trusted Memory | runtime/trusted-project-state-store.ps1, runtime/resume-gate.ps1 |
| Expert Packs | governance/expert-packs/, runtime/expert-pack-loader.ps1 |
| Business Invariants | runtime/business-invariant-engine.ps1 |
| Multi-Agent | governance/contracts/, governance/multi-agent/ |
| Verifier | runtime/verifier.ps1, runtime/gate-evidence-binder.ps1 |
| Engine Broker | runtime/engine-broker.ps1, runtime/engine-registry.ps1 |
| Audit Trail | runtime/audit-ledger.ps1, runtime/evidence-hash-chain.ps1 |
| Regression | All testbeds/, runnable-starters/, pilots/, missions/ |
