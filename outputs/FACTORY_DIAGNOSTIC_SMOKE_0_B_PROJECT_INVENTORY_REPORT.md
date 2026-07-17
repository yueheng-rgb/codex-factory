# FACTORY-DIAGNOSTIC-SMOKE-0-B — Project Inventory Report

**217 files, 44.3 MB** — 4 apps, 10 DB tables, 2 server implementations, 0 tests.

## File Classification

| Category | Count | Key Files |
|----------|-------|-----------|
| Source Code | 134 | Vue views/components, Express routes, API clients |
| Database Scripts | 6 | schema.sql, seed files, init scripts |
| Build Artifacts | 22 | dist/ in all 3 frontend apps |
| Writer/Generator | 13 | _writer*.js, write_*.py (code generation tools) |
| Config | 8 | package.json ×5, vite config ×3 |
| Static Assets | 35 | 32 PNG product images + HTML entry points |
| Tests | 0 | test_pw.js is utility, not a test |

## Apps

| App | Port | Framework | Pages |
|-----|------|-----------|-------|
| client-v2 (Customer) | 5173 | Vue 3 + Vite | Home, Detail, Cart, Orders, Favorites, Compare, Profile, Login |
| admin (Admin) | 5174 | Vue 3 + Vite | Dashboard, Products, Categories, Orders, Users, Merchants |
| merchant (Merchant) | 5175 | Vue 3 + Vite | Dashboard, Products, Orders |
| server (Backend) | 3000 | Express.js | TWO implementations (see Architecture review) |

## Critical Discovery

**Two competing server implementations exist:**
1. Root-level `server/index.js` with `routes/*.js` (5 routes) — the running server
2. `server/src/index.js` with full MVC structure (14 routes) — NOT connected to runtime
