# FACTORY-RELEASE-READINESS-0 — I: Release Candidate Path Design Report

**Timestamp:** 2026-06-28T17:10:00+08:00
**Section:** I — Release Candidate Path Design

---

## RC Path Stages

| Stage | Name | Description | Precondition |
|-------|------|-------------|-------------|
| 1 | **RELEASE-READINESS-0** | Criteria audit (this phase) | P6-R1 PASS |
| 2 | **PACK-STAGING-P7** or **USER-TRIAL-0** | Final clean usability/user trial | READINESS-0 PASS |
| 3 | **RELEASE-CANDIDATE-0** | Create RC package (NOT release) | User approval to proceed |
| 4 | **RC-SMOKE-0** | Extraction + clean install + gate validation | RC-0 PASS |
| 5 | **RC-USER-REVIEW-0** | User review of RC package | RC-SMOKE-0 PASS |
| 6 | **v0.5 Decision** | User explicitly approves or rejects | All 5 stages complete |

---

## Critical Rules

- **RC is NOT final release.** RC package has `releaseCandidate=true`, `releaseAllowed=false`.
- **v0.5 requires explicit user approval.** No auto-promotion.
- **releaseAllowed remains `false`** until v0.5 decision stage.
- **v05Package remains `false`** until v0.5 decision stage.
- **RC can be created** without changing releaseAllowed or v05Package.
- **RC can be discarded** if smoke or review finds issues.

---

## Current Stage

We are at **Stage 1 (RELEASE-READINESS-0)**. After this phase completes:
- If criteria are mostly READY (17/18): proceed to Stage 2
- If critical gaps found: return to staging for fixes

---

**Status:** RC_PATH_DEFINED
**Verdict:** 6-stage path defined; RC ≠ release
