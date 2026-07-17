# Protocol Pack Usage Guide

**Version**: 0.5.0-candidate
**Status**: PROTOCOL_DRAFT
**Context**: Large-project multi-agent mode

---

## 1. Overview

The Agent Company Protocol Pack provides policies, scripts, fixtures, and documentation for running multi-agent Factory projects under strict governance. It is designed for **large-project contexts only** — not for small or medium projects.

---

## 2. Prerequisites

- Codex CLI with multi-agent support
- PowerShell 5.1+ (for validation scripts)
- A project with defined module boundaries (Architect baseline)

---

## 3. Installation

The protocol pack lives at:

```
C:\Codex_App_Factory\factory-agent-company-protocol-pack\
```

No installation is required. Reference paths directly.

---

## 4. Role Assignment

Assign these roles before starting any multi-agent run:

| Role | Count | Agent ID Pattern |
|------|-------|-----------------|
| Main Agent | 1 | `main-agent` |
| Architect | 1 | `architect` |
| Builder | 2-5 | `builder-N` |
| Integrator | 1 | `integrator` |
| Reviewer | 1 | `reviewer` |
| Verifier | 1 | `verifier` |
| Integrity Checker | 1 | `integrity-checker` |

---

## 5. Capsule Creation Workflow

### Step 1: Architect defines module contracts

Architect produces `task-graph.json` with module boundaries and API contracts.

### Step 2: Main Agent creates worker capsules

For each Builder, create a capsule JSON following the schema in `fixtures/valid-worker-capsule-fixture.json`.

### Step 3: Validate capsules

```powershell
powershell -File scripts/validate-capsule.ps1 -CapsulePath fixtures/valid-worker-capsule-fixture.json
```

Expected output: JSON with overall `PASS`, exit code `0`.

### Step 4: Spawn workers

Spawn each Builder with its validated capsule. Record spawn decisions in `spawn-decisions.json`.

### Step 5: Workers build and hand off

Each Builder produces:
- `progress-report-builder-N.json` — periodic progress
- `blocker-report-builder-N.json` — if blocked
- `handoff-builder-N.json` — final handoff

### Step 6: Integrator merges

Integrator receives all handoffs, runs cross-scope checks, and produces `integration-result.json`.

### Step 7: Reviewer audits

Reviewer produces `reviewer-result.json` with quality gap report.

### Step 8: Verifier gates

Verifier runs all gate checks and produces `verifier-result.json`.

### Step 9: Integrity Checker sweeps

Integrity Checker runs full audit (including drift injection detection) and produces `integrity-check-result.json`.

### Step 10: Close receipts

Each worker receives a `close-receipt-builder-N.json`.

---

## 6. Simulation Instructions

To run a simulation of the full protocol:

1. Create a simulation directory under `harness/runs/`.
2. Populate all simulation artifacts (task graph, spawn decisions, capsules, reports, handoffs, integration result, reviewer result, verifier result, integrity check result, close receipts).
3. Run the Integrity Checker against the drift injection fixture.
4. Verify at least one drift injection is detected.

---

## 7. Validation Commands

```powershell
# Validate a worker capsule
powershell -File scripts/validate-capsule.ps1 -CapsulePath fixtures/valid-worker-capsule-fixture.json

# Validate an invalid capsule (should FAIL)
powershell -File scripts/validate-capsule.ps1 -CapsulePath fixtures/invalid-worker-capsule-no-scope-fixture.json
```

---

## 8. Key Policies

| Policy | File | Owner |
|--------|------|-------|
| Drift Control | `policies/drift-control-policy.md` | Integrator Lead |
| Scope Isolation | `policies/scope-isolation-policy.md` | Main Agent |
| Integrity Check | `policies/integrity-check-policy.md` | Integrity Checker |

---

## 9. Fixture Reference

| Fixture | Purpose |
|---------|---------|
| `valid-worker-capsule-fixture.json` | Reference capsule that passes validation |
| `invalid-worker-capsule-no-scope-fixture.json` | Capsule missing ownedScope — must fail validation |
| `valid-worker-handoff-fixture.json` | Reference handoff with complete evidence |
| `valid-close-receipt-fixture.json` | Reference close receipt |
| `drift-injection-fixture.json` | Injected drift patterns for IC detection testing |

---

## 10. Boundary Rules (Do Not Violate)

1. No v0.5 release — this is a draft.
2. Multi-agent is NOT proven default.
3. 10-role model is archived reference only.
4. Large-project context only.
5. Verifier-based gating (no score-based PASS/FAIL).
6. Compressed summaries are NOT evidence.
7. Main Agent must not write worker scope.
8. Integrator is sole merge owner.
9. Verifier and Integrity Checker are readonly.

---

*End of Protocol Pack Usage Guide*
