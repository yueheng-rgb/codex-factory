# R2.3-K Sandboxed Tool Trial & Read-only Search Adapter Report

**Phase:** FACTORY-R2.3-K | **Date:** 2026-07-10 | **Status:** COMPLETE

## Overview

First real tool capability trial in Codex Factory: Playwright verifier ran 6/6 PASS in disposable sandbox on a local fixture project. A read-only search adapter was established that imports external search results without API keys or network calls, with quality gating and Research Intake conversion.

## Key Results

| Dimension | Result |
|------|------|
| R2.3-J Preflight | 1 gap → ACCEPT_CAVEAT (gate order intentional) |
| Playwright Sandbox Trial | **6/6 PASS** (real execution) |
| Tool Permission Gate | Correctly blocked Playwright without network, allowed with controls |
| Search Adapter | 3 example inputs processed (1 accepted, 1 rejected, 1 reference-only) |
| Search Quality Gate | 10/10 high_quality for official docs, 4/10 needs_review for AI-no-sources |
| Combined Simulation | **10/10 PASS** |
| Verification | **21/21 PASS** |

## Playwright Trial Details

- Fixture: `C:\Users\90961\Desktop\factory-tool-sandbox-trial`
- Server: Node.js HTTP on 127.0.0.1:9876
- 6 assertions: page load, H1 text, status paragraph, feature count, footer version, 404 response
- Sandbox: disposable workspace, no external network, no file writes
- Gate: Tool Permission Gate checked before execution

## Search Adapter Details

- 3 example inputs tested (official docs, AI-no-sources, mixed community)
- Zero API keys, zero network calls
- Converts valid inputs to Research Intake Packets
- Quality gate scores from 4-10/10
- Implementer agents blocked from direct search adapter access

## Deliverables

### Schemas
- `schemas/search-adapter-input.schema.json`

### Runtime (4)
- `runtime/read-only-search-adapter.ps1`
- `runtime/search-result-quality-gate.ps1`
- `runtime/sandboxed-playwright-trial.ps1`
- `runtime/r2-3-k-combined-simulation.ps1`

### Verification
- `harness/verification/verify-r2-3-k-tool-search-trial.ps1` — 21/21 PASS

### Tool Registry
- TOOL-SEARCH-ADAPTER-001 registered (allowedWithControls)
- TOOL-PLAYWRIGHT-VER-001 tested in live sandbox

### Outputs (7 reports)
- All present in `outputs/`
