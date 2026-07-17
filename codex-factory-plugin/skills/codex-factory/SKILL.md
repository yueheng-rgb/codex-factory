---
name: codex-factory
description: Codex App Factory — structured multi-agent project building with phase-driven development, verifier-based gating, worker contracts, evidence hierarchy, and session rotation. Use when the user asks to scaffold, verify, or manage a multi-phase Factory project, run factoryctl verify, validate resource packs, generate handoffs, or apply P0/P1/P2 decision protocols and claim classification.
---

# Codex App Factory

Structured multi-agent project building with phase-driven development.

## Core Rules

1. **No scoring system as PASS/FAIL gate** — all gating must be verifier-based and evidence-backed
2. **Failure-router excluded from core** — do not include failure-router in runnable packages
3. **Compressed summary is NOT evidence** — rely only on repo artifacts, verifier JSON, manifest SHA256
4. **Unverified Codex capability claims cannot be marked VERIFIED_FACT**
5. **Main Agent undeclared fallback is a blocking risk** — workers must have explicit contracts
6. **Verifiers are readonly** — verifiers inspect, do not modify
7. **Integrator is sole merge owner** — only integrator merges builder outputs

## Quick Start

```powershell
# Run factory control plane
.\scripts\factoryctl.ps1 status
.\scripts\factoryctl.ps1 verify --json

# Validate resource pack
powershell -File .\scripts\validate-resource-pack.ps1
```

## Phase Types

| Phase | Purpose |
|---|---|
| DRY | Dry run / stress test / portability |
| H | Hardening / packaging / feasibility |
| P | Repair / reconciliation |

## Agent Roles

| Role | Responsibility |
|---|---|
| orchestrator | Main Agent: assigns work, spawns agents |
| builder | Creates source files per worker contract |
| verifier | Readonly validation; produces machine-readable results |
| integrator | Sole merge owner; combines builder outputs |
| repair | Fixes specific defects under narrow scope |

## Protocols (in references/)

- `p0-p1-p2-decision-protocol.md` — Incident classification
- `evidence-hierarchy.md` — Evidence strength ranking
- `claim-classification.md` — How to classify capability claims
- `worker-reporting-protocol.md` — Progress event format
- `integrator-verifier-boundary.md` — Separation of duties
- `main-agent-scheduling-protocol.md` — Spawn and scheduling rules
- `scoring-system-policy.md` — Scoring prohibition

## Schemas (in references/)

- `worker-contract.schema.json` — Worker contract definition
- `evidence-entry.schema.json` — Evidence entry format
- `progress-event.schema.json` — Progress event schema

## Verifier Modules (in references/)

- `parent-phase-check.md`
- `hard-floor-check.md`
- `negative-control-check.md`
- `scope-isolation-check.md`
- `no-generic-fail-check.md`
- `session-rotation-readiness-check.md`
