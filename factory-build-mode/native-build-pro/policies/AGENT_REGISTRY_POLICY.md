# Native Agent Registry Policy

## Required For Every Native Build Pro Run

1. **Registry must exist before spawning**: Create registry JSON in trial `.codex-factory/`.
2. **Every agent recorded**: id, nickname, role, nativeSpawned, forkContext, status.
3. **Handoff recorded**: timestamp and output summary.
4. **Close receipt recorded**: close_agent return value captured.
5. **Pre-close audit**: verify all agents completed, 0 stale, 0 orphan before closing phase.
6. **Post-close verification**: verifier checks registry completeness.

## Forbidden
- Closing phase with active agents
- Treating handoff notification as close evidence
- Omitting agent IDs
- Counting UI panel as registry
