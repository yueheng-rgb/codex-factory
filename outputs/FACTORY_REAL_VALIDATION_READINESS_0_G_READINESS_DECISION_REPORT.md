# FACTORY-REAL-VALIDATION-READINESS-0 — Readiness Decision

**Date**: 2026-06-29
**Phase**: FACTORY-REAL-VALIDATION-READINESS-0
**Sub-step**: G

---

## 1. Is R1 Ready for a First Real Project Trial?

**YES, with conditions.**

R1 readiness assessment:

| Factor | Status | Detail |
|--------|--------|--------|
| v0.5-R1 package delivered | ✅ | `codex-factory-core-v0.5.1-r1.zip`, SHA256 verified |
| USER-HANDOFF-R1 PASS | ✅ | 20/20 |
| External Conversation Space reconciled | ✅ | LEDGER-RECONCILIATION-0 PASS 45/45; 72 phases |
| Mount protocol operational | ✅ | Mount #16 FRESH |
| Project selection criteria defined | ✅ | Sub-step B: 10 inclusion + 8 exclusion |
| Trial scope defined | ✅ | Sub-step C: 12 behaviors |
| Safety boundaries defined | ✅ | Sub-step D: 16 pre-trial + 5 during + 5 post |
| Evidence standard defined | ✅ | Sub-step E: 18 evidence items |
| Failure/repair plan defined | ✅ | Sub-step F: 13 failure modes |
| 7 theory phases complete | ✅ | All 30-60 checks PASS |
| RISK-CS-002 (TCM keys) | ⚠️ | Active blocker; TCM excluded from first trial |
| Real validation executed | ❌ | NOT YET (correct — this is readiness only) |

## 2. What Type of Project Should Be Used?

**Strong recommendation**: CLI tool, static site, homework, or local utility library.

- **Must**: local-only, no secrets, can create working copy, ≥5 files, runnable, user-approved
- **Must NOT**: production, TCM, deploy-required, unrotated secrets, unclear ownership

## 3. What Exact Boundaries Must Be Maintained?

1. Original project read-only; all work in working copy
2. No server connections, no deploy, no production DB
3. Cleanup PLAN only; DELETE disabled without explicit confirmation
4. Multi-agent requires user confirmation
5. Dashboard/snapshot/attach = TIER-3 (navigation), not evidence
6. Phase close required; phase-ledger must update
7. Mount freshness required before and after
8. RISK-CS-002 acknowledged; TCM excluded

## 4. What Evidence Must Be Captured?

18 items per sub-step E. Minimum: projectId, paths, command logs, exit codes, phase close report, verifier result, mount freshness (before/after), phase-ledger tail, direction guard check.

## 5. What Counts as PASS / WARN / FAIL?

| Verdict | Definition |
|---------|------------|
| **PASS** | All 12 behaviors produce expected output; no safety boundary crossed; phase-ledger updates; direction guard fresh |
| **WARN** | All behaviors pass but with caveats (e.g., CLI name mismatch logged); no safety violation |
| **FAIL** | Any safety boundary crossed; any behavior wrong; phase-ledger stale; direction guard stale; verifier fails |

## 6. Is TCM Blocked Until Secret Rotation?

**YES.** RISK-CS-002 is an active blocker. TCM cannot be used for the first real trial unless:
- User certifies all secrets have been rotated
- User explicitly approves TCM as trial target
- Evidence of rotation is recorded

## 7. Recommended Next Action

| Priority | Action | Condition |
|----------|--------|-----------|
| **1** | Complete sub-steps H (negative controls) + I (verifier) | NOW |
| **2** | Pause. Wait for user to nominate a project. | After READINESS-0 PASS |
| **3** | FACTORY-REAL-VALIDATION-0 | Only after user provides project + user approves |
| **4** | R1 repair | Only if readiness gaps found |

**Decision**: R1 is ready for a first real project trial — with the project, boundaries, evidence, and failure plan defined above. Do NOT start the trial until the user nominates and approves a specific project.
