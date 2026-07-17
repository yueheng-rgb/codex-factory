# Worker Handoff Protocol

> **Version**: 1.0.0 | **Phase**: FACTORY-AGENT-1 | **Schema**: `worker-handoff.schema.json`

## 1. Purpose

The Worker Handoff is the formal transfer of completed work from a Builder agent to the Integration Lead. It is the definitive record of what was produced, how it was verified, and what issues remain. A handoff without full SHA256 coverage and a complete contract checklist is **automatically rejected**.

## 2. Handoff Prerequisites

Before a Builder may initiate handoff, the following conditions MUST be met:

1. **STATUS report submitted**: A STATUS report with `completionPercent: 100` has been filed and acknowledged by the Orchestrator.
2. **All expectedOutputs exist**: Every `{path, description}` from the capsule's `expectedOutputs` maps to a real file.
3. **All SHA256 checksums computed**: Every file has a fresh SHA256 digest.
4. **Contract checklist prepared**: Every item in the capsule's contract has been reviewed with evidence.
5. **Transcript reference exists**: The agent's activity transcript is available at a known path.

## 3. Handoff Contents

### 3.1 File Manifest (`files`)

A complete list of every file produced by the agent. Each entry:

| Field | Requirement |
|-------|------------|
| `path` | Absolute or workspace-relative path. Must be within ownedScope. |
| `sha256` | 64-character lowercase hex digest. Freshly computed at handoff time. |
| `size` | File size in bytes. Must be > 0 for substantive files. |

**Rule**: The file manifest MUST include ALL files, not just "deliverables." Configuration files, helper files, and evidence files must all be listed.

### 3.2 Contract Checklist (`contractChecklist`)

Every item from the capsule's expected outputs and required evidence, checked off with concrete proof:

| Field | Requirement |
|-------|------------|
| `item` | Description of the contract item. |
| `completed` | `true` only if provably complete. |
| `evidence` | Path to file, checksum, or log excerpt proving completion. |

**Rule**: Every contract item MUST appear in the checklist. Items marked `completed: true` MUST have non-empty evidence. Items marked `completed: false` MUST appear in `knownIssues`.

### 3.3 Transcript Reference (`transcriptRef`)

A path string pointing to the agent's activity transcript. The transcript:

- Proves that the agent genuinely performed work (not just generated a manifest).
- Must be timestamped and attributable to the agent.
- The Orchestrator may sample the transcript against the file manifest for consistency.

### 3.4 Known Issues (`knownIssues`)

All issues the agent is aware of at handoff time:

| Field | Requirement |
|-------|------------|
| `description` | Clear problem statement. |
| `severity` | P0, P1, or P2. |
| `workaround` | Available mitigation. Use `"NONE"` if no workaround exists. |

**Rule**: P0 known issues MUST block handoff acceptance by the Integrator unless explicitly waived by the Orchestrator.

### 3.5 Verification Target (`verifiedBy`)

Initially set to `null`. Populated by the Verifier agent after handoff validation. This field is the only field not set by the Builder.

## 4. Handoff Validation (Integrator-Side)

The Integration Lead MUST validate every handoff before accepting it:

| Check | Rule | Failure Action |
|-------|------|---------------|
| SHA256 match | Every file's SHA256 must match actual file content | Reject handoff |
| File manifest complete | All expectedOutputs present in `files` | Reject handoff |
| Contract checklist complete | All items present, all `completed: true` have evidence | Reject handoff |
| Transcript exists | `transcriptRef` is a valid, readable path | Reject handoff |
| knownIssues non-blocking | No P0 issues, or P0 issues waived by Orchestrator | Reject handoff |
| nativeGenerated = true | Handoff is machine-generated | Reject handoff, P0 escalation |
| ownedScope compliance | All file paths are within ownedScope | Reject handoff, escalate scope contamination |

## 5. Handoff Rejection Reasons

### 5.1 Missing SHA256

If any file in the manifest lacks a SHA256 checksum → **immediate rejection**. The Builder must recompute and resubmit.

### 5.2 Incomplete Contract Checklist

If any contract item is missing from the checklist, or any `completed: true` item lacks evidence → **rejection**. The Builder must complete the checklist.

### 5.3 No Transcript Reference

If `transcriptRef` is empty or points to a non-existent file → **rejection**. Handoff without a transcript is treated as potential deception.

### 5.4 File List Mismatch

If the Integrator discovers files on disk that are not in the manifest, or manifest entries that don't exist on disk → **rejection**. File list must be exact.

### 5.5 Scope Contamination

If any file path is outside ownedScope or inside forbiddenScope → **rejection + P0 escalation**.

## 6. Handoff Consumption by Integrator

### 6.1 Acceptance

Once validated, the Integrator:

1. Signs the handoff by setting `verifiedBy` to the verifier's agentId.
2. Copies all files from the agent's workspace to the integration staging area.
3. Archives the handoff JSON and transcript.
4. Triggers close receipt generation for the Builder.

### 6.2 Integration Staging

All accepted handoff files are staged at:

```
factory-agent-company-protocol-pack/staging/{phase}/{agentId}/
```

The Integrator merges from staging into the integration workspace per `integration-merge-protocol.md`.

## 7. Anti-Deception Rules for Handoff

| Rule | Trigger | Action |
|------|---------|--------|
| Handoff without SHA256 | Any file entry lacking SHA256 | Reject handoff |
| File list mismatch | Manifest ≠ actual files | Reject handoff, P0 escalation |
| Markdown-only handoff | All files are `.md` with no code/artifacts | Reject handoff, flag for review |
| Empty file handoff | All files have size near 0 | Reject handoff, P0 escalation |
| Preclassified-only evidence | Evidence is classifications, not actual artifacts | Reject handoff |
| Compressed summary as transcript | `transcriptRef` points to a one-line summary | Reject handoff |
