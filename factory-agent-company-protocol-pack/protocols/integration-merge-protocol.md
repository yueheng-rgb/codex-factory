# Integration & Merge Protocol

> **Version**: 1.0.0 | **Phase**: FACTORY-AGENT-1 | **Owner**: Integration Lead

## 1. Purpose

This protocol defines how the Integration Lead merges outputs from multiple Builder agents into a unified, consistent workspace. Integration is the most sensitive operation in the factory — cross-scope issues, contamination, and merge conflicts must be handled with strict controls.

## 2. Pre-Merge Gate

### 2.1 All Handoffs Received and Validated

Before ANY merge begins, the Integration Lead MUST confirm:

1. **All expected handoffs received**: Every agent assigned to the phase has submitted a handoff.
2. **All handoffs validated**: Every handoff has passed validation per `worker-handoff-protocol.md`.
3. **All `verifiedBy` fields populated**: Every handoff has been signed by the Verifier agent.
4. **No P0 known issues outstanding**: Any P0 issues have been resolved or waived by the Orchestrator.

### 2.2 Pre-Merge Checklist

| Check | Rule | Blocking? |
|-------|------|-----------|
| Handoff count matches agent count | Phase spec defines N agents → N handoffs | YES |
| All handoffs pass SHA256 validation | Every file checksum matches | YES |
| All contract checklists complete | All items checked, all evidence present | YES |
| No scope overlaps detected | ownedScopes are disjoint | YES |
| No contamination detected | No file outside ownedScope | YES |
| All transcripts available | Every agent has readable transcript | NO (warn) |

### 2.3 Gating Decision

- **All blocking checks pass** → Proceed to merge.
- **Any blocking check fails** → Halt merge, escalate to Orchestrator.

## 3. Merge Process

### 3.1 Merge Order

Files are merged in dependency order. The Integration Lead MUST:

1. Resolve the dependency graph from the task graph.
2. Merge agents with no dependencies first.
3. Merge dependent agents only after their dependencies are integrated.
4. Verify that dependency outputs are available before merging dependents.

### 3.2 Merge Operations

For each file from a validated handoff:

1. **Copy to integration workspace**: From `staging/{phase}/{agentId}/` to the integration target.
2. **Verify SHA256 post-copy**: Checksum must match the handoff manifest.
3. **Update dependency graph**: Mark the file's module as integrated.
4. **Declare integration point**: Record the merge in the integration log.

### 3.3 Integration Point Declaration

Every merge operation is recorded:

```json
{
  "mergeId": "merge-{phase}-{sequence}",
  "agentId": "...",
  "handoffId": "...",
  "filesMerged": ["path1", "path2"],
  "mergedAt": "ISO timestamp",
  "postMergeSHA256": ["abc...", "def..."],
  "conflicts": [],
  "repairs": []
}
```

## 4. Post-Merge Verification

### 4.1 Reviewer Check

After merge, a Reviewer agent (distinct from the Integrator) MUST:

1. Verify that all merged files are at expected paths.
2. Spot-check SHA256 of 10% of files (minimum 3 files if fewer than 30).
3. Confirm no files from different agents occupy the same path.
4. Verify the integration workspace is internally consistent (no broken references).

### 4.2 Verifier Check

A separate Verifier agent MUST:

1. Re-run SHA256 validation on all merged files.
2. Confirm the dependency graph is fully resolved.
3. Sign off on the integration log.

## 5. Conflict Resolution

### 5.1 Detection: Two Builders Modify Same File

If two agents produce files at the same path, this is a **scope contamination** event:

1. **Halt merge** for the conflicting file.
2. **Log conflict**: Record both agentIds, both file SHA256s, and the path.
3. **Escalate to Orchestrator**: The Orchestrator decides which output takes precedence or whether both agents must be re-run with revised scopes.
4. **Do NOT silently resolve**: The Integrator MUST NOT pick one agent's output over another's without Orchestrator authorization.

### 5.2 Conflict Resolution Paths

| Scenario | Resolution |
|----------|-----------|
| Identical content (same SHA256) | Safe to merge, log the duplication |
| Different content, one agent owns the scope | Agent A's scope includes path, Agent B's doesn't → B violated scope, quarantine B's output |
| Different content, both scopes overlap | Orchestrator error — both capsules had overlapping ownedScopes, both agents re-spawned |
| Different content, integration file | If the file is an integration point (e.g., index file) → Integrator may merge manually with Orchestrator approval |

## 6. Repair Declarations

### 6.1 When Repairs Are Needed

The Integrator MUST declare repairs when:

- Cross-scope references are broken (Agent A's file references Agent B's output that isn't available).
- Configuration files need consolidation from multiple agents.
- Index or manifest files must aggregate outputs from multiple agents.

### 6.2 Repair Rules

| Rule | Description |
|------|-------------|
| Integrator MUST NOT write Builder scope | Repairs are limited to integration glue; never rewrite Builder output |
| Every repair MUST be declared | Recorded in the integration log with justification |
| Repairs MUST be verified | Reviewer checks all repairs |
| No silent repairs | Any unlogged repair = P0 integrity violation |

### 6.3 Repair Declaration Format

```json
{
  "repairId": "repair-{mergeId}-{sequence}",
  "file": "path/to/repaired/file",
  "reason": "Cross-scope index consolidation",
  "affectedAgents": ["agentId1", "agentId2"],
  "repairDescription": "...",
  "verified": false
}
```

## 7. Anti-Deception Rules for Integration

| Rule | Trigger | Action |
|------|---------|--------|
| Integrator writes Builder scope | Any file modified inside a Builder's ownedScope | P0 escalation, revert |
| Merge without Verifier check | Integration log lacks verifier sign-off | Block merge, require verification |
| Silent conflict resolution | Conflict resolved without Orchestrator approval | P0 escalation |
| Unlogged repair | Repair exists but not in integration log | P0 escalation |
| Merge with missing handoff | Merging before all handoffs received | Block merge |
| Merge with failed SHA256 | Post-merge SHA256 doesn't match | Revert merge, re-validate |
