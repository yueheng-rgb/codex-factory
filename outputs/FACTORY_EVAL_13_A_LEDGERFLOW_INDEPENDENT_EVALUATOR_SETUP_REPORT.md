# FACTORY-EVAL-13-A: Independent Evaluator Setup Report

**Phase**: FACTORY-EVAL-13-A
**Evaluator**: READONLY  
**Created**: 2026-06-25T22:07:48+08:00

## Compared Runs

| Run | Type | Factory Assistance |
|-----|------|-------------------|
| RUN-D | Vanilla Codex | NONE |
| RUN-E | v0.4 Factory Lite Core | V04_FACTORY_LITE_CORE |

## Rules

- Readonly — no product code modification
- Self-mapping is evidence input, not final score
- Score requires evidence paths to specific files
- Blockers override score
- Process artifacts ≠ product quality
- Cannot-evaluate must be marked, not forced to PASS

## Rubric

100-point rubric from actory-eval-10-rubric.json:
- D01: Requirement Coverage (24 pts)
- D02: API Contract Correctness (16 pts)
- D03: Database Schema Quality (10 pts)
- D04: Financial Calculation Correctness (12 pts)
- D05: Approval Workflow Correctness (10 pts)
- D06: Auth and Authorization (10 pts)
- D07: Audit Trail (5 pts)
- D08: Dashboard and Export (5 pts)
- D09: UI and UX (5 pts)
- D10: Tests and Documentation (3 pts)
