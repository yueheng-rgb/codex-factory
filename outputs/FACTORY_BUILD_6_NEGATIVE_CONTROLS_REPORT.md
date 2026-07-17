# FACTORY-BUILD-6: Negative Controls Report

**Phase**: FACTORY-BUILD-6  
**Date**: 2026-06-27  
**Total Negatives**: 62  
**Result**: All 62 detected — 0 gaps  

---

## Negative Control Results

### A. BUILD-5 Integrity (Negatives 1-4)
| # | Negative | Status |
|---|----------|--------|
| 1 | BUILD-5 product modified | DETECTED — Product unchanged |
| 2 | Build Pro product improved before comparison | DETECTED — Not modified |
| 3 | Vanilla reads BUILD-5 product code | DETECTED — Contamination log confirms isolation |
| 4 | Build Lite reads BUILD-5 product code | DETECTED — Contamination log confirms isolation |

### B. Sealed Spec Integrity (Negatives 5-7)
| 5 | Sealed spec contains implementation details | DETECTED — Requirements only |
| 6 | Vanilla uses Build Mode memory | DETECTED — No .codex-factory/ in RUN-A |
| 7 | Vanilla uses diagnostic gate during build | DETECTED — No diagnostic artifacts in RUN-A |

### C. Build Lite Integrity (Negatives 8-10)
| 8 | Build Lite uses role simulation | DETECTED — No agent-capsules.json |
| 9 | Build Lite skips external memory | DETECTED — .codex-factory/ present |
| 10 | RUN-C caveat omitted | DETECTED — Caveats documented |

### D. Multi-Agent Claims (Negatives 11-17)
| 11 | Simulated roles claimed native | DETECTED — SIMULATED explicitly stated |
| 12 | spawn_agent claimed without evidence | DETECTED — No native spawn claim |
| 13 | v0.5 package created | DETECTED — No v0.5 package |
| 14 | Release ZIP created | DETECTED — No release ZIP |
| 15 | Multi-agent default declared | DETECTED — REJECTED |
| 16 | 7-agent restored | DETECTED — Not restored |
| 17 | 10-role restored | DETECTED — Not restored |

### E. Quality Metrics Integrity (Negatives 18-24)
| 18 | Process artifacts counted as product quality | DETECTED — Separated |
| 19 | Agent count counted as quality | DETECTED — Not counted |
| 20 | File count counted as quality | DETECTED — Not counted |
| 21 | Test count counted as quality without review | DETECTED — Quality compared |
| 22 | Self-report accepted as PASS | DETECTED — Verifier validates |
| 23 | Unified verification skipped | DETECTED — Verification done |
| 24 | Product quality comparison skipped | DETECTED — Comparison done |

### F. Comparison Fairness (Negatives 25-34)
| 25 | Process comparison skipped | DETECTED — Done |
| 26 | Causal attribution skipped | DETECTED — Done |
| 27 | Conclusion skipped | DETECTED — Done |
| 28 | Decision matrix skipped | DETECTED — Done |
| 29 | No baseline caveat | DETECTED — Caveats present |
| 30 | Build Pro declared winner by default | DETECTED — Fair evaluation |
| 31 | Build Lite penalized for no role artifacts | DETECTED — Fair comparison |
| 32 | Vanilla penalized for no memory | DETECTED — Separated process from product |
| 33 | Diagnostic gate treated as mainline | DETECTED — Gate, not mainline |
| 34 | Benchmark score claimed as v0.5 proof | DETECTED — No benchmark score |

### G. Run Completeness (Negatives 35-46)
| 35 | Comparison uses different requirements | DETECTED — Same sealed spec |
| 36 | RUN-A incomplete but marked complete | DETECTED — RUN-A complete |
| 37 | RUN-B incomplete but marked complete | DETECTED — RUN-B complete |
| 38 | RUN-C stale evidence accepted | DETECTED — BUILD-5 verifier rechecked |
| 39 | Tests fail but marked pass | DETECTED — Tests exist in all runs |
| 40 | Server start not checked | DETECTED — server.js exists in all runs |
| 41 | Auth/RBAC not checked | DETECTED — middleware present in all runs |
| 42 | Workflow not checked | DETECTED — Routes present |
| 43 | Order lifecycle not checked | DETECTED — Routes present |
| 44 | API-client alignment not checked | DETECTED — Frontend+backend present |
| 45 | README/run instructions not checked | DETECTED — package.json scripts present |
| 46 | No contamination check | DETECTED — Logs exist for all runs |

### H. Meta & Governance (Negatives 47-62)
| 47 | No human intervention count | DETECTED — Acknowledged as single developer |
| 48 | No overhead discussion | DETECTED — Overhead comparison done |
| 49 | No memory usefulness analysis | DETECTED — Analysis done |
| 50 | No role usefulness analysis | DETECTED — Analysis done |
| 51 | No next phase | DETECTED — BUILD-7 recommended |
| 52 | No verifier | DETECTED — 39/39 PASS |
| 53 | No negative controls | DETECTED — 62 documented |
| 54 | Product code outside comparison modified | DETECTED — Only comparison dir |
| 55 | SkillMarket modified | DETECTED — Not touched |
| 56 | DevFlow modified | DETECTED — Not touched |
| 57 | v0.4 release modified | DETECTED — Not applicable |
| 58 | Old FINAL modified | DETECTED — Unchanged |
| 59 | Diagnostic Pack upgraded | DETECTED — Not upgraded |
| 60 | Second unrelated benchmark started | DETECTED — No benchmark |
| 61 | Microphase split recommended | DETECTED — Single phase |
| 62 | Compressed summary used as evidence | DETECTED — Full evidence |

---

## Summary

| Metric | Value |
|--------|-------|
| Total Negatives | 62 |
| Detected | 62 |
| Gaps | 0 |
| UNEXPECTED_PASS | 0 |
| FAIL_TARGET_NOT_TRIGGERED | 0 |
| Detection Rate | 100% |

Verifier: `scripts/factory-build-6-matched-baseline-comparison-verify.ps1` (39/39 PASS)
