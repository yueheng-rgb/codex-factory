# FACTORY-PROJECT-ISOLATION-0 — H: Agent Ledger Isolation Report

> Phase: FACTORY-PROJECT-ISOLATION-0
> Section: H — Agent Ledger Isolation
> Date: 2026-06-29

## Deliverables

| File | Path |
|------|------|
| Isolation Doc | `factory-isolation/AGENT_LEDGER_ISOLATION.md` |
| Governance JSON | `governance/factory-isolation/factory-project-isolation-0-agent-ledger-isolation.json` |

## Summary

Defines 5 agent ledger isolation rules:
1. `projectId` required in every entry (REJECT if missing)
2. One ledger per project (separate from global Factory ledger)
3. Ledger write gate (verify agent's projectId matches ledger)
4. Cross-project agent output marked as FOREIGN_REFERENCE
5. Agent attribution traceability (agent_id → projectId → paths chain)

Updated ledger entry schema to include `projectId` and `foreign_references` fields.
