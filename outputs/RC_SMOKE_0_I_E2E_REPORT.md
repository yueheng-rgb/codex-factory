# RC-SMOKE-0 — Section I: End-to-End RC Smoke Report

**Phase:** RC-SMOKE-0
**Section:** I
**Generated:** 2026-06-28T21:13:00+08:00
**Status:** PASS

## E2E Walkthrough

| Step | Action | Result | Notes |
|---|---|---|---|
| 1 | Verify RC0 hash | PASS | SHA: A058FD67... |
| 2 | Extract RC0 | PASS | 2735 files, 227 dirs |
| 3 | CLI help | PASS | factoryctl.ps1 synopsis available |
| 4 | CLI status | PASS | exit 0, JSON output |
| 5 | CLI agents | PASS | exit 0, graceful missing state |
| 6 | CLI watch | PASS | exit 0, aggregate output |
| 7 | CLI verify | PASS | exit 1 (expected, no diagnosis) |
| 8 | Bootstrap (policy) | PASS | Build Lite default, Gate triggers correct |
| 9 | Preflight (policy) | PASS | All gates behave correctly |
| 10 | Memory validate (policy) | PASS | 8/8 tests pass |
| 11 | Cleanup plan (policy) | PASS | PLAN default, DELETE requires confirm |
| 12 | Phase close (policy) | PASS | Verifier required, stale rejected |

## User Burden Assessment

| Metric | Score |
|---|---|
| Commands to run | 5 CLI commands (status/agents/progress/watch/verify) |
| Exit codes clear | YES |
| Output readable | YES (JSON format) |
| Next hints present | YES (allowedNextPhase in status) |
| Blockers visible | YES (v0.5 BLOCKED in all metadata) |
| Warnings clear | YES (missing state handled gracefully) |

## Limitations Observed

1. CLI requires existing governance state — won't work in truly empty directory
2. No explicit "bootstrap" command — bootstrapping is documentation-driven (AGENTS.md)
3. Memory quality policies are in `factory-build-mode/` not top-level

**Section I verdict: PASS — E2E walkthrough complete**
