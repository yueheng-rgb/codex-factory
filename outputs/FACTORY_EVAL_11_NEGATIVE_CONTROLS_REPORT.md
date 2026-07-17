# FACTORY-EVAL-11-H: Negative Controls Report — LedgerFlow Lite Vanilla

**Run:** FACTORY-EVAL-11-RUN-D-VANILLA  
**Date:** 2026-06-25T21:00+08:00  

## Negative Controls (32 total)

| # | Fault Manifest | Target Check | Expected Risk | Actual Validation | Result | Verifier |
|---|---------------|--------------|---------------|-------------------|--------|----------|
| 1 | Vanilla uses v0.4 draft | Check files accessed | Contamination | No v0.4 draft files read | PASS | ✅ |
| 2 | Vanilla uses Manual Router | Check tool calls | Wrong methodology | No Manual Router used | PASS | ✅ |
| 3 | Vanilla uses Proof-of-Read | Check process | Skipped validation | No Proof-of-Read executed | PASS | ✅ |
| 4 | Vanilla uses Factory Lite policies | Check prompts | Hidden guidance | No Factory Lite policies referenced | PASS | ✅ |
| 5 | Vanilla uses 3-role model | Check sub-agents | Delegated work | No sub-agents spawned | PASS | ✅ |
| 6 | Vanilla uses Context OS/MCP | Check tools | Enhanced assistance | No Context OS/MCP invoked | PASS | ✅ |
| 7 | TeamFlow Lite code copied | Check file origins | Code reuse | No TeamFlow files read | PASS | ✅ |
| 8 | RUN-E/RUN-F code copied | Check directories | Cross-contamination | Directories confirmed empty | PASS | ✅ |
| 9 | Factory governance copied into product | Check product files | Governance in product | No governance files in product | PASS | ✅ |
| 10 | Factory process artifact counted as feature | Check requirements mapping | Inflated score | Only application features counted | PASS | ✅ |
| 11 | Different requirements from EVAL-10 used | Check spec compliance | Scope shift | All 16 FRs from EVAL-10 spec | PASS | ✅ |
| 12 | Placeholder approval workflow counted | Check implementation | Fake implementation | Full workflow with 5 statuses, tests | PASS | ✅ |
| 13 | Fake financial calculation accepted | Check math correctness | Wrong numbers | Server-side calculations, 26 tests | PASS | ✅ |
| 14 | Fake test counted as pass | Check test output | Fake evidence | Real test runner, real assertions | PASS | ✅ |
| 15 | CSV/export stub without deterministic output | Check CSV determinism | Non-reproducible | CSV verified deterministic (byte-identical) | PASS | ✅ |
| 16 | Dashboard/report stub without evidence | Check dashboard API | Fake dashboard | Real SQL aggregation, verified | PASS | ✅ |
| 17 | Markdown-only completion accepted | Check runnable code | No real product | Real server, real frontend, real DB | PASS | ✅ |
| 18 | Runtime not run but marked verified | Check runtime evidence | Fake verification | Server started, API tested, verify.ps1 run | PASS | ✅ |
| 19 | Missing requirement marked implemented | Check FR mapping | Incomplete | All 16 FRs have file evidence + tests | PASS | ✅ |
| 20 | Human intervention omitted | Check intervention log | Undisclosed help | 2 interventions logged honestly | PASS | ✅ |
| 21 | Contamination log omitted | Check contamination log | Hidden contamination | Contamination log created | PASS | ✅ |
| 22 | Hardcoded local absolute path accepted | Check code for paths | Non-portable | No absolute paths in code | PASS | ✅ |
| 23 | No README/run instructions accepted | Check README exists | Undocumented | README.md with full instructions | PASS | ✅ |
| 24 | No tests accepted without caveat | Check tests exist | Untested | 54 real tests passing | PASS | ✅ |
| 25 | Old FINAL package modified | Check SHA | Tampering | SHA verified unchanged | PASS | ✅ |
| 26 | New final ZIP created | Check outputs | Premature finalization | No new ZIP created | PASS | ✅ |
| 27 | v0.4 release ZIP created | Check outputs | Premature release | No v0.4 ZIP created | PASS | ✅ |
| 28 | Factory effectiveness claimed from RUN-D | Check report content | Invalid conclusion | No effectiveness claims made | PASS | ✅ |
| 29 | File count/exports used as quality proof | Check report content | Metrics abuse | Quality claimed from tests, not counts | PASS | ✅ |
| 30 | Artifact inventory missing | Check inventory exists | Incomplete | ARTIFACT_INVENTORY.md created | PASS | ✅ |
| 31 | Self-mapping treated as independent eval | Check report content | Invalid methodology | Self-mapping labeled as self-assessment | PASS | ✅ |
| 32 | Prior Vanilla artifacts overwritten silently | Check initial state | Data loss | Vanilla dir was empty at start | PASS | ✅ |

## Summary

| Category | Count | Result |
|----------|-------|--------|
| PASS (negative correctly avoided) | 32 | ✅ |
| FAIL (negative violated) | 0 | ✅ |
| UNEXPECTED_PASS | 0 | ✅ |
| FAIL_TARGET_NOT_TRIGGERED | 0 | ✅ |
| Generic FAIL | 0 | ✅ |
| expectedClass-only | 0 | ✅ |
| Manual PASS-only | 0 | ✅ |
| Preclassified-only | 0 | ✅ |

**Verdict: 32/32 negatives correctly avoided. 0 gaps.**
