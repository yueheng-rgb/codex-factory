# Worker Capsule Protocol

> **Version**: 1.0.0 | **Phase**: FACTORY-AGENT-1 | **Owner**: Orchestrator

## 1. Purpose

The Worker Capsule is the fundamental isolation and contract boundary for every Builder agent in the Codex App Factory. No Builder agent may operate without a valid, validated capsule. The capsule defines what the agent may touch, what it must produce, and what evidence it must leave behind.

## 2. Capsule Creation (Orchestrator-Only)

### 2.1 Pre-Spawn Capsule Generation

Before any Builder is spawned, the Orchestrator MUST:

1. **Generate capsuleId**: Format `capsule-{phase}-{agentId}-{timestamp14}`.
2. **Define ownedScope**: List all filesystem paths the agent is authorized to read and write. Every expected output path MUST fall within ownedScope.
3. **Define forbiddenScope**: Explicitly list paths the agent MUST NOT touch. This includes other agents' owned scopes, shared configuration files, and system directories.
4. **Set forkContext to `false`**: Forking is strictly forbidden. Every agent receives a fresh capsule.
5. **Populate allowedImports / forbiddenImports**: List approved and disallowed modules, tools, and protocols.
6. **Define expectedOutputs**: Every `{path, description}` entry represents a concrete deliverable. No handoff is valid unless all expected outputs exist.
7. **Define requiredEvidence**: Specify evidence types the agent must produce (e.g., `"SHA256_FILE_MANIFEST"`, `"TRANSCRIPT_REF"`, `"CONTRACT_CHECKLIST"`).
8. **Populate handoffRequirements**: All four booleans — `fileList`, `sha256`, `transcriptRef`, `contractChecklist` — MUST be `true`.
9. **Define closeConditions**: At minimum, define conditions for COMPLETED, FAILED, STALE, and REPLACED.
10. **Define antiDeceptionChecks**: At minimum: `"NO_FAKE_FILES"`, `"NO_MARKDOWN_ONLY_PASS"`, `"NO_SHA256LESS_HANDOFF"`, `"NO_UNVERIFIED_CLOSE"`.
11. **Define escalationTriggers**: At minimum: scope contamination, SHA256 mismatch, missing evidence, stalling.
12. **Set assignedBy**: The Orchestrator's own agentId.
13. **Set assignedAt**: Current ISO 8601 timestamp.
14. **Set contractVersion**: Semantic version string (e.g., `"1.0.0"`).

### 2.2 Capsule Validation (Pre-Delivery)

Before delivering the capsule to a Builder, the Orchestrator MUST validate:

| Check | Rule | Failure Action |
|-------|------|---------------|
| ownedScope exists | At least one path defined | Reject capsule, re-generate |
| forbiddenScope defined | Explicitly listed, even if empty (`[]`) | Reject if missing entirely |
| forkContext is false | MUST be `false` | Reject capsule |
| expectedOutputs non-empty | At least one deliverable | Reject capsule |
| handoffRequirements all true | All four booleans = `true` | Reject capsule |
| contractVersion matches | Matches Factory phase's expected version | Reject capsule |

## 3. Capsule Delivery (Spawn Time)

At spawn time, the Orchestrator delivers the validated capsule to the Builder agent. The capsule becomes the single source of truth for:

- What the agent may read/write (ownedScope)
- What the agent must not touch (forbiddenScope)
- What the agent must produce (expectedOutputs)
- What evidence is required (requiredEvidence)
- How to hand off (handoffRequirements)
- When to close (closeConditions)
- What triggers escalation (escalationTriggers)

The Builder MUST acknowledge receipt of the capsule before beginning any work. Acknowledgement is recorded in the spawn log.

## 4. Capsule Amendment (Pre-Spawn Only)

Capsules may ONLY be amended by the Orchestrator, and ONLY before the Builder is spawned.

### 4.1 Valid Amendments

- Adding or removing items from ownedScope (reflecting phase spec changes)
- Updating expectedOutputs (reflecting design changes)
- Adjusting closeConditions (reflecting new risk factors)

### 4.2 Invalid Amendments

- Amending a capsule after Builder spawn (creates contract ambiguity)
- Builder self-amending its capsule (P0 integrity violation)
- Amending forkContext to `true` (never allowed)

### 4.3 Amendment Process

1. Orchestrator detects need for amendment.
2. Orchestrator creates new capsule version, increments contractVersion.
3. Old capsule is invalidated (marked `REPLACED`).
4. Builder is terminated with `REPLACED` closeReason if already spawned.
5. New Builder is spawned with amended capsule.

## 5. Builder Operation Without Capsule

### 5.1 Detection

If the system detects a Builder operating without a valid capsule:

1. **Immediate block**: All file I/O is rejected.
2. **Log event**: `CAPSULE_MISSING` with agentId and timestamp.
3. **Escalate to Orchestrator**: Trigger `NO_CAPSULE_DETECTED`.
4. **Do NOT spawn replacement**: Wait for Orchestrator investigation.

### 5.2 Root Cause Analysis

Orchestrator must determine:
- Was the capsule never created? (Orchestrator bug)
- Was the capsule lost during delivery? (transport bug)
- Did the agent bypass capsule checks? (P0 integrity violation)

## 6. Capsule Violation Handling

### 6.1 Scope Contamination

If a Builder writes to a path outside ownedScope or inside forbiddenScope:

1. **Quarantine agent**: Immediately halt all operations.
2. **Log contamination event**: `SCOPE_CONTAMINATION` with:
   - agentId
   - expectedScope (ownedScope)
   - actualPath (violation path)
   - fileContent SHA256
3. **Escalate to Orchestrator**: Trigger `SCOPE_VIOLATION` with P0 severity.
4. **Quarantine contaminated files**: Move to quarantine directory, do not merge.
5. **Generate close receipt**: closeReason = `FAILED`, spawnFailureClassified = `CONFIGURATION`.

### 6.2 Expected Output Missing

If at handoff time, any expectedOutput item does not exist:

1. **Reject handoff**: Return to Builder with missing items listed.
2. **Log event**: `EXPECTED_OUTPUT_MISSING`.
3. If Builder cannot resolve within one retry cycle → escalate, close as `FAILED`.

### 6.3 Evidence Missing

If requiredEvidence items are not present in handoff:

1. **Reject handoff**: Return to Builder.
2. **Log event**: `EVIDENCE_MISSING`.
3. No retry — escalate immediately. Missing evidence = possible deception.

## 7. Capsule Lifecycle Summary

```
Orchestrator creates capsule
        ↓
Orchestrator validates capsule
        ↓
Orchestrator delivers capsule to Builder at spawn
        ↓
Builder acknowledges capsule
        ↓
Builder operates within capsule constraints
        ↓
Builder produces artifacts + evidence
        ↓
Builder performs handoff (must satisfy handoffRequirements)
        ↓
Verifier validates handoff
        ↓
Builder generates close receipt
        ↓
Capsule archived with all artifacts
```
