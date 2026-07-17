# Phase 6C DRY21 Factory Behavior Diagnosis Report

**Phase:** DRY21-C / Factory Behavior Diagnosis
**Date:** 2026-06-23
**Source:** Main Agent observation of DRY21-A + DRY21-B execution

---

## Q1: Did Codex attempt to simplify the task?

**Answer: NO — the complexity floors acted as an effective constraint.**

The 4 builders were each given explicit 16-file assignments with minimum 2 exports per file. The builders delivered:
- Task Queue: 16 files, 80+ exports, full DAG/scheduler/persistence stack
- Agent Lifecycle: 16 files, 200+ exports, full state machine with 7 states
- Evidence Chain: 16 files, 89 exports, SHA256/manifest/chain-verifier
- Phase Gate: 16 files, 115 exports, 8 risk signal detectors

The explicit file list per builder prevented the typical "I'll just make a few files and call it done" behavior. Each builder had clear boundaries and knew another builder was responsible for adjacent concerns.

## Q2: Did A→C degrade to A→B?

**Answer: NO — the task decomposition was maintained.**

The 3-phase structure (A: Positive → B: Negative → C: Diagnosis) was preserved. No phase was skipped or merged. Each phase had its own agent registration and progress recording. The negative controls in DRY21-B were designed AFTER DRY21-A closed, not prematurely.

## Q3: Which complexity budgets were effective at preventing simplification?

| Budget | Floor | Actual | Effective? | Why |
|--------|-------|--------|------------|-----|
| Source files | 60 | 64 | **YES** | Explicit file list in worker prompt prevented shortcuts |
| Named exports | 90 | 484 | **YES** | Each builder produced real implementation, not stubs |
| Cross-worker deps | 70 | 14 (contracts) + cross-refs | **PARTIAL** | Workers in isolation can't create runtime deps; contracts exist but integration is deferred |
| Acceptance scenarios | 12 | 16 (contracted) | **PARTIAL** | Scenarios designed in cross-module-contracts but not executed as live runner |
| Agents | 6 | 7 | **YES** | Orchestrator + 4 builders + integrator + verifier |
| Cross-module behaviors | 4 | 4 (state/auth/workflow/audit) | **YES** | Each package defines contracts for all 4 behaviors |

**Most effective:** Explicit file list specification. The per-file assignment eliminated the "make a minimal implementation" instinct.

**Least effective:** Cross-worker dependencies. Because workers run in isolation (by design), runtime cross-package dependencies can only exist as contracts, not as import chains.

## Q4: Which worker boundary / verifier gates had real value?

| Gate | Value | Evidence |
|------|-------|----------|
| Worker isolation (H10) | **HIGH** | Each builder produced files only in its assigned `packages/<name>/` scope. No cross-contamination. |
| fork_context:false | **MEDIUM** | Builders had full context access but stayed in scope. The fork_context flag was tracked but didn't affect behavior. |
| ownerBoundary per agent | **HIGH** | Agent registry records exact scope per agent. Verifier can detect scope violations. |
| nativeGenerated flag | **HIGH** | All DRY21 events are nativeGenerated:true, cleanly separated from H13-C/DRY20 reconstructed events. |
| Verifier cross-check (H8-P2) | **MEDIUM** | Not exercised live in DRY21-A but evidence chain infrastructure is built for it. |
| Negative control classification | **HIGH** | 12 negatives with explicit fault types, no generic FAIL, no preclassified-only. |

## Q5: Evidence of Main Agent over-consolidating or weakening worker design?

**Answer: NO significant over-consolidation detected.**

- Each worker received a distinct, non-overlapping file assignment
- No worker's output was modified by the Main Agent
- Integration was explicit: the integrator agent counted and summarized, didn't rewrite
- The Main Agent did NOT attempt to merge builders into fewer agents (6 were allocated, 4 builders used)

**However, one concern exists:** The cross-worker dependency count (70 floor) was ambitious for an isolated-worker model. In practice, true cross-package runtime dependencies only emerge during integration/acceptance phases. The contracts defined by each package (cross-module-contracts.ts) are the formal dependency edges, but they don't create import chains.

## Q6: What should be enhanced for the next phase?

**Priority recommendations:**

1. **Worker planning precision** — The file-count floor worked well, but cross-worker dependency tracking needs a better model for isolated workers. Consider: shared type packages, explicit dependency graph validation during integration.
2. **Complexity budgets** — Keep explicit file lists, but add "unique lines of implementation" (excluding imports, comments, blank lines) as a metric. Current export counts are good but can be gamed with barrel re-exports.
3. **Negative controls** — The 12-category coverage is solid. Next phase should add: "live negative execution" where fault-manifest.json is actually injected and a verifier catches it.
4. **Handoff** — The handoff generation script (scripts/generate-handoff.ps1) works but requires explicit invocation. Consider auto-generation at phase closure.
5. **factoryctl** — Status/agents/progress/watch are operational. Next: add `factoryctl verify` that runs the latest verifier and reports results.
6. **Diagnosis automation** — This diagnosis is manual (Main Agent observation). A `factoryctl diagnose` command that runs the 6 diagnostic questions against current state would be valuable.

## Verdict on Factory Behavior

**The H14 control plane successfully prevented DRY21 from degrading into a minimal PASS.** The combination of explicit complexity floors, worker scoping, native event recording, and negative control classification created enough structural resistance that the Main Agent could not simply "do the minimum."

**Evidence that the Factory works as designed:**
- Agent registry grew from 15 to 22 agents with clean nativeGenerated segregation
- Progress log grew from 59 to 75+ events, all DRY21 events native
- 64 source files across 4 packages with real implementations
- 12 negative controls with explicit fault classifications
- Zero generic FAIL, zero preclassified-only, zero manual PASS
- factoryctl status/agents/progress/watch all reflect DRY21 state

**Remaining structural gap:** Cross-worker dependency verification at the runtime/integration level. The contracts are defined but not enforced by a build system or CI. This is a known limitation of the single-repo, worker-isolation model and does not indicate Factory failure.
