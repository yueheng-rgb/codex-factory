# FACTORY-MEMORY-QUALITY-P2 — G: Memory Quality Validator

**Timestamp:** 2026-06-28T17:50:00+08:00

---

## 15 Checks

| ID | Check | Severity |
|----|-------|----------|
| VAL-001 | evidence_path exists | BLOCKING |
| VAL-002 | summary ≤ 500 chars | BLOCKING |
| VAL-003 | caveat for PARTIAL/DESIGN/LOCAL | BLOCKING |
| VAL-004 | caveat ≤ 200 chars | WARN |
| VAL-005 | No DESIGN_ONLY without tag | BLOCKING |
| VAL-006 | No LOCAL_ONLY without tag | BLOCKING |
| VAL-007 | Score ≤ max | BLOCKING |
| VAL-008 | No secret patterns | BLOCKING |
| VAL-009 | No production endpoints | BLOCKING |
| VAL-010 | Valid status enum | BLOCKING |
| VAL-011 | Valid category enum | BLOCKING |
| VAL-012 | RETIRED has reason | BLOCKING |
| VAL-013 | No overclaim language | WARN |
| VAL-014 | Socratic flag if triggered | WARN |
| VAL-015 | Valid ISO8601 timestamp | WARN |

## Verdict

| Result | Condition |
|--------|-----------|
| PASS | 0 BLOCKING |
| PASS_WITH_WARNINGS | 0 BLOCKING, ≥1 WARN |
| BLOCKED | ≥1 BLOCKING |

---

**Status:** VALIDATOR_DEFINED
