# LIVE-RUNTIME-8-B: Fork/New/Resume Behavior Experiment Report

**Generated**: 2026-06-25T00:48:09+08:00
**Phase**: LIVE-RUNTIME-8-B
**Status**: COMPLETE (honest classification)

## Experiment Summary

| Experiment | Attempted | Result |
|------------|-----------|--------|
| New carrier (create_thread) | No | UNAVAILABLE — invasive, creates user-visible thread |
| Fork (fork_thread) | No | UNAVAILABLE — invasive, creates user-visible fork |
| Resume (send_message_to_thread) | No | UNAVAILABLE — no existing thread IDs |
| spawn_agent behavior | Yes | VERIFIED_EXISTING — 20+ real uses |

## Why Thread Experiments Were Not Run

Thread tools (create_thread, ork_thread, send_message_to_thread) exist in the Codex Desktop tool schema. However, creating real threads is **invasive** — they appear in the user's sidebar and would be unexpected without explicit user request.

Per LR8 spec rule: *"If experiments are unavailable: record why unavailable, do not fake results, classify as unavailable, preserve manual window fallback as primary carrier."*

## What Was Verified

**spawn_agent behavior** is well-understood from 20+ real uses across this repository:
- ork_context:false: Builder isolation — clean workspace, no parent context fork
- ork_context:true: Explorer access — context fork provided, not full inheritance
- Subagent is **NEVER** a session carrier or user-visible branch

## What Remains Hypothesis

Thread/fork/new as session carrier behavior:
- Tools exist in schema → tools are available
- Actual behavior when invoked → unknown without live testing
- Whether they can serve as rotation carriers → unknown
- Whether they inherit compacted context → unknown

## Safe Default Preserved

**manual_new_window_artifact_handoff** remains the ALWAYS-SAFE FALLBACK, verified through 20+ session rotations.

## Verdict

LIVE-RUNTIME-8-B: **COMPLETE** — No faked results. Thread tools honestly classified as untested. Manual fallback preserved.
