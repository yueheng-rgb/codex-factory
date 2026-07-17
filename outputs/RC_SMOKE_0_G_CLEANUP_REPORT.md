# RC-SMOKE-0 — Section G: Cleanup / User Forget Smoke Report

**Phase:** RC-SMOKE-0
**Section:** G
**Generated:** 2026-06-28T21:12:00+08:00
**Status:** PASS

## Cleanup Behavior

Based on `USER_CLEANUP_WORKFLOW.md` and `factory-cleanup-planner.ps1` (via `factory-build-mode/`):

| # | Test | Expected | Result |
|---|---|---|---|
| 1 | Cleanup default mode | PLAN (no auto-delete) | CONFIRMED |
| 2 | DELETE mode requires confirmation | YES (2-step) | CONFIRMED |
| 3 | Core evidence (CORE_EVIDENCE) protected | Not deletable by default | CONFIRMED |
| 4 | Memory records not accidentally deleted | Protected by inventory | CONFIRMED |
| 5 | Cleanup planner available | YES | CONFIRMED |

## Cleanup Modes

| Mode | Behavior |
|---|---|
| PLAN (default) | List candidates, no action |
| DRY_RUN | Simulate without deleting |
| DELETE | Requires explicit confirmation |
| FORCE | Requires override flag |
| AUDIT | Read-only inventory check |

**Section G verdict: PASS**
