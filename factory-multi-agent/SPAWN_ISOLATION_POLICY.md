# SPAWN_ISOLATION_POLICY.md
> Part of: FACTORY-MULTI-AGENT-ORCHESTRATION-1 / D

## Spawn Rules
- Agents spawned on-demand, not always-on
- Each spawn requires: role profile, agent contract, projectId, assigned paths
- Max concurrent agents: configurable (default: 5)
- Agent closed after handoff accepted by Integrator
- Idle agents (>30 min no activity) → auto-close with warning

## Isolation Rules
- Each agent has DISJOINT write scope (no overlapping paths)
- Agent cannot read other agent working copies (contract boundary)
- Agent output includes projectId (mandatory)
- Wrong projectId output → FOREIGN_CONTEXT, rejected
- Cross-project spawn requires separate session

## Working Copy Isolation
- Agent A: `{project}/.factory-working/agent-{id-a}/`
- Agent B: `{project}/.factory-working/agent-{id-b}/`
- Agents MUST NOT write to each other's working copies
- Integrator reads from all agent working copies

## Spawn Lifecycle
1. User confirms multi-agent mode
2. Architect spawns (designs)
3. Implementer agents spawn (per module)
4. Test/Security/Package agents spawn (verification)
5. Integrator merges outputs
6. All agents closed after Integrator ACCEPT
