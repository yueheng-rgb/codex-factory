# Agent Lifecycle Protocol

## States
- **spawned**: Agent created via spawn_agent. fork_context recorded. Contract assigned.
- **in_progress**: Agent is executing its assigned scope. Progress events emitted.
- **completed**: Agent finished work. Registry updated. Contract outputs verified.
- **failed**: Agent did not complete. Failure classified (timeout, error, scope violation).
- **stale**: Agent has not emitted progress event within threshold (e.g., 30 min).
- **closed**: Agent explicitly closed via close_agent. Resources released.
- **archived**: Historical agent. Excluded from active capacity count.

## Transitions
- spawned → in_progress (on first progress event).
- in_progress → completed (on close_agent with success).
- in_progress → failed (on error, timeout, or close_agent with failure).
- any → stale (on progress timeout).
- completed/failed/stale → closed (on explicit close_agent).
- closed → archived (on phase closure, excluded from active capacity).

## Rules
- Failed agents MUST NOT be counted in success statistics.
- Stale agents count against active capacity until closed.
- Main Agent MUST NOT write implementation for failed worker.
- Replacement agent requires new contract + registry entry + fork_context:false.