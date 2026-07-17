# FACTORY-EVAL-5 / A — Vanilla Run Setup Report

> Run: FACTORY-EVAL-5-RUN-A-VANILLA
> Started: 2026-06-25T17:00:00+08:00
> Factory assistance: DISABLED

## Setup Confirmed

- [x] EVAL-4 PASS verified (36/36)
- [x] Benchmark spec available
- [x] Run comparison design available
- [x] Evaluation rubric available
- [x] FINAL package SHA verified unchanged
- [x] No new ZIP
- [x] Vanilla run directory created (empty)
- [x] RUN_METADATA created

## Constraints Active

- No Manual Router
- No Proof-of-Read
- No Role Agents
- No Agent OS
- No Context OS / MCP Memory
- No Factory Verifier as dev guide
- Single Codex agent implementation path
- No Factory process artifacts in product

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Node.js + Express |
| Database | SQLite via better-sqlite3 |
| Frontend | Vanilla HTML/CSS/JS (no build step) |
| Auth | JWT + bcryptjs |
| Testing | Node test runner + supertest |

## Product Directory

`harness/benchmarks/factory-eval-real-project/runs/vanilla/product/`
