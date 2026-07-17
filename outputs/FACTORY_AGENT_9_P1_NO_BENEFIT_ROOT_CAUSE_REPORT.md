# FACTORY-AGENT-9-P1 / Multi-Agent No-Benefit Root Cause Report

**Date:** 2026-06-26T18:40:47.1129379+08:00  
**Verdict:** PASS  
**Parent Phase:** FACTORY-AGENT-9 (MULTI_AGENT_NO_BENEFIT)

---

## 1. EVIDENCE LOCKED

14 facts locked with classification (SUPPORTED/UNSUPPORTED/INCONCLUSIVE/REJECTED).  
See: governance/factory-agent/factory-agent-9-p1-evidence-lock.json

## 2. ROOT CAUSE ANALYSIS — 8 Hypotheses

| # | Hypothesis | Probability | Impact | Repair |
|---|-----------|-------------|--------|--------|
| H1 | Benchmark too small for multi-agent benefit | HIGH | HIGH | MODERATE |
| H2 | Agent orchestration overhead consumed value | HIGH | HIGH | EASY |
| H3 | Orchestrator didn't enforce complexity floors | MEDIUM | HIGH | EASY |
| H4 | Reviewer gate too permissive on caveats | MEDIUM | MEDIUM | EASY |
| H5 | Worker scope split created integration gaps | LOW | MEDIUM | MODERATE |
| H6 | Process artifacts without product benefit | MEDIUM | MEDIUM | EASY |
| H7 | Vanilla Codex unexpectedly strong | HIGH | HIGH | UNKNOWN |
| H8 | 7-agent form wrong for this project scale | HIGH | HIGH | EASY |

**Primary causes:** H1 (benchmark size), H7 (Vanilla strength), H8 (agent form)  
**Secondary:** H2 (overhead), H3 (orchestrator permissiveness)  
**Unlikely:** H5 (worker split)

See: governance/factory-agent/factory-agent-9-p1-root-cause-analysis.json

## 3. CLAIMS FROZEN

12 claims classified. Key rejections:
- "Multi-agent is default" → REJECTED
- "v0.5 superior to Vanilla" → REJECTED
- "207 tests = better quality" → REJECTED
- "Worker isolation proven possible" → SUPPORTED

6 forbidden claim classes defined.

See: governance/factory-agent/factory-agent-9-p1-claim-freeze.json

## 4. DECISION OPTIONS (5 paths)

| Option | Name | Recommended |
|--------|------|-------------|
| A | Repair AGENT-8 | NO |
| B | Second larger benchmark | NO |
| C | Simplify to 3-agent model | NO |
| D | Demote to diagnostic layer | NO |
| E | Stop line + user review | NO |

**Chosen:** HYBRID-P1 = Simplify + Harden before next benchmark

See: governance/factory-agent/factory-agent-9-p1-decision-options.json

## 5. NEXT-STEP RECOMMENDATION

**Phase:** FACTORY-AGENT-RUNTIME-P1

Plan:
1. Reduce agents from 7 to 4 (Orchestrator + 2 Builders + Reviewer/Verifier)
2. Make Reviewer caveats BLOCKING for phase closure
3. Add mid-run complexity floor enforcement to Orchestrator
4. Re-run on OpsFlow Lite to verify
5. Only if P1 wins: proceed to larger benchmark

Decision rules applied: repair before new benchmark, simplify before escalation.

See: governance/factory-agent/factory-agent-9-p1-next-step-recommendation.json

## 6. NEGATIVE CONTROLS

30 negatives designed, all covered. No UNEXPECTED_PASS, no FAIL_TARGET_NOT_TRIGGERED.

## 7. CONCLUSION

v0.5 Agent Company's NO_BENEFIT on OpsFlow Lite is:
- **Real** — Vanilla scored higher (85.5 vs 80.0)
- **Explained** — Root causes identified (benchmark size, agent form, overhead)
- **Actionable** — P1 simplification + hardening addresses all repairable causes
- **Not terminal** — Worker isolation, registry, anti-deception are real gains

Multi-agent implementation is not proven. Diagnostic/verification agents have demonstrated value. Next step is targeted runtime simplification before scaling up.