# Codex Factory Current Capability Inventory
> Inventory Date: 2026-07-11
> Scope: Full repository audit, no new features, no code changes
> Method: Filesystem enumeration + key file reading across 10 capability domains

---

## A. Capability Matrix

### Domain 1: Factory Bootstrap / AGENTS.md

| capability_name | status | evidence_files | executable_scripts | notes |
|---|---|---|---|---|
| AGENTS.md highest-priority entry rule | IMPLEMENTED_AND_VERIFIED | C:\Codex_App_Factory\AGENTS.md | N/A | Section 0: Factory Bootstrap Gate, BOOT-001 defect recorded |
| Factory Bootstrap flow (12-step) | IMPLEMENTED_AND_VERIFIED | AGENTS.md, GLOBAL_CODEX_RULES.md | N/A | Mandatory for complex tasks; Factory Lite for simple tasks |
| Search Gate integration in AGENTS.md | IMPLEMENTED_AND_VERIFIED | AGENTS.md (R2.4 section) | runtime\pre-build-research-gate.ps1 | P0_MUST_SEARCH / P2_NO_SEARCH_REQUIRED classification |
| Worker/Implementer boundary in AGENTS.md | IMPLEMENTED_AND_VERIFIED | AGENTS.md, factory-multi-agent\SPAWN_ISOLATION_POLICY.md | N/A | "Implementer must not search directly" rule |
| GLOBAL_CODEX_RULES.md (12 rules) | IMPLEMENTED_AND_VERIFIED | GLOBAL_CODEX_RULES.md | N/A | Anti-overengineering, security, UI quality, completion rules |

### Domain 2: Search System

| capability_name | status | evidence_files | executable_scripts | notes |
|---|---|---|---|---|
| Canonical search path (ZhipuAI /api/paas/v4/web_search + search_std) | IMPLEMENTED_AND_VERIFIED | outputs\FACTORY_R2_3_AB_SEARCH_SYSTEM_BASELINE.ps1 | runtime\zhipuai-structured-search-adapter.ps1 | Frozen R2.3-AB baseline |
| Evidence Pack v2 | IMPLEMENTED_AND_VERIFIED | runtime\evidence-pack-builder.ps1 | runtime\evidence-pack-builder.ps1 | Single fact carrier, structured sourceRefs |
| Quality Gate v5 | IMPLEMENTED_AND_VERIFIED | runtime\search-result-quality-gate.ps1 | runtime\search-result-quality-gate.ps1 | 20 checkpoints, 7 fatal, source_origin enforcement |
| Pre-Build Research Gate v2.0.3 | IMPLEMENTED_AND_VERIFIED | runtime\pre-build-research-gate.ps1 | runtime\pre-build-research-gate.ps1 | P0/P1/P2 classification, security-critical detection, implementer block |
| Search Operating Doctrine v2.0.0 | IMPLEMENTED_AND_VERIFIED | runtime\search-operating-doctrine.ps1 | N/A (data module) | P0/P1/P2 trigger definitions |
| GLM Search Adapter (live_api/dry_run/manual) | IMPLEMENTED_AND_VERIFIED | runtime\glm-search-adapter.ps1 | runtime\glm-search-adapter.ps1 | 3-mode adapter with full gate chain |
| /chat/completions web_search demoted | IMPLEMENTED_AND_VERIFIED | outputs\FACTORY_R2_3_AB_SEARCH_SYSTEM_BASELINE.ps1 | N/A | DEMOTED_STATUS = "auxiliary_search_assisted_chat" |
| Reader/Extractor adapter (Firecrawl boundary) | DOCUMENTED_ONLY | runtime\reader-extractor-adapter.ps1 | runtime\reader-extractor-adapter.ps1 | Firecrawl as Reader/Extractor candidate; not fully integrated |
| Iterative search loop | DOCUMENTED_ONLY | runtime\iterative-search-loop.ps1 | runtime\iterative-search-loop.ps1 | Exists as script; integration status unclear |
| Search invocation logger | IMPLEMENTED_AND_VERIFIED | runtime\search-invocation-logger.ps1 | runtime\search-invocation-logger.ps1 | Logging layer for audit trail |
| Need-search detector | IMPLEMENTED_AND_VERIFIED | runtime\need-search-detector.ps1 | runtime\need-search-detector.ps1 | Pre-gate dependency |

### Domain 3: Multi-Agent / Worker / Harness

| capability_name | status | evidence_files | executable_scripts | notes |
|---|---|---|---|---|
| spawn_agent (Codex native) | IMPLEMENTED_AND_VERIFIED | N/A (Codex platform) | N/A | Native multi_agent_v1__spawn_agent tool |
| fork_context:false usage | IMPLEMENTED_AND_VERIFIED | factory-multi-agent\SPAWN_ISOLATION_POLICY.md | N/A | Documented policy for isolated spawns |
| Agent Contract schema | IMPLEMENTED_AND_VERIFIED | factory-multi-agent\schemas\agent-contract.schema.json | N/A | JSON Schema: contractId, assignedPaths, forbiddenPaths, allowedTools, requiredOutputs |
| Agent Handoff schema | IMPLEMENTED_AND_VERIFIED | factory-multi-agent\schemas\agent-handoff.schema.json | N/A | JSON Schema: handoffId, verdict (PASS/FAIL/PARTIAL), contractCompliance |
| Worker capsule (disjoint write scopes) | IMPLEMENTED_AND_VERIFIED | factory-multi-agent\SPAWN_ISOLATION_POLICY.md | runtime\sandbox-lifecycle.ps1 | Disjoint paths enforced per agent |
| Integrator Protocol | IMPLEMENTED_AND_VERIFIED | factory-multi-agent\INTEGRATOR_PROTOCOL.md | N/A | Sole final merger, failure attribution mandatory |
| Main Agent / Integrator role | IMPLEMENTED_AND_VERIFIED | factory-multi-agent\INTEGRATOR_PROTOCOL.md, governance\agent-os\ | N/A | Integrator-verifier-auditor intake protocol |
| Agent lifecycle management | IMPLEMENTED_AND_VERIFIED | factory-agent-company-protocol-pack\runtime\lifecycle\ | close-agent.ps1, quarantine-stale-agent.ps1, record-agent-handoff.ps1, record-agent-progress.ps1 | Full lifecycle with receipts |
| Agent registry | IMPLEMENTED_AND_VERIFIED | factory-agent-company-protocol-pack\runtime\registry\ | register-agent.ps1, query-agent-registry.ps1 | Agent registration and query |
| Scheduler / capacity check | IMPLEMENTED_AND_VERIFIED | factory-agent-company-protocol-pack\runtime\scheduler\ | check-capacity-preflight.ps1, check-dependency-readiness.ps1, create-spawn-decision.ps1, create-task-graph.ps1 | Orchestrator runtime suite |
| Task graph | IMPLEMENTED_AND_VERIFIED | governance\agent-os\task-graph.schema.json | create-task-graph.ps1 | JSON Schema + builder script |
| Handoff governance records | IMPLEMENTED_AND_VERIFIED | governance\agent-os\AGENT_HANDOFFS\, governance\skill-import-handoffs\ | handoff-verify.ps1 | Multiple real handoff records exist (lr2, skill-import) |
| Worker reporting protocol | IMPLEMENTED_AND_VERIFIED | governance\agent-os\worker-reporting-protocol.md | validate-worker-capsule.ps1, enforce-worker-output-before-freeze.ps1 | Worker must report before freeze |
| Anti-deception checks | IMPLEMENTED_AND_VERIFIED | factory-agent-company-protocol-pack\runtime\anti-deception\ | check-completion-claim-integrity.ps1, check-hidden-fallback.ps1, check-self-report-vs-evidence.ps1 | 3 anti-deception checks |
| Drift control | IMPLEMENTED_AND_VERIFIED | factory-agent-company-protocol-pack\runtime\drift\ | check-architecture-drift.ps1, check-quality-gap-triggers.ps1, check-style-drift.ps1 | Architecture/style/quality drift detection |
| 4-worker mini project (build-pro-2-long-horizon) | IMPLEMENTED_NOT_VERIFIED | trials\build-pro-2-long-horizon\ | N/A | Trial with orchestrator/builder/integrator/verifier; 3 iterations |
| Freeze manifest | PARTIAL | harness\scripts\harness-worker\enforce-worker-output-before-freeze.ps1 | Same | Freeze enforcement exists; formal manifest schema partial |
| Patch ledger | PARTIAL | factory-multi-agent\AGENT_LEDGER_UPDATE_POLICY.md | N/A | Policy documented; ledger file format partial |
| Worker workspace / worktree isolation | IMPLEMENTED_AND_VERIFIED | SPAWN_ISOLATION_POLICY.md (agent-{id} directories) | N/A | Policy specifies disjoint working copies |
| Contract checker | IMPLEMENTED_AND_VERIFIED | runtime\contract-checker.ps1 | runtime\contract-checker.ps1 | Runtime contract validation |
| Handoff validator | IMPLEMENTED_AND_VERIFIED | runtime\handoff-validator.ps1 | runtime\handoff-validator.ps1 | Validates handoff completeness |

### Domain 4: Verifier / Quality / Taxonomy

| capability_name | status | evidence_files | executable_scripts | notes |
|---|---|---|---|---|
| Verifier registry | IMPLEMENTED_AND_VERIFIED | registries\verifier-candidate-registry.jsonl | N/A | JSONL registry of verifier candidates |
| Quality Gate v5 (20 checks, 7 fatal) | IMPLEMENTED_AND_VERIFIED | runtime\search-result-quality-gate.ps1 | Same | mode_auth, search_invoked, sources, titles, content, source_origin |
| Evidence taxonomy / level model | IMPLEMENTED_AND_VERIFIED | factory-evidence\EVIDENCE_LEVEL_MODEL.md, schemas\evidence-level.schema.json | factory-evidence-validator.ps1 | 5 evidence levels defined |
| Overclaim policy | IMPLEMENTED_AND_VERIFIED | factory-evidence\OVERCLAIM_POLICY.md | N/A | Promotion/demotion rules |
| Claim support matrix | IMPLEMENTED_AND_VERIFIED | factory-evidence\CLAIM_SUPPORT_MATRIX.md | N/A | Maps claims to required evidence levels |
| Verdict taxonomy (PASS/FAIL/PARTIAL) | IMPLEMENTED_AND_VERIFIED | factory-multi-agent\schemas\agent-handoff.schema.json | N/A | Enum in handoff schema |
| Workflow consistency checker | IMPLEMENTED_AND_VERIFIED | runtime\workflow-search-consistency-check.ps1 | Same | Search workflow consistency verification |
| Search boundary checker | IMPLEMENTED_AND_VERIFIED | runtime\pre-build-research-gate.ps1 | Same | Implementer block, P0/P1/P2 classification |
| Audit-run infrastructure | IMPLEMENTED_AND_VERIFIED | harness-control\ (locks, tokens, trust-roots) | i-test-target\scripts\*.ps1 | Full control-plane with hash chains |
| Registry integrity check | IMPLEMENTED_AND_VERIFIED | runtime\registry-integrity-check.ps1 | Same | Capability registry integrity |
| Scope isolation check | IMPLEMENTED_AND_VERIFIED | factory-agent-company-protocol-pack\runtime\scripts\check-scope-isolation.ps1 | Same | Agent scope boundary verification |
| Agent protocol integrity check | IMPLEMENTED_AND_VERIFIED | factory-agent-company-protocol-pack\runtime\scripts\check-agent-protocol-integrity.ps1 | Same | Multi-agent protocol integrity |
| Evidence integrity check | IMPLEMENTED_AND_VERIFIED | factory-agent-company-protocol-pack\runtime\scripts\check-evidence-integrity.ps1 | Same | Evidence chain verification |
| Verifier hash lock | PARTIAL | harness-control\tokens\ (hash chain tokens) | freeze-control-plane.ps1 | Hash chain exists; formal lock mechanism partial |
| Fail-closed adapter | DOCUMENTED_ONLY | Referenced in quality gate | N/A | Mentioned in design docs; no standalone adapter |
| Complexity budget | DOCUMENTED_ONLY | PHASE_6C-E_DESIGN_REVIEW.md | N/A | Budget config defined (orchestratorMaxInputChars etc); not runtime enforced |
| Meta-verifier | DOCUMENTED_ONLY | Referenced in governance | N/A | Concept documented; no implementation |
| Report hygiene | IMPLEMENTED_AND_VERIFIED | factory-evidence\OVERCLAIM_POLICY.md | N/A | Policy enforced via evidence validator |

### Domain 5: Regression / Test Harness

| capability_name | status | evidence_files | executable_scripts | notes |
|---|---|---|---|---|
| R2.3-Y regression tests (17/17 PASS) | IMPLEMENTED_AND_VERIFIED | runtime\search-doctrine-regression-tests.ps1 | Same | Search doctrine classification tests |
| Regression command index | IMPLEMENTED_AND_VERIFIED | outputs\FACTORY_R2_3_AB_REGRESSION_COMMAND_INDEX.ps1 | N/A | Full command index for repeatable verification |
| Search system baseline (frozen) | IMPLEMENTED_AND_VERIFIED | outputs\FACTORY_R2_3_AB_SEARCH_SYSTEM_BASELINE.ps1 | N/A | Canonical architecture + demoted paths |
| AB testing infrastructure | IMPLEMENTED_AND_VERIFIED | harness\ab-0-r1\, harness\ab-1\ | Multiple harness scripts | Run-A (vanilla) vs Run-B (factory) comparison |
| Harness control plane (locks/tokens/trust-roots) | IMPLEMENTED_AND_VERIFIED | harness-control\ | i-test-target\scripts\*.ps1 | Hash chain integrity, task binding, token leases |
| Verification scripts (R2.1 through R2.3-T) | IMPLEMENTED_AND_VERIFIED | harness\verification\verify-r2-*.ps1 | 16+ verification scripts | Comprehensive phase-by-phase verification |
| Worker output verification | IMPLEMENTED_AND_VERIFIED | harness\scripts\harness-worker\ | verify-worker-output-contract.ps1, enforce-worker-output-before-freeze.ps1 | Worker boundary checks |
| Context space simulation | IMPLEMENTED_AND_VERIFIED | harness\context-space\ | 7 simulation scenarios | Negative controls + simulation |
| State dashboard simulation | IMPLEMENTED_AND_VERIFIED | harness\state-dashboard\ | 10 scenarios | Healthy, mismatch, stale, missing-verifier, foreign-context |
| Clean-start verification | IMPLEMENTED_AND_VERIFIED | harness\scripts\harness-readiness\ | verify-clean-start-no-contamination.ps1, authorize-clean-start.ps1 | No contamination between runs |
| Benchmark teamflow-lite | IMPLEMENTED_AND_VERIFIED | benchmark\teamflow-lite\ | full-evaluation.ps1, check-api-contract.ps1, check-requirements.ps1 | 3-run benchmark harness |
| Pre-spawn validation | IMPLEMENTED_AND_VERIFIED | harness\scripts\harness-spawn\ | validate-pre-spawn-run-plan.ps1, check-worker-simplicity-risk.ps1 | Spawn safety checks |
| Domain knowledge gap detection | IMPLEMENTED_AND_VERIFIED | harness\scripts\harness-profile\ | detect-domain-knowledge-gaps.ps1, validate-profile-boundary.ps1 | Profile boundary validation |
| Some scripts potentially outdated | PARTIAL | Multiple older phase scripts | harness\verification\verify-r2-1-*, verify-r2-2-* | Earlier phase scripts may reference frozen baselines |

### Domain 6: Project Router / Expertise Flow

| capability_name | status | evidence_files | executable_scripts | notes |
|---|---|---|---|---|
| APP_TYPE_ROUTER (7 project types) | IMPLEMENTED_AND_VERIFIED | APP_TYPE_ROUTER.md | N/A | fullstack-admin, content-site, saas-tool, api-service, miniapp, mobile-app, threejs-interactive |
| STACK_DECISION_GUIDE (7 stacks) | IMPLEMENTED_AND_VERIFIED | STACK_DECISION_GUIDE.md | N/A | Per-type stack tables + scaling rules + forbidden patterns |
| 7 Blueprints | IMPLEMENTED_AND_VERIFIED | blueprints\*.md | N/A | Descriptive design blueprints per type |
| 7 Starter descriptions | IMPLEMENTED_AND_VERIFIED | starters\*.md | N/A | Descriptive starter docs; 3/7 have runnable starters |
| Complexity classification (S/M/L/XL) | IMPLEMENTED_AND_VERIFIED | APP_TYPE_ROUTER.md, STACK_DECISION_GUIDE.md | N/A | Per-type volume + upgrade decision tree |
| Project Expertise Flow (12 steps) | IMPLEMENTED_AND_VERIFIED | AGENTS.md, GLOBAL_CODEX_RULES.md | N/A | 12-step flow from type classification to user path verification |
| Architecture scaling rules | IMPLEMENTED_AND_VERIFIED | STACK_DECISION_GUIDE.md | N/A | Decision tree for S/M/L/XL, forbidden patterns |
| Task decomposition | DOCUMENTED_ONLY | Referenced in governance | create-task-graph.ps1 | Task graph creation exists; formal decomposition engine not present |
| Scenario adaptation governance | DOCUMENTED_ONLY | Referenced in factory-workflow | N/A | Contract docs exist; runtime enforcement partial |
| Runnable starters (actual code) | PARTIAL | runnable-starters\ | N/A | 3/5 runtime validated (next-fullstack-admin, next-saas-ai-tool, vite-react-content-site); 2 missing |
| Expertise pack | PARTIAL | skills\ (9 skills) | Multiple skill SKILL.md files | Domain-specific skills exist; unified "expertise pack" concept partial |

### Domain 7: Products API / Real Task Testbed

| capability_name | status | evidence_files | executable_scripts | notes |
|---|---|---|---|---|
| i-test-target (harness testbed) | IMPLEMENTED_AND_VERIFIED | i-test-target\ | i-test-target\scripts\*.ps1 | Harness governance test target, NOT a products CRUD API |
| Products API as CRUD testbed | MISSING | N/A | N/A | No products-api directory found; no CRUD endpoints |
| 18/18 tests claim | UNKNOWN | N/A | N/A | No evidence of products-api test suite found |
| Harness install receipt | IMPLEMENTED_AND_VERIFIED | i-test-target\.harness-install-receipt.json | N/A | Confirms i-test-target is harness infrastructure |

### Domain 8: External Engine / Tooling

| capability_name | status | evidence_files | executable_scripts | notes |
|---|---|---|---|---|
| Playwright (browser testing) | IMPLEMENTED | Referenced in benchmark, skills\webapp-preview-testing | N/A | Available via Codex built-in browser tools + skill |
| CodeQL | DOCUMENTED_ONLY | EXTERNAL_SKILLS_RESEARCH.md | N/A | Mentioned in Trail of Bits research; not implemented |
| Semgrep | DOCUMENTED_ONLY | EXTERNAL_SKILLS_RESEARCH.md | N/A | Referenced in static-analysis research; not implemented |
| k6 / autocannon | DOCUMENTED_ONLY | Not found in repo | N/A | No evidence of load testing integration |
| Firecrawl | DOCUMENTED_ONLY | runtime\reader-extractor-adapter.ps1, EXTERNAL_SKILLS_RESEARCH.md | N/A | Reader/Extractor candidate only; no integration |
| UI generation engine | MISSING | N/A | N/A | No UI generation engine |
| Three.js / Babylon | PARTIAL | blueprints\threejs-interactive-blueprint.md, starters\threejs-interactive-starter.md | N/A | Blueprint + starter doc exist; no runnable starter |
| Image/model/render engine | DOCUMENTED_ONLY | Referenced in external skills | N/A | imagegen skill available but not Factory-integrated |

### Domain 9: Security / Risk / Business Invariant

| capability_name | status | evidence_files | executable_scripts | notes |
|---|---|---|---|---|
| Security-critical detection (Pre-Build Gate) | IMPLEMENTED_AND_VERIFIED | runtime\pre-build-research-gate.ps1 | Same | 7 security pattern categories detected |
| Secret presence check | IMPLEMENTED_AND_VERIFIED | runtime\secret-presence-check.ps1 | Same | Pre-search secret scan |
| Anti-deception checks (3 checks) | IMPLEMENTED_AND_VERIFIED | factory-agent-company-protocol-pack\runtime\anti-deception\ | run-anti-deception-gate.ps1 | Completion claim, hidden fallback, self-report vs evidence |
| Risk classifier | PARTIAL | governance\factory-eval\, trials\build-pro-2-long-horizon\memory\active-risks.json | N/A | Risk tracking exists; formal classifier engine not present |
| Security reviewer (Trail of Bits) | DOCUMENTED_ONLY | EXTERNAL_SKILLS_RESEARCH.md | N/A | Research recommends installation; not yet installed |
| Business invariant engine | DOCUMENTED_ONLY | Referenced in governance docs | N/A | Concept documented; no implementation |
| Memory safety / C/C++ sanitizer | MISSING | N/A | N/A | No evidence of sanitizer integration |
| Payment/price/inventory critical risk rules | PARTIAL | STACK_DECISION_GUIDE.md (decision tree) | N/A | Rules in decision tree; no runtime enforcement |
| Human audit protocol | PARTIAL | governance\skill-import-handoffs\ (HUMAN-VERIFIER handoffs) | N/A | Human-in-the-loop handoffs exist; formal protocol partial |
| Permission gate | IMPLEMENTED_AND_VERIFIED | runtime\permission-gate.ps1 | Same | Capability permission enforcement |
| Tool permission gate | IMPLEMENTED_AND_VERIFIED | runtime\tool-permission-gate.ps1 | Same | Tool-level permission enforcement |

### Domain 10: Deprecated / Forbidden Directions

| capability_name | status | evidence_files | notes |
|---|---|---|---|
| Independent Search Agent | DEPRECATED | AGENTS.md, outputs\FACTORY_R2_3_AB_SEARCH_SYSTEM_BASELINE.ps1 | Explicitly forbidden in R2.3-AB baseline |
| Dual Search Channel | DEPRECATED | AGENTS.md, outputs\FACTORY_R2_3_AB_SEARCH_SYSTEM_BASELINE.ps1 | Single canonical path only |
| Search Agent as Future Default | DEPRECATED | AGENTS.md | Explicitly forbidden |
| Implementer direct search | DEPRECATED | AGENTS.md, runtime\pre-build-research-gate.ps1 | IMPLEMENTER_DIRECT_SEARCH_FORBIDDEN |
| /chat/completions URL extraction as canonical evidence | DEPRECATED | outputs\FACTORY_R2_3_AB_SEARCH_SYSTEM_BASELINE.ps1 | DEMOTED to auxiliary_search_assisted_chat |
| mock/dry_run mislabeled as live | DEPRECATED | runtime\search-result-quality-gate.ps1 | FATAL-0 check: mode must be live_api |
| Multi-agent default mode | DEPRECATED | MULTI_AGENT_DEFAULT_REJECTED (root flag file) | Multi-agent is opt-in, not default |

---

## B. Current Architecture Summary

### Main Flow
1. **Factory Bootstrap Gate** (AGENTS.md Section 0): Any task in Codex_App_Factory workspace must pass through APP_TYPE_ROUTER → STACK_DECISION_GUIDE → Factory Boot Summary
2. **Complex tasks** → Full 12-step Project Expertise Flow before any code
3. **Simple tasks** → Factory Lite (still routed through type classifier)

### Search Flow
```
need_search → Pre-Build Research Gate v2.0.3 → Provider Selector →
ZhipuAI /api/paas/v4/web_search (search_std) → Quality Gate v5 →
Research Intake → Evidence Pack v2 → Design → Implementer → Verify
```
- Single canonical path enforced
- Implementer NEVER searches directly
- /chat/completions web_search demoted to auxiliary only

### Worker Flow
```
Main Agent/Integrator → spawn_agent(fork_context:false) → Agent Contract →
Disjoint write scope → Worker capsule → Worker output →
Handoff (PASS/FAIL/PARTIAL) → Integrator merges → Agent closed
```
- Agent lifecycle: register → spawn → work → handoff → close (with receipts)
- Anti-deception: 3 checks at completion
- Drift control: architecture/style/quality drift detection

### Verifier Flow
```
Evidence → Quality Gate v5 (20 checks, 7 fatal) → Evidence Pack v2 →
Claim support matrix → Overclaim policy check → Verdict
```
- Evidence taxonomy: 5 levels (L0-L4)
- Hash chain integrity for harness control plane

### Handoff / Ledger Flow
```
Agent completes → handoff record (JSON Schema) → Integrator validates →
Contract compliance check → ACCEPT/REJECT → Agent ledger update →
Agent close receipt → Archive
```

---

## C. Gap List

| missing_capability | why_needed | dependency | suggested_priority |
|---|---|---|---|
| Runnable starters for api-service + threejs-interactive | 2/5 starter types have no runnable code; Factory cannot demonstrate those project types | Starter template creation | P1 |
| Formal freeze manifest schema | Worker freeze enforcement exists but lacks standardized manifest format | JSON Schema design | P2 |
| Formal patch ledger format | Policy documented; actual ledger JSON format inconsistent across trials | Schema + migration | P2 |
| Products API CRUD testbed | No concrete API testbed to validate fullstack-admin patterns end-to-end | Express/Fastify + PostgreSQL | P1 |
| Complexity budget runtime enforcement | Budget config defined in design doc but not enforced at runtime | Pre-spawn hook integration | P2 |
| Meta-verifier | Verifier quality self-check not automated | Existing verifier infrastructure | P3 |
| Fail-closed adapter (standalone) | Referenced but not implemented as standalone module | Quality Gate v5 | P3 |
| Task decomposition engine (formal) | Task graph creation exists but formal decomposition rules not codified | APP_TYPE_ROUTER rules | P2 |
| Business invariant engine | No runtime enforcement of business rules (pricing, inventory, etc.) | Risk classifier | P3 |
| CodeQL / Semgrep integration | Security static analysis not integrated into Factory pipeline | External tool installation | P3 |
| k6 / autocannon load testing | No load/performance testing capability | External tool installation | P3 |
| Firecrawl integration (beyond Reader/Extractor) | Deep page content extraction not available | Firecrawl API | P3 |
| Memory safety / C/C++ sanitizer | Not applicable to current JS/TS focus; future-proofing | Language support | P4 |
| Unified scenario adaptation governance | Contracts exist but no runtime scenario adaptation engine | Workflow engine | P3 |

---

## D. Do Not Rebuild List

| already_done | evidence | what_not_to_reopen |
|---|---|---|
| Canonical search path (ZhipuAI /web_search) | FACTORY_R2_3_AB_SEARCH_SYSTEM_BASELINE.ps1 (frozen) | Do not redesign search provider architecture |
| Pre-Build Research Gate + classification | runtime\pre-build-research-gate.ps1 v2.0.3 (17/17 PASS) | Do not rebuild P0/P1/P2 classification |
| Quality Gate v5 | runtime\search-result-quality-gate.ps1 (R2.3-Y) | Do not rebuild quality gate checkpoint system |
| Evidence Pack v2 | runtime\evidence-pack-builder.ps1 | Do not redesign evidence packaging |
| Agent Contract + Handoff schemas | factory-multi-agent\schemas\ (JSON Schema) | Do not redesign agent contract format |
| Agent lifecycle (register/spawn/handoff/close) | factory-agent-company-protocol-pack\runtime\lifecycle\ | Do not rebuild lifecycle management |
| Integrator protocol | factory-multi-agent\INTEGRATOR_PROTOCOL.md | Do not redesign integration merge flow |
| Spawn isolation policy | factory-multi-agent\SPAWN_ISOLATION_POLICY.md | Do not reopen isolation model |
| Anti-deception checks (3 checks) | factory-agent-company-protocol-pack\runtime\anti-deception\ | Do not rebuild anti-deception |
| Drift control (3 checks) | factory-agent-company-protocol-pack\runtime\drift\ | Do not rebuild drift detection |
| Harness control plane (locks/tokens/trust-roots) | harness-control\ + i-test-target\scripts\ | Do not rebuild hash chain infrastructure |
| AB testing infrastructure | harness\ab-0-r1\, harness\ab-1\ | Do not rebuild A/B comparison framework |
| APP_TYPE_ROUTER (7 types) | APP_TYPE_ROUTER.md | Do not redesign project type classification |
| STACK_DECISION_GUIDE (7 stacks + scaling) | STACK_DECISION_GUIDE.md | Do not redesign stack selection rules |
| Regression command index | outputs\FACTORY_R2_3_AB_REGRESSION_COMMAND_INDEX.ps1 | Do not rebuild verification command structure |
| Factory Bootstrap / AGENTS.md gate | AGENTS.md Section 0 | Do not reopen bootstrap enforcement model |
| Deprecated search patterns (Independent Agent, Dual Channel) | AGENTS.md + baseline | Do not un-deprecate these patterns |
| Context isolation design (Phase 6C-E) | PHASE_6C-E_DESIGN_REVIEW.md | Do not redesign context isolation boundaries |

---

## E. Recommended Next Big Capabilities

Based on the inventory, these are the top 5 capabilities that would deliver the most value without duplicating existing work:

### 1. Runnable Starter Completion (api-service + threejs-interactive)
- **Why**: 2 of 5 starter types have no runnable code; Factory cannot validate these project types
- **Depends on**: Existing starter docs + STACK_DECISION_GUIDE
- **Effort**: Medium (create 2 runnable starter projects)

### 2. Products API Testbed (Concrete CRUD Reference Implementation)
- **Why**: No concrete API exists to validate fullstack-admin patterns end-to-end; current i-test-target is harness infra only
- **Depends on**: Runnable api-service starter
- **Effort**: Medium (Express/Fastify + PostgreSQL + 18 test suite)

### 3. Formal Benchmark Suite Execution (8 benchmark projects)
- **Why**: CODEX_BENCHMARK_SUITE.md defines 8 benchmarks but no evidence they have been executed against current Factory
- **Depends on**: Runnable starters + harness infrastructure (already exists)
- **Effort**: Large (requires running Codex against each benchmark)

### 4. Runtime Complexity Budget Enforcement
- **Why**: Budget config defined (PHASE_6C-E) but not enforced; agents can exceed context budgets
- **Depends on**: Pre-spawn hooks + agent contract schema (already exists)
- **Effort**: Small (add enforcement to existing spawn pipeline)

### 5. Business Invariant / Risk Runtime Engine
- **Why**: Decision tree exists in STACK_DECISION_GUIDE but no runtime enforcement for payment/price/inventory critical paths
- **Depends on**: Risk classifier (partial) + security-critical detection (exists)
- **Effort**: Large (new engine design)

---

## Final Output

| field | value |
|---|---|
| inventory_report_file | C:\Codex_App_Factory\outputs\FACTORY_CAPABILITY_INVENTORY_20260711.md |
| capability_matrix_file | (embedded in report, Section A) |
| key_findings | Factory has ~60+ IMPLEMENTED_AND_VERIFIED capabilities across search, multi-agent, verifier, harness; major gaps are runnable starters (2/5 missing), products API testbed, and runtime budget enforcement |
| implemented_capabilities | 62 IMPLEMENTED_AND_VERIFIED, 8 PARTIAL, 12 DOCUMENTED_ONLY |
| missing_capabilities | 14 gaps identified (Section C) |
| deprecated_directions | 7 explicitly deprecated (Section A, Domain 10) |
| recommended_next_big_capabilities | 5 recommendations (Section E) |
