# FACTORY-V05-R1-INTEGRATION-0 — I: Multi-Agent Integration

## Integrated from MULTI-AGENT-ORCHESTRATION-1 (30/30)

| Protocol | File | R1 Behavior |
|----------|------|-------------|
| Decision Policy | MULTI_AGENT_DECISION_POLICY.md | Mandatory question for large projects |
| Role Profiles | ROLE_PROFILES.md | Planner, Builder, Skeptic, Verifier, Integrator |
| Spawn Isolation | SPAWN_ISOLATION_POLICY.md | projectId-scoped; no cross-project agent outputs |
| Skill Loading | SKILL_PROFILE_LOADING_POLICY.md | Skills loaded per-agent contract |
| Agent Contract | schemas/agent-contract.schema.json | Scope, projectId, role, expected outputs |
| Agent Handoff | schemas/agent-handoff.schema.json | Output paths, caveats, evidence level |
| Integrator Protocol | INTEGRATOR_PROTOCOL.md | Sole final merger; worker output never final |
| Agent Ledger | AGENT_LEDGER_UPDATE_POLICY.md | Per-agent tracking; missing = WARNING |
| Failure Attribution | FAILURE_ATTRIBUTION_POLICY.md | Which agent failed, why, what to repair |
| Dashboard Integration | DASHBOARD_INTEGRATION.md | factory state --agents shows ledger |
| Recovery Integration | RECOVERY_INTEGRATION.md | Missing ledger triggers recovery plan |

## R1 Rules
- Multi-agent NEVER auto-starts. User confirmation required.
- Build Lite remains safe fallback for small projects.
- Every agent contract requires projectId.
- Integrator is sole final merger.
- Anonymous output rejected.
- Wrong projectId output = FOREIGN_CONTEXT.
