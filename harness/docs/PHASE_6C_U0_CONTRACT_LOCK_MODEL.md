# Phase 6C-U0 Contract Lock Model

> **Phase**: 6C-U0-A
> **Status**: MVP — demonstrates drift detection with fixtures, not live multi-agent runs.

---

## 1. Problem

In multi-agent code generation, parallel Workers produce code independently.
When Worker A exports a function named `ClaimTask` and Worker B imports it as `Claim_Task`,
neither Worker detects the mismatch — they work in isolated workspaces.

Without a contract lock that defines interfaces BEFORE work begins, and without
a drift detector that compares results AFTER submission, this mismatch only surfaces
at integration time (or worse, at runtime).

## 2. Solution

**Contract Lock + Interface Drift Gate** is a three-part mechanism:

### 2.1 Contract Lock (`interface-contract.lock.json`)

A machine-readable JSON file that defines, BEFORE Workers start:

- Which interfaces exist (stable `interfaceId`)
- Which Worker owns (exports) each interface
- Which Workers require (import) each interface
- The exact `name` and `file` for each interface

The contract is locked (`locked: true`) and must not change after Workers begin.

### 2.2 Worker Interface Manifest (`worker-interface-manifest.json`)

Each Worker submits a manifest declaring:

- What they ACTUALLY exported (symbol name, interfaceId, file)
- What they ACTUALLY imported (symbol name, interfaceId, file)

This is machine-generated (or written by the Worker as part of submission).

### 2.3 Interface Drift Detector (`detect-interface-drift.ps1`)

After all Workers submit, the detector:

1. Validates the contract is locked
2. Validates every manifest is valid JSON
3. Checks every export `interfaceId` exists in the contract
4. Checks every export `name` matches the contract
5. Checks every export `file` matches the contract
6. Checks every import `interfaceId` exists in the contract
7. Checks every import `name` matches the contract
8. Checks every import `file` matches the contract
9. Verifies every `requiredBy` worker actually imports
10. Verifies every `owner` worker actually exports

If any check fails, the detector emits `interface-drift-report.json` with:
- `verdict: FAIL`
- `driftCount: N` (number of mismatches)
- Detailed drift entries showing expected vs. actual values

## 3. Integration Gate

The integration gate (`integration-gate-report.json`) reads the interface drift report:

- If drift report PASS → integration gate PASS (proceed to integration)
- If drift report FAIL → integration gate FAIL (block integration)

The integration gate does NOT perform its own analysis — it depends on the drift detector.

## 4. File Map

| File | Role |
|---|---|
| `schemas/INTERFACE_CONTRACT_SCHEMA.json` | Schema for contract lock format |
| `schemas/WORKER_INTERFACE_MANIFEST_SCHEMA.json` | Schema for worker manifest format |
| `scripts/validate-interface-contract.ps1` | Validates contract against schema |
| `scripts/validate-worker-interface-manifest.ps1` | Validates manifest against schema |
| `scripts/detect-interface-drift.ps1` | Core detector — compares manifests to contract |
| `scripts/phase6c-u0-a-verify.ps1` | Umbrella verifier — all U0-A checks |
| `runs/phase6c-u0-a/` | Positive fixture (no drift) |
| `runs/phase6c-u0-a-negative/` | Negative fixture (A/B mismatch) |

## 5. Limitations (U0-A MVP)

- Uses static fixture files, not live Worker output
- Does not run spawn_agent or parallel Workers
- Does not extract TypeScript exports from source code (manifests are hand-written)
- Does not integrate with validate-state.ps1 (future U0-B)
- Does not support dynamic interface discovery
- Contract is defined once per run, not per-task

## 6. Next Steps

- U0-B: Integrate drift detector into validate-state.ps1 (hard gate)
- U0-C: Auto-extract exports from TypeScript source files
- U0-D: Run with real spawn_agent Workers producing interface manifests