# FACTORY-EVAL-4 / B — Benchmark Specification Report

> Generated: 2026-06-25T17:05:00+08:00
> Section: B — TeamFlow Lite Full Specification

---

## Functional Requirements Summary

| ID | Requirement | Key Acceptance Criteria |
|---|---|---|
| FR01 | User Registration & Auth | JWT + bcrypt, duplicate email 409, wrong password 401 |
| FR02 | Team/Workspace Management | Owner-only update/delete, cascade on team delete |
| FR03 | Role-Based Access Control | 4 roles, server-side enforcement, owner manages roles |
| FR04 | Task CRUD | Scoped to team, viewer read-only, cross-team 403 |
| FR05 | Task Status Workflow | 4 valid transitions, invalid→400 with message, audit logged |
| FR06 | Task Assignment & Due Dates | Assign to member, due date optional/future, overdue queryable |
| FR07 | Comments & Activity Feed | Immutable comments, chronological, activity feed includes events |
| FR08 | Audit Log | Append-only, queryable by team/user/action/date, immutable |
| FR09 | Notification Stub | Overdue tasks endpoint, scoped to user, no email infra |
| FR10 | Search/Filter/Sort | Title search, status/assignee/priority filters, multi-sort |
| FR11 | Error Handling & Validation | 400/401/403/404/500, field-level errors, no stack traces |

---

## Data Model (8 Entities, 6 Tables + 1 Enum Table)

```
User ──┬── TeamMember ──┬── Team ──┬── Task ──┬── Comment
       │                │          │          │
       └── AuditLog ─────┘          └── AuditLog
```

**Core Tables**:
- **User**: id, email (UNIQUE), password_hash, display_name, timestamps
- **Team**: id, name, description, created_by, timestamps
- **TeamMember**: id, team_id+user_id (UNIQUE), role (owner/admin/member/viewer), joined_at
- **Task**: id, team_id, title, description, priority, status (todo/in_progress/blocked/done), assignee_id, due_date, created_by, timestamps
- **Comment**: id, task_id, author_id, content (immutable), created_at
- **AuditLog**: id, team_id, actor_id, action, target_type, target_id, details (JSONB), created_at

---

## API Endpoint Outline (21 Endpoints)

| Group | Method | Path | Auth |
|---|---|---|---|
| Auth | POST | /api/auth/register | Public |
| Auth | POST | /api/auth/login | Public |
| Auth | GET | /api/auth/me | JWT |
| Teams | POST | /api/teams | JWT |
| Teams | GET | /api/teams | JWT |
| Teams | GET | /api/teams/:teamId | JWT |
| Teams | PATCH | /api/teams/:teamId | Owner |
| Teams | DELETE | /api/teams/:teamId | Owner |
| Teams | GET | /api/teams/:teamId/members | JWT+Member |
| Teams | POST | /api/teams/:teamId/members | Owner/Admin |
| Teams | PATCH | /api/teams/:teamId/members/:userId | Owner/Admin |
| Teams | DELETE | /api/teams/:teamId/members/:userId | Owner/Admin |
| Tasks | POST | /api/teams/:teamId/tasks | Member+ |
| Tasks | GET | /api/teams/:teamId/tasks | Viewer+ |
| Tasks | GET | /api/teams/:teamId/tasks/:taskId | Viewer+ |
| Tasks | PATCH | /api/teams/:teamId/tasks/:taskId | Member+ |
| Tasks | PATCH | /api/teams/:teamId/tasks/:taskId/status | Member+ |
| Tasks | DELETE | /api/teams/:teamId/tasks/:taskId | Admin+ |
| Comments | POST | /api/teams/:teamId/tasks/:taskId/comments | Member+ |
| Comments | GET | /api/teams/:teamId/tasks/:taskId/comments | Viewer+ |
| Activity | GET | /api/teams/:teamId/activity | Viewer+ |
| Audit | GET | /api/teams/:teamId/audit-log | Owner/Admin |
| Notifications | GET | /api/tasks/overdue | JWT |

---

## UI Pages (7 Pages)

| Page | States Required |
|---|---|
| Login/Register | login form, register form, loading, error (invalid), error (duplicate) |
| Dashboard | team list, empty state, loading, error |
| Team View | task board, filter bar, empty state, loading, error |
| Task Detail | task info, edit form, status buttons, comments, loading, error |
| Team Members | member list, invite form, role mgmt, empty, loading, error |
| Audit Log | log entries, filters, empty, loading, error |
| Overdue Tasks | overdue list, empty (none), loading, error |

---

## Test Requirements

**Unit Tests (4 areas)**:
- Auth service logic
- Task CRUD + status transitions
- Permission checks
- Input validation

**Integration Tests (6 scenarios)**:
- Full auth flow
- Task CRUD via HTTP
- Permission boundaries (viewer cannot write)
- Status workflow transitions
- Audit log entries created on actions
- Multi-tenant isolation

---

## Acceptance Criteria

- [ ] Single command to run
- [ ] All 21 API endpoints return appropriate responses
- [ ] All 7 UI pages render without crashing
- [ ] Server-side permission checks on all write endpoints
- [ ] Full audit trail for create/update/delete/status-change/assignment
- [ ] All tests pass with meaningful assertions
- [ ] README: setup, run, test, API overview

---

## Next: Section C — Run Comparison Design
