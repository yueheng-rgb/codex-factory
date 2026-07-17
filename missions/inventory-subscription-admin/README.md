# Inventory Subscription Admin — v2.0-RC Mission Project

Combines **Admin System**, **Ecommerce**, and **SaaS Tool** Expert Packs
into a single real project.

## Quick Start
```bash
npm install
npm test       # 38 tests
npm start      # Server on port 3300
```

## Expert Packs Activated
| Pack | Invariants Enforced | Tests |
|------|-------------------|-------|
| admin-system | 6 | 11 |
| ecommerce | 6 | 12 |
| saas-tool | 4 | 8 |
| Negative Controls | — | 10 |
| Edge Cases | — | 1 |
| **TOTAL** | **16 invariants** | **38 tests** |

## API Endpoints
| Method | Path | Requires |
|--------|------|----------|
| GET | /health | None |
| GET | /ready | None |
| GET | /admin/users/:id | Auth |
| PATCH | /admin/users/:id/role | user:write |
| POST | /admin/products | product:write |
| PATCH | /admin/products/:id/price | ADMIN+ |
| PATCH | /admin/products/:id/status | product:write + confirm |
| POST | /admin/products/:id/inventory | inventory:write |
| GET | /admin/tenants/:id | tenant:read |
| POST | /admin/tenants/:id/quota | tenant:read |
| PATCH | /admin/tenants/:id/subscription | SUPER_ADMIN only |
| GET | /admin/audit | audit:read |

## Seeded Users
| ID | Role | Tenant | Key Perms |
|----|------|--------|-----------|
| su_1 | SUPER_ADMIN | t1 | * |
| adm_1 | ADMIN | t1 | product:rw, inventory:w, user:rw, audit:r, tenant:r |
| op_1 | OPERATOR | t1 | product:rw, inventory:w, user:rw |
| vw_1 | VIEWER | t1 | product:r |

## Architecture
- Fastify + TypeScript
- In-memory store (NOT production)
- 3 service domains: auth (admin), product (ecommerce), tenant (SaaS)
- Tenant isolation enforced at service layer
- Audit log on all sensitive actions

## Non-Claims
- NOT a production system
- In-memory store — data lost on restart
- No real auth (JWT/OAuth) — uses x-user-id header
- No admin UI — API-only
- NOT production-deployable
