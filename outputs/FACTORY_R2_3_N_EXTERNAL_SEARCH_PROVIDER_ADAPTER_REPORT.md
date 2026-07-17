# R2.3-N External Search Provider Adapter — Main Report

**Phase:** FACTORY-R2.3-N  
**Date:** 2026-07-10  
**Status:** COMPLETE  
**Verification:** 32/32 PASS  
**Simulation:** 10/10 PASS

---

## Overview

R2.3-N delivers the External Search Provider Adapter MVP. The adapter framework supports three modes (manual, dry_run, live_api) with full gate/quality/ledger integration. GLM Search (ZhipuAI) is registered as the first external_api candidate provider, but the live_api code path is gated and has NOT been executed with a real API key. The adapter supports three modes — manual, dry_run, live_api — and integrates with Tool Permission Gate, networkBoundary, secret handling, Search Quality Gate v2, Research Intake, and Search Invocation Ledger.

**Key design principle:** Search is a capability consumed by Research Intake / Librarian agents, NOT by Implementer agents. Search results are reference material, not verified knowledge. They must pass quality gate, human review, and Research Intake before entering the knowledge bank.

---

## Deliverables Summary

| # | Deliverable | Path | Status |
|---|-------------|------|:---:|
| 1 | Secret Policy Schema | schemas/search-provider-secret-policy.schema.json | ✅ |
| 2 | GLM Request Schema | schemas/glm-search-request.schema.json | ✅ |
| 3 | GLM Response Schema | schemas/glm-search-response.schema.json | ✅ |
| 4 | Search Invocation Schema | schemas/search-invocation.schema.json | ✅ |
| 5 | Secret Presence Check | untime/secret-presence-check.ps1 | ✅ |
| 6 | Search Invocation Logger | untime/search-invocation-logger.ps1 | ✅ |
| 7 | GLM Search Adapter | untime/glm-search-adapter.ps1 | ✅ |
| 8 | Search Quality Gate v2 | untime/search-result-quality-gate.ps1 | ✅ |
| 9 | Tool Registry (GLM entry) | egistries/tool-candidate-registry.jsonl | ✅ |
| 10 | Search Invocation Ledger | governance/search-invocations/search-invocation-index.jsonl | ✅ |
| 11 | Simulation (10 scenarios) | untime/tests/r2-3-n-glm-simulation.ps1 | ✅ |
| 12 | Verification (32 checks) | harness/verification/verify-r2-3-n-search-provider-adapter.ps1 | ✅ |

---

## Three-Mode Architecture

| Mode | Network | API Key | Gate Tool | Status |
|------|:---:|:---:|---|---|
| manual | no_network | not needed | TOOL-SEARCH-ADAPTER-001 | ALLOW |
| dry_run | no_network | not needed | TOOL-SEARCH-ADAPTER-001 | ALLOW |
| live_api | external_api | required | TOOL-GLM-SEARCH-001 | PENDING_HUMAN / DOWNGRADE |

**Downgrade policy:** live_api → dry_run if: gate REJECT (local-first), API key missing, API call fails.

---

## Agent Access Control

| Agent | Search (dry_run/manual) | Search (live_api) |
|-------|:---:|:---:|
| RSRC-001 (Research) | ALLOW | PENDING_HUMAN |
| LIB-001 (Librarian) | ALLOW | PENDING_HUMAN |
| ARCH-001 (Architect) | READ curated only | BLOCKED |
| VER-001 (Verifier) | READ refs only | BLOCKED |
| SEC-001 (Security) | AUDIT only | BLOCKED |
| IMPL-* (Implementer) | **REJECT** | **REJECT** |

---

## Quality Gate v2

Upgraded from 8-point to 12-point scoring system. New checks:
- Source type distribution (official_docs, blog, github, advertisement, ai_generated)
- Advertisement/marketing detection (score penalty)
- Duplicate URL detection
- Title/snippet presence validation

---

## Key Constraints Preserved

- ❌ No Stitch MCP, no DB MCP, no cloud
- ❌ No API keys in files, logs, ledgers, or outputs
- ❌ Implementer agents blocked from search
- ❌ Search results NOT auto-promoted to skill registry
- ✅ Local-first: manual and dry_run always available
- ✅ live_api available only with env var + human approval
- ✅ Safe downgrade on failure (no hard errors from missing key)

---

## Readiness Statement

R2.3-N delivers a **local-first search intake infrastructure**. It does NOT:
- Claim live search (gated)
- Require cloud or external MCP servers
- Store API keys in any file
- Allow Implementer agents to search

What it DOES deliver:
- Three search modes with safe fallback
- Full integration with Factory gate/quality/ledger ecosystem
- live_api code path ready; requires API key + human approval to execute
