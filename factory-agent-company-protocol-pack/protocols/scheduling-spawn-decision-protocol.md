# Scheduling & Spawn Decision Protocol

> **Version**: 1.0.0 | **Phase**: FACTORY-AGENT-1 | **Owner**: Orchestrator

## 1. Purpose

This protocol defines how the Orchestrator decides when to spawn Builder agents, how to allocate work across agents, and how to handle spawn failures. Spawning is a controlled, auditable process — agents are never spawned arbitrarily or silently.

## 2. Task Graph Creation

### 2.1 From Phase Specification to Task Graph

Before any spawn decisions, the Orchestrator MUST:

1. Parse the active phase specification (e.g., `FACTORY-AGENT-1`).
2. Identify all independent work modules (directories, file groups, logical subsystems).
3. Build a dependency graph where nodes = modules and edges = dependencies.
4. Identify modules with no inter-dependencies as candidates for parallel spawning.

### 2.2 Task Graph Representation

The task graph is stored as:

```json
{
  "phase": "FACTORY-AGENT-1",
  "generatedAt": "2026-06-26T00:00:00Z",
  "nodes": [
    {
      "moduleId": "schemas-proto-pack",
      "paths": ["factory-agent-company-protocol-pack/schemas/", "factory-agent-company-protocol-pack/protocols/"],
      "dependencies": [],
      "estimatedComplexity": "MEDIUM",
      "assignedAgent": null
    }
  ],
  "resolutionOrder": ["schemas-proto-pack"]
}
```

## 3. Complexity Trigger for Spawning

### 3.1 Threshold

The Orchestrator MUST spawn multiple agents when:

- The project contains **5 or more independent modules** (no cross-dependencies).
- AND the estimated total work exceeds what a single agent can complete within the phase time budget.

### 3.2 Single-Agent Exception

If the project has fewer than 5 independent modules, the Orchestrator MAY use a single agent. This decision must be logged with justification.

### 3.3 Module Independence Criteria

Two modules are independent if:

- Their ownedScopes do not overlap.
- Neither module reads files produced by the other.
- The modules can be built and validated in isolation.

## 4. Capacity Preflight

Before spawning any agent, the Orchestrator MUST perform a capacity preflight:

### 4.1 Agent Limits Check

| Resource | Limit | Action if Exceeded |
|----------|-------|-------------------|
| Active agents | Configurable (default: 10) | Queue spawn, retry after completion |
| Total agents per phase | Configurable (default: 20) | Reject spawn, report to operator |
| Stale agents (>30 min no report) | Flagged, not counted | Terminate stale agents first |
| Concurrent spawns | 3 at a time | Serialize beyond 3 |

### 4.2 Stale Agent Cleanup

Before counting active agents, the Orchestrator MUST:

1. Query all agents for last report timestamp.
2. If any agent has not reported in >30 minutes → mark STALE.
3. Terminate STALE agents with closeReason `STALE`.
4. Remove from active agent count.
5. Log each termination.

### 4.3 Active Agent Count

```
activeCount = total spawned - (COMPLETED + FAILED + STALE + REPLACED)
```

Only agents that are actively working count against the limit.

## 5. Spawn Decision Factors

The Orchestrator evaluates each spawn candidate against:

| Factor | Weight | Description |
|--------|--------|-------------|
| Module independence | HIGH | More independent = better parallelization |
| Risk level | HIGH | High-risk modules may need dedicated agents |
| Available builders | MEDIUM | Must match agent role to module type |
| Dependency resolution | CRITICAL | Do not spawn if dependencies are unresolved |
| Expected output size | LOW | Large outputs may split further |

### 5.1 Spawn Decision Matrix

| Condition | Decision |
|-----------|----------|
| 5+ independent modules, capacity available | Spawn parallel agents |
| 5+ independent modules, no capacity | Queue, spawn as slots free |
| <5 independent modules | Single agent or sequential |
| Dependency exists | Spawn after dependency completes |
| High-risk module | Dedicated agent with extended evidence requirements |

## 6. Spawn Failure Handling

### 6.1 Failure Classification

Every spawn failure MUST be classified:

| Classification | Definition | Example |
|---------------|-----------|---------|
| TRANSIENT | Temporary issue, likely to resolve on retry | Network timeout, resource contention |
| CONFIGURATION | Misconfiguration, fixable by operator | Wrong agent type, missing tool |
| PERMANENT | Unrecoverable, requires architectural change | Agent type unavailable, system limitation |

### 6.2 Retry Strategy

| Classification | Max Retries | Backoff | After Max Retries |
|---------------|-------------|---------|-------------------|
| TRANSIENT | 3 | 30s → 60s → 120s | Escalate to operator |
| CONFIGURATION | 1 | 10s | Escalate to operator, classify as FAILED |
| PERMANENT | 0 | N/A | Replace agent, classify as REPLACED |

### 6.3 Replacement on Permanent Failure

If a spawn failure is classified as PERMANENT:

1. Mark the failed agent with closeReason `REPLACED`.
2. Record `replacementAgentId` in the close receipt.
3. Select or create a replacement agent with equivalent role.
4. Generate a new capsule for the replacement.
5. Spawn the replacement agent.
6. Log the full replacement chain.

## 7. Anti-Deception Rules for Spawning

### 7.1 Spawn Failure MUST Be Recorded

Every spawn failure MUST generate a log entry with:
- Timestamp
- AgentId (attempted)
- Failure classification
- Error details
- Retry count

**Violation**: Hiding or suppressing spawn failures is a **P0 integrity violation**.

### 7.2 Failed Agent MUST NOT Count as Success

An agent that failed to spawn or was terminated before producing output MUST NOT:
- Appear in completion statistics.
- Be counted as "work done."
- Be reported as a successful parallelization.

### 7.3 Spawn Without Capsule = Blocked

No agent may be spawned without a fully validated capsule. The Orchestrator MUST enforce this; any bypass is a **P0 integrity violation**.

### 7.4 Silent Fallback to Main Agent = P0 Violation

If a spawn fails and the Orchestrator silently falls back to doing the work on the main thread without recording the failure, this is a **P0 integrity violation**. The failure and fallback MUST both be logged.

## 8. Spawn Log Format

Every spawn attempt and outcome is logged:

```json
{
  "spawnId": "spawn-{agentId}-{timestamp}",
  "agentId": "...",
  "capsuleId": "...",
  "attemptedAt": "ISO timestamp",
  "status": "SUCCESS | FAILED",
  "classification": "TRANSIENT | CONFIGURATION | PERMANENT | null",
  "retryCount": 0,
  "errorDetail": "..."
}
```

Spawn logs are stored at: `factory-agent-company-protocol-pack/spawn-logs/{phase}/`
