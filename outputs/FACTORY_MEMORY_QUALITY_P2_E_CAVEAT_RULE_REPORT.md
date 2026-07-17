# FACTORY-MEMORY-QUALITY-P2 — E: Caveat Rule

**Timestamp:** 2026-06-28T17:50:00+08:00

---

## When Caveat is Required

- DESIGN_ONLY — design analysis, not executed evidence
- LOCAL_ONLY — local trial, not production validation
- PARTIAL — claim is incomplete; state what is missing
- CONDITIONAL — "if user approves"; state the condition
- SINGLE_DATAPOINT — warn about limited generalizability

## Blocking Rules

| Violation | Action |
|-----------|--------|
| No caveat for DESIGN_ONLY | BLOCK |
| No caveat for LOCAL_ONLY | BLOCK |
| No caveat for PARTIAL | BLOCK |
| Overclaim detected | BLOCK + downgrade |

---

**Status:** CAVEAT_RULE_DEFINED
