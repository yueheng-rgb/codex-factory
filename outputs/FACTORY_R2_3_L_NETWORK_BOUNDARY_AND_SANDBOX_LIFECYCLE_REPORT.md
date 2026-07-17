# R2.3-L Network Boundary Refinement & Sandbox Lifecycle Report

**Phase:** FACTORY-R2.3-L | **Date:** 2026-07-10 | **Status:** COMPLETE

## Overview

Refined Codex Factory's network permission model from a single `networkAccess` boolean to a 7-level `networkBoundary` model. Established sandbox lifecycle management with session tracking, artifact capture, and cleanup policies. Re-ran Playwright trial under `loopback_only` boundary — gate now correctly ALLOWs instead of REJECTs.

## Key Results

| Dimension | Result |
|------|------|
| Network Boundary Model | 7 levels (no_network → cloud_service) |
| Tool Registry | 11 entries updated with networkBoundary |
| Permission Gate | Updated to use networkBoundary + host allowlist |
| Playwright Loopback Trial | **ALLOW_WITH_CONTROLS, 6/6 PASS** |
| Negative Controls | **8/8 PASS** |
| Sandbox Lifecycle | create → run → capture → cleanup → archive |
| Verification | **20/20 PASS** |

## Network Boundary Change

**Before (R2.3-J/K):**
- Playwright: `networkAccess=true` → REJECT in local-first (false positive)

**After (R2.3-L):**
- Playwright: `networkBoundary=loopback_only` → ALLOW_WITH_CONTROLS in local-first ✅
- Stitch MCP: `networkBoundary=external_api` → REJECT in local-first ✅
- External host access from loopback tool → REJECT (boundary_violation) ✅

## Deliverables

### Schemas (2)
- `schemas/network-boundary.schema.json`
- `schemas/tool-permission-packet.schema.json` (updated)

### Runtime (3)
- `runtime/tool-permission-gate.ps1` (v2 with networkBoundary)
- `runtime/sandbox-lifecycle.ps1`
- `runtime/tool-registry-loader.ps1` (supports networkBoundary field)

### Governance
- `governance/sandbox-sessions/sandbox-session-index.jsonl`

### Outputs (7 reports)
- All present in `outputs/`
