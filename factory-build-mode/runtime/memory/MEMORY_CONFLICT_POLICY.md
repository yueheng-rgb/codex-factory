# Memory Conflict Detection Policy

## Conflict Types

### 1. State Conflict
When project-state.json currentStage conflicts with actual task completion status.
**Rule**: task-graph.json is authoritative for task status. project-state.json must be updated to match.

### 2. Task Status Conflict
When multiple tasks are IN_PROGRESS (only 1 allowed for single-agent, 1 per agent for multi-agent).
**Rule**: Validate and flag. Oldest IN_PROGRESS task wins unless explicitly overridden.

### 3. ProjectId Mismatch
When a memory file's projectId does not match project-state.json.
**Rule**: BLOCK continuation. All files must have consistent projectId.

### 4. Stale Handoff
When handoff-packet.json is >24 hours old.
**Rule**: WARN. Allow continuation but flag staleness.

### 5. Risk Resolution Without Evidence
When a risk is marked RESOLVED but lacks resolutionEvidence.
**Rule**: WARN. Resolution is accepted but flagged.

### 6. Verifier Entry Without Command
When verifier-history entry lacks command field.
**Rule**: WARN. Entry is recorded but flagged.

### 7. Compressed Summary as Sole Evidence
When summary files exist but evidence paths are absent.
**Rule**: WARN. Compressed summaries are NOT evidence per memory boundary.

### 8. Decision Log Malformation
When a line in decision-log.jsonl is not valid JSON.
**Rule**: WARN. Malformed line is skipped but logged.

## Resolution Priority

1. Verifier results > Memory files
2. task-graph.json > project-state.json for task status
3. project-state.json > handoff-packet.json for stage
4. All > conversation memory (untrusted after rotation)
