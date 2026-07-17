# FACTORY-V05-R1-INTEGRATION-PLAN — Phase Report

> **Phase:** FACTORY-V05-R1-INTEGRATION-PLAN
> **Date:** 2026-06-29
> **Status:** COMPLETE (planning only)
> **Predecessor:** FACTORY-PROJECT-LIFECYCLE-0 PASS (263/263 theory baseline)

---

## Executive Summary

This phase plans the integration of 7 completed theory phases (263 verifier checks, ~350 files) into a v0.5-R1 package. No package was created. No v0.5 zip was modified. No v0.6. No cloud. No real validation.

**Decision:** Proceed to FACTORY-V05-R1-INTEGRATION-0 only after user approval.

---

## A. Scope Lock

- **This is integration planning only** — no package creation, no v0.5 modification, no v0.6.
- **Goal:** Map 7 theory phases into a safe v0.5-R1 integration plan with file map, CLI plan, smoke plan, risk register, decision gates.
- **Excluded:** real project validation, cloud deployment, production, Native Build Pro default, multi-agent auto-start.

## B. Theory Baseline Inventory

| # | Phase | Checks | Category | R1 |
|---|-------|--------|----------|-----|
| 1 | FACTORY-DEFAULT-WORKFLOW-0 | 60 | WORKFLOW_DEFAULT | MUST |
| 2 | FACTORY-PROJECT-ISOLATION-0 | 48 | GOVERNANCE_RULE | MUST |
| 3 | FACTORY-STATE-DASHBOARD-0 | 38 | CLI_COMMAND | MUST |
| 4 | FACTORY-RECOVERY-0 | 28 | SCRIPT_RUNTIME | MUST |
| 5 | FACTORY-MULTI-AGENT-ORCHESTRATION-1 | 30 | POLICY | MUST |
| 6 | FACTORY-EVIDENCE-TAXONOMY-0 | 29 | GOVERNANCE_RULE | MUST |
| 7 | FACTORY-PROJECT-LIFECYCLE-0 | 30 | GOVERNANCE_RULE | MUST |

**Total:** 263 checks. All 7 phases MUST integrate. None deferred.

## C. Feature Selection

### Must Integrate (13)
- Default Startup Protocol
- Multi-Agent Decision Gate
- Project Path Handoff Contract
- Natural Language Cleanup Contract
- Project Identity / Registry
- Mount Isolation Rules
- Cleanup Isolation Rules
- Agent Ledger projectId requirement
- State Dashboard prototype
- Recovery scan MVP
- Evidence Taxonomy validator MVP
- Lifecycle state model
- Lifecycle operation permission matrix

### Should Integrate (7)
- Role profiles, agent contract/handoff schemas, dashboard templates, recovery prompts, lifecycle user commands, evidence record schema, state dashboard fixtures

### Deferred
- Web UI, cloud update/distribution, production deployment, v0.6 feature expansion, broad real validation until R1 package exists

## D. File Integration Map

~80 files mapped across 7 phases into R1 target paths: `governance/`, `schemas/`, `scripts/`, `templates/`, `factory-*/`, `harness/`. Full map in `FACTORY_V05_R1_INTEGRATION_PLAN_D_FILE_INTEGRATION_MAP_REPORT.md`.

## E. CLI Integration Plan

- Canonical CLI name: `factory.ps1` (alias `factoryctl.ps1`)
- New R1 commands: `factory state`, `factory recover`, `factory evidence check`, `factory cleanup plan`, `factory lifecycle`
- Existing v0.5 commands preserved: Build Lite, Phase Close, Package QA, Security/Deploy Gate
- See `FACTORY_V05_R1_INTEGRATION_PLAN_E_CLI_INTEGRATION_PLAN_REPORT.md`

## F–I. Domain Integration

| Domain | Report | Key Rules |
|--------|--------|-----------|
| Default Workflow | F | Startup Protocol as Step 0; cleanup PLAN-first; path handoff mandatory |
| Multi-Agent | G | On-demand roles; Integrator sole merger; projectId mandatory; never auto-start |
| Isolation/Lifecycle/Cleanup | H | Identity check at mount; lifecycle governs ops; cleanup scoped; foreign blocked |
| Dashboard/Recovery/Evidence | I | Dashboard shows state+evidence; recovery scan; validator blocks overclaim |

## J. Smoke & Verification Plan

14-step verification ladder: file inclusion → manifest/hash → extraction → CLI help → dashboard fixture → cleanup PLAN → recovery plan → evidence validator → lifecycle permission → multi-agent contract → forbidden content → overclaim → negative controls → verifier.

## K. Risk Register

| Risk | Severity | Mitigation | Blocker? |
|------|----------|------------|----------|
| Too many files without CLI discoverability | MEDIUM | CLI help + dashboard index | No |
| CLI name mismatch | HIGH | Canonical name lock in manifest | Yes |
| Prototype scripts not production-hardened | MEDIUM | Label as fixture-level in R1 | No |
| User confusion v0.5 vs v0.5-R1 | MEDIUM | Clear version manifest, changelog | No |
| Theory features overclaimed as validated | HIGH | Evidence taxonomy enforced; caveat labels | Yes |
| Dashboard/recovery/evidence scripts still fixture-level | LOW | Honest labeling; no E6+ claims | No |
| Lifecycle/delete commands misunderstood | MEDIUM | User confirmation required for destructive ops | No |
| Multi-agent role profiles overcomplicate simple tasks | LOW | Build Lite remains default for small projects | No |

## L. R1 Decision Gate

**Prerequisites to proceed to R1 integration:**
1. All target files mapped ✅
2. CLI canonical name chosen (`factory.ps1`) ✅
3. Required modules categorized ✅
4. Smoke plan defined ✅
5. Forbidden content rules carried forward ✅
6. No v0.6 scope creep ✅
7. **User approves proceeding to R1 integration** ⏳

## M. Strategy Decision

1. **Is v0.5-R1 integration justified?** Yes — 263 theory checks across 7 phases warrant a structured integration pass.
2. **Which features included?** 13 Must + 7 Should (see Section C).
3. **Which deferred?** Web UI, cloud, production, v0.6.
4. **Next step:** FACTORY-V05-R1-INTEGRATION-0 (after user approval).
5. **What should NOT be done now?** Create R1 zip, modify v0.5, start v0.6, real validation, cloud, deploy, auto-start multi-agent.

## N. Negative Controls

35 negative controls executed — see `FACTORY_V05_R1_INTEGRATION_PLAN_NEGATIVE_CONTROLS_REPORT.md`. 0 gaps.

## O. Verifier

Verifier script: `scripts/factory-v05-r1-integration-plan-verify.ps1`
Result: All 26 checks PASS.

---

## Closure

FACTORY-V05-R1-INTEGRATION-PLAN **PASS** — all 7 theory phases mapped into a safe v0.5-R1 integration plan with file/CLI/smoke/risk/decision gates. v0.5 preserved. v0.6/cloud/real validation avoided. User approval required before actual R1 integration.

**Recommended next:** FACTORY-V05-R1-INTEGRATION-0 (only after user approval).
