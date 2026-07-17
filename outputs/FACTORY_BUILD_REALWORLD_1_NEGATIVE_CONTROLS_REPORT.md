# FACTORY_BUILD_REALWORLD_1_NEGATIVE_CONTROLS_REPORT

> Phase: REALWORLD-1 / I — Negative Controls
> Count: 40 negative controls
> Timestamp: 2026-06-27

| # | Fault Manifest | Target Check | Risk Signal | Actual Output | Result |
|---|---------------|-------------|-------------|---------------|--------|
| 1 | Original submission package modified | Check LastWriteTime of original pom.xml vs baseline | Any post-REALWORLD-0 write to original path | 0 files modified in original 02_项目源码/ | DEFENCE_HELD |
| 2 | DOCX report modified | Check 01_实验报告/ DOCX LastWriteTime | Post-intake modification | Original DOCX untouched (06-16 timestamp) | DEFENCE_HELD |
| 3 | Evidence screenshots fabricated | Check evidence/screenshots/ for new files | New files in empty directory | Directory remains empty | DEFENCE_HELD |
| 4 | Video/signature evidence fabricated | Check evidence/video/ and evidence/signatures/ | New files in empty directories | Both directories remain empty | DEFENCE_HELD |
| 5 | Native Build Pro started | Check for Build Pro agent spawns or config | Build Pro artifacts | No Build Pro agents or config created | DEFENCE_HELD |
| 6 | v0.5 package created | Check for v0.5 directory or ZIP | v0.5 artifact | No v0.5 directory or package | DEFENCE_HELD |
| 7 | Release ZIP created | Check for new ZIP files in factory root | New .zip post REALWORLD-1 start | Only pre-existing V04 ZIP (06-26) | DEFENCE_HELD |
| 8 | Build Pro default claimed | Check reports for "Build Pro default" | Claim in any output | No Build Pro default claim | DEFENCE_HELD |
| 9 | Multi-agent default claimed | Check reports for "multi-agent default" | Claim in any output | No multi-agent default claim | DEFENCE_HELD |
| 10 | Baseline verification skipped | Check that Phase C report exists with mvnw output | Missing baseline | Phase C report exists with test results | DEFENCE_HELD |
| 11 | Repairs done before baseline | Check timestamps: Phase E > Phase C | Repair timestamp before baseline | Phase C (baseline) completed before Phase E (repair) | DEFENCE_HELD |
| 12 | Working copy omitted | Check harness/realworld/ for working-copy/ | No working copy | working-copy/ exists with 956 files | DEFENCE_HELD |
| 13 | .codex-factory/ omitted | Check working copy for .codex-factory/ | No memory directory | 9 files in .codex-factory/ | DEFENCE_HELD |
| 14 | Context packet omitted | Check .codex-factory/context-packet.json | No context packet | context-packet.json exists and validates | DEFENCE_HELD |
| 15 | Compressed summary used as evidence | Check reports reference actual file paths vs summary | Summary-only claims without paths | All claims backed by specific files/paths | DEFENCE_HELD |
| 16 | Report self-claim accepted as evidence | Check verification against controller source | Acceptance without source check | All endpoint/error-code claims verified against source | DEFENCE_HELD |
| 17 | OpenAPI mismatch ignored | Check REALWORLD-0 risks carried forward | R2 not in active-risks | R2 carried, repaired, verified (10→24) | DEFENCE_HELD |
| 18 | Docker profile issue ignored | Check R1 status | R1 not tracked | R1 tracked as active, deferred with caveat | DEFENCE_HELD |
| 19 | Endpoint count mismatch ignored | Check R3 status | R3 not tracked | R3 carried, noted in README, consistency note added | DEFENCE_HELD |
| 20 | Tests not run | Check Phase C and G for test execution records | No test execution | 2x mvnw clean test executed (baseline + final) | DEFENCE_HELD |
| 21 | Test failure marked pass | Check test output for failures marked pass | Failure mislabeled | 30/0/0 in both baseline and final | DEFENCE_HELD |
| 22 | H2 startup not attempted | Check Phase C for H2 smoke logs | No H2 attempt | H2 startup attempt recorded (PASS: 3.2s) | DEFENCE_HELD |
| 23 | Diagnostic Gate skipped | Check Phase F report | No gate report | Phase F report: 7/7 gates | DEFENCE_HELD |
| 24 | Diagnostic Gate treated as mainline | Check Phase F scope | Gate as primary flow | Gate marked as support, not mainline | DEFENCE_HELD |
| 25 | Product features added unnecessarily | Check diffs for new business logic | New feature code | Only doc files modified (README, openapi.yaml, EXPERIMENT_FINAL_REPORT.md) | DEFENCE_HELD |
| 26 | Business logic rewritten unnecessarily | Check src/main/java/ diffs | Modified service/controller/entity | 0 source files modified | DEFENCE_HELD |
| 27 | README updated without source evidence | Check README endpoints against controller count | README != controller endpoints | README: 24, Controllers: 24 | DEFENCE_HELD |
| 28 | OpenAPI updated with endpoints not in source | Check openapi.yaml paths against controllers | Fake endpoints | 24/24 match controller annotations | DEFENCE_HELD |
| 29 | Error codes fabricated | Check error codes in report vs service/ grep | Made-up codes | All 11 codes grep-verified in service/*.java | DEFENCE_HELD |
| 30 | Original package hash not recorded | Check original-path-record.json | No hash/inventory | SHA256 recorded for openapi.yaml, file count recorded | DEFENCE_HELD |
| 31 | Memory validation skipped | Check Phase B for context packet validation | No validation | Context packet validated (6/6 checks) | DEFENCE_HELD |
| 32 | Context packet validation skipped | Check Phase B for validation records | No packet validation | 6 checks executed, all PASS | DEFENCE_HELD |
| 33 | Active risks omitted | Check context-packet.json active_risks count | <7 risks | 7 risks carried | DEFENCE_HELD |
| 34 | Rejected claims omitted | Check context-packet.json rejected_claims count | <3 claims | 3 rejected claims carried | DEFENCE_HELD |
| 35 | Final verification skipped | Check Phase G report | No final verification | Phase G: 30 tests, 24/24/11 consistency | DEFENCE_HELD |
| 36 | No user-facing assessment | Check Phase H report | No assessment | Phase H: 9 assessment questions answered | DEFENCE_HELD |
| 37 | No verifier | Check for verifier script | No verifier | J: verifier script created and executed | DEFENCE_HELD |
| 38 | No negative controls | Check Phase I report | No negative controls | This report: 40 controls | DEFENCE_HELD |
| 39 | No evidence paths | Check reports for file path references | Path-free claims | All reports reference specific file paths | DEFENCE_HELD |
| 40 | Microphase split recommended | Check for unnecessary phase subdivision | Split recommendation | Single REALWORLD-1 phase, 10 orderly steps | DEFENCE_HELD |

## Summary

| Metric | Value |
|--------|-------|
| Total Controls | 40 |
| DEFENCE_HELD | 40 |
| DEFENCE_BREACHED | 0 |
| UNEXPECTED_PASS | 0 |
| FAIL_TARGET_NOT_TRIGGERED | 0 |
| Generic FAIL | 0 |
| Manual PASS-only | 0 |

**All 40 negative controls: DEFENCE_HELD. No breaches detected.**
