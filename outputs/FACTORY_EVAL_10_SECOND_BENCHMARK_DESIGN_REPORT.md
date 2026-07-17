# FACTORY-EVAL-10: Second Benchmark Design Report

**Status:** COMPLETED — 28/28 Verifier PASS  
**Generated:** 2026-06-25T20:30:00+08:00

---

## LedgerFlow Lite — Second Benchmark

A small invoicing/expense system designed to test v0.4 Factory Lite generalizability beyond task management.

### Why Different from TeamFlow Lite

| Aspect | TeamFlow Lite | LedgerFlow Lite |
|---|---|---|
| Domain | Task management | Financial operations |
| Core entity | Tasks with comments | Invoices with line items |
| Calculations | None | Tax, totals, aggregations |
| Workflow | Status transitions | Approval chain |
| Export | None | CSV export |
| FRs | 11 | 16 |

### Benchmark Design

| Run | Type | Allowed Mechanisms | Overhead |
|---|---|---|---|
| RUN-A | Vanilla Codex | None | 0ms |
| RUN-B | v0.4 Factory Lite Core | Manual Router + POR + Constitution + Evidence + Contamination | ~200ms |
| RUN-C | v0.4 3-Role Optional | Core + Architect/Builder/Reviewer | ~350ms |

### Rubric (100 points)

D01 Requirement Coverage (24), D02 API Contract (16), D03 Database Schema (10), D04 Financial Calculation (12), D05 Approval Workflow (10), D06 Auth (10), D07 Audit Trail (5), D08 Dashboard/Export (5), D09 UI/UX (5), D10 Tests/Docs (3)

### Status

- **DESIGN ONLY** — no implementation started
- Harness directories created, empty
- Awaiting user review before FACTORY-EVAL-11

### Recommended Next

**FACTORY-EVAL-11** — LedgerFlow Lite Vanilla Run (RUN-A), or user review.
