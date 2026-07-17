# LIVE-RUNTIME-1-E: Automation Rotation Watcher Plan

**Status**: PLAN ONLY — no production implementation

## What to Monitor
- currentTrustedPhase staleness
- session-rotation-handoff.json age
- Compressed context signal detection
- Agent registry active/stale counts
- Verifier result staleness vs state
- Factory-state write timestamps

## Rules
- Alert is NOT a verifier PASS
- Read-only: never writes governance state
- Never advances phase
- Never creates handoff
- Recommend manual session rotation + startup verification when stale

## Remaining
- Runtime scheduling (cron/task scheduler)
- Automated alert routing
- Compact-context signal from Codex environment API
- Integration into factoryctl watch command
