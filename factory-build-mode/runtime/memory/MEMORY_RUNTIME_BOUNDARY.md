# Memory Runtime Boundary

## What Memory Files ARE

- External project state for Codex Factory
- File-based, project-local
- Structured (JSON schemas) and machine-readable
- Append-only where appropriate (decision log)
- Versioned and timestamped

## What Memory Files Are NOT

- NOT conversation memory
- NOT compressed summaries
- NOT authoritative evidence of product quality
- NOT a replacement for verifier results
- NOT cloud-synced (MVP)

## Trust Model

1. Conversation memory: UNTRUSTED after rotation
2. Compressed summaries: NOT evidence
3. Verifier results: authoritative for diagnostic gate
4. Memory files: guide continuation, do not prove quality
5. Handoff: convenience artifact, verified by startup recovery

## Authority Hierarchy

| Source | Authority | Scope |
|--------|-----------|-------|
| Verifier result JSON | HIGH | Diagnostic gate decisions |
| project-state.json | MEDIUM | Stage tracking |
| task-graph.json | MEDIUM | Work status |
| decision-log.jsonl | LOW | Context only |
| handoff-packet.json | LOW | Convenience, must be validated |
