# FACTORY-EVAL-10-A: Second Benchmark Project Selection

**Project:** LedgerFlow Lite  
**Type:** Small invoicing/expense system with approval workflow

## Why LedgerFlow Lite?

| Aspect | TeamFlow Lite (EVAL-8) | LedgerFlow Lite (EVAL-10) |
|---|---|---|
| Domain | Task/workflow management | Financial operations |
| Core entity | Tasks | Invoices with line items |
| Workflow | Status transitions | Approval chain (draft→paid) |
| Calculations | None | Tax, totals, aggregations |
| Reporting | Simple overdue list | Dashboard with aggregates |
| Export | None | CSV export |
| FRs | 11 | 14-16 |

## What This Tests

LedgerFlow Lite tests whether v0.4 Factory Lite generalizes beyond task management to a financial domain with calculations, line items, approval workflows, and reporting — exposing new simplification risks that v0.4's Manual Router + Proof-of-Read should catch.
