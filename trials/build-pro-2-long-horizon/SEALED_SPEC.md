# NexusDesk Enterprise Lite — Sealed Product Specification

**Trial**: FACTORY-BUILD-PRO-2 | **Date**: 2026-06-27 | **Sealed**: Yes (no modifications during trial)

---

## Product Scope

A team operations platform for small-to-medium teams (10-500 users).

### Core Modules

1. **Auth**: Register, login, JWT, RBAC (admin/manager/agent/client/viewer)
2. **Clients**: CRUD, organization management, contacts
3. **Projects**: Project spaces, members, status tracking
4. **Tasks**: Task CRUD, assignment, priority, due dates, dependencies
5. **Tickets**: Ticket CRUD, workflow (new→triaged→assigned→waiting_customer→resolved→closed/reopened)
6. **Approvals**: Change approval workflow (pending→approved/rejected)
7. **Knowledge Base**: Articles CRUD, categories, search
8. **Notifications**: In-app + email notifications for assignments, mentions, status changes
9. **Audit Log**: Immutable audit trail for all state-changing operations
10. **Reports**: Basic dashboard, task/ticket metrics, team workload
11. **Automation Rules**: Configurable triggers + actions (e.g., auto-assign, auto-close)

### Tech Stack

- **Backend**: Node.js + Express + TypeScript
- **Frontend**: React + TypeScript (Vite)
- **Database**: SQLite (via better-sqlite3)
- **Auth**: bcrypt + JWT
- **API**: RESTful JSON

### Non-Goals (v1)

- No real-time WebSocket
- No payment/billing
- No multi-tenancy
- No file uploads
- No mobile apps
- No OAuth/SSO

### Architecture

- Monolith backend (deliberate choice for team size target)
- Clean separation: routes → services → repositories
- Shared TypeScript types between frontend and backend
