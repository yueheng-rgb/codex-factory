# FACTORY-EVAL-11: LedgerFlow Lite Vanilla Baseline Run Report

**Run ID:** FACTORY-EVAL-11-RUN-D-VANILLA  
**Date:** 2026-06-25T21:00+08:00  
**Status:** COMPLETE  

## What Was Built

A full-stack invoicing, expense, approval, and reporting system (LedgerFlow Lite) implemented entirely without Factory assistance.

**Stack:** Node.js + Express + SQLite (sql.js) + Native HTML/CSS/JS  
**Product Location:** harness/benchmarks/factory-eval-second-project/runs/vanilla/product/

## What Runs

- Server starts with 
ode server.js on port 3000
- Database auto-creates and seeds with 
ode seed.js
- Full SPA frontend with login, dashboard, invoice management, customer management, audit log
- All 16 functional requirements implemented

## Test Results

| Test Suite | Passed | Failed |
|------------|--------|--------|
| Unit Tests (Financial + Workflow + Permissions) | 26 | 0 |
| Integration Tests (Auth, CRUD, Workflow, CSV, Dashboard, Permissions) | 28 | 0 |
| Verification Script | 18 | 0 |
| **Total** | **72** | **0** |

## Architecture Overview

- **Backend:** Express server with modular route files
- **Auth:** JWT with bcrypt password hashing, role-based middleware
- **Database:** SQLite via sql.js (pure JS, no native deps), WAL mode, foreign keys
- **Frontend:** Single-page app with vanilla JS, CSS Grid/Flexbox
- **API:** RESTful, JSON responses, proper HTTP status codes

## Financial Calculation Handling

- All calculations server-side in ecalculateInvoice()
- line_total = quantity * unit_price
- subtotal = sum(line_totals)
- 	ax_amount = subtotal * tax_rate
- grand_total = subtotal + tax_amount
- Rounding to 2 decimal places at each step
- Verified with zero-tax and multi-line-item test cases

## Workflow / Approval Handling

- Status transitions enforced: draft → submitted → approved/rejected, rejected → draft, approved → paid
- Invalid transitions return 400
- Permission checks: clerk submits, manager/admin approve/reject/mark-paid, viewer read-only
- Audit log records all status changes

## Known Missing Requirements

None. All 16 FRs implemented and verified.

## Known Defects

- Dashboard shows current-month metrics only; seed data dates are 2025 so shows 0 for demo
- No file upload support (not in spec)

## Simplification Risks Observed

- sql.js chosen over better-sqlite3 due to missing C++ build tools
- Frontend uses vanilla JS (no framework) — adequate for this scope
- No pagination on list endpoints (seed data is small)

## Human Intervention Count: 2

1. Switched from better-sqlite3 to sql.js (build tool issue)
2. Fixed execute() lastInsertRowid order bug

Both were environmental/technical, not design changes.

## Contamination Verdict: CLEAN

No v0.4 draft, Manual Router, Proof-of-Read, Factory Lite, 3-role model, Context OS/MCP, or other Factory mechanisms were used during implementation.

## Readiness for Independent Evaluation

The product is fully functional with:
- Runnable server
- Complete test suite (72/72 passing)
- Verification script
- README with instructions
- Seed data
- All required features

Ready for FACTORY-EVAL-12 (v0.4 Factory Lite Core Run) comparison when appropriate.
