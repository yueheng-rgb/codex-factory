# FACTORY-EVAL-8: Independent Effectiveness Comparison Report

**Phase:** FACTORY-EVAL-8 / Independent Effectiveness Comparison  
**Status:** COMPLETED — 26/26 Verifier PASS  
**Generated:** 2026-06-25T20:00:00+08:00

---

## Executive Summary

Independent READONLY evaluation compared RUN-A (Vanilla), RUN-B (Factory Lite), and RUN-C (Role-Agent) on the TeamFlow Lite benchmark using the EVAL-4 100-point rubric. Factory Lite demonstrated real product quality improvement over Vanilla. The Role-Agent model did NOT outperform Factory Lite despite 7.8x more process overhead.

## Rubric Scores

| Dimension | Max | RUN-A (Vanilla) | RUN-B (Factory Lite) | RUN-C (Role-Agent) |
|---|---|---|---|---|
| D01 Requirement Coverage | 25 | 25 | 25 | 25 |
| D02 API Contract | 20 | 18 | 19 | 20 |
| D03 Database Schema | 15 | 12 | 13 | 15 |
| D04 Auth & Authorization | 15 | 15 | 15 | 15 |
| D05 UI States | 10 | 3 | 7 | 9 |
| D06 Audit Trail | 5 | 5 | 5 | 5 |
| D07 Test Quality | 5 | 4 | 5 | 3 |
| D08 Documentation | 5 | 4 | 5 | 1 |
| **TOTAL** | **100** | **86** | **94** | **93** |

## Key Findings

### Q1: Did Factory Lite outperform Vanilla?
**YES.** RUN-B scored 94 vs RUN-A's 86 (+8 points). Key gains: better test coverage (30 vs 19 with recorded results), EJS UI (7 vs 3 UI score), better code structure, and Factory process maintained contamination integrity. Overhead: +200ms.

### Q2: Did Role-Agent outperform Factory Lite?
**NO.** RUN-C scored 93 vs RUN-B's 94 (-1 point). Despite superior architecture (React SPA, better-sqlite3, TypeScript), RUN-C was penalized for: NO README (-4 points), tests never run (-2 points). The 10-role company model's ~1555ms overhead diverted effort from critical deliverables to process artifacts.

### Q3: Which mechanisms are useful?
**KEEP:** Manual Router, Proof-of-Read, Contamination logging, Evidence hierarchy  
**CUT:** 10-role company model (replace with 3-role: Architect, Builder, Reviewer)  
**DEFER:** Cross-role contracts, Drift detection (to multi-agent projects)  
**REWORK:** Role handoffs (lighter format), Verifier/Auditor (merge into Reviewer)

### Q4: Did Factory prevent simplification?
**PARTIALLY.** The Role-Agent process incentivized creating process artifacts over completing product deliverables. Factory Lite avoided this by keeping process minimal.

## Negative Controls

36/36 negative controls PASS, 0 gaps. All anti-gaming measures verified.

## Verifier

26/26 verifier checks PASS.

## Recommended Next Phase

**FACTORY-EVAL-9:** Factory v0.4 Keep-Cut-Defer Decision — apply EVAL-8 findings to trim the Factory to its effective core.
