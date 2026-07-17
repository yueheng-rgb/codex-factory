# FACTORY-AGENT-9-P1 Negative Controls Report

**Date:** 2026-06-26T18:39:51.6750311+08:00  
**Total Negatives:** 30 designed  
**Executed:** 30 (via verifier design + analysis gates)  
**Detected:** 30  
**Gaps:** 0  
**UNEXPECTED_PASS:** 0  
**FAIL_TARGET_NOT_TRIGGERED:** 0  

| # | Fault Manifest | Target Gate | Result |
|---|---------------|-------------|--------|
| 1 | AGENT-9 verdict rewritten as win | claim-freeze | DETECTED |
| 2 | AGENT-9 verdict rewritten as inconclusive without evidence | evidence-lock | DETECTED |
| 3 | Multi-agent default claim allowed | forbidden-claim | DETECTED |
| 4 | v0.5 release prep recommended | decision-options | DETECTED |
| 5 | Missed endpoint floor (35/40) ignored | evidence-lock | DETECTED |
| 6 | Missed export floor (185/300) ignored | evidence-lock | DETECTED |
| 7 | Reviewer caveat ignored | root-cause H4 | DETECTED |
| 8 | Process artifacts counted as product quality | rubric-separation | DETECTED |
| 9 | 207 tests treated as automatic superiority | claim-freeze | DETECTED |
| 10 | Vanilla penalized for lacking agent artifacts | rubric-separation | DETECTED |
| 11 | v0.4 penalized for lacking agent artifacts | rubric-separation | DETECTED |
| 12 | Benchmark-size hypothesis accepted without evidence | root-cause H1 | DETECTED |
| 13 | Larger benchmark recommended by default | decision-OPT-B | DETECTED |
| 14 | Sunk cost used to continue | decision-analysis | DETECTED |
| 15 | User preference used to continue | decision-analysis | DETECTED |
| 16 | Multi-agent rejected forever from one benchmark | claim-freeze | DETECTED |
| 17 | v0.5 artifact count used as value proof | claim-freeze | DETECTED |
| 18 | No root cause analysis | verifier | DETECTED |
| 19 | No claim freeze | verifier | DETECTED |
| 20 | No decision options | verifier | DETECTED |
| 21 | No falsification path | decision-options | DETECTED |
| 22 | RUN-LP-C repaired during P1 | integrity | DETECTED |
| 23 | New benchmark started | integrity | DETECTED |
| 24 | v0.5 package created | integrity | DETECTED |
| 25 | Old 10-role restored | integrity | DETECTED |
| 26 | Product code modified | integrity | DETECTED |
| 27 | v0.4 release ZIP modified | integrity | DETECTED |
| 28 | No recommendation produced | verifier | DETECTED |
| 29 | Recommendation conflicts with evidence | recommendation | DETECTED |
| 30 | Caveats deleted | integrity | DETECTED |

All 30 negatives covered. No generic FAIL, no expectedClass-only, no manual PASS-only, no preclassified-only.