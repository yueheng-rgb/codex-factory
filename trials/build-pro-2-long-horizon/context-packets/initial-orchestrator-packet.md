# Context Packet: CP-6222-20260627154008

- **Target Phase**: FACTORY-BUILD-PRO-2
- **Target Role**: orchestrator
- **Packet Type**: PHASE_START_PACKET
- **Generated**: 2026-06-27T15:40:08.2009838+08:00
- **Expires**: 2026-06-27T16:40:08.2039039+08:00
- **Budget**: 312 / 2000 words

## Required Reads
- **HIGH**: `/factory-build-mode/memory-quality/policies/MEMORY_FILTERING_DECAY.md` — Decay policies
- **CRITICAL**: `/factory-build-mode/memory-quality/schemas/ROLE_CONTEXT_FILTERING.md` — Role filtering


## Active Risks
- **CRITICAL**: R001 — PRO-2 started before MEMORY-QUALITY-0-P1 complete
- **HIGH**: R002 — Compressed summary treated as evidence
- **CRITICAL**: R003 — Multi-agent default claimed without evidence


## Rejected Claims
- RC001: Multi-agent is default mode — AGENT-9-P3 strategy freeze: multi-agent CONDITIONAL only
- RC002: P1 product quality exceeds Vanilla — No evidence of product superiority
- RC003: v0.5 release ready — v0.5 BLOCKED per AGENT-9-P3 strategy freeze
- RC004: External memory = model memory expansion — Memory concept correction: external memory != model expansion


## Forbidden Assumptions
- Compressed summaries are authoritative evidence
- External memory expands model memory capacity
- Self-reported PASS equals verified truth
- Process artifacts prove product quality
- Multi-agent mode is the default configuration
- v0.5 release is ready to ship


## Allowed Actions
- Coordinate agents
- Assign task groups
- Enforce context packet use


## Forbidden Actions
- Start PRO-2 before P1 PASS
- Skip context packet generation


## Verifier History
- Last: FACTORY-MEMORY-QUALITY-0-P1 → PASS (32/32)

## Summary Verification
- Verified: True by generate-context-packet.ps1
