# FACTORY-BUILD-0 / B: Build Capability Inventory Report

> **Phase**: FACTORY-BUILD-0 / Complex Project Production Harness Mainline Reset
> **Date**: 2026-06-27

---

## Capability Classification: "Can It Build Complex Projects?"

### Category 1 — Directly Usable for Build (11 capabilities)

| # | Capability | Status | Build Role |
|---|-----------|--------|------------|
| 1 | Manual Router (APP_TYPE_ROUTER.md) | ✅ | Routes project type → architecture → starter |
| 2 | Proof-of-Read | ✅ | Verifies codebase understanding before modification |
| 3 | Evidence Hierarchy (Tier 1-5) | ✅ | Prevents process-artifact-as-product confusion |
| 4 | Verifier Framework | ✅ | Machine-readable pass/fail checks |
| 5 | Negative Controls Framework | ✅ | Every check fails when wrong, no PASS-by-default |
| 6 | Diagnostic Pack as Gate | ✅ | Pre-build quality gate, readonly |
| 7 | Session Handoff / Startup Verification | ✅ | New windows pick up state without memory |
| 8 | 4-Agent P1 Runtime | ⚠️ Partial | Conditional multi-agent collaboration |
| 9 | Reviewer-Verifier | ✅ | Single-agent readonly inspection |
| 10 | Mid-Run Floor Checks | ✅ | Prevents premature PASS declarations |
| 11 | Lifecycle/Handoff/Close Receipt | ⚠️ Partial | Phase completion evidence chains |

### Category 2 — Auxiliary for Build (5 capabilities)

| # | Capability | Role |
|---|-----------|------|
| 12 | Report-vs-Source Checks | Verifies claims against implementation |
| 13 | Anti-Deception Checks | Detects false PASS, self-report |
| 14 | Contamination Check | Protects build state isolation |
| 15 | Student Project Mode | Specialized academic diagnostic |
| 16 | Quick Mode | Fast structural first-pass |

### Category 3 — NOT YET BUILT (10 MISSING) ⚠️

| # | Capability | Priority | Why Critical |
|---|-----------|----------|-------------|
| 17 | **One-Click Project Intake** | P0 | Entry point for all builds |
| 18 | **Automatic Complexity Classifier** | P0 | Routes to correct mode without human guess |
| 19 | **Real Production Task Graph** | P0 | Dependency-ordered work plan |
| 20 | Agent Work Allocation | P1 | Assigns tasks to agents with clear boundaries |
| 21 | Cross-Agent Integration | P1 | Merges outputs, resolves conflicts |
| 22 | **External Project Memory** | P0 | State persists across sessions |
| 23 | Long-Term Context Continuation | P1 | Resume after days without context loss |
| 24 | Cloud Knowledge/Data Recovery | P2 | Project-specific external knowledge |
| 25 | Multi-Round Sustained Development | P1 | Iterate across weeks |
| 26 | **Real Complex Project Delivery Closed Loop** | P0 | Full intake→build→verify→deliver cycle |

### Category 4 — Use With Caution (5 items)

| # | Capability | Caution |
|---|-----------|---------|
| 27 | 4-Agent P1 (Full) | Process evidence only, no product superiority |
| 28 | Full Multi-Agent (7-agent) | CUT as default, experimental only |
| 29 | Benchmark Scoring | Measures, doesn't build |
| 30 | Release Packaging | Gate behind Build Mode success |
| 31 | SkillMarket Evidence | CLOSED — trial complete |

---

## Critical Gap Assessment

**10 of 26 needed capabilities are MISSING.**

Existing capabilities are strong on **verification and safety** (Verifier, Negative Controls, Diagnostic Pack, Evidence Hierarchy). They are weak on **production and coordination** (Intake, Task Graph, External Memory, Delivery Loop).

The Build Harness MVP must close the P0 gaps: Intake, Classifier, Task Graph, External Memory, and Delivery Closed Loop.

| Category | Count |
|----------|-------|
| Directly usable | 11 |
| Auxiliary | 5 |
| **MISSING** | **10** |
| Use with caution | 5 |
| **Total** | **31** |
