# Codex Factory v2.0 — Release Notes

> **Release:** v2.0.0  
> **Stage:** stable mission-validated release  
> **Date:** 2026-07-12  
> **NOT a production system — NOT the "Final" version**

---

## Overview

Codex Factory v2.0 is the first **mission-validated** release. It packages the full Factory pipeline —
Bootstrap → Router → Surface Plan → Search Gate → Design → Worker/Implementer → Verifier →
Risk Gate → Business Invariants → External Engine Broker → Evidence Binding → Release Report —
with a real mission project proving end-to-end capability.

---

## What's New Since v1.3

| Capability | v1.3 Status | v2.0 Status |
|-----------|------------|------------|
| Trusted Memory / Compression Defense | DONE | PRESERVED |
| Audit Trail / Hash Chain | DONE | PRESERVED |
| Multi-Agent Stress Test | SIMULATED | REAL MISSION |
| Expert Pack Activation | 3 packs | 3 packs + combo |
| Mission Project | NONE | 38/38 PASS |
| Regression | 172/172 | 210/210 |
| External Engines | 3 available | 3 available (unchanged) |

---

## Key Metrics (v2.0)

- **210/210 regression tests PASS**
- **3 Expert Packs** (admin-system, ecommerce, saas-tool)
- **16 business invariants** enforced across all packs
- **1 mission project** (missions/inventory-subscription-admin)
- **Multi-agent:** 3 workers, VERIFIED handoffs, no conflicts
- **Compression defense:** 3/3 injected errors BLOCKED
- **Semgrep:** CLEAN on all projects
- **39 verified phases** spanning R1.0 through v2.0-RC

---

## What v2.0 Is NOT

- NOT a production system
- NOT the "Final" version
- NOT a deployment-ready platform
- Claims about "100w concurrent users" are NOT supported by local smoke
- READY_FOR_STAGING ≠ READY_FOR_PRODUCTION
- Compression summaries are NOT trusted memory

---

## Files

| File | Purpose |
|------|---------|
| outputs/V2_0_RELEASE_VERSION.json | Version metadata |
| outputs/V2_0_RELEASE_MANIFEST.json | Full capability manifest |
| outputs/V2_0_CAPABILITY_SUMMARY.md | Capability overview |
| outputs/V2_0_MISSION_TRIAL_EVIDENCE.md | Mission evidence package |
| outputs/V2_0_REGRESSION_COMMAND_INDEX.md | Regression command index |
| outputs/V2_0_KNOWN_RISKS_AND_NON_CLAIMS.md | Known risks |
| outputs/V2_0_DEPRECATED_DIRECTIONS_FINAL_LOCK.md | Deprecated locks |
| outputs/V2_0_RELEASE_READINESS_CHECK.md | Readiness check |
| outputs/V2_0_V2X_ROADMAP.md | v2.x roadmap |

---

## Upgrading from v1.x

v2.0 is backward-compatible with all v1.x projects. No migration required. All runnable starters, testbeds, and pilot projects function identically. The mission project (missions/inventory-subscription-admin) is additive.

---

## Known Risks (Carried from v1.3)

- In-memory store (data lost on restart)
- No real auth (x-user-id header only)
- Playwright browser version mismatch
- CodeQL/k6 require user installation
- Multi-agent stress was simulated, now also validated with real mission

---

## Next Steps

See outputs/V2_0_V2X_ROADMAP.md for the v2.x roadmap.

Recommended next: **v2.1 Real CI Artifact Store** — raw logs, exit codes, commit/diff binding, artifact retention.
