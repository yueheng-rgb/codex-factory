# Ecommerce Runtime Validation Testbed
# Codex Factory R5.2 — Ecommerce Pack Runtime Validation

## Purpose

This testbed validates the R5.1 Ecommerce Expert Pack at runtime.
It proves that all 12 ecommerce business invariants, 8 risk rules,
required tests, external engine plan, and audit gates work in real code.

**NOT a production ecommerce system.** This is a validation testbed.

## Activated Expert Pack

- **Pack**: `ecommerce` v1.0.0
- **Source**: `governance/expert-packs/ecommerce/ecommerce-pack.json`
- **Integration**: All 12 invariants traced to pack definition in `business-invariants.json`

## Invariants Validated (12/12)

| # | Invariant | Enforced In |
|---|-----------|-------------|
| 1 | price_non_negative | product.service.ts |
| 2 | price_not_zero_unless_explicit_free | product.service.ts |
| 3 | inventory_non_negative | inventory.service.ts |
| 4 | order_total_matches_items | order.service.ts |
| 5 | payment_idempotency_required | order.service.ts |
| 6 | paid_order_cannot_be_modified_without_refund_flow | order.service.ts |
| 7 | cancelled_order_cannot_be_paid | order.service.ts |
| 8 | archived_product_not_sellable | product.service.ts + order.service.ts |
| 9 | user_cannot_modify_price | product.service.ts |
| 10 | admin_required_for_price_change | product.service.ts + routes/products.ts |
| 11 | stock_delta_must_be_audited | inventory.service.ts |
| 12 | refund_amount_cannot_exceed_paid_amount | order.service.ts |

## Negative Controls (5/5)

1. User modifies price → FORBIDDEN (403)
2. Inventory adjusted negative → REJECTED
3. Duplicate payment callback → IDEMPOTENT
4. Paid order directly cancelled → BLOCKED
5. Refund exceeds payment → BLOCKED

## Stack

- Fastify (REST API)
- TypeScript
- Vitest (testing)
- In-memory store

## Quick Start

```bash
npm install
npm test          # Run all validation tests
npx tsx src/server.ts   # Start server on :3200
```

## Endpoints

- `GET /health` — Health check
- `POST /api/products` — Create product
- `GET /api/products` — List products
- `GET /api/products/:id` — Get product
- `PATCH /api/products/:id` — Update product (role-based)
- `POST /api/products/:id/inventory` — Adjust inventory (audited)
- `GET /api/audit-log` — View audit trail
- `POST /api/orders` — Create order
- `GET /api/orders/:id` — Get order
- `POST /api/payment-callback` — Process payment (idempotent)
- `POST /api/orders/:id/refund` — Refund order
- `POST /api/orders/:id/cancel` — Cancel order

## Role Headers

- `x-user-role`: ADMIN or USER (default: USER)
- `x-user-id`: User identifier (default: anon)

## Risk Rules Validated (7/8)

ECOM-R001 through ECOM-R008 validated via tests.
ECOM-R006 (discount) marked design-only — not in testbed scope.
