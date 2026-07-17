# RC-SMOKE-1 — Section A: Scope Lock

**Phase:** RC-SMOKE-1 | **Section:** A | **Status:** SCOPE_LOCKED

## Purpose
Live command coverage to close the RC-USER-ACCEPTANCE-0 WARNING_COMMAND_COVERAGE gap.
Gates, memory, cleanup, phase-close were policy-verified — now live-executed in safe fixtures.

## Prerequisites
- [x] RC-USER-ACCEPTANCE-0 PASS 26/26 (with coverage warning)
- [x] RC-SMOKE-0 PASS 31/31
- [x] RC0 SHA: A058FD67...

## Constraints
No release. No v0.5. No deploy. No prod DB. No real secrets. No package modification.
Live smoke PASS does not auto-unblock v0.5.

**Section A verdict: SCOPE_LOCKED**
