# FACTORY-DIAGNOSTIC-SMOKE-0-F — Security & RBAC Review Report

**Verdict: BASIC_WITH_GAPS**

## What Works

- ✅ JWT authentication (jsonwebtoken)
- ✅ bcrypt password hashing
- ✅ Server-side admin role check (adminMiddleware)
- ✅ Frontend route guards (client, admin, merchant apps)
- ✅ Role-based UI visibility

## What Has Gaps

| Gap | Severity |
|-----|----------|
| JWT_SECRET hardcoded in auth.js (different from .env) | CRITICAL |
| SMTP credentials in plaintext .env | HIGH |
| DB password 123456 in plaintext | HIGH |
| No merchant-specific middleware (frontend-only role check) | MEDIUM |
| No resource ownership verification (user can access others' data) | MEDIUM |
| Rate limiting, SQL guard, audit — only in UNUSED server | MEDIUM |
| Categories route has no auth (write operations unprotected) | LOW |
