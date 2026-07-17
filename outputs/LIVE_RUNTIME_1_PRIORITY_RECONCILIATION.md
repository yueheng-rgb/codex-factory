# LIVE-RUNTIME-1-A: Priority Reconciliation

**Generated**: 2026-06-24T23:53:01+08:00
**Verdict**: RESOLVED

## Discrepancy

LIVE-RUNTIME-0 findings table classified capacity preflight as **P0**, but the recommendation section listed it as **P1**. This reconciliation resolves the inconsistency.

## Resolved Priorities

| Gap | Severity | Rationale |
|-----|----------|-----------|
| Agent archive/quarantine/close lifecycle | **P0** | 28/67 agents never closed; no archive mechanism; 0.55 close-to-create ratio |
| Capacity preflight | **P0** | DRY23-P1 spawn failure directly triggered Main Agent fallback; capacity exhaustion is root cause |
| Cross-session state reconciliation | **P0** | 20+ rotations with no automated reconciliation; H13-D repair was manual |
| Automation rotation watcher | **P1** | Important but manual rotation is reliable; plan/stub sufficient for now |

## Key Evidence: Capacity Preflight → P0

DRY23-P1: Agent thread limit reached → spawn failure → **BLOCKING_MAIN_AGENT_UNDECLARED_FALLBACK** → 34 files written to worker scopes without contract.

This is the Factory's most severe historical failure mode, directly triggered by capacity exhaustion. Capacity preflight is therefore **P0**, not P1.

## Decision

All three P0 gaps must be closed in LIVE-RUNTIME-1. Automation rotation watcher (P1) will be a non-mutating design plan only.
