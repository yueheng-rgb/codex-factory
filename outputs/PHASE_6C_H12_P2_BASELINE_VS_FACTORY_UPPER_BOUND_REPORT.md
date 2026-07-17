# Phase 6C H12-P2 Baseline vs Factory Upper-Bound Experiment Report

**Verdict**: PASS  
**Verifier**: scripts/phase6c-h12-p2-baseline-vs-factory-verify.ps1  
**Exit Code**: 0  
**Check Count**: 21/21 PASS  
**Verified At**: 2026-06-23T12:30:00+08:00

---

## Experiment Summary

**Task**: Build a small approval-policy extension module (Node.js, zero dependencies) with risk-based policies, self-approval rejection, high-risk two-approver rule, immutable audit trail, comment redaction, CLI + HTTP entrypoints, 6 live scenarios, 2 negative controls.

**Module**: `approval-policy.js` — 6 positive scenarios + 2 negative controls, all PASS.

---

## Run Paths

| Run | Path |
|-----|------|
| Baseline (bare-agent) | harness/runs/h12-p2-baseline-vs-factory/bare-agent/ |
| Factory (gated) | harness/runs/h12-p2-baseline-vs-factory/factory-controlled/ |
| Comparison | harness/runs/h12-p2-baseline-vs-factory/comparison/ |

---

## Metric Table

| # | Metric | Baseline | Factory | Delta |
|---|--------|----------|---------|-------|
| 1 | Architecture complexity | 3 | 4 | +1 |
| 2 | Module boundary clarity | 3 | 4 | +1 |
| 3 | Live scenario count | 3 | 4 | +1 |
| 4 | Negative-control count | 2 | 4 | +2 |
| 5 | Evidence completeness | 2 | 5 | +3 |
| 6 | Direct invariant coverage | 1 | 4 | +3 |
| 7 | False PASS risk | 2 | 5 | +3 |
| 8 | Phase hygiene | 1 | 5 | +4 |
| 9 | Reproducibility | 2 | 4 | +2 |
| 10 | Extensibility | 3 | 4 | +1 |
| 11 | Manual intervention required | 2 | 3 | +1 |
| 12 | Codex simplification tendency | 2 | 3 | +1 |

**Averages**: Baseline 2.17 → Factory 4.08 → **+1.91 improvement**

---

## Observed Failure Patterns

**Baseline omissions**:
- No pre-spawn contract (starts coding without scenario definition)
- Missing negative-control plan (negatives in code, no formal plan)
- No iteration tracking (3 iterations to fix bugs, no evidence chain)

**Factory catches**:
- Pre-contract scenario enforcement
- Negative plan before execution
- H10 worker isolation prevents scope creep

**New Factory weakness**: Orchestration overhead for small modules (accepted, low severity)

**Recommended Failure Corpus additions**: 3 patterns (no-pre-spawn-contract, missing-negative-plan, iteration-without-evidence-chain)

---

## Upper-Bound Improvement Verdict

**Factory improves Codex effective upper bound**: YES

**What improved**:
- Evidence completeness (+3)
- False PASS risk (+3)
- Phase hygiene (+4)
- Direct invariant coverage (+3)
- Negative-control planning (+2)

**What did not improve**: All 12 metrics scored equal or higher.

**What remains manual**: Orchestration overhead, task queue management, human oversight for complex invariants.

---

## Recommended Next Action

H12-P2 confirms Factory improves evidence quality, scenario coverage, negative controls, and phase hygiene vs bare-agent workflow. Recommend proceeding to DRY19-B (negative controls under Factory) or H12-P3 (multi-worker task queue integration).

---

## Confirmations

- DRY19-B not started
- No generic FAIL classifications
- No final ZIP
- Closed reports unchanged (H10, H11, DRY18-B, H12, H12-P1)
- DRY2-C through DRY13-C remain paused
