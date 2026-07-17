# FACTORY-DIAGNOSTIC-SMOKE-0-D — Architecture & Runtime Surface Report

**Verdict: CONFUSING**

## Two Server Implementations

| Aspect | Root-level (RUNNING) | server/src/ (ALTERNATE) |
|--------|---------------------|------------------------|
| Entry | `server/index.js` | `server/src/index.js` |
| Routes | 5 | 14 |
| Auth | JWT (basic) | JWT + email verification |
| Security | cors + json | rate-limit, SQL guard, audit, validation, compression |
| Models | None | 5 (user, product, order, cart, review) |
| Services | None | 6 (auth, category, dashboard, merchant, order, product) |

## Runtime Surface

To run this project: **MySQL + 4 Node processes**
- MySQL database (schema.sql import)
- `cd server && node index.js` (port 3000)
- `cd client-v2 && npm run dev` (port 5173)
- `cd admin && npm run dev` (port 5174)
- `cd merchant && npm run dev` (port 5175)

No docker-compose. No concurrently. No single start command.
