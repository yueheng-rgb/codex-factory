# FACTORY-DEFAULT-WORKFLOW-0 — F: Project Path Handoff Contract Report

> Phase: FACTORY-DEFAULT-WORKFLOW-0
> Section: F — Project Path Handoff Contract
> Date: 2026-06-28

## Deliverables

| File | Path |
|------|------|
| Contract Definition | `factory-workflow/PROJECT_PATH_HANDOFF_CONTRACT.md` |
| Governance JSON | `governance/factory-workflow/factory-default-workflow-0-project-path-handoff-contract.json` |

## Contract Summary

Defines 7 mandatory path categories for every project handoff:
1. Project Root
2. Source Code
3. Configuration Files
4. Database Artifacts
5. Documentation
6. Build / Run Artifacts
7. Governance / Factory Artifacts

### Key Rules
- Always absolute paths
- UNKNOWN_WITH_REASON for unknown paths (never omit silently)
- Structured handoff template
- No URIs, no guessing
