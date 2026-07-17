# Admin System Runtime Validation Testbed

Validates all 13 invariants from the **admin-system** expert pack against a
live in-memory admin backend.

## Quick Start

```bash
npm install
npm test
npm start    # Starts server on port 3200
```

## What This Testbed Validates

| # | Invariant | Category | Status |
|---|-----------|----------|--------|
| 1 | admin_required_for_admin_routes | authentication | ✅ |
| 2 | role_permission_must_be_enforced | permission | ✅ |
| 3 | ordinary_admin_cannot_escalate_role | permission | ✅ |
| 4 | destructive_action_requires_confirmation | safety | ✅ |
| 5 | deleted_record_not_listed_by_default | data-integrity | ✅ |
| 6 | status_transition_allowed | business-logic | ✅ |
| 7 | protected_fields_cannot_be_modified_without_permission | permission | ✅ |
| 8 | batch_operation_must_be_scoped | safety | ✅ |
| 9 | audit_log_required_for_sensitive_actions | audit | ✅ |
| 10 | export_requires_permission | permission | ✅ |
| 11 | import_requires_validation | data-integrity | ✅ |
| 12 | pagination_limit_enforced | performance | ✅ |
| 13 | search_filter_must_be_whitelisted | security | ✅ |

## Negative Controls (8)

1. Unauthenticated admin route access → BLOCKED
2. Viewer accessing forbidden resource → BLOCKED
3. Operator escalating to SUPER_ADMIN → BLOCKED
4. Delete without confirmation → BLOCKED
5. Batch operation exceeds scope → BLOCKED
6. Sensitive action without audit log → IMPOSSIBLE
7. Export without permission → BLOCKED
8. Import with invalid fields → BLOCKED

## API Endpoints

| Method | Path | Requires |
|--------|------|----------|
| GET | /health | None |
| GET | /admin/users | user:read |
| GET | /admin/users/:id | user:read |
| PATCH | /admin/users/:id/role | user:write |
| POST | /admin/resources | resource:write |
| GET | /admin/resources | resource:read |
| GET | /admin/resources/:id | resource:read |
| PATCH | /admin/resources/:id | resource:write |
| PATCH | /admin/resources/:id/status | resource:write |
| DELETE | /admin/resources/:id | resource:delete + confirmation |
| POST | /admin/batch-delete | resource:delete + confirmation |
| POST | /admin/batch-update-status | resource:write |
| POST | /admin/export | export:read |
| POST | /admin/import | resource:write + ADMIN+ |
| GET | /admin/audit-log | audit:read |

## Authentication

All /admin/* routes require `x-user-id` header with a valid seeded user:
- `su_1` — SUPER_ADMIN (all permissions)
- `adm_1` — ADMIN (most permissions including export, audit)
- `op_1` — OPERATOR (read + write, no delete/export/audit)
- `vw_1` — VIEWER (read only)

## Pack Traceability

Every invariant, risk rule, and test category traces back to:
`governance/expert-packs/admin-system/admin-system-pack.json` v1.0.0

See `business-invariants.json` for full traceability matrix.

## Non-Claims

- NOT a production admin system
- NOT a replacement for real auth (JWT/OAuth)
- In-memory store only — no database
- Testbed for validation, not deployment
