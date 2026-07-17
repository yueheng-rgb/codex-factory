# FACTORY R2.3-AB: Search System Baseline Freeze & Handoff

**Date:** 2026-07-11
**Phase:** R2.3-AB
**Classification:** **A = SEARCH_SYSTEM_BASELINE_FROZEN_AND_HANDOFF_READY**

---

## 1. Baseline Status

| Component | Status | Document |
|-----------|:---:|----------|
| Canonical Search Path | FROZEN | /api/paas/v4/web_search, search_std, provider_search_result |
| Demoted Path | FROZEN | /chat/completions → auxiliary_search_assisted_chat only |
| Architecture | FROZEN | 10-stage pipeline (need_search → … → Verify) |
| Evidence Rule | FROZEN | EP v2 is single fact carrier; Implementer never searches |
| P0/P1/P2 Policy | FROZEN | 4 P0 categories, 4 P1 triggers, 5 P2 triggers + early exit |
| Quality Gate v5 | FROZEN | 11 fatal rules, 5 non-fatal warnings |
| Firecrawl Boundary | FROZEN | Future Reader/Extractor only; NOT canonical search |
| Invariants | FROZEN | 10 never-violate rules |
| Regression Commands | INDEXED | 19 scripts catalogued |
| Phase Ledger | RECORDED | 12 phases from Q to AA |

---

## 2. Frozen Architecture

`
need_search
  → Pre-Build Research Gate v2.0.1
  → Provider Selector
  → ZhipuAI /api/paas/v4/web_search (search_std)
  → Quality Gate v5
  → Research Intake
  → Evidence Pack v2
  → Design
  → Implementer
  → Verify
`

---

## 3. Canonical vs Demoted

| Path | Endpoint | Status | EP Eligible |
|------|----------|:---:|:---:|
| **Canonical** | /api/paas/v4/web_search | Active | Yes (source_origin=provider_search_result) |
| **Demoted** | /chat/completions + web_search tool | Auxiliary only | No (model_text_extraction rejected by QG v5) |

---

## 4. Search Necessity Policy (Frozen)

| Level | Categories | Budget | EP Required |
|-------|------------|--------|:---:|
| **P0_MUST_SEARCH** | Security, External Deps, Architecture, High Rework | 6q/10s | Yes |
| **P1_SHOULD_SEARCH** | UI pattern, community reference, unfamiliar lib | 3q/5s | Optional |
| **P2_NO_SEARCH** | Local bug, style/text, tests, docs, copy-pattern | 0 | No |

---

## 5. Quality Gate v5 Fatal Rules (Frozen)

1. search_invocation_present
2. external_source_url_present
3. source_title_present
4. source_snippet_or_content_present
5. source_origin = provider_search_result (reject model_text_extraction)
6. source != API endpoint URL
7. source != LLM knowledge answer
8. esponse != mock
9. esponse != dry_run
10. 
o_secret_leak
11. evidence_pack_schema_valid

---

## 6. Implementer Boundary (Frozen)

| Allowed Inputs | Forbidden |
|----------------|-----------|
| Evidence Pack v2 | Direct search |
| Design document | Provider API call |
| Project files | Provider raw response |
| | LLM knowledge gap-fill |
| | Chat URL extraction |

---

## 7. Firecrawl Boundary (Frozen)

| Status | NOT ACTIVE |
|--------|-----------|
| Allowed (future) | reader_provider, extractor_provider, crawler_provider, source_enrichment_provider |
| Forbidden | independent_search_agent, canonical_search_replacement, direct_implementer_tool, evidence_pack_bypass |
| Activation Gate | Separate Reader/Extractor Feasibility Spike |

---

## 8. Phase Ledger (R2.3 Search)

| Phase | Classification | Core Achievement |
|-------|:---:|---|
| R2.3-Q | A_PROVIDER | Provider API connected, search not verified |
| R2.3-R | B_UNCORROBORATED | Chat web_search uncorroborated → demoted |
| R2.3-S | A | Pipeline consolidated, 10 fatal gates |
| R2.3-T | A | Pre-Build Research Gate P0/P1/P2 |
| R2.3-U | B_UNCORROBORATED | Real trial but chat URL extraction |
| R2.3-U-BILLING | A_BILLING_CONFIRMED | Billing probe confirmed search_std |
| R2.3-V | A | Canonical /web_search migration |
| R2.3-W | A | Design comparison: search value confirmed |
| R2.3-X | A | Implementation comparison: value confirmed |
| R2.3-Y | A | Doctrine v2.0 optimized (17/17 regression) |
| R2.3-Z | A | Cross-project validation (3 types) |
| R2.3-AA | A | E2E P0 pipeline demo: rate limit |
| **R2.3-AB** | **A** | **Baseline frozen & handoff ready** |

---

## 9. Regression Command Index

| Category | Scripts | Requires Key |
|----------|:---:|:---:|
| Core Search | 4 (gate, QG v5, doctrine regression, canonical adapter) | 1 of 4 |
| Skill Verification | 5 (C–G) | No |
| Sandbox Verification | 4 (J–M) | No |
| Live Demo | 1 (E2E rate limit) | No |
| Quick Smoke | 3 (gate tests) | No |
| **Total** | **17** | |

Full index: outputs/FACTORY_R2_3_AB_REGRESSION_COMMAND_INDEX.ps1

---

## 10. Handoff Readiness

| Criterion | Status |
|-----------|:---:|
| Canonical path unambiguous | ✓ |
| Demoted path documented | ✓ |
| Architecture immutable | ✓ |
| Evidence rule clear | ✓ |
| P0/P1/P2 policy explicit | ✓ |
| QG v5 fatal rules listed | ✓ |
| Implementer boundary enforced | ✓ |
| Firecrawl boundary defined | ✓ |
| Phase ledger complete | ✓ |
| Regression commands indexed | ✓ |
| 10 invariants explicit | ✓ |
| No architecture regression | ✓ |

---

## 11. What This Baseline Enables

- **New Codex sessions** can read this baseline and understand the search subsystem without re-discovering architecture
- **Future phases** can build on frozen constraints without accidentally breaking the pipeline
- **Regression tests** can be run against the frozen baseline to detect architecture drift
- **Handoff to other agents** is unambiguous: the architecture, constraints, and verification commands are documented

---

## 12. What This Baseline Does NOT Cover

- Production deployment (not in scope for R2.3)
- Multi-provider search (deferred)
- Firecrawl/Reader integration (separate spike needed)
- Frontend Tool Trial (deferred)
- Live API key management (user-provided, never stored)

---

## 13. Baseline Files

| File | Description |
|------|-------------|
| outputs/FACTORY_R2_3_AB_SEARCH_SYSTEM_BASELINE.ps1 | Frozen baseline (10 sections, 12 invariants) |
| outputs/FACTORY_R2_3_AB_REGRESSION_COMMAND_INDEX.ps1 | 17 regression commands catalogued |
| outputs/FACTORY_R2_3_AB_BASELINE_FREEZE_REPORT.md | This report |

---

## 14. Recommended Next Step

**Phase:** R2.3-AC — Factory Integration Handoff

With the search subsystem baseline frozen, the next step is to integrate it into the broader Factory workflow:
1. Wire the Search Baseline into the Factory Bootstrap flow (AGENTS.md → search necessity check)
2. Add search gate check to Project Expertise Flow (before Design stage)
3. Document how new agents/Codex sessions consume the frozen baseline

**Do NOT:**
- Unfreeze the baseline without explicit phase
- Reintroduce demoted paths as canonical
- Let Implementer search
- Restore Search Agent or Dual Channel

---

**secretSafetyResult:** PASS
**keyLeaked:** false
**baselineStatus:** FROZEN_AND_HANDOFF_READY
**phasesRecorded:** 13 (Q through AB)
