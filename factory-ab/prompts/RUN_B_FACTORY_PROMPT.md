# RUN-B: Factory Build Lite Prompt — InventoryOps Portal Lite

## Task

Build a full-stack **InventoryOps Portal Lite** — an inventory management admin portal.
Use the Factory Build Lite workflow: install → bootstrap → preflight → build → phase-close.

## Requirements

### Core Features
1. **CRUD for inventory items:** name, SKU, quantity, location, status (active/inactive/discontinued)
2. **Role-based access:** admin (full CRUD), operator (view + update quantity), viewer (read-only)
3. **Dashboard:** summary stats — total items, low stock alerts (< 10), item count by location
4. **REST API:** pagination, filtering (by status, location), sorting (by name, quantity, updated_at)
5. **Database:** PostgreSQL schema with migrations
6. **Backend:** Python FastAPI or Node.js Express
7. **Frontend:** React admin-style SPA
8. **Unit tests** for API endpoints
9. **README** with install and run instructions
10. **Deploy config template:** `.env.production.example` (empty template, no real secrets)
11. **Safety rule:** alert/block when deleting items with stock > 0

## Deliverables
- Full project source code
- Database schema + migration files
- API with pagination/filtering/sorting
- Frontend SPA with dashboard
- Unit tests (pytest or jest)
- README.md with setup instructions
- `.env.example` with placeholder values

## Success Criteria
- Install with one documented command
- API returns paginated, filtered, sortable results
- Dashboard shows correct summary stats
- Tests pass
- Delete-with-stock alert works

---

**Note:** This is a synthetic project. No real data, no real secrets, no deployment required.
Factory Build Lite is active with Security Gate, Package QA Gate, Context Space, and Test Repair Policy.
