# FACTORY-EVAL-13: LedgerFlow Independent Comparison — RUN-D vs RUN-E

**Phase**: FACTORY-EVAL-13  
**Evaluator**: READONLY  
**Date**: 2026-06-25T22:13:25+08:00  
**Status**: COMPLETE

## Executive Summary

Independent comparison of LedgerFlow Lite implemented by:
- **RUN-D (Vanilla Codex)** — no Factory mechanisms
- **RUN-E (v0.4 Factory Lite Core)** — Manual Router, Proof-of-Read, Required-Reading Gate, Evidence Hierarchy, Contamination Logging, Anti-Gaming, Context Budget

## Score Summary

| Dimension | Max | RUN-D | RUN-E | Δ |
|-----------|-----|-------|-------|---|
| D01 - Requirement Coverage | 24 | 24 | 24 | 0 |
| D02 - API Contract | 16 | 15 | 16 | +1 RUN-E |
| D03 - DB Schema | 10 | 10 | 9 | +1 RUN-D |
| D04 - Financial Calc | 12 | 12 | 12 | 0 |
| D05 - Workflow | 10 | 10 | 9 | +1 RUN-D |
| D06 - Auth | 10 | 10 | 10 | 0 |
| D07 - Audit Trail | 5 | 5 | 5 | 0 |
| D08 - Dashboard/Export | 5 | 5 | 5 | 0 |
| D09 - UI/UX | 5 | 5 | 2 | +3 RUN-D |
| D10 - Tests/Docs | 3 | 3 | 3 | 0 |
| **TOTAL** | **100** | **99** | **95** | **+4 RUN-D** |

## Key Findings

1. **UI is the decisive gap**: RUN-D has a full SPA with loading/empty/error states. RUN-E has a minimal API landing page. This accounts for 100% of the score difference.
2. **Without UI, scores are 94 vs 93**: Statistically identical product quality for core backend functionality.
3. **v0.4 mechanisms are process tools, not product tools**: POR, evidence hierarchy, anti-gaming, contamination logging serve evaluation integrity and process audit — they do not directly improve product quality.
4. **Anti-overengineering may suppress UI**: The Always-On Constitution's anti-overengineering rules may have discouraged UI investment in RUN-E. This is a Constitutional trade-off, not a bug.
5. **Pagination gap**: RUN-D lacks pagination on list endpoints. RUN-E has it. This wasn't driven by any v0.4 mechanism.

## v0.4 Mechanism Effectiveness

| Mechanism | Product Impact | Process Impact |
|-----------|---------------|----------------|
| Always-On Constitution | Mixed (may suppress UI) | Rules followed |
| Manual Router | No advantage | Classification done |
| Proof-of-Read | None | Audit trail |
| Required-Reading Gate | None | Spec verified read |
| Evidence Hierarchy | None | Clean score separation |
| Contamination Logging | None | Benchmark integrity |
| Anti-Gaming | None | Score inflation prevented |
| Context Budget | None | Passive tracking |

## Verdict

**INCONCLUSIVE** — v0.4 Factory Lite Core does not add measurable product quality for this project type. Across two benchmarks (EVAL-8 and EVAL-13), v0.4 Core has not demonstrated consistent product quality improvement over Vanilla Codex.

v0.4's value proposition is better framed as a **process integrity layer** (audit trail, evaluation hygiene, contamination control) rather than a **product quality improvement layer**.

## Recommendation: USER REVIEW

Recommended options:
1. **FACTORY-EVAL-14**: Test 3-role optional model — may address UI quality gap
2. **FACTORY-V04-P1**: Reframe v0.4 as process integrity layer, adjust Constitution UI guidance
3. **FACTORY-EVAL-10-P1**: Third benchmark for more robust evidence

## Verification

- Verifier: **28/28 PASS**
- Negative controls: **35/35 PASS, 0 gaps**
- No product code modified
- No release ZIPs created
- v0.4 draft remains DRAFT_NOT_RELEASED
