# LIVE-RUNTIME-8-D: Carrier Decision Matrix Update Report

**Generated**: 2026-06-25T00:48:36+08:00
**Phase**: LIVE-RUNTIME-8-D
**Status**: COMPLETE

## Updated Classification

| Category | Carriers | Status |
|----------|----------|--------|
| **PRIMARY_SAFE_FALLBACK** | manual_new_window_artifact_handoff | VERIFIED_FACT (20+ sessions) |
| **SEMI_AUTOMATIC_IF_AVAILABLE** | app_thread_start/fork/resume | HYPOTHESIS (tools exist, untested) |
| **SEMI_AUTOMATIC_IF_AVAILABLE** | cli_new/fork/resume | PARTIALLY_VERIFIED (documented) |
| **NOT_A_NEW_CONTEXT** | automation_same_thread_wakeup | REJECTED |
| **INTERNAL_ONLY** | spawn_agent (both modes) | VERIFIED_FACT |
| **REJECTED** | Full context inheritance, auto window creation | REJECTED |

## Key Updates

- Thread/fork/new carriers are honestly classified as HYPOTHESIS — tools exist but untested for live carrier
- Manual artifact handoff remains PRIMARY_SAFE_FALLBACK
- Automation wakeup is NOT a new context carrier
- Subagents are INTERNAL_ONLY, never session carriers
- Full context inheritance and auto window creation remain REJECTED claims

## Verdict

LIVE-RUNTIME-8-D: **COMPLETE** — Decision matrix updated with LR8 carrier classifications
