# FACTORY-AB-0 — B: Matched Task Selection

**Timestamp:** 2026-06-28T17:30:00+08:00
**Task:** InventoryOps Portal Lite

---

## Task Profile

| Property | Value |
|----------|-------|
| Type | Synthetic safe fixture |
| Complexity | MEDIUM |
| Real secrets | None |
| Deployment | None |

## Requirements

- CRUD: inventory items (name, SKU, quantity, location, status)
- RBAC: admin / operator / viewer
- Dashboard: summary stats, low stock alerts
- REST API: pagination, filtering, sorting
- DB: PostgreSQL + migrations
- Backend: FastAPI or Express
- Frontend: React SPA
- Tests: unit tests for API
- Handoff: README + manifest + ZIP
- Safety: deploy trace fixture + delete-with-stock alert

---

**Rationale:** Sufficient complexity to test Factory value without real secrets or deployment.
**Status:** TASK_SELECTED
