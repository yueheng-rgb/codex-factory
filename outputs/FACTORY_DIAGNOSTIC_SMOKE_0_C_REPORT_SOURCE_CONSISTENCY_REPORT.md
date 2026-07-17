# FACTORY-DIAGNOSTIC-SMOKE-0-C — Report-Source Consistency Report

**24 claims checked. 12 verified. 12 with issues. 50% discrepancy rate.**

## Claim Classification

| Classification | Count | Examples |
|---------------|-------|----------|
| VERIFIED | 9 | DB tables, frontend pages, JWT+brypt auth |
| PARTIAL | 4 | MVC architecture (only in unused server), favorites/reviews (table exists, API missing) |
| NOT_FOUND | 6 | Email verification, message system, merchant revenue, file upload, test coverage, rate-limiting |
| CONTRADICTED | 2 | "One-click startup" (requires 5 processes), "npm start" (wrong entry point) |

## Key Discrepancies

1. **Auth routes missing**: Frontend calls `/api/auth/login` but running server has no auth route registered
2. **Favorites/reviews broken**: Tables exist in schema, frontend has UI, but NO API endpoint on running server
3. **Messages not implemented**: No table in schema, no route on any server
4. **Security features overstated**: Rate limiting, SQL guard, audit — all in unused server/src/
5. **Startup claimed simple**: Actually requires MySQL + 4 Node processes

## Verdict

Project report OVERSTATES implementation completeness. The database design and frontend structure are solid, but the backend API is only ~50% implemented on the running server. Many claimed features exist only as schema tables or frontend UI with no backend connection.
