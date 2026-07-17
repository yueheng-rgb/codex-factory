# Release Readiness Criteria v1.0

## v0.5 Release Readiness Audit

This document defines the 18 criteria for evaluating whether `codex-factory-core` staging is ready for release candidate planning. **This is NOT a release. v0.5 remains BLOCKED.**

---

## Criteria Status

| ID | Category | Status |
|----|----------|--------|
| RRC-01 | Installation usability | READY |
| RRC-02 | Bootstrap correctness | READY |
| RRC-03 | Mode selection (Build Lite default) | READY |
| RRC-04 | Build Lite real project safety | READY |
| RRC-05 | Security/Deploy Gate safety | READY |
| RRC-06 | Package QA Gate safety | READY |
| RRC-07 | Context Space freshness | READY |
| RRC-08 | Phase close reliability | READY_MINOR_WARN |
| RRC-09 | Test repair policy | READY |
| RRC-10 | Staging bundle hygiene | READY |
| RRC-11 | Verifier robustness | READY |
| RRC-12 | Negative control coverage | READY |
| RRC-13 | Documentation usability | READY |
| RRC-14 | User burden reduction | READY |
| RRC-15 | Non-overclaim discipline | READY |
| RRC-16 | Coverage reconciliation | READY |
| RRC-17 | RC extraction/smoke | READY |
| RRC-18 | User review readiness | READY |

**Summary: 17 READY, 1 READY_MINOR_WARN, 0 NOT_READY**

---

## v0.5 Blockers

### ACTIVE (4)

| ID | Blocker | Severity |
|----|---------|----------|
| BLOCK-001 | No vanilla Codex baseline comparison | CRITICAL |
| BLOCK-002 | No production deployment validation | HIGH |
| BLOCK-003 | Local dev ≠ production readiness | CRITICAL |
| BLOCK-004 | User explicit approval required | CRITICAL |

### RESOLVED (5)

BOOT-001, QA-001, phase-ledger leak, phase-close boundary, coverage audit

---

## RC Path

1. RELEASE-READINESS-0 → This audit
2. PACK-STAGING-P7 or USER-TRIAL-0 → Final clean trial
3. RELEASE-CANDIDATE-0 → RC package (NOT release)
4. RC-SMOKE-0 → Extraction + clean install + gates
5. RC-USER-REVIEW-0 → User review
6. v0.5 decision → User explicitly approves

---

**v0.5 = BLOCKED. releaseAllowed = false. v05Package = false.**
