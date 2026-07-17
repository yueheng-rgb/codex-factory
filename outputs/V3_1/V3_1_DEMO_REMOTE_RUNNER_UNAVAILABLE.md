# V3.1 — Remote Runner Unavailable Pipeline Demo

## Purpose

Demonstrate that V3.1 honestly admits when remote/container runners are not available,
rather than silently passing or faking remote execution.

## Runners Probed

| Runner | Status | Isolation | Artifact Capture |
|--------|--------|-----------|------------------|
| remote-placeholder | NOT_IMPLEMENTED | container (claimed) | No |
| container-placeholder | NOT_IMPLEMENTED | container (claimed) | No |

## Execution Attempt

- **Remote execution attempted:** No (no runner available to attempt)
- **Result:** REMOTE_RUNNER_NOT_CONFIGURED
- **Gate Decision:** BLOCKED

## Why BLOCKED Is Correct

A task claiming to use a remote runner must be BLOCKED when:
1. No real remote runner is connected
2. No container runtime is available
3. No cloud execution capability exists
4. No cross-machine artifact store is configured

## Trust Level

**NONE** — No remote/container runner configured. All execution is local.

## Non-Claims

- remote-placeholder is NOT a real remote runner
- container-placeholder is NOT a real container runtime
- This environment has NO cloud or container execution capability
- Do NOT claim remote/container isolation for local runs

## Result

**BLOCKED** — REMOTE_RUNNER_NOT_CONFIGURED (honest admission)