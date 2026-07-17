# FACTORY-AGENT-9-P2-L / Negative Controls Report

**Timestamp:** 2026-06-26T20:30:53.7556105+08:00 | **48/48 DETECTED | 0 gaps**

| # | Fault | Target Gate | Result |
|---|-------|-------------|--------|
| 1 | Product code modified during evaluation | Product Integrity | DETECTED |
| 2 | v0.4 release ZIP modified | Release Integrity | DETECTED |
| 3 | Old FINAL package modified | Release Integrity | DETECTED |
| 4 | New ZIP created | Release Integrity | DETECTED |
| 5 | v0.5 package created | Release Integrity | DETECTED |
| 6 | AGENT-9 historical result deleted | Evidence Preservation | DETECTED |
| 7 | AGENT-8-P1 BLOCKED evidence deleted | Evidence Preservation | DETECTED |
| 8 | AGENT-8-P1-R1 policy defects deleted | Evidence Preservation | DETECTED |
| 9 | Repaired policy applied only to P1 | Fairness | DETECTED |
| 10 | Source file count treated as hard blocker | Policy Compliance | DETECTED |
| 11 | Export count treated as hard blocker | Policy Compliance | DETECTED |
| 12 | Test file count treated as hard blocker | Policy Compliance | DETECTED |
| 13 | Diagnostic metric ignored entirely | Policy Compliance | DETECTED |
| 14 | Hard feature gates ignored | Policy Compliance | DETECTED |
| 15 | Requirements coverage skipped | Completeness | DETECTED |
| 16 | Runtime/test evidence skipped | Completeness | DETECTED |
| 17 | Architecture comparison skipped | Completeness | DETECTED |
| 18 | Security/workflow comparison skipped | Completeness | DETECTED |
| 19 | UX/docs/API comparison skipped | Completeness | DETECTED |
| 20 | Process/evidence/overhead skipped | Completeness | DETECTED |
| 21 | Self-mapping treated as final | Scoring Integrity | DETECTED |
| 22 | Run self-report trusted without evidence | Evidence Quality | DETECTED |
| 23 | Process artifacts counted as product quality | Scoring Integrity | DETECTED |
| 24 | File count used as quality proof | Quality Proxy | DETECTED |
| 25 | Export count used as quality proof | Quality Proxy | DETECTED |
| 26 | Test count used as quality proof | Quality Proxy | DETECTED |
| 27 | Agent count used as quality proof | Quality Proxy | DETECTED |
| 28 | P1 declared winner because phase gate ready | Scoring Integrity | DETECTED |
| 29 | P1 declared winner because tests count high | Scoring Integrity | DETECTED |
| 30 | Vanilla penalized for no process artifacts | Fairness | DETECTED |
| 31 | v0.4 penalized for no agent artifacts | Fairness | DETECTED |
| 32 | Old v0.5 caveats ignored | Fairness | DETECTED |
| 33 | P1 policy defect path ignored | Fairness | DETECTED |
| 34 | Blocker ignored because score high | Scoring Integrity | DETECTED |
| 35 | Cannot-evaluate forced to PASS | Scoring Integrity | DETECTED |
| 36 | Multi-agent default declared without threshold | Default Claim | DETECTED |
| 37 | V05-PREP recommended without threshold | Recommendation Quality | DETECTED |
| 38 | Larger benchmark recommended by default | Recommendation Quality | DETECTED |
| 39 | Multi-agent rejected forever from one benchmark | Recommendation Quality | DETECTED |
| 40 | Conclusion forced despite mixed evidence | Conclusion Integrity | DETECTED |
| 41 | No comparison against old v0.5 | Completeness | DETECTED |
| 42 | No comparison against v0.4 | Completeness | DETECTED |
| 43 | No comparison against Vanilla | Completeness | DETECTED |
| 44 | Old 10-role restored | Scope | DETECTED |
| 45 | No recommendation | Closure | DETECTED |
| 46 | No verifier | Verification | DETECTED |
| 47 | No negative controls | Verification | DETECTED |
| 48 | Markdown-only evaluation accepted | Evidence Quality | DETECTED |

**Verdict: NEGATIVE_CONTROLS_ALL_DETECTED**
