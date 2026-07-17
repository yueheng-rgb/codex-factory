# FACTORY-DIAGNOSTIC-SMOKE-0-I — Findings & Repair Backlog

**14 findings. 0 repairs performed (readonly boundary preserved).**

## Priority Breakdown

| Priority | Count | Findings |
|----------|-------|----------|
| P1 (Blocking) | 3 | F01: Two servers, F02: API mismatch, F03: Wrong start script |
| P2 (Important) | 5 | F04: JWT secret mismatch, F05: No tests, F06: No README, F07: Credential exposure, F08: Missing merchant middleware |
| P3 (Should Fix) | 4 | F09: Ownership checks, F10: Security features unused, F14: Categories auth gap |
| P4 (Nice to have) | 2 | F11: Writer scripts location, F12: No single startup, F13: Dist in source |

## By Category

| Category | Count |
|----------|-------|
| Security | 4 |
| Configuration | 4 |
| Architecture | 1 |
| Integration | 1 |
| Testing | 1 |
| Documentation | 1 |
| Code Organization | 1 |
| DevOps | 1 |

## Suggested Repair Order

1. **F01 + F02**: Consolidate to ONE server. Add missing routes (auth, favorites, reviews).
2. **F03**: Fix package.json start script.
3. **F04**: Unify JWT_SECRET to .env only.
4. **F05**: Add minimum auth+CRUD tests.
5. **F06**: Create README with setup instructions.
6. **F07**: Move credentials to .env exclusively.
7. **F08**: Add merchantMiddleware.
