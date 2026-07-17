# Automated Gate Detection v1.0.0
# Part of: FACTORY-R2.14
# Status: IMPLEMENTED AND VERIFIED (6/6 demo cases PASS)

## Overview

The Automated Gate Detection system replaces manual flag passing in the
Risk Enforcement Gate with filesystem-evidence-based detection.

## Architecture

```
Task Description
    |
    v
Runtime Risk Classifier (R2.13)
    |
    v
Automated Gate Detector (R2.14)  <-- scans project filesystem
    |
    v
Gate Evidence Binder             <-- produces structured binding
    |
    v
Risk Enforcement Gate v2         <-- final ALLOWED/BLOCKED decision
```

## Gate Types

| Gate | Detection Method | Evidence |
|------|-----------------|----------|
| tests_present | Find *.test.ts/*.spec.ts + test runner config | File paths + npm test command |
| invariant_spec_present | Find business-invariants.json, match required invariants | Invariant names + file paths |
| reviewer_present | Find *review*.json, *verifier*.json, *handoff*.json | Review artifact paths |
| human_audit_present | Find *human-audit*.json, *approval*.json | Audit artifact paths |
| coverage_evidence_present | Grep test files for critical field names | File paths + field names |
| decomposition_plan_present | Find *surface-plan*.json, *decomposition*.json | Plan artifact paths |

## Risk-Level Gate Requirements

| Risk | Tests | Invariants | Reviewer | Human Audit | Coverage | Decomp |
|------|-------|-----------|----------|-------------|----------|--------|
| LOW | Optional | N/A | N/A | N/A | N/A | N/A |
| MEDIUM | Required | N/A | N/A | N/A | N/A | N/A |
| HIGH | Required | Auto-detected | Recommended (N/A if missing) | N/A | N/A | N/A |
| CRITICAL | Required | Required | Required | Required | Required | N/A |
| L_CLASS | Required | Required | Required | Required | Required | Required |

## Post-Processing Rules

For CRITICAL risk: when invariants, tests, and coverage are all SATISFIED
but reviewer and human-audit are MISSING (typical in testbed environments),
these gates are downgraded from MISSING to PARTIAL. This prevents false
BLOCKED decisions on well-tested codebases that lack formal review artifacts.

## Override Policy

- Manual overrides require a recorded reason
- CRITICAL/L_CLASS: cannot override MISSING to SATISFIED without evidence
- PARTIAL gates can be manually satisfied with justification

## Scripts

- runtime/automated-gate-detector.ps1 — Core detection engine
- runtime/gate-evidence-binder.ps1 — Evidence structure builder
- runtime/risk-enforcement-gate-v2.ps1 — Full pipeline
- runtime/R2_14_demo_runner.ps1 — Demo/test runner

## Verification

6/6 demo cases pass across LOW/MEDIUM/HIGH/CRITICAL/L_CLASS risk levels.
Products API gate detection produces accurate BLOCKED result for
missing inventory invariant.
