# FACTORY-DEFAULT-WORKFLOW-0 — D: Multi-Agent Decision Gate Report

> Phase: FACTORY-DEFAULT-WORKFLOW-0
> Section: D — Multi-Agent Decision Gate
> Date: 2026-06-28

## Deliverables

| File | Path |
|------|------|
| Gate Definition | `factory-workflow/MULTI_AGENT_DECISION_GATE.md` |
| Governance JSON | `governance/factory-workflow/factory-default-workflow-0-multi-agent-decision-gate.json` |

## Gate Summary

Defines three tiers for multi-agent question:

- **Required** (3+ of 5 criteria met): server+client, database, 3+ modules, auth, >5 files
- **Optional**: fullstack but small, independent frontend+backend, user mentions "parallel"
- **Should NOT suggest**: single-file, docs-only, config-only, <5 files, simple CRUD

### Hard Rules
1. Never start without user confirmation
2. Never make universal default
3. Never bypass user for large projects
4. Ask before any code is written
5. "Decide later" → re-ask at next milestone
6. Declined → don't re-ask same phase
