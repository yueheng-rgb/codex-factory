# FACTORY-EVAL-4 / Real Project Benchmark Design — Final Report

> Generated: 2026-06-25T16:33:00+08:00
> Verifier: 36/36 PASS
> Status: **DESIGN COMPLETE — IMPLEMENTATION NOT STARTED**

---

## Overview

FACTORY-EVAL-4 designed a complete benchmark framework for comparing three Codex configurations on a non-Factory real project:

| Run | Configuration | Description |
|---|---|---|
| **RUN-A** | Vanilla Codex | No Factory assistance — baseline |
| **RUN-B** | Factory Lite | Manual Router + Proof-of-Read only |
| **RUN-C** | Factory Role-Agent | Full Role-Agent Company Model |

**Benchmark Project**: **TeamFlow Lite** — a multi-tenant team task/workflow SaaS

---

## What Was Designed (Sections A-I)

| Section | Deliverable | Status |
|---|---|---|
| **A** | Benchmark project selection | TeamFlow Lite selected — 5 rejected alternatives |
| **B** | Benchmark specification | 11 FRs, 21 API endpoints, 7 UI pages, 8 DB entities |
| **C** | Run comparison design | 3 runs, 5 primary metrics, 9 isolation rules |
| **D** | Evaluation rubric | 8 dimensions, 100 points, anti-gaming per dimension |
| **E** | Independent evaluator policy | 12-step process, blindness, cannot-evaluate policy |
| **F** | Benchmark harness design | 8 skeleton scripts, directory structure |
| **G** | Anti-gaming controls | 14 controls + 10 stop conditions |
| **H** | Negative controls | 30/30 PASS, 0 gaps |
| **I** | Verifier script | 36/36 checks PASS |

---

## Key Design Decisions

1. **Non-Factory project**: TeamFlow Lite has no Factory governance, verifier, or self-reference
2. **Same spec for all runs**: SHA256-verified identical specification
3. **Objective rubric only**: No file counts, export counts, or agent counts scored
4. **Independent evaluator**: Separate Codex session, blind to builder process
5. **Process overhead tracked**: Role-Agent overhead measured separately from product quality
6. **Stop conditions**: 10 conditions that halt benchmark if comparability breaks

---

## What Was NOT Done

- No benchmark runs executed
- No Vanilla baseline started
- No Factory Lite run started
- No Factory Role-Agent run started
- No Factory effectiveness claimed
- FINAL package NOT modified (SHA256 verified)
- No new final ZIP created

---

## Recommended Next Phase

**FACTORY-EVAL-5 / Vanilla Codex Baseline (RUN-A)**

Run TeamFlow Lite with Vanilla Codex (no Factory assistance) to establish the baseline quality score.

---

## File Inventory

### Governance JSONs (9)
- `governance/factory-eval/factory-eval-4-benchmark-project-selection.json`
- `governance/factory-eval/factory-eval-4-benchmark-spec.json`
- `governance/factory-eval/factory-eval-4-run-comparison-design.json`
- `governance/factory-eval/factory-eval-4-evaluation-rubric.json`
- `governance/factory-eval/factory-eval-4-independent-evaluator-policy.json`
- `governance/factory-eval/factory-eval-4-benchmark-harness-design.json`
- `governance/factory-eval/factory-eval-4-anti-gaming-policy.json`
- `governance/factory-eval/factory-eval-4-negative-controls-result.json`
- `governance/factory-eval/factory-eval-4-benchmark-design-result.json`

### Verifier
- `governance/factory-eval/verifier-factory-eval-4-result.json` (36/36 PASS)
- `scripts/factory-eval-4-real-project-benchmark-design-verify.ps1`

### Output Reports (8)
- `outputs/FACTORY_EVAL_4_A_BENCHMARK_PROJECT_SELECTION_REPORT.md`
- `outputs/FACTORY_EVAL_4_B_BENCHMARK_SPEC_REPORT.md`
- `outputs/FACTORY_EVAL_4_C_RUN_COMPARISON_DESIGN_REPORT.md`
- `outputs/FACTORY_EVAL_4_D_EVALUATION_RUBRIC_REPORT.md`
- `outputs/FACTORY_EVAL_4_E_INDEPENDENT_EVALUATOR_POLICY_REPORT.md`
- `outputs/FACTORY_EVAL_4_F_BENCHMARK_HARNESS_DESIGN_REPORT.md`
- `outputs/FACTORY_EVAL_4_G_ANTI_GAMING_STOP_CONDITIONS_REPORT.md`
- `outputs/FACTORY_EVAL_4_NEGATIVE_CONTROLS_REPORT.md`

### Harness Skeletons (8)
- `benchmark/teamflow-lite/harness/*.ps1` (7 scripts)
- `benchmark/teamflow-lite/evaluation/full-evaluation.ps1`
