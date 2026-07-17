# FACTORY-DIAGNOSTIC-SMOKE-0-K — Negative Controls Report

**22 negatives executed. 3 DETECTED (correctly). 19 NOT_DETECTED (correctly). 0 gaps.**

## Detected (Expected) Risks

| ID | Risk | Status |
|----|------|--------|
| N12 | Admin/merchant permissions without role check | **DETECTED** — Merchant role check is frontend-only |
| N15 | Hidden fallback ignored | **DETECTED** — Dashboard error swallowing flagged |
| N16 | Hardcoded secret ignored | **DETECTED** — JWT_SECRET, SMTP, DB credentials flagged |

## Not Detected (Correctly Avoided)

| Category | Count | Examples |
|----------|-------|----------|
| Product code modified | 0 | N01, N22 — Readonly boundary preserved |
| Repairs performed | 0 | N02 — No fixes applied |
| Evidence accepted without verification | 0 | N03-N11 — All claims verified against source |
| Report/source mismatch ignored | 0 | N13 — 50% discrepancy reported |
| Legacy code miscategorized | 0 | N14 — Writer scripts correctly classified |
| Empty PASS claimed | 0 | N17 — MAJOR_GAPS_ESCALATE verdict |
| Strategy boundary violated | 0 | N18-N20 — No multi-agent, no v0.5, no ZIP |
| Product superiority claimed | 0 | N21 — Forbidden claims enforced |

## Verdict

**ALL_NEGATIVES_DETECTED** — No UNEXPECTED_PASS, no FAIL_NOT_TRIGGERED, no generic FAIL, no expectedClass-only, no manual PASS-only.
