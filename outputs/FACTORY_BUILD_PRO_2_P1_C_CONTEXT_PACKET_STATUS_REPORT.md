# FACTORY-BUILD-PRO-2-P1 — Section C: Context Packet Status Decision Report

**Phase**: FACTORY-BUILD-PRO-2-P1 | **Date**: 2026-06-27

## Decision

**Context Packet: REQUIRED for Native Build Pro / long-horizon mode.**

| Mode | Context Packet Status |
|------|----------------------|
| Build Lite | OPTIONAL |
| Native Build Pro | **REQUIRED** |
| Long-horizon | **REQUIRED** (per-iteration) |
| Recovery | **REQUIRED** (RECOVERY_PACKET) |
| Native agent start | **REQUIRED** (AGENT_START_PACKET) |

## Rationale

PRO-2 used 10 context packets across 3 iterations. Without structured minimal context, agents lose role boundaries and memory degrades across iterations. The ~15% overhead is justified for Build Pro but excessive for Build Lite.
