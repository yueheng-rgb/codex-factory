# R2.3-O Evidence Search Loop — Main Report

**Phase:** FACTORY-R2.3-O  
**Status:** COMPLETE  
**Verification:** 28/28 PASS | **Simulation:** 12/12 PASS

---

## Overview

R2.3-O transforms Codex Factory's search capability from "one-time pre-task search" to a **Evidence Search Loop** — an iterative, budget-controlled, quality-gated system where search can trigger at any engineering phase: task analysis, implementation, build failure, version uncertainty, dependency introduction, conflicting sources, and verification failure.

Search results flow through: Search Trigger → Adapter → Reader/Extractor → Quality Gate → Research Intake → Evidence Pack → Agent Context. Implementer agents NEVER call providers directly.

---

## Deliverables

| # | Deliverable | Path |
|---|-------------|------|
| 1 | Search Trigger Policy Schema | schemas/search-trigger-policy.schema.json |
| 2 | Need Search Detector | untime/need-search-detector.ps1 |
| 3 | Evidence Pack Schema | schemas/evidence-pack.schema.json |
| 4 | Evidence Pack Builder | untime/evidence-pack-builder.ps1 |
| 5 | Reader/Extractor Schema | schemas/reader-extractor.schema.json |
| 6 | Reader/Extractor Adapter | untime/reader-extractor-adapter.ps1 |
| 7 | Search Loop State Schema | schemas/search-loop-state.schema.json |
| 8 | Iterative Search Loop | untime/iterative-search-loop.ps1 |
| 9 | Provider Comparison Matrix | egistries/search-provider-comparison-registry.jsonl (10 providers) |
| 10 | Simulation (12 scenarios) | untime/tests/r2-3-o-evidence-search-loop-simulation.ps1 |
| 11 | Verification | harness/verification/verify-r2-3-o-evidence-search-loop.ps1 |

---

## Key Architecture

### Search Trigger Policy (10 triggers, 6 non-triggers)
**Triggers:** framework/library/API refs, version/latest, external platforms, build/test failures, new dependencies, insufficient evidence, conflicting sources, security/CVE, user requests latest, low confidence.

**Non-triggers:** pure internal logic, user-provided docs, simple refactor, data structure change, style only, evidence sufficient.

### Evidence Pack
Standardized evidence artifact consumed by agents. Contains: task context, sources (typed + authority + freshness), quality gate verdict, allowed/forbidden actions, usage constraints. Explicitly forbids direct skill registry entry.

### Iterative Loop
6 trigger types: initial_search, error_driven_search, version_uncertainty_search, dependency_introduction_search, conflicting_sources_search, verification_failure_search. Budget: max 5 rounds, 10 sources/round. Anti-infinite-loop: 3 consecutive empty rounds → human escalation.

### Agent Access
- **RSRC-001 / LIB-001:** trigger search, read Evidence Pack
- **ARCH-001 / VER-001:** read Evidence Pack
- **Implementer agents:** read approved Evidence Pack ONLY, **BLOCKED from calling providers**

### Provider Matrix
10 providers compared: GLM, Tavily, Exa, Brave, Jina, Firecrawl, Kimi, Manual, ChatGPT Manual, Dry Run. All external API providers are candidates; only manual + dry_run are active.

---

## Readiness

R2.3-O delivers **Evidence Search Loop MVP** — local-first, dry_run/manual operational, live_api gated. NOT production search capability. No external APIs connected.
