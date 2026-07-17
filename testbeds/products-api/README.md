# Products API CRUD Testbed

> Formal CRUD testbed for the Codex App Factory.
> Validates api-service patterns: CRUD, validation, error format, status transitions.
> This is a **test infrastructure asset**, not a production application.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Health check |
| `GET` | `/api/products` | List products (page, pageSize, search, category, status) |
| `GET` | `/api/products/:id` | Get product by ID |
| `POST` | `/api/products` | Create product |
| `PATCH` | `/api/products/:id` | Update product fields |
| `PATCH` | `/api/products/:id/status` | Status transition (active ? inactive ? discontinued) |

## Features

- Unified response format: `{ ok: true, data }` / `{ ok: false, error: { code, message } }`
- Unknown field rejection on create and update
- Schema validation (required fields, types, ranges)
- Status transition rules (state machine)
- Pagination, search, and filtering on list endpoint
- Full test suite

## Start

```bash
npm install
npm run dev        # http://localhost:3001
```

## Test

```bash
npm test           # vitest run
npm run typecheck  # TypeScript check
```