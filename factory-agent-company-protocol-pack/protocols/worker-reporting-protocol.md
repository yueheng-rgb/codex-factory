# Worker Reporting Protocol

> **Version**: 1.0.0 | **Phase**: FACTORY-AGENT-1 | **Schema**: `worker-reporting.schema.json`

## 1. Purpose

Every Builder agent MUST submit structured reports during its lifecycle. Reports provide visibility to the Orchestrator, enable early detection of blockers, and serve as evidence that real work is being performed. Reports MUST conform to `worker-reporting.schema.json`.

## 2. Required Report Types

### 2.1 PROGRESS (Periodic)

**Trigger**: Automatically generated at configurable intervals (default: every 5 minutes of active work, or at significant milestone boundaries).

**Required content**:
- `completionPercent`: Estimated completion (0-100). Must be justified by concrete file count and milestone progress.
- `filesCreated`: Every file created since the last PROGRESS report, each with SHA256.
- `nextExpectedMilestone`: Concrete, verifiable next step (not "continue working").

**Anti-deception rule**: A PROGRESS report with `completionPercent` that does not match the file count and milestone evidence is rejected. The Orchestrator must cross-reference.

### 2.2 BLOCKER (Issue)

**Trigger**: Whenever the agent encounters an issue that prevents or degrades progress.

**Required content**:
- `blockersDetected`: Non-empty array. Each blocker must include:
  - `description`: Clear, specific description.
  - `severity`: P0 (blocks all progress), P1 (degrades quality/speed), P2 (minor).
  - `targetGate`: Which gate or milestone is impacted.
- `detail`: Must describe what the agent tried, what failed, and what it needs to proceed.

**Blocker escalation path**:

| Severity | Escalation Target | Timeout |
|----------|-------------------|---------|
| P0 | Orchestrator (immediate) | 0 seconds |
| P1 | Orchestrator (batched) | 5 minutes |
| P2 | Logged only, no escalation | N/A |

**Anti-deception rule**: A BLOCKER report with severity P0 but no concrete blocking condition (i.e., "might be blocked later") is rejected as a false alarm.

### 2.3 STATUS (Completion)

**Trigger**: When the agent believes it has completed all expected outputs and is ready to hand off.

**Required content**:
- `completionPercent`: MUST be 100.
- `filesCreated`: Complete manifest of all files, with SHA256.
- `detail`: Summary of all completed work, referencing expectedOutputs from the capsule.
- `nextExpectedMilestone`: "HANDOFF" — this triggers the handoff protocol.

**Anti-deception rule**: A STATUS report with `completionPercent: 100` but `filesCreated` that does not include all expected outputs is rejected.

## 3. File Evidence Requirements

### 3.1 SHA256 Mandate

Every file referenced in any report MUST include a SHA256 checksum. The checksum:

- Allows the Orchestrator to verify file integrity across transfers.
- Prevents silent file corruption from being accepted.
- Enables cross-referencing between PROGRESS → STATUS → HANDOFF reports.

### 3.2 File Count vs. Completion

**Rule**: File count alone does NOT prove completion. The Orchestrator MUST verify:

1. All expectedOutputs from the capsule exist in the final file manifest.
2. Every file has a SHA256 that matches the actual file content.
3. The content is substantive (non-trivial file sizes, not placeholders).

## 4. Report Validation (Orchestrator-Side)

The Orchestrator MUST validate every incoming report against these rules:

| Check | Rule | Rejection Action |
|-------|------|-----------------|
| Schema compliance | Report must validate against `worker-reporting.schema.json` | Reject, request re-submission |
| SHA256 completeness | Every `filesCreated` entry must have SHA256 | Reject report |
| nativeGenerated = true | Report must be machine-generated | Reject, P0 escalation |
| File count vs completion% | `completionPercent: 100` but no files = contradiction | Reject, flag for review |
| Empty detail | `detail` must be substantive | Reject report |
| Duplicate reportId | Each reportId must be unique | Reject, P0 escalation |

## 5. Anti-Deception Rules for Reporting

### 5.1 Markdown-Only Reports ≠ PASS

A STATUS report that is purely descriptive ("all done, looks good") without concrete file evidence is **rejected**. Reports must contain machine-verifiable data (SHA256, file paths, sizes).

### 5.2 Report Without Artifacts = Rejected

Any report that references work but includes an empty `filesCreated` array is **rejected**. Work that produces no files is not work.

### 5.3 Completion Percent Inflation

If `completionPercent` jumps from 20% to 100% in a single PROGRESS → STATUS transition with minimal file creation, the Orchestrator MUST flag this as suspicious and require additional evidence.

### 5.4 Compressed Summary as Evidence = Rejected

A `detail` field that summarizes work in one vague sentence (e.g., "completed all tasks") without referencing specific files, checksums, or milestones is **rejected**.

## 6. Report Storage and Indexing

All reports are stored in the factory audit log at:

```
factory-agent-company-protocol-pack/reports/{phase}/{agentId}/
```

Each report file is named: `{reportId}.json`

The Orchestrator maintains an index: `reports/{phase}/_index.json` mapping reportId → agentId → timestamp.
