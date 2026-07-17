# FACTORY-PROJECT-ISOLATION-0 — E: Cross-Project Memory Boundary Report

> Phase: FACTORY-PROJECT-ISOLATION-0
> Section: E — Cross-Project Memory Boundary
> Date: 2026-06-29

## Deliverables

| File | Path |
|------|------|
| Boundary Doc | `factory-isolation/CROSS_PROJECT_MEMORY_BOUNDARY.md` |
| Governance JSON | `governance/factory-isolation/factory-project-isolation-0-cross-project-memory-boundary.json` |

## Summary

Defines three memory categories:
- **Project-Scoped (12 types)**: Never transfer between projects
- **Global-Scoped (6 types)**: Always transfer
- **Conditionally Transferable (4 types)**: User opt-in or preference

Memory boundary enforced on project switch: flush → clear → load → preserve → detect foreign.
