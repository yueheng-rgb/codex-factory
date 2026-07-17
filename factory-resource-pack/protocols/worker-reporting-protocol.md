# Worker Reporting Protocol

> Phase: H18 · Category: protocols · Stability: stable
> Depends on: BOUNDARY.md, role-model/agent-role-matrix.json, evidence-hierarchy.md

## Purpose

This protocol defines how worker agents (Builders and other implementing agents)
report completion of contracted work. A completion claim is only valid when all
required evidence components are present and independently verifiable.

## Completion Claim Requirements

A worker completion claim MUST include ALL of the following five components.
Missing any component invalidates the claim.

### 1. Registry Entry

The worker must be registered in `AGENT_REGISTRY.json` via Platform/factoryctl.

**Required fields:**
- `agentId`: unique identifier assigned at spawn
- `role`: worker role (e.g., Builder)
- `contractId`: the contract this worker is fulfilling
- `status`: must transition to `COMPLETED` (not `ACTIVE`, not `FAILED`)
- `spawnedAt`: timestamp of spawn
- `completedAt`: timestamp of completion claim

**Invalid states:**
- Worker not in registry → claim rejected
- Worker status not `COMPLETED` → claim rejected
- `completedAt` before `spawnedAt` → claim rejected (temporal inconsistency)
- `completedAt` more than 2x expected window after `spawnedAt` without progress events → suspect

### 2. Progress Event

At least one progress event must be recorded in `AGENT_PROGRESS.jsonl` before
the completion claim.

**Required fields:**
- `agentId`: matches registry entry
- `contractId`: matches contract
- `phase`: current work phase
- `timestamp`: when progress was recorded
- `summary`: brief description of progress state

**Invalid states:**
- No progress events → claim rejected
- All progress events have timestamps AFTER `completedAt` → claim rejected (retroactive progress)
- Last progress event is more than 4x expected interval before `completedAt` → stale progress, claim suspect
- All progress events are `phase: "started"` with no intermediate progress → insufficient evidence of work

### 3. Handoff / Completion Artifact

The worker must produce a completion artifact at a defined handoff path.

**Required contents:**
- Contract reference (`contractId`)
- Output artifact inventory (list of all produced files/artifacts with paths)
- Summary of work completed (human-readable but NOT the primary evidence)
- Known limitations or caveats (P2-level issues the worker is aware of)
- Path to full transcript
- Self-assessment against contract gates (informational only, not authoritative)

**Format:** Structured markdown or JSON at the contract-specified handoff path.

### 4. Transcript Path

The worker must provide the path to the complete, unedited transcript of the
implementation session.

**Transcript requirements:**
- Complete: covers the entire implementation session from start to completion claim
- Unedited: no sections removed, no modifications after the fact
- Traceable: includes timestamps or sequence markers
- Available: accessible to Verifier for gate checking

**Invalid states:**
- "Transcript not available" → claim rejected
- Transcript truncated (missing sections) → claim rejected
- Transcript edited after session → claim rejected (governance violation)
- Transcript is a summary, not the full session → claim rejected (summary ≠ transcript)

### 5. Contract Output Verification

The worker must verify that all contract-specified outputs exist and are accessible.

**Verification steps:**
- Enumerate all contract output requirements
- Confirm each output file/artifact exists at the specified path
- Confirm output format matches contract specification
- Note any discrepancies (informational, not authoritative — Verifier makes final determination)

## Completion Report Anti-Patterns

These patterns invalidate a completion claim. Workers MUST avoid them.
Main Agent MUST reject claims exhibiting any of these patterns.

### Vague Report

**Pattern:** "Implemented the auth module. It works. Done."

**Why invalid:** No evidence chain. No artifact inventory. No transcript reference.
No gate-by-gate self-assessment. Impossible to verify.

**Required instead:** Specific artifact inventory, transcript path, gate-by-gate
check, concrete output references.

### Missing Progress Event

**Pattern:** Completion claim with no prior progress event in the ledger.

**Why invalid:** No evidence that work was actually performed over time.
Could be fabricated after the fact.

**Required instead:** At minimum, one progress event at a midpoint in the work
with timestamp between `spawnedAt` and `completedAt`.

### Report Without Artifact

**Pattern:** Detailed completion report but no actual output files exist at the
claimed paths.

**Why invalid:** Report claims outputs that don''t exist. Fabrication or path error.

**Required instead:** Every claim of output must be verifiable by checking the
actual filesystem at the claimed path.

### Artifact Without Transcript

**Pattern:** Output files exist and look plausible, but no implementation
transcript is available.

**Why invalid:** Cannot verify that the worker (not another agent) produced the
output. Cannot verify the process followed architecture constraints. Cannot
verify scope boundaries were respected.

**Required instead:** Complete transcript must accompany all artifacts.

### Stale Progress

**Pattern:** Progress event timestamp is many hours before completion claim,
with no intermediate progress events.

**Why invalid:** The reported progress may not reflect the actual state of work
at completion time. The worker may have been idle or context may have been lost.

**Required instead:** Progress events should be reasonably spaced throughout
the work window. The last progress event should be within 2x the expected
progress interval of `completedAt`.

### Unverified Completion Claim

**Pattern:** Worker self-reports PASS on all gates without verifier check.

**Why invalid:** Workers cannot self-verify. PASS/FAIL determination is the
Verifier''s exclusive authority.

**Required instead:** Worker may provide informational self-assessment, but
must explicitly note: "Verifier determination is authoritative. This
self-assessment is informational only."

### Compressed Summary as Transcript

**Pattern:** Worker provides a one-paragraph summary and calls it a "transcript."

**Why invalid:** Summary ≠ transcript. Summary discards evidence. Per
`evidence-hierarchy.md`, summary is UNTRUSTED unless corroborated.

**Required instead:** Full, unedited transcript. Summary may accompany
transcript as a convenience, but does not replace it.

## Completion Report Template

```json
{
  "contractId": "<contract-id>",
  "agentId": "<agent-id>",
  "role": "builder",
  "completedAt": "<ISO-8601 timestamp>",
  "registryEntryConfirmed": true,
  "progressEvents": [
    { "phase": "started", "timestamp": "<ISO-8601>" },
    { "phase": "in-progress", "timestamp": "<ISO-8601>" },
    { "phase": "completed", "timestamp": "<ISO-8601>" }
  ],
  "artifactInventory": [
    { "path": "<relative-path>", "type": "source|config|test|doc", "description": "<brief>" }
  ],
  "transcriptPath": "<path-to-transcript>",
  "contractOutputs": [
    { "requirement": "<contract output requirement>", "path": "<output-path>", "status": "present|missing" }
  ],
  "selfAssessment": {
    "disclaimer": "INFORMATIONAL ONLY. Verifier determination is authoritative.",
    "gates": [
      { "gateId": "<gate-id>", "selfStatus": "likely-pass|likely-fail|uncertain", "note": "<brief>" }
    ]
  },
  "knownLimitations": [
    { "severity": "P2", "description": "<caveat description>" }
  ]
}
```

## Verification Flow

1. Worker submits completion report to Main Agent and Platform
2. Platform records completion in registry and progress ledger
3. Main Agent schedules Verifier check (does NOT self-verify)
4. Verifier checks all five evidence components
5. Verifier produces JSON verdict
6. If PASS → Main Agent proceeds to integration scheduling
7. If FAIL → Main Agent initiates repair or replacement per scheduling protocol

## Version

| Field | Value |
|---|---|
| Phase | H18 |
| Category | protocols |
| Stability | stable |
| Depends on | BOUNDARY.md, role-model/agent-role-matrix.json, evidence-hierarchy.md |
| Referenced by | main-agent-scheduling-protocol.md, integrator-verifier-boundary.md |
