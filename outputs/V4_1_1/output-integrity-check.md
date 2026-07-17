# V4.1.1 Output Integrity Check Report

## Root Cause

PowerShell hashtable literal parsing bug: `@(...) + (if ...)` inside `@{ }` causes
`if` to be interpreted as a command name rather than a language statement.
This silently produces `null`/empty objects, resulting in 0-byte JSON output files.

## Fix Applied

Pre-compute all conditional arrays before hashtable literal construction.

### Files Changed

- `runtime/task-decomposition-engine.ps1`

### Changes

| # | Change | Location |
|---|--------|----------|
| 1 | Fix `riskResult` construction — pre-compute `$riskReasons`, `$gates`, `$artifacts` | Lines 63-73 |
| 2 | Fix `agentPlan` construction — pre-compute `$gateSeq`, `$evidenceInputs` | Lines 251-257 |
| 3 | Add `generic-complex-project` task template (10 tasks) | Lines 132-143 |
| 4 | Add `backend-api` task template (8 tasks) | Lines 144-152 |
| 5 | Add honest fallback: unknown types → `generic-complex-project` with `fallback_reason` | Lines 155-170 |
| 6 | Add `evidence_requirements.json` standalone output | Line 333 |
| 7 | Add output integrity check (size>0, JSON parse, required fields, exit 1 on failure) | Lines 336-395 |
| 8 | Bump version to 4.1.1 | — |

## Demo Results

### admin-system

| File | Size | JSON Parse |
|------|------|------------|
| task_graph.json | 13,016 bytes | OK |
| worker_plan.json | 5,246 bytes | OK |
| validation_plan.json | 8,424 bytes | OK |
| risk_classification.json | 716 bytes | OK |
| agent_execution_plan.json | 3,321 bytes | OK |
| evidence_requirements.json | 70 bytes | OK |
| engine-full-output.json | 48,137 bytes | OK |
| output-integrity-report.json | 2,463 bytes | OK |

**Integrity: 7/7 PASS**

### ecommerce-miniapp

| File | Size | JSON Parse |
|------|------|------------|
| task_graph.json | 13,107 bytes | OK |
| worker_plan.json | 5,246 bytes | OK |
| validation_plan.json | 8,487 bytes | OK |
| risk_classification.json | 716 bytes | OK |
| agent_execution_plan.json | 3,320 bytes | OK |
| evidence_requirements.json | 70 bytes | OK |
| engine-full-output.json | 48,310 bytes | OK |
| output-integrity-report.json | 2,468 bytes | OK |

**Integrity: 7/7 PASS**

## Fallback Strategy

- **Fully supported**: admin-system, ecommerce, miniapp, saas, generic-complex-project, backend-api
- **Fallback**: Unknown types → `generic-complex-project` with `fallback_reason` and reduced confidence
- **No silent admin-system fallback**

## Regression

| Check | Result |
|-------|--------|
| V3.4.2 snapshot verifier | FIXED_AND_VERIFIED_LOCALLY |
| Secret scan | PASS (secretPresent: false) |
| GitHub Actions workflow | INTACT |
| search_provider default | none |
| GLM binding | optional |
| Skill pack manager | present |
| Knowledge build-evidence | present |

## Classification

**V4_1_1_TASK_DECOMPOSITION_OUTPUT_RELIABILITY_CLOSED (A)**
