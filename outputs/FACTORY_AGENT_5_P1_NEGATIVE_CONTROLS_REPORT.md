# FACTORY-AGENT-5-P1-G / Negative Controls Report

**Timestamp:** 2026-06-26T20:23:00.9904896+08:00
**Phase:** FACTORY-AGENT-5-P1

## Summary

| Metric | Value |
|--------|-------|
| Total negatives | 32 |
| Detected | 32 |
| Gaps | 0 |
| UNEXPECTED_PASS | 0 |
| FAIL_TARGET_NOT_TRIGGERED | 0 |
| Generic FAIL | 0 |
| ExpectedClass-only | 0 |
| Manual PASS-only | 0 |
| Preclassified-only | 0 |

## Detail

| # | ID | Fault | Target Gate | Expected Class | Result |
|---|-----|-------|-------------|----------------|--------|
| 01 | NC-01 | Policy repair deletes AGENT-8-P1 BLOCKED_BY_REVIEWER | Evidence Preservation | EVIDENCE_DELETED | DETECTED |
| 02 | NC-02 | Policy repair deletes R1 policy defect evidence | Evidence Preservation | POLICY_DEFECT_DELETED | DETECTED |
| 03 | NC-03 | Policy repair modifies product code | Product Integrity | PRODUCT_MODIFIED | DETECTED |
| 04 | NC-04 | Policy repair changes only P1 scoring | Fairness | UNFAIR_SCORING | DETECTED |
| 05 | NC-05 | Source file floor remains hard blocker without rationale | Policy Quality | UNJUSTIFIED_HARD_FLOOR | DETECTED |
| 06 | NC-06 | Export floor remains hard blocker without rationale | Policy Quality | UNJUSTIFIED_HARD_FLOOR | DETECTED |
| 07 | NC-07 | Export floor removed silently without defect record | Transparency | SILENT_REMOVAL | DETECTED |
| 08 | NC-08 | Source floor removed silently without defect record | Transparency | SILENT_REMOVAL | DETECTED |
| 09 | NC-09 | Fake exports allowed | Anti-Gaming | FAKE_EXPORTS_ALLOWED | DETECTED |
| 10 | NC-10 | Re-export-only files counted meaningful | Anti-Gaming | REEXPORT_COUNTED | DETECTED |
| 11 | NC-11 | Empty files counted meaningful | Anti-Gaming | EMPTY_COUNTED | DETECTED |
| 12 | NC-12 | File/export count used as product quality proof | Quality Proxy | COUNT_AS_QUALITY | DETECTED |
| 13 | NC-13 | Requirements coverage demoted incorrectly | Hard Floor Integrity | WRONG_DEMOTION | DETECTED |
| 14 | NC-14 | Workflow validator demoted incorrectly | Hard Floor Integrity | WRONG_DEMOTION | DETECTED |
| 15 | NC-15 | Audit log demoted incorrectly | Hard Floor Integrity | WRONG_DEMOTION | DETECTED |
| 16 | NC-16 | Notification outbox demoted incorrectly | Hard Floor Integrity | WRONG_DEMOTION | DETECTED |
| 17 | NC-17 | API contract demoted incorrectly | Hard Floor Integrity | WRONG_DEMOTION | DETECTED |
| 18 | NC-18 | Tests demoted incorrectly | Hard Floor Integrity | WRONG_DEMOTION | DETECTED |
| 19 | NC-19 | No fair reapplication plan | Fairness | NO_REAPPLICATION_PLAN | DETECTED |
| 20 | NC-20 | AGENT-9 historical result overwritten | Historical Integrity | HISTORY_OVERWRITTEN | DETECTED |
| 21 | NC-21 | AGENT-9-P2 instructions missing | Handoff | MISSING_INSTRUCTIONS | DETECTED |
| 22 | NC-22 | Anti-gaming policy missing | Policy Completeness | MISSING_ANTI_GAMING | DETECTED |
| 23 | NC-23 | Benchmark requirements changed | Stability | REQUIREMENTS_CHANGED | DETECTED |
| 24 | NC-24 | Multi-agent effectiveness claimed | Effectiveness Claim | EFFECTIVENESS_CLAIMED | DETECTED |
| 25 | NC-25 | P1 declared default | Default Claim | DEFAULT_CLAIMED | DETECTED |
| 26 | NC-26 | v0.5 package created | Release Integrity | NEW_VERSION | DETECTED |
| 27 | NC-27 | New benchmark started | Scope | NEW_BENCHMARK | DETECTED |
| 28 | NC-28 | v0.4 release ZIP modified | Release Integrity | ZIP_MODIFIED | DETECTED |
| 29 | NC-29 | Old FINAL package modified | Release Integrity | FINAL_MODIFIED | DETECTED |
| 30 | NC-30 | No verifier | Verification | NO_VERIFIER | DETECTED |
| 31 | NC-31 | No negative controls | Verification | NO_NEGATIVES | DETECTED |
| 32 | NC-32 | No recommendation | Closure | NO_RECOMMENDATION | DETECTED |

## Verdict
**NEGATIVE_CONTROLS_ALL_DETECTED** — 32/32 negatives triggered intended risk signals. 0 gaps.
