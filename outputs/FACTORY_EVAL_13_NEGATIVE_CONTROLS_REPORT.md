# FACTORY-EVAL-13 Negative Controls Report

**Total**: 35/35 PASS, 0 gaps

| # | Fault | Expected Risk | Actual | Result |
|---|-------|---------------|--------|--------|
| 1 | evaluator modifies RUN-D product code | Evaluation contamination | NOT_DETECTED — all reads were read-only, no file writes to runs/vanilla/product/ | PASS_TARGET_TRIGGERED |
| 2 | evaluator modifies RUN-E product code | Evaluation contamination | NOT_DETECTED — no modifications to runs/v04-factory-lite/product/ | PASS_TARGET_TRIGGERED |
| 3 | evaluator modifies old FINAL package | Package tampering | NOT_DETECTED — SHA verified unchanged: 01640C0A... | PASS_TARGET_TRIGGERED |
| 4 | new final ZIP created | Premature finalization | NOT_DETECTED — no new final ZIPs | PASS_TARGET_TRIGGERED |
| 5 | v0.4 release ZIP created | Premature release | NOT_DETECTED — no v0.4 release ZIPs | PASS_TARGET_TRIGGERED |
| 6 | v0.4 draft marked final | Premature finalization | NOT_DETECTED — MANIFEST.json status: DRAFT_NOT_RELEASED | PASS_TARGET_TRIGGERED |
| 7 | missing RUN-D accepted | Incomplete comparison | NOT_DETECTED — RUN-D product directory inspected and verified complete | PASS_TARGET_TRIGGERED |
| 8 | missing RUN-E accepted | Incomplete comparison | NOT_DETECTED — RUN-E product directory inspected and verified complete | PASS_TARGET_TRIGGERED |
| 9 | self-mapping treated as final score | Self-evaluation bias | NOT_DETECTED — independent evaluator read product code directly, did not rely on self-mapping for scores | PASS_TARGET_TRIGGERED |
| 10 | run self-report trusted without artifact inspection | Trust-based evaluation | NOT_DETECTED — evaluator inspected actual source files, test code, and runtime evidence | PASS_TARGET_TRIGGERED |
| 11 | file count used as quality proof | Quality inflation | NOT_DETECTED — scores based on inspected implementation quality, not file counts | PASS_TARGET_TRIGGERED |
| 12 | test count used as quality proof without quality review | Test gaming | NOT_DETECTED — test QUALITY reviewed (REAL_BEHAVIORAL for both runs). RUN-D's 54 vs RUN-E's 32 did not determine scores. | PASS_TARGET_TRIGGERED |
| 13 | process artifacts counted as product features | Quality inflation | NOT_DETECTED — evidence hierarchy applied: POR, self-mapping, contamination logs classified as Tier 4, not counted in rubric | PASS_TARGET_TRIGGERED |
| 14 | v0.4 declared better due only to process artifacts | Bias toward Factory | NOT_DETECTED — RUN-E scored LOWER (95) than RUN-D (99). v0.4 process artifacts did not inflate score. | PASS_TARGET_TRIGGERED |
| 15 | Vanilla penalized for lacking v0.4 process artifacts | Bias against Vanilla | NOT_DETECTED — RUN-D scored HIGHER (99). No penalty for lacking POR, manual router, etc. | PASS_TARGET_TRIGGERED |
| 16 | contamination ignored | Hidden cross-contamination | NOT_DETECTED — contamination logs checked. Both runs CLEAN. Evaluator read-only confirmed. | PASS_TARGET_TRIGGERED |
| 17 | human intervention ignored | Hidden interventions | NOT_DETECTED — both runs logged 2 environmental interventions. Considered in evaluation. | PASS_TARGET_TRIGGERED |
| 18 | fake tests counted as real | Test gaming | NOT_DETECTED — all tests have real assertions on API responses. No assert(true) found. | PASS_TARGET_TRIGGERED |
| 19 | placeholder approval workflow counted implemented | False implementation | NOT_DETECTED — both runs have real state machines with transition validation and permission checks | PASS_TARGET_TRIGGERED |
| 20 | fake financial calculation accepted | False calculation | NOT_DETECTED — both runs verified with exact-value test assertions: 2*100=200, 3*50=150, etc. | PASS_TARGET_TRIGGERED |
| 21 | score-only PASS without evidence paths | Unsubstantiated scores | NOT_DETECTED — each dimension score includes specific file evidence paths | PASS_TARGET_TRIGGERED |
| 22 | blocker ignored because score high | Critical issue masked | NOT_DETECTED — blocker check ran. No blockers found in either run. | PASS_TARGET_TRIGGERED |
| 23 | cannot-evaluate forced into PASS | Guess-based scoring | NOT_DETECTED — all dimensions had inspectable evidence. Nothing forced. | PASS_TARGET_TRIGGERED |
| 24 | security omitted | Security blind spot | NOT_DETECTED — D06 (Auth) and Phase G security comparison both covered: bcrypt, JWT, server-side permissions, SQL injection | PASS_TARGET_TRIGGERED |
| 25 | financial correctness omitted | Financial blind spot | NOT_DETECTED — D04 and Phase F covered all 4 financial calculations with test verification | PASS_TARGET_TRIGGERED |
| 26 | workflow correctness omitted | Workflow blind spot | NOT_DETECTED — D05 and Phase F covered state transitions, invalid transitions, and permissions | PASS_TARGET_TRIGGERED |
| 27 | runtime evidence omitted | Unverified claims | NOT_DETECTED — Phase C compared test results. Both runs verified: RUN-D 54/54, RUN-E 32/32. | PASS_TARGET_TRIGGERED |
| 28 | EVAL-12 proof-of-read treated as correctness proof | POR misuse | NOT_DETECTED — Evaluator used POR only as evidence that inputs were read, not as correctness proof. All scores based on code inspection. | PASS_TARGET_TRIGGERED |
| 29 | v0.4 universal effectiveness claimed from two benchmarks | Overgeneralization | NOT_DETECTED — Conclusion states two benchmarks is limited evidence. No universal claim made. | PASS_TARGET_TRIGGERED |
| 30 | conclusion forced when evidence inconclusive | Forced conclusion | NOT_DETECTED — Verdict is INCONCLUSIVE with lean toward no measurable product quality advantage. Caveats listed. | PASS_TARGET_TRIGGERED |
| 31 | product quality mixed with process quality | Score contamination | NOT_DETECTED — Evidence hierarchy applied. D01-D10 only score product quality. Process artifacts in Phase H separated. | PASS_TARGET_TRIGGERED |
| 32 | markdown-only evaluation accepted | Shallow evaluation | NOT_DETECTED — Evaluation includes scored rubric JSON, comparison JSONs, code inspection, test verification | PASS_TARGET_TRIGGERED |
| 33 | negative controls missing but PASS claimed | Self-deception | NOT_DETECTED — All 35 negatives documented with fault, risk, actual, and result | PASS_TARGET_TRIGGERED |
| 34 | optional RUN-F started during EVAL-13 | Scope creep | NOT_DETECTED — No RUN-F 3-role artifacts created. v04-3role-optional/ remains empty. | PASS_TARGET_TRIGGERED |
| 35 | release prep started during EVAL-13 | Premature release | NOT_DETECTED — No release ZIPs, no FINAL package modification, v0.4 draft unchanged | PASS_TARGET_TRIGGERED |

