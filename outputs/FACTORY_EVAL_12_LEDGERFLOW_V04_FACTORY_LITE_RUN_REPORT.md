# FACTORY-EVAL-12: LedgerFlow Lite v0.4 Factory Lite Core — RUN-E Report

**Phase**: FACTORY-EVAL-12  
**Run**: RUN-E / V04_FACTORY_LITE_CORE  
**Date**: 2026-06-25T21:34:18+08:00  
**Status**: COMPLETE

## What Was Built

LedgerFlow Lite — an invoicing and expense tracking system implemented as an Express + SQLite monolith. The system supports user registration with role-based access control (admin, manager, clerk, viewer), customer CRUD, invoice management with multi-line items, a 5-stage approval workflow (draft → submitted → approved/rejected → paid), audit logging, dashboard summaries, search/filter/sort, and CSV export.

## What Runs

- Server starts on port 3000: 
ode server.js
- Seed data: 
ode seed.js (4 users, 5 customers, 5 invoices)
- Tests: 
ode --test tests/all.test.js (32 tests)
- All 16 functional requirements implemented and verified

## Test Results

| Category | Count | Pass | Fail |
|----------|-------|------|------|
| Unit: Financial Calculations | 5 | 5 | 0 |
| Unit: Approval Workflow | 6 | 6 | 0 |
| Unit: Permission Boundaries | 5 | 5 | 0 |
| Integration: Auth Flow | 3 | 3 | 0 |
| Integration: Customer CRUD | 1 | 1 | 0 |
| Integration: Invoice Lifecycle | 1 | 1 | 0 |
| Integration: CSV Export | 1 | 1 | 0 |
| Integration: Dashboard | 1 | 1 | 0 |
| Integration: Audit Log | 2 | 2 | 0 |
| Integration: Search/Filter/Sort | 3 | 3 | 0 |
| Validation | 4 | 4 | 0 |
| **TOTAL** | **32** | **32** | **0** |

## Known Missing Requirements

None. All 16 FRs implemented and verified.

## Known Defects

None identified.

## Simplification Risks Observed

- SQLite is used instead of PostgreSQL (per anti-overengineering rules for small projects)
- HTML frontend is minimal (server-rendered) — FR14 satisfied but could be richer
- No rate limiting, CORS configuration, or production security hardening
- Single-file database — not suitable for concurrent multi-process access

## Architecture Overview

Monolithic Express server:
- server.js — entry point, middleware, HTML landing page
- db.js — SQLite via sql.js with query helper functions
- middleware/auth.js — JWT auth, role-based access control
- outes/auth.js — register, login, me
- outes/customers.js — customer CRUD
- outes/invoices.js — invoice CRUD, approval workflow, CSV export
- outes/dashboard.js — aggregate dashboard queries
- outes/audit.js — audit log with filtering

## Financial Calculation Handling

All calculations server-side:
- line_total = quantity × unit_price (with Math.round for precision)
- subtotal = Σ line_totals
- tax_amount = subtotal × tax_rate / 100
- grand_total = subtotal + tax_amount
- Verified: 5 unit tests with exact value comparisons

## Workflow/Approval Handling

5-stage state machine:
- draft → submitted (clerk) → approved (manager) → paid (manager)
- draft → submitted (clerk) → rejected (manager) → back to draft
- Invalid transitions return HTTP 400
- Permission enforced: clerk cannot approve (403), viewer read-only (403)
- Verified: 6 unit tests covering valid and invalid transitions

## Human Intervention Count

**2 interventions** (both environmental, zero design changes):
1. better-sqlite3 → sql.js switch (missing C++ build tools)
2. Server auto-listen fix for test imports

## v0.4 Process Overhead

~375ms total for all v0.4 Factory Lite Core mechanisms:
- Required Reading Gate: ~200ms
- Proof-of-Read generation: ~100ms
- Manual Router: ~50ms
- Contamination logging: ~10ms
- Evidence hierarchy/anti-gaming/context budget: ~15ms

## Contamination Verdict

**CLEAN** — No cross-contamination with RUN-D. All 7 contamination checks passed. No RUN-D product code was read, copied, or referenced during implementation.

## Readiness for Independent Evaluation

RUN-E is ready for independent comparison against RUN-D in FACTORY-EVAL-13. All required artifacts are in place: product code, tests, self-mapping, proof-of-read, overhead tracking, contamination logs, and negative controls.

## Verifier Results

- Verifier: 28/28 checks PASS
- Negative controls: 38/38 PASS, 0 gaps
- No UNEXPECTED_PASS
- No FAIL_TARGET_NOT_TRIGGERED
