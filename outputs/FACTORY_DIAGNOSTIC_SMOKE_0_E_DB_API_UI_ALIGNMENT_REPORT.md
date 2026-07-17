# FACTORY-DIAGNOSTIC-SMOKE-0-E — DB/API/UI Alignment Report

**Verdict: MISMATCH — Running server implements ~50% of intended API surface**

## DB → API Alignment

| DB Table | API on Running Server | Status |
|----------|----------------------|--------|
| users | Partial (register/login/profile missing) | PARTIAL |
| products | Yes (full CRUD with admin auth) | ALIGNED |
| categories | Yes (GET only, no auth) | ALIGNED |
| cart_items | Yes (full CRUD with auth) | ALIGNED |
| orders | Partial (basic CRUD, no merchant filter) | PARTIAL |
| favorites | **NO** (table exists, API missing) | MISSING |
| reviews | **NO** (table exists, API missing) | MISSING |
| merchants | **NO** (table exists, API missing) | MISSING |

## UI → API Alignment

| Page | Expected API | On Running Server |
|------|-------------|-------------------|
| Login | POST /api/auth/login | **MISSING** |
| Favorites | /api/favorites/* | **MISSING** |
| Product Detail | GET /api/products/:id | ALIGNED |
| Cart | /api/cart/* | ALIGNED |
| Order Detail | /api/orders/:id/messages | **MISSING** |

## Missing Routes Summary

The running server needs these routes added: `/api/auth` (login, register, profile), `/api/favorites`, `/api/reviews`, `/api/merchants`, `/api/orders/:id/messages`
