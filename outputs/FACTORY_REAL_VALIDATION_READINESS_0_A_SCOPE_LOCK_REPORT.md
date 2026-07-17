# FACTORY-REAL-VALIDATION-READINESS-0 — Scope Lock Report

**Date**: 2026-06-29
**Phase**: FACTORY-REAL-VALIDATION-READINESS-0
**Sub-step**: A — Scope Lock

---

## 1. What This Phase IS

Readiness planning before the first real R1 project trial. Defines gates, criteria, boundaries, and evidence standards. **No real validation is performed.**

## 2. What This Phase IS NOT

| NOT | Reason |
|-----|--------|
| Real project validation | No project modification, no working copies |
| v0.6 development | v0.5-R1 is the current release |
| Cloud deployment | Local only, no servers |
| REALWORLD-2-P1 | TCM validation requires separate readiness |
| Release packaging | v0.5-R1 already delivered |

## 3. Current Baseline

| Item | Status |
|------|--------|
| v0.5-R1 package | Delivered (`codex-factory-core-v0.5.1-r1.zip`, 866.4 KB, 489 files) |
| USER-HANDOFF-R1 | PASS 20/20 |
| R1 scope | Local workflow/tooling patch |
| Cumulative checks | 369 PASS |
| Real project validation | NOT STARTED |
| v0.6 | NOT STARTED, not planned |

## 4. R1 New Capabilities (7 Theoretical Phases)

1. Default Workflow
2. Project Isolation
3. State Dashboard
4. Recovery
5. Multi-Agent Orchestration
6. Evidence Taxonomy
7. Project Lifecycle

## 5. Readiness Gate Purpose

Before validating any of these 7 phases on a real project, we must establish:
- What projects are safe to use
- What exact behaviors to validate
- What safety boundaries must not be crossed
- What evidence must be captured
- What failure looks like and how to respond
- Whether R1 is actually ready or has gaps

## 6. Verdict

**READINESS_PLANNING_ONLY. No real validation started. No project modification. No v0.6. No cloud.**
