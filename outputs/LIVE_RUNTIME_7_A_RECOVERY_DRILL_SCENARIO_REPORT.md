# LIVE-RUNTIME-7-A: Recovery Drill Scenario Definition Report

**Generated**: 2026-06-25T00:42:46+08:00
**Phase**: LIVE-RUNTIME-7-A
**Status**: COMPLETE

## Overview

4 drill scenarios defined to test end-to-end context-limit recovery chain:
Watcher → Controller → Context OS/MCP Memory → Startup Verification → Safe Continuation

## Drill Scenarios

| ID | Name | Trigger | Watcher | Controller | Startup | Next Action |
|----|------|---------|---------|------------|---------|-------------|
| DRL-01 | CONFIRMED_COMPACT_BEFORE_MAJOR_PHASE | Compact marker detected | ROTATION_REQUIRED | manual_new_window | Must PASS in new carrier | Narrow task only |
| DRL-02 | STALE_CONTEXT_RECOVERY | Stale handoff/packet | ROTATION_REQUIRED | stale flag; full checks | BLOCKED if unreconciled | Repair + retry |
| DRL-03 | MEMORY_CONFLICT_RECOVERY | Context OS vs verifier mismatch | ROTATION_REQUIRED | conflict flag; must reconcile | BLOCKED until resolved | Reconciliation first |
| DRL-04 | CLEAN_ROTATION_RECOVERY | Clean state, precaution rotation | ROTATION_RECOMMENDED | standard packet | PASS → narrow only | NOT phase closure |

## Rules

- All scenarios use only repo artifacts, verifier JSON, manifest SHA — NO conversation memory
- Watcher/controller do NOT mutate state
- Startup verification mandatory before continuation
- Compressed summary NEVER evidence
- Clean scenario does NOT mean automatic phase closure

## Verdict

LIVE-RUNTIME-7-A: **COMPLETE** — 4 drill scenarios defined
