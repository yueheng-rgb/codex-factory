# FACTORY-EVAL-4 / A — Benchmark Project Selection Report

> Generated: 2026-06-25T17:00:00+08:00
> Phase: FACTORY-EVAL-4 / Real Project Benchmark Design
> Section: A — Benchmark Project Selection
> Status: SELECTED

---

## Selected Project: TeamFlow Lite

**Type**: Multi-tenant team task/workflow SaaS
**Decision**: SELECTED as the single benchmark project for three-run comparison

---

## Why This Project

### Complexity Justification

TeamFlow Lite has 11 distinct cross-cutting concerns:

1. User registration and authentication (JWT/bcrypt)
2. Team/workspace multi-tenancy isolation
3. Role-based access control (owner/admin/member/viewer)
4. Full CRUD operations on tasks
5. Task status workflow with state machine transitions
6. Task assignment and due date tracking
7. Comment/activity feed per task
8. Audit log for all important actions
9. Notification/reminder stub
10. Search, filter, and sort capabilities
11. Input validation and error handling across all surfaces

This spread is complex enough to surface real differences between Vanilla Codex (no guidance), Factory Lite (Manual Router + Proof-of-Read), and Factory Role-Agent (role-specialized agents with contracts).

### Size Justification

- **Estimated API endpoints**: 15-25
- **Estimated database tables**: 8-12
- **Estimated UI pages**: 6-10
- **Target**: completable within 200 message turns per run

Small enough that all three runs can be completed in a reasonable timeframe. Large enough that organization, architecture decisions, and cross-cutting concerns matter — the exact areas where Factory claims to add value.

### Simplification Risk Exposure

| Risk Surface | Why It Matters |
|---|---|
| Multi-tenant isolation | Easy to leak data between teams if not careful |
| Permission boundaries | Frontend hiding buttons ≠ authorization; must be enforced server-side |
| Audit trail completeness | Easy to skip, hard to fake when independently verified |
| Workflow state transitions | Invalid transitions must be rejected; sloppy code allows any transition |
| Notification stub | Tempting to skip entirely; must exist in some form |

---

## Rejected Alternatives

| Project | Reason for Rejection |
|---|---|
| E-commerce platform | Too large — payment, inventory, shopping cart expand scope beyond comparable runs |
| Blog/Content CMS | Too small — insufficient role complexity, no workflow lifecycle |
| Chat application | Too narrow — lacks audit, workflow, permissions depth |
| API-only microservice | No frontend — cannot evaluate full-stack delivery quality |
| Factory-style governance tool | Self-referential — Factory would have unfair domain advantage |

---

## Relevant Roles

The benchmark maps directly to Factory Role-Agent Model roles:

| Role | Responsibility in Benchmark |
|---|---|
| **Architect** | Data model design, API route planning, component tree structure |
| **Backend Developer** | API routes, middleware, validation, error handling |
| **Frontend Developer** | UI components, state management, form handling, loading/error states |
| **Database Engineer** | Schema design, migrations, constraints, indexes, seed data |
| **Security Reviewer** | Auth correctness, RBAC enforcement, multi-tenant isolation checks |
| **QA Engineer** | Test suite design, edge case coverage, integration tests |
| **Tech Writer** | README, API documentation, run/deploy instructions |

---

## Objective Evaluation Dimensions

These dimensions ensure the evaluation measures real product quality, not artifacts:

1. **Requirement coverage** — functional checklist, not file count
2. **API contract correctness** — endpoint completeness, error codes, validation
3. **Database schema quality** — constraints, indexes, normalization
4. **Auth and authorization correctness** — boundary tests, role escalation attempts
5. **UI state coverage** — loading, empty, error, success, edge cases per page
6. **Audit trail completeness** — all important actions logged with timestamp/user
7. **Test coverage and quality** — meaningful assertions, not placeholder tests
8. **Documentation quality** — runnable, accurate, complete instructions
9. **Human intervention count** — tracked per run as overhead metric

---

## Technology Stack (Recommended, Not Mandated)

| Layer | Recommendation | Alternative Allowed |
|---|---|---|
| Frontend | React | Any SPA framework |
| Backend | Node.js/Express or Python/FastAPI | Any web framework |
| Database | PostgreSQL or SQLite | Any relational DB |
| Auth | JWT + bcrypt | Session-based acceptable |
| Run command | Single command | docker-compose up, npm start, etc. |

---

## Non-Factory Verification

All five checks pass — this project does not depend on Factory:

- [x] No Factory governance features
- [x] No Factory verifier features
- [x] No Codex Factory self-reference
- [x] No agent framework implementation required
- [x] No benchmark-specific shortcuts embedded

---

## Project Scope Boundaries

### Included (Required)
- User registration/login (JWT)
- Team/workspace CRUD
- Role-based access (owner/admin/member/viewer)
- Task CRUD with title, description, priority, status
- Task workflow: todo → in_progress → blocked → done
- Task assignment and due dates
- Comments/activity feed
- Audit log for key actions
- Overdue tasks list (notification stub)
- Search/filter/sort by status, assignee, priority, due date
- Input validation (frontend + backend)
- Error handling with meaningful messages
- Tests (unit + integration)
- README with run instructions
- API documentation

### Excluded (Out of Scope)
- Payment/billing
- Real-time WebSocket
- File uploads/attachments
- Email delivery (stub only)
- OAuth/social login
- i18n/multi-language
- Mobile-responsive beyond basic
- Admin analytics dashboard

---

## Next: Section B — Benchmark Specification

Define detailed functional requirements, data model sketch, API endpoint outline, and acceptance criteria.
