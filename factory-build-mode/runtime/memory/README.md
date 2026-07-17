# External Memory Runtime

## What This Is

The file-based external memory system for Codex Factory projects. All state lives under {project}/.codex-factory/.

## Key Principles

- File-based MVP, not cloud memory yet
- Conversation memory is untrusted after rotation
- Compressed summaries are NOT evidence
- Memory guides Codex but cannot replace verifier evidence
- All memory files are project-local

## Memory Files

| File | Purpose |
|------|---------|
| project-state.json | Current stage, mode, progress |
| decision-log.jsonl | Append-only decision log |
| task-graph.json | Work items with status |
| architecture-map.json | Design decisions |
| requirement-map.json | Requirements + traceability |
| active-risks.json | Risk register |
| verifier-history.json | Verifier run history |
| handoff-packet.json | Continuation packet |

## Scripts

| Script | Purpose |
|--------|---------|
| init-memory.ps1 | Initialize .codex-factory/ directory |
| validate-memory.ps1 | Validate memory integrity |
| read-memory.ps1 | Read and summarize current state |
| recover-startup.ps1 | Startup recovery for new window |
| update-state.ps1 | Update project state |
| update-task.ps1 | Update task graph |
| append-decision.ps1 | Append decision log entry |
| generate-handoff.ps1 | Generate handoff packet |
