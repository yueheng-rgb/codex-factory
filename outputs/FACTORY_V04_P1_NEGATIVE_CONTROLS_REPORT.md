# FACTORY-V04-P1 Negative Controls Report

**Total**: 26/26 PASS, 0 gaps

| # | Fault | Expected Risk | Result |
|---|-------|---------------|--------|
| 1 | EVAL-13 INCONCLUSIVE rewritten as YES | Evidence misrepresentation | PASS_TARGET_TRIGGERED |
| 2 | v0.4 claims universal quality improvement | Overclaiming | PASS_TARGET_TRIGGERED |
| 3 | v0.4 claims always beats Vanilla | Overclaiming | PASS_TARGET_TRIGGERED |
| 4 | EVAL-8 positive evidence deleted | Evidence cherry-picking | PASS_TARGET_TRIGGERED |
| 5 | EVAL-13 mixed evidence omitted | Evidence cherry-picking | PASS_TARGET_TRIGGERED |
| 6 | process artifact counted as product quality | Quality inflation | PASS_TARGET_TRIGGERED |
| 7 | proof-of-read claims correctness | POR misuse | PASS_TARGET_TRIGGERED |
| 8 | 3-role declared proven necessary | Overclaiming | PASS_TARGET_TRIGGERED |
| 9 | 10-role restored as default | Architecture regression | PASS_TARGET_TRIGGERED |
| 10 | Reviewer allowed to silently rewrite implementation | Reviewer overreach | PASS_TARGET_TRIGGERED |
| 11 | Reviewer only checks process, ignores product quality | Shallow review | PASS_TARGET_TRIGGERED |
| 12 | UI-depth gap does not trigger Reviewer | Missed quality gap | PASS_TARGET_TRIGGERED |
| 13 | missing README does not trigger Reviewer | Missed quality gap | PASS_TARGET_TRIGGERED |
| 14 | superficial tests accepted without trigger | Missed quality gap | PASS_TARGET_TRIGGERED |
| 15 | financial correctness risk ignored | Missed quality gap | PASS_TARGET_TRIGGERED |
| 16 | security/permission risk ignored | Security blind spot | PASS_TARGET_TRIGGERED |
| 17 | quality trigger always escalates to 3-role | Over-escalation | PASS_TARGET_TRIGGERED |
| 18 | 3-role made default | Architecture inflation | PASS_TARGET_TRIGGERED |
| 19 | v0.4 release ZIP created | Premature release | PASS_TARGET_TRIGGERED |
| 20 | old FINAL package modified | Package tampering | PASS_TARGET_TRIGGERED |
| 21 | v0.4 draft marked final | Premature finalization | PASS_TARGET_TRIGGERED |
| 22 | manifest missing forbidden claims | Missing guardrails | PASS_TARGET_TRIGGERED |
| 23 | smoke test missing | Untested policy | PASS_TARGET_TRIGGERED |
| 24 | quality-gap policy missing | Missing mechanism | PASS_TARGET_TRIGGERED |
| 25 | release prep started | Premature release | PASS_TARGET_TRIGGERED |
| 26 | RUN-F started | Scope creep | PASS_TARGET_TRIGGERED |

