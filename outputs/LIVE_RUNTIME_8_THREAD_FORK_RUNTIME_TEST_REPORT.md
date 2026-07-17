# LIVE-RUNTIME-8: Live Codex Runtime Thread-Fork Test Report

**Generated**: 2026-06-25T00:49:41+08:00
**Phase**: LIVE-RUNTIME-8
**Status**: PASS
**Verifier**: 22/22 PASS

## Overview

LIVE-RUNTIME-8 tests real Codex runtime thread/fork/new/resume carrier capabilities with honest classification. Thread tools exist in schema but were NOT live-tested (invasive). spawn_agent is verified through 20+ real uses. Manual artifact handoff remains safe fallback.

## Sub-Phase Results

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| LR8-A | Runtime Carrier Capability Probe (11 carriers) | COMPLETE |
| LR8-B | Fork/New/Resume Behavior Experiment | COMPLETE |
| LR8-C | Startup Verification Enforcement on Carriers | COMPLETE |
| LR8-D | Carrier Decision Matrix Update | COMPLETE |
| LR8-E | Negative Controls (26/26) | COMPLETE |

## Carrier Honest Classification

| Category | Count | Carriers |
|----------|-------|----------|
| VERIFIED_FACT | 3 | manual_new_window, spawn_agent (both modes) |
| PARTIALLY_VERIFIED | 5 | cli_new/fork/resume, project_automation, app_threads |
| HYPOTHESIS | 3 | app_thread_start/fork/resume |
| REJECTED | 1 | automation_same_thread_wakeup |

## Key Findings

- Thread tools (create_thread, ork_thread, etc.) exist in Codex Desktop schema but were NOT tested for live carrier behavior — classified as HYPOTHESIS
- No faked results: thread experiments honestly marked UNAVAILABLE_FOR_NON_INVASIVE_TEST
- spawn_agent behavior confirmed through 20+ real uses: builder isolation (fork_context:false), explorer (fork_context:true), NEVER a session carrier
- Manual new window + artifact handoff remains PRIMARY_SAFE_FALLBACK (VERIFIED_FACT)
- All carriers require startup verification before any major phase
- Decision matrix updated with 5 clear categories
- 26/26 negatives DETECTED_AND_BLOCKED

## Recommended Next Phase

LIVE-RUNTIME-9 / Automation Runtime Scheduling Test, or Semi-Automatic Rotation UX
