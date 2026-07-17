# MULTI_AGENT_ROLE_PROFILE_DRAFT.md

> Part of: FACTORY-DEFAULT-WORKFLOW-0
> Section: E — Multi-Agent Role Profile Draft
> Version: 1.0.0-draft

---

## Purpose

Define the role profiles available for multi-agent orchestration within Factory. These are draft profiles — they will be refined in FACTORY-MULTI-AGENT-ORCHESTRATION-1 based on real project validation.

---

## Role Profiles

### 1. Architect Agent
- **Responsibility**: Project structure, module boundaries, API contract design, database schema
- **Inputs**: Factory Boot Summary, user requirements
- **Outputs**: Architecture doc, API sketch, DB schema, module tree
- **Cannot**: Write implementation code, modify files outside design scope
- **Handoff to**: Worker agents

### 2. Backend Worker Agent
- **Responsibility**: Server-side implementation, API endpoints, database operations, middleware
- **Inputs**: Architecture doc, API sketch, DB schema
- **Outputs**: Backend code files, route handlers, DB migrations
- **Cannot**: Modify frontend code, change architecture decisions
- **Handoff to**: Integrator agent

### 3. Frontend Worker Agent
- **Responsibility**: Client-side implementation, UI components, state management, routing
- **Inputs**: Architecture doc, UI design, API contract
- **Outputs**: Frontend code files, components, pages
- **Cannot**: Modify backend code, change API contract unilaterally
- **Handoff to**: Integrator agent

### 4. Integrator Agent
- **Responsibility**: Cross-cutting integration, contract validation, end-to-end wiring
- **Inputs**: Backend outputs, frontend outputs, API contract
- **Outputs**: Integration fixes, contract validation report
- **Cannot**: Introduce new features
- **Handoff to**: QA agent

### 5. QA / Verifier Agent
- **Responsibility**: Verification, testing, negative controls, final report
- **Inputs**: All agent outputs, acceptance criteria
- **Outputs**: Verification report, test results, negative control pass/fail
- **Cannot**: Modify source files (report issues only)
- **Handoff to**: Main agent (for user presentation)

---

## Role Assignment Rules

| Project Type | Recommended Roles |
|-------------|-------------------|
| Fullstack (small, < 10 files) | Architect + 1 Worker (single agent is sufficient) |
| Fullstack (medium, 10-30 files) | Architect + Backend Worker + Frontend Worker |
| Fullstack (large, 30+ files) | Architect + Backend Worker + Frontend Worker + Integrator + QA |

## Agent Ledger Requirement

Every agent output MUST include:
- Agent role name
- Agent ID (from spawn)
- Timestamp
- Input artifacts referenced
- Output artifacts produced
- Known caveats

See: Agent Ledger Contract (Section J)
