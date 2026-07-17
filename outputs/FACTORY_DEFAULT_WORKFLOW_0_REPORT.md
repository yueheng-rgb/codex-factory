# FACTORY-DEFAULT-WORKFLOW-0 — Final Report

> Phase: FACTORY-DEFAULT-WORKFLOW-0
> Status: **PASS**
> Date: 2026-06-28
> Verifier: 60/60 checks passed

---

## Executive Summary

FACTORY-DEFAULT-WORKFLOW-0 has successfully defined and solidified the default usage protocol for Codex Factory after v0.5. The Factory is now governed by explicit rules so that selecting a project folder and stating a requirement automatically triggers the correct flow — no long instructions needed.

## Deliverables Inventory

| Section | Description | Files |
|---------|-------------|-------|
| A | Scope Lock | 2 |
| B | Default Startup Protocol | 3 |
| C | User Requirement Entry Contract | 3 |
| D | Multi-Agent Decision Gate | 3 |
| E | Multi-Agent Role Profile Draft | 3 |
| F | Project Path Handoff Contract | 3 |
| G | Natural Language Cleanup Contract | 3 |
| H | CLI Name Reconciliation | 3 |
| I | State Dashboard Requirements | 3 |
| J | Agent Ledger Contract | 3 |
| K | Cloud Deferral Record | 3 |
| L | Default Workflow Simulation (8 scenarios) | 11 |
| M | Strategy Decision | 2 |
| N | Negative Controls (35) | 2 |
| O | Verifier Script + Results | 3 |

**Total files created**: 50

## Document Locations

| Type | Path |
|------|------|
| Workflow Protocols | `factory-workflow/` (10 files) |
| Governance JSONs | `governance/factory-workflow/` (17 files) |
| Section Reports | `outputs/` (13 report MDs) |
| Simulation Scenarios | `harness/default-workflow/default-workflow-0-simulation/` (8 files) |
| Verifier | `scripts/factory-default-workflow-0-verify.ps1` |

## Key Decisions Ratified

1. ✅ Default Factory usage path defined (select folder + state requirement)
2. ✅ Multi-agent decision mandatory as a question for large projects
3. ✅ Natural-language cleanup defined (PLAN first, never destructive by default)
4. ✅ Full path handoff required at every project completion
5. ✅ Cloud deferred to post-v1.0
6. ✅ Agent ledger contract established for accountability
7. ✅ v0.5 zip preserved (SHA256 verified)
8. ✅ No v0.6 created, no cloud action taken

## Next Phase Recommendation

| Priority | Phase | Rationale |
|----------|-------|-----------|
| 1 | **FACTORY-PROJECT-ISOLATION-0** | Validate Factory isolation on real projects |
| 2 | **FACTORY-MULTI-AGENT-ORCHESTRATION-1** | Refine role profiles with real validation |
| 3 | **FACTORY-STATE-DASHBOARD-0** | Implement CLI `factory state` |

## Verifier Result

- **Checks**: 60
- **Passed**: 60
- **Failed**: 0
- **Verdict**: PASS
- **v0.5 SHA256**: `9FD3A5F979FE1FDEA712F69CAC300E2F49F4E84705A0448D98186CA950AC16CB` (verified)
