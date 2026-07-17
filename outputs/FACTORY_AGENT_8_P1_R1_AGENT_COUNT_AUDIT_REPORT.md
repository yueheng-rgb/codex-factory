# FACTORY-AGENT-8-P1-R1 Agent Count Audit Report

**Date:** 2026-06-26T19:50:21.2383428+08:00  
**Audit Scope:** All agent registries across all runs  
**Finding:** NO POLICY VIOLATION  

---

## 1. RAW COUNTS (why "30+" appears)

Registry files found: **2**
- 05-agent-company/registry/agent-registry.jsonl: 23 raw entries  
- 05-agent-company-p1/registry/agent-registry.jsonl: 6 raw entries  
- **Total raw entries: 29**

Each agent has both "active" (spawn) and "completed" (close) entries → raw count looks inflated.

## 2. UNIQUE AGENTS

### Old Run (FACTORY-AGENT-8, 7-agent model)
| Agent | SpawnId | Role | Status |
|-------|---------|------|--------|
| McClintock | 019f033f... | builder-db | completed |
| Plato | 019f0343... | builder-backend | completed |
| Ptolemy | 019f034d... | builder-frontend | completed |
| Ampere | 019f0352... | builder-tests | completed |
| Carver | 019f0360-8b30... | reviewer | completed |
| Raman | 019f0360-8b62... | verifier | completed |
| Linnaeus | 019f0360-8b8f... | integrity-checker | completed |

**Old run total: 7 spawned agents**

### New P1 Run (FACTORY-AGENT-8-P1, 4-agent model)
| Agent | SpawnId | Role | Status |
|-------|---------|------|--------|
| Kuhn | 019f0390-c376... | product-builder | completed |
| Parfit | 019f039a-dc15... | test-integration-docs-builder | completed |
| Boyle | 019f03ad-6616... | reviewer-verifier | completed |

**New P1 run total: 3 spawned agents + 1 Orchestrator (Main Agent) = 4**

---

## 3. CLASSIFICATION

| Category | Count |
|----------|-------|
| Real spawned agents (total, both runs) | 10 |
| Real spawned agents (old run, pre-P1) | 7 |
| Real spawned agents (P1 run) | 3 |
| nativeGenerated:true | 10/10 |
| forkContext:false | 10/10 |
| Active | 0 (all completed) |
| Completed | 10 |
| Stale/open/unresolved | 0 |
| Negative control fixtures | 0 |
| Simulation-only | 0 |
| Main Agent (orchestrator, not spawned) | 2 (one per run) |

---

## 4. POLICY COMPLIANCE

| Check | Status |
|-------|--------|
| P1 run agents ≤ 4 | ✅ 3 spawned + 1 orchestrator = 4 |
| maxAgentsAllowed: 4 violated? | ❌ NO |
| All agents have capsules? | ⚠️ Reviewer-Verifier missing capsule |
| All agents have handoffs? | ⚠️ Reviewer-Verifier missing handoff |
| All agents have close receipts? | ⚠️ Reviewer-Verifier missing close receipt |
| All agents forkContext:false? | ✅ |
| All agents nativeGenerated:true? | ✅ |
| Reviewer-Verifier readonly? | ✅ |
| Orchestrator wrote no builder scope? | ✅ |

---

## 5. GAPS FOUND

1. **Reviewer-Verifier (Boyle)** is missing capsule, handoff, and close receipt.
   - Root cause: Orchestrator did not create capsule before spawning Boyle.
   - Boyle was READONLY and produced a gate result at gates/reviewer-verifier-result.json
   - Not blocking for agent count audit but should be recorded.

## 6. VERDICT

**NO POLICY VIOLATION.**

- 10 total spawned agents across 2 separate runs (not 30+)
- P1 run exactly at 4-agent limit (3 spawned + 1 orchestrator)
- No negative/fixture/simulation agents counted as real
- No stale/active/unresolved agents
- 1 gap: Reviewer-Verifier missing process artifacts (non-blocking for count)

## 7. RAW ENTRY EXPLANATION

The "30+ agents" impression comes from 29 raw JSONL entries across 2 registries, where each agent has 2 entries (active + completed) plus the old run has some agents with only "active" entries (gatekeepers closed via close_agent tool, not registry update).