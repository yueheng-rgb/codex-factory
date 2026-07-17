# FACTORY-EVAL-4 / E — Independent Evaluator Policy Report

> Generated: 2026-06-25T17:18:00+08:00
> Section: E — Independent Evaluator Policy

---

## Core Principle

**The evaluator must be a separate agent from the builder.** Builder produces artifacts; evaluator independently verifies them against the rubric. Evaluator does not see builder process, only final artifacts.

---

## Evaluator Setup

| Requirement | Detail |
|---|---|
| Separation | Different Codex session/window from builder |
| Blindness | No access to builder conversation, message turns, process artifacts |
| Inputs | Benchmark spec + Evaluation rubric + Run output directory |
| Budget | 50 message turns maximum for evaluation |

---

## Evaluator Mandate

### Must Do
1. Read benchmark spec (Section B) completely before evaluating
2. Read evaluation rubric (Section D) completely before scoring
3. Inspect run output directory for all delivered files
4. Run the project using documented run command
5. Verify API endpoints with curl/HTTP client
6. Verify UI pages by checking component files
7. Inspect database schema for constraints, indexes, relationships
8. Run test suite and record pass/fail results
9. Perform boundary tests for auth and authorization
10. Check audit log entries after performing actions
11. Verify README instructions by following them
12. Produce structured evaluation report with evidence paths per score

### Must NOT Do
- Modify run output files
- Fix bugs or complete unfinished work
- Trust builder self-assessments
- Give partial credit for half-implemented features
- Accept placeholder implementations (TODO comments)
- Score file/export/agent count as quality
- Use different criteria for different runs
- Show bias toward any run configuration

---

## Evaluation Process (12 Steps)

| Step | Action |
|---|---|
| 1 | **Receive and inventory** — list all files in run output |
| 2 | **Read spec and rubric** — fully read before proceeding |
| 3 | **Run the project** — follow README; record success/failure |
| 4 | **D01: Requirement Coverage** — verify each FR01-FR11 |
| 5 | **D02: API Contract** — test all 21 endpoints with valid + invalid inputs |
| 6 | **D03: Database Schema** — inspect constraints, indexes, normalization |
| 7 | **D04: Auth & Authorization** — boundary tests for 401/403/multi-tenant |
| 8 | **D05: UI States** — check loading/empty/error/success per page |
| 9 | **D06: Audit Trail** — perform actions, query log, verify entries |
| 10 | **D07: Test Quality** — run tests, inspect for real assertions |
| 11 | **D08: Documentation** — follow setup/run/test from README |
| 12 | **Produce evaluation report** — JSON with scores + evidence paths |

---

## Cannot Evaluate Policy

| Scenario | Handling |
|---|---|
| Project won't start | D08=0, D01-D07 marked cannot_evaluate |
| Endpoint returns 500 | D02 partial, record the error |
| No test files found | D07=0 |
| No schema file found | D03=0 |
| Any unverifiable item | MUST record as cannot_evaluate, not skip |

---

## Evaluation Output Format

JSON file per run at `governance/factory-eval/factory-eval-5-result.json`:
- `run_id` (A/B/C)
- `total_score` (0-100)
- Per-dimension scores with evidence paths
- Human intervention count
- Message turns
- Caveats and cannot_evaluate items

---

## Next: Section F — Benchmark Harness Design
