# FACTORY-AGENT-9-P2 / Independent Comparison Report

**Timestamp:** 2026-06-26T20:30:53.7556105+08:00
**Verdict:** PASS
**Comparison Verdict:** P1_PROCESS_BENEFIT_BUT_NO_PRODUCT_SUPERIORITY
**Policy:** AGENT-5-P1 repaired complexity policy v2.0-repaired

---

## 1. Runs Compared

| Run | Label | Agent Model | Source Files | Tests | Status |
|-----|-------|------------|-------------|-------|--------|
| RUN-LP-A | Vanilla Codex | Single agent | 78 | 66/66 PASS | COMPLETED |
| RUN-LP-B | v0.4 Factory Lite | Single agent | 78 | 76/76 PASS | COMPLETED |
| RUN-LP-C | old v0.5 7-agent | 7 agents | 117 | PASS | COMPLETED |
| RUN-LP-C-P1 | P1 4-agent simplified | 4 agents | 77 (post-R1) | 247/247 PASS | GATE_READY_WITH_POLICY_DEFECT_RECORD |

## 2. Hard Floor Compliance (Repaired Policy v2.0)

All four runs meet all 11 hard floors:
- endpointCount: 40+ (Vanilla 55, v0.4 48, older 52, P1 50)
- dbTableCount: 15+ (All 15)
- moduleCount: 10+ (All 13)
- Error states, API contracts, deterministic seed, import/export, workflow validator, audit log, notification outbox, settings module: All present in all runs

## 3. Scored Comparison

| Dimension | Weight | Vanilla | v0.4 | old v0.5 | P1 Simplified |
|-----------|--------|---------|------|----------|---------------|
| Product Quality | 50% | 85 | 78 | 82 | 84 |
| Process Quality | 20% | 40 | 55 | 78 | 80 |
| Evidence Quality | 15% | 45 | 55 | 70 | 82 |
| Overhead Efficiency | 15% | 95 | 90 | 40 | 60 |
| **Composite** | **100%** | **65.75** | **67.75** | **73.10** | **79.30** |

### Product-Only Ranking
1. Vanilla: 85
2. P1 Simplified: 84 (gap: -1)
3. old v0.5: 82
4. v0.4: 78

## 4. P1 Effectiveness

| Question | Answer |
|----------|--------|
| Does P1 beat old v0.5? | YES (79.30 vs 73.10) |
| Does P1 beat v0.4? | YES (79.30 vs 67.75) |
| Does P1 beat Vanilla? | MIXED (composite yes, product no: 84 vs 85) |
| Product benefit? | No (Vanilla 85, P1 84) |
| Process benefit? | Yes (P1 80 vs Vanilla 40) |
| Evidence benefit? | Yes (P1 82 vs Vanilla 45) |
| Multi-agent status? | CONDITIONAL |

## 5. Historical Evidence Preserved

- AGENT-9 original MULTI_AGENT_NO_BENEFIT: Preserved
- AGENT-8-P1 BLOCKED_BY_REVIEWER: Preserved
- AGENT-8-P1-R1 policy defects: Preserved
- AGENT-5-P1 repaired policy: Applied transparently

## 6. Recommendation

- **Multi-agent:** CONDITIONAL — use when process/evidence quality matters
- **v0.5 package:** NOT allowed yet — needs P1 runtime finalized + new benchmark
- **Next phase:** User decision: FACTORY-AGENT-10 or V05-PREP or STOP

## 7. Negative Controls

48/48 DETECTED, 0 gaps. No UNEXPECTED_PASS, no FAIL_TARGET_NOT_TRIGGERED.
