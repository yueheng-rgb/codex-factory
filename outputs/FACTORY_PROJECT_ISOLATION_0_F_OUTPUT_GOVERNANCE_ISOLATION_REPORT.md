# FACTORY-PROJECT-ISOLATION-0 — F: Output/Governance Isolation Report

> Phase: FACTORY-PROJECT-ISOLATION-0
> Section: F — Output/Governance Isolation
> Date: 2026-06-29

## Deliverables

| File | Path |
|------|------|
| Isolation Doc | `factory-isolation/OUTPUT_GOVERNANCE_ISOLATION.md` |
| Governance JSON | `governance/factory-isolation/factory-project-isolation-0-output-governance-isolation.json` |

## Summary

Defines isolation rules for phase reports, verifier results, strategy decisions, negative controls, phase ledgers, decision records, and evidence. All governance artifacts require `projectId`. Cross-project viewing allowed only as FOREIGN_REFERENCE. Path isolation enforced: each project has its own `outputs/` and `governance/` directories.
