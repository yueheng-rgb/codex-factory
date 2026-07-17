# FACTORY-STATE-DASHBOARD-0 — E: Agent Ledger View Report

> Phase: FACTORY-STATE-DASHBOARD-0
> Section: E — Agent Ledger View
> Date: 2026-06-29

## Deliverables

| File | Path |
|------|------|
| View Doc | `factory-dashboard/AGENT_LEDGER_VIEW.md` |
| JSON Schema | `factory-dashboard/schemas/agent-ledger-view.schema.json` |
| Governance JSON | `governance/factory-dashboard/factory-state-dashboard-0-agent-ledger-view.json` |

## Summary

Defines per-agent display: agent_id, role, projectId, timestamp, phase, inputs, outputs (never omitted), verdict, caveats, parent, handoff, foreign refs. Summary view: total entries, by-role breakdown, verdict counts, integrator verdict, failure attribution. 6 integrity checks: missing projectId, anonymous agent, no outputs, no verdict, no integrator verdict, no failure attribution.
