# Memory Filtering + Decay Policy

## Active Filtering (at ingestion time)
- **Redundancy filter**: Skip writes where content == previous version
- **Noise filter**: Reject L0-L1 claims without evidence paths
- **Size filter**: Individual .codex-factory/ files must be < 100KB

## Decay Rules (periodic or phase-boundary)
- **L0-L1**: Purge after phase closure (keep only phase summary reference)
- **L2**: Downgrade to archive after 2 phases
- **L3**: Keep until project closure, then archive
- **L4-L5**: Keep indefinitely as frozen evidence

## Contradiction Detection
- If L4 evidence contradicts L3 state → flag as CONTAMINATION
- If two L4 sources disagree → flag as EVIDENCE_CONFLICT
- If L0-L2 claim contradicts L4 → reject L0-L2, keep L4

## Archive Policy
- Create `factory-memory-archive/` for superseded L3-L5 files
- Never delete L4-L5 evidence
- Archive name format: `{project}-{phase}-archive-{date}.zip`
