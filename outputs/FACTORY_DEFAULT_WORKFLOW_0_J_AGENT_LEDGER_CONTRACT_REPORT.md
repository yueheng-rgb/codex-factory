# FACTORY-DEFAULT-WORKFLOW-0 — J: Agent Ledger Contract Report

> Phase: FACTORY-DEFAULT-WORKFLOW-0
> Section: J — Agent Ledger Contract
> Date: 2026-06-28

## Deliverables

| File | Path |
|------|------|
| Contract Definition | `factory-workflow/AGENT_LEDGER_CONTRACT.md` |
| Governance JSON | `governance/factory-workflow/factory-default-workflow-0-agent-ledger-contract.json` |

## Summary

Defines a JSONL-based agent ledger with 10 required/optional fields per entry. Key properties:
- **Append-only, immutable** — entries never modified
- **Every agent writes own entries** — no cross-agent writes
- **Integrator acceptance/rejection** — formal handoff review
- **Failure attribution** — always attribute which agent failed

Located at: `governance/factory-workflow/agent-ledger.jsonl`
