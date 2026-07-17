# Mini Inventory Admin Pilot

Codex Factory R3.2 — Real Project Pilot: Full Factory Pipeline End-to-End

## Quick Start

```bash
cd pilots/mini-inventory-admin
npm install
npm run build
npm start        # Server at http://localhost:3100
```

## Commands

| Command | Description |
|---------|-------------|
| `npm install` | Install dependencies |
| `npm run build` | Compile TypeScript |
| `npm start` | Start server (port 3100) |
| `npm run dev` | Dev mode with hot reload |
| `npm test` | Run 22 API tests |
| `npm run typecheck` | TypeScript type checking |

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| GET | `/api/items` | List items (pagination, search, filter) |
| GET | `/api/items/:id` | Get item by ID |
| POST | `/api/items` | Create item |
| PATCH | `/api/items/:id` | Update item |
| PATCH | `/api/items/:id/status` | Change item status |
| POST | `/api/items/:id/inventory` | Adjust inventory (+/- delta) |
| DELETE | `/api/items/:id` | Hard delete (BLOCKED — archive instead) |

## Admin Surface

Open `admin/index.html` in a browser (served via any HTTP server, or open directly).
Connects to `http://localhost:3100/api/items`.

## Business Invariants

All invariants enforced server-side. See `business-invariants.json`.

| Invariant | Severity | Scope |
|-----------|----------|-------|
| price_non_negative | CRITICAL | create, update |
| price_not_zero_unless_explicit_free | CRITICAL | create, update |
| inventory_non_negative | CRITICAL | create, update, adjust |
| status_transition_allowed | HIGH | status change |
| archived_entity_not_mutable | HIGH | update, adjust |
| user_cannot_modify_protected_fields | HIGH | create, update |
| destructive_action_requires_confirmation | CRITICAL | delete |

## Test Coverage (22 tests)

- CRUD operations (5)
- Validation (2)
- Price invariant (2)
- Price zero/explicit free (2)
- Inventory invariant (4)
- Status transition (2)
- Archived entity (2)
- Protected fields (2)
- Destructive action blocked (1)

## External Engine Results

| Engine | Result |
|--------|--------|
| semgrep | 0 findings (CLEAN) — 227 rules, 12 files |
| autocannon | 338,571 req, 0 errors (CLEAN) |
| playwright | TOOL_FAILED (browser version mismatch) |
| codeql | SKIPPED (not installed) |
| k6 | SKIPPED (not installed) |

## Surfaces

- **api-service**: Fastify + TypeScript, port 3100
- **admin-web**: Single-page admin panel (admin/index.html)
- **database**: In-memory store (swap to Postgres for production)
- **docs-release**: This README + R3.2 report
