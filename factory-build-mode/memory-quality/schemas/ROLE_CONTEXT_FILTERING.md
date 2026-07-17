# Role Context Filtering

## Policy
Each agent role receives a filtered subset of the context packet.

| Role | Sees | Does NOT See |
|------|------|-------------|
| **Orchestrator** | Full packet, all sections | Nothing filtered |
| **worker-backend** | Critical state, decisions, risks, next steps | Frontend-specific details, test internals |
| **worker-frontend** | Critical state, UI-related decisions, risks | Backend route internals, DB schema details |
| **worker-test** | Critical state, test-related decisions, evidence paths | Implementation details of routes/pages |
| **worker-verify** | Full evidence section, risks, rejected claims | Implementation code |
| **Reviewer** | Evidence paths, rejected claims, risks, anti-deception | Implementation details |

## Forbidden Leaks
- Never include agent IDs or internal handoff details in non-orchestrator packets
- Never include file paths outside the agent's scope
- Never include prompts or system messages
