# FACTORY-MEMORY-QUALITY-0-P1 — Section C: Context Packet Generator Report

**Phase**: FACTORY-MEMORY-QUALITY-0-P1 | **Date**: 2026-06-27 | **Status**: COMPLETED

## Script

`factory-build-mode/runtime/memory/generate-context-packet.ps1` (15.9 KB)

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| -ProjectRoot | Yes | Project root with .codex-factory/ |
| -TargetPhase | Yes | Target factory phase |
| -TargetRole | Yes | builder/verifier/reviewer/integrator/auditor/orchestrator |
| -PacketType | No | Default: AGENT_START_PACKET |
| -OutputJson | No | JSON output file path |
| -OutputMarkdown | No | Markdown output file path |
| -MaxAgeMinutes | No | Default: 60 |

## Features

- 6 role-specific context profiles (required reads, allowed/forbidden actions)
- Word budget enforcement (max 2000 words)
- Stale packet detection (expiresAt + stale flag)
- Summary verification status embedded
- NEVER includes product source, SkillMarket, DevFlow, SkillForge, AtlasOps, or release artifacts
