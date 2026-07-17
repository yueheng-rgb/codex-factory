# FACTORY-DEFAULT-WORKFLOW-0 — I: State Dashboard Requirements Report

> Phase: FACTORY-DEFAULT-WORKFLOW-0
> Section: I — State Dashboard Requirements
> Date: 2026-06-28

## Deliverables

| File | Path |
|------|------|
| Requirements Doc | `factory-workflow/STATE_DASHBOARD_REQUIREMENTS.md` |
| Governance JSON | `governance/factory-workflow/factory-default-workflow-0-state-dashboard-requirements.json` |

## Summary

Defines 5 state categories for CLI-queryable visibility:
1. Project Status (phase, bootstrap, mode, multi-agent)
2. Build State (last build, status, artifact path)
3. Agent State (active agents, ledger, handoffs)
4. Governance State (verifier, negative controls, reports)
5. Cleanup State (pending plans, cache size)

Explicitly deferred: web UI, real-time monitoring, database persistence, graphs, alerts, multi-project dashboard.
