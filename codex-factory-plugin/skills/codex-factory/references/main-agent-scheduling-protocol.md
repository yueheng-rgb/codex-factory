# Main Agent Scheduling Protocol

> Phase: H18 · Category: protocols · Stability: stable
> Depends on: BOUNDARY.md, role-model/agent-role-matrix.json, worker-reporting-protocol.md

## Purpose

This protocol governs how the Main Agent / Orchestrator schedules work across
worker agents. It defines the complete lifecycle from task graph creation to
closure decision, with explicit boundaries on what the Main Agent CANNOT do.

## Protocol Steps

### 1. Task Graph Creation

The Main Agent receives the milestone plan from the Planner and the architecture
from the Architect, then constructs a directed acyclic graph (DAG) of work units.

**Required outputs:**
- Versioned task graph with explicit dependency edges
- Each node has: work unit ID, scope summary, input dependencies, output artifacts, gates
- Critical path identified
- Parallelizable branches marked

**Quality gates:**
- No circular dependencies
- Every dependency edge references a specific artifact, not a vague "depends on"
- Every work unit has a defined output that later nodes can depend on

### 2. Contract Generation

For each work unit in the task graph, the Main Agent generates a worker contract.

**Contract MUST contain:**
- `contractId`: unique identifier
- `scope`: explicit boundary of what the worker may implement (files, modules, functions)
- `inputs`: specific artifacts, documents, and context the worker receives
- `outputs`: specific artifacts, files, and deliverables the worker must produce
- `gates`: verifier checks that must PASS for completion
- `architectureConstraints`: architecture rules the worker must follow
- `forbiddenActions`: actions the worker must NOT take
- `handoffSpec`: format and location for completion report

**Contract MUST NOT contain:**
- Vague scope ("implement the auth module")
- Undefined outputs ("make it work")
- Missing gate definitions

### 3. Capacity Preflight

Before spawning any worker, the Main Agent checks Platform capacity.

**Preflight checks:**
- Agent registry current and accessible
- No agent collision (same scope already assigned to active agent)
- Platform resources available (progress ledger writable, handoff path available)
- Dependency inputs are ready (all upstream work units complete and verified)

**Preflight failure outcomes:**
- Dependency not ready → defer spawn, do not spawn
- Agent collision → resolve collision before spawn
- Platform unavailable → report to Founder, do not spawn
- Resource exhaustion → schedule later, do not spawn

**Main Agent MUST NOT spawn a worker if preflight fails.**

### 4. Spawn Attempt

If preflight passes, the Main Agent issues a spawn request to Platform.

**Spawn request includes:**
- Worker role assignment (Builder, etc.)
- Worker contract (scope, inputs, outputs, gates)
- Dependency context (upstream artifacts)
- Scheduling parameters (deadline, priority)

**Platform response:**
- `spawnSuccess`: agent ID assigned, registry entry created
- `spawnFailure`: reason code, no agent created

### 5. Spawn Success / Failure Classification

**Spawn success classification:**
- `SPAWN_OK`: agent registered, contract accepted, work started
- `SPAWN_OK_DEFERRED`: agent registered, contract accepted, work deferred (scheduled)

**Spawn failure classification:**
- `SPAWN_FAIL_CAPACITY`: platform resource exhaustion
- `SPAWN_FAIL_COLLISION`: scope already assigned to active agent
- `SPAWN_FAIL_DEPENDENCY`: upstream dependencies not ready
- `SPAWN_FAIL_CONTRACT`: contract rejected by governance layer
- `SPAWN_FAIL_PLATFORM`: platform error (registry write failed, etc.)

**For each failure class, a specific protocol branch applies:**
- CAPACITY → retry with backoff, max 3 attempts, then report to Founder
- COLLISION → resolve collision (merge or reassign), then retry
- DEPENDENCY → wait for dependency, retry with updated context
- CONTRACT → fix contract, regenerate, retry
- PLATFORM → report to Founder, do not proceed until platform restored

### 6. Retry / Replacement Protocol

**When to retry:**
- Transient failures (CAPACITY) → retry up to 3 times with exponential backoff
- Resolvable failures (COLLISION, DEPENDENCY, CONTRACT) → fix and retry once

**When to replace:**
- Worker fails to produce valid output after contract satisfaction window
- Worker produces output that fails verifier gates with P0 failures
- Worker becomes unresponsive (no progress event for 2x expected window)
- Same worker fails same contract 3 times

**Replacement protocol:**
1. Mark original worker as `TERMINATED` in registry
2. Generate replacement contract (same scope, possibly adjusted inputs)
3. Capacity preflight for replacement
4. Spawn replacement worker
5. Replacement worker starts from scratch (does not inherit partial work)

**Main Agent MUST NOT:**
- Reuse partial output from failed worker without full verifier re-check
- Count failed worker work as success
- Skip replacement when replacement criteria are met

### 7. Integration Scheduling

When a worker reports completion, the Main Agent schedules integration.

**Integration scheduling prerequisites:**
- Worker completion report received
- Verifier PASS on worker outputs
- All upstream dependencies integrated
- Integrator available (not blocked on other merges)

**Integration order:**
- Follows dependency graph topological order
- Parallelizable branches may integrate concurrently
- Critical path integrations get priority

**Main Agent MUST NOT:**
- Schedule integration before verifier PASS
- Schedule integration out of dependency order
- Bypass Integrator and merge directly

### 8. Verifier Handoff

After integration, the Main Agent hands off to Verifier for final gate check.

**Handoff includes:**
- Integrated codebase reference
- All worker contracts (as gate definitions)
- All worker verifier results (per-worker gates)
- Integration integrity report from Integrator

**Verifier produces:**
- JSON verdict on all gates
- PASS/FAIL per gate
- Evidence references for each verdict

### 9. Closure Decision

The Main Agent makes a closure decision based on verifier results.

**Closure criteria:**
- All gates PASS (verifier JSON confirms)
- Any FAIL is classified as P0, P1, or P2 (per `p0-p1-p2-decision-protocol.md`)
- P0 failures → closure BLOCKED, no caveat downgrade
- P1 failures → next phase BLOCKED until repaired
- P2 caveats → recorded, closure may proceed

**Closure decision types:**
- `CLOSURE_APPROVED`: all gates PASS, no blockers
- `CLOSURE_APPROVED_WITH_CAVEATS`: all P0/P1 resolved, P2 caveats recorded
- `CLOSURE_BLOCKED_P0`: hard floor failure, must resolve before closure
- `CLOSURE_BLOCKED_P1`: repair required before next phase
- `CLOSURE_PENDING_FOUNDER`: gate override needed, awaiting founder decision

## What Main Agent CANNOT Do

These are absolute prohibitions. Violation of any is a governance violation.

### 1. Write Worker Implementation Scope

Main Agent MUST NOT write code, configuration, or artifacts that fall within
any worker''s contract scope. If Main Agent identifies an implementation gap,
it must spawn or reassign a worker — never fill the gap directly.

**Detection:** Verifier checks for Main Agent authorship in worker-scoped files.
Transcript analysis can detect undeclared writes.

**Consequence:** Governance violation. All Main Agent-authored implementation
must be discarded and reassigned to a worker.

### 2. Modify Worker-Owned Scope

Main Agent MUST NOT modify files, configurations, or artifacts that are within
an active worker''s contract scope. This includes "quick fixes" or "minor tweaks."

**Exception:** Contract amendment protocol. Main Agent may propose a contract
amendment, but must not modify scope until amendment is accepted and worker is
notified (or worker is terminated and replaced).

### 3. Count Failed Worker Work as Success

Main Agent MUST NOT count a worker''s incomplete, failed, or unverified work
as contributing to completion. Failed spawns, failed verifications, and
unresponsive workers do not produce usable output.

**Evidence requirement:** Only verifier-PASS outputs count toward completion.
No exceptions.

### 4. Treat Compressed Summary as Evidence

Main Agent MUST NOT treat a compressed or summarized version of worker output
as evidence of completion. The evidence hierarchy is:
Verifier result > Transcript > Registry entry > Progress event > Summary.

Summary is UNTRUSTED unless corroborated by verifier. Compressed summary is
NEVER evidence.

## Anti-Patterns

- "I''ll just write this small part myself" → governance violation
- "The worker almost finished, close enough" → failed work is not success
- "The summary says it works" → summary is not evidence
- "I verified it myself" → Main Agent cannot self-verify
- "Let me skip preflight, it''s a simple spawn" → preflight is mandatory

## Version

| Field | Value |
|---|---|
| Phase | H18 |
| Category | protocols |
| Stability | stable |
| Depends on | BOUNDARY.md, role-model/agent-role-matrix.json |
| Referenced by | All scheduling and orchestration workflows |
