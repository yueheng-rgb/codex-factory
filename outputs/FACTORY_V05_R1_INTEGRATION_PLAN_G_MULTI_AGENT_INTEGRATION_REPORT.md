# G: Multi-Agent Integration Plan — R1 Embedding

## Integration Targets from MULTI-AGENT-ORCHESTRATION-1 (30/30 PASS)

| Asset | Source Path | R1 Target Path | Category |
|-------|------------|----------------|----------|
| Decision Policy | `factory-multi-agent/MULTI_AGENT_DECISION_POLICY.md` | `governance/factory-multi-agent/` | POLICY |
| Role Profile Spec | `factory-multi-agent/ROLE_PROFILE_SPEC.md` | `governance/factory-multi-agent/` | POLICY |
| Spawn/Isolation Policy | `factory-multi-agent/SPAWN_ISOLATION_POLICY.md` | `governance/factory-multi-agent/` | POLICY |
| Agent Contract Schema | `factory-multi-agent/schemas/agent-contract.schema.json` | `schemas/` | SCHEMA_TEMPLATE |
| Agent Handoff Schema | `factory-multi-agent/schemas/agent-handoff.schema.json` | `schemas/` | SCHEMA_TEMPLATE |
| Integrator Protocol | `factory-multi-agent/INTEGRATOR_PROTOCOL.md` | `governance/factory-multi-agent/` | POLICY |
| Agent Ledger Policy | `factory-multi-agent/AGENT_LEDGER_POLICY.md` | `governance/factory-multi-agent/` | POLICY |
| Failure Attribution Policy | `factory-multi-agent/FAILURE_ATTRIBUTION_POLICY.md` | `governance/factory-multi-agent/` | POLICY |
| Role Templates | `factory-multi-agent/roles/` | `templates/agent-roles/` | SCHEMA_TEMPLATE |

## R1 Integration Rules
- Role profiles loaded on-demand at startup; never always-on.
- Multi-agent only after user confirmation (Decision Gate).
- Every agent contract requires `projectId`, scope boundaries, handoff schema.
- Integrator is sole final merger; worker output never becomes final directly.
- Agent ledger updated per agent; missing ledger = WARNING.
- Anonymous/wrong-projectId output rejected as FOREIGN_CONTEXT.
- Build Lite remains safe fallback; multi-agent NOT universal default.
