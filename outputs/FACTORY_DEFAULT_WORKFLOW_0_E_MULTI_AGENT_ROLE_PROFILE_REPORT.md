# FACTORY-DEFAULT-WORKFLOW-0 — E: Multi-Agent Role Profile Draft Report

> Phase: FACTORY-DEFAULT-WORKFLOW-0
> Section: E — Multi-Agent Role Profile Draft
> Date: 2026-06-28

## Deliverables

| File | Path |
|------|------|
| Profile Draft | `factory-workflow/MULTI_AGENT_ROLE_PROFILE_DRAFT.md` |
| Governance JSON | `governance/factory-workflow/factory-default-workflow-0-multi-agent-role-profile.json` |

## Profiles Defined (5 Draft Roles)

| Role | Responsibility | Write Scope |
|------|---------------|-------------|
| Architect | Design, schemas, contracts | Design docs only |
| Backend Worker | Server-side implementation | Backend code |
| Frontend Worker | Client-side implementation | Frontend code |
| Integrator | Cross-cutting integration | Integration layer |
| QA / Verifier | Verification, testing | Reports only |

## Assignment Rules

- Small fullstack (< 10 files): 2 roles (single agent sufficient)
- Medium fullstack (10-30 files): 3 roles
- Large fullstack (30+ files): 5 roles

## Note

These are **draft** profiles. Real refinement and validation will occur in FACTORY-MULTI-AGENT-ORCHESTRATION-1.
