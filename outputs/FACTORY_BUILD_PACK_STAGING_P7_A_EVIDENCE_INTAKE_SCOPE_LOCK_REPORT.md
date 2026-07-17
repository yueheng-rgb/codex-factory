# FACTORY-BUILD-PACK-STAGING-P7 — A: Evidence Intake & Scope Lock

**Timestamp:** 2026-06-28T17:20:00+08:00
**Phase:** PACK-STAGING-P7 / Final Clean User Trial

---

## Inherited Evidence

| Source | Status |
|--------|--------|
| PACK-STAGING-P6-R1 | PASS 31/31 — 4-layer coverage clean |
| RELEASE-READINESS-0 | PASS 29/29 — 17/18 criteria READY |
| v0.5 status | BLOCKED — 4 CRITICAL/HIGH blockers |
| releaseAllowed | `false` |
| v05Package | `false` |
| Staging bundle | `codex-factory-core-v0.9.0-pre-P6-R1-STAGING.zip` (70KB, 65 files) |

---

## P7 Purpose

**Primary:** Final clean user trial before RC consideration.

**Validates:**
- One-command workflow from fresh extraction
- User-facing clarity of docs and commands
- Gate trigger correctness (Security, Package QA, Context Space)
- Safety boundaries (no release, no deploy, no secrets)

**Prepares:**
- A/B comparison evidence design (BLOCK-001 prep, not resolution)

**Is NOT:**
- Release, v0.5, RC package, deployment, BLOCK-001 resolution

---

## Rejected Claims

| Claim | Reason |
|-------|--------|
| P7 = release | P7 is a staging trial, not a release |
| P7 success = v0.5 unblocked | 4 blockers remain unresolved |
| Clean install = production readiness | Local trial ≠ production |
| Factory usability = Factory superiority | No vanilla baseline |

---

**Scope Lock:** FROZEN — clean user trial only
**Status:** EVIDENCE_INTAKE_AND_SCOPE_LOCKED
