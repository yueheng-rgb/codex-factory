# FACTORY-RELEASE-READINESS-0 — B: Criteria Definition Report

**Timestamp:** 2026-06-28T17:10:00+08:00
**Section:** B — Release Readiness Criteria Definition

---

## 18 Release Readiness Criteria

| ID | Category | Requirement | Status |
|----|----------|-------------|--------|
| RRC-01 | Installation usability | One-command install works on clean Windows | READY |
| RRC-02 | Bootstrap correctness | Bootstrap validates VERSION/BOUNDARY/modules | READY |
| RRC-03 | Mode selection | Build Lite default; NBP conditional | READY |
| RRC-04 | Build Lite real project safety | Working-copy isolation, original untouched | READY |
| RRC-05 | Security/Deploy Gate safety | 10 checks, 6 blocking; triggers for deployed projects | READY |
| RRC-06 | Package QA Gate safety | Final ZIP handoff gate; read-only; BLOCKED prevents handoff | READY |
| RRC-07 | Context Space freshness | Phase close updates ledgers/snapshots/guard | READY |
| RRC-08 | Phase close reliability | Ledger/snapshot/guard update; verifier boundary | READY_MINOR_WARN |
| RRC-09 | Test repair policy | CLASSIFICATION_FIRST; HONEST_SKIP; NO_FAKE_PASS | READY |
| RRC-10 | Staging bundle hygiene | No secrets, no projects, no .env, manifest/zip reconciled | READY |
| RRC-11 | Verifier robustness | No UNEXPECTED_PASS, no generic FAIL, no manual-only | READY |
| RRC-12 | Negative control coverage | 45+ controls per phase, 0 gaps | READY |
| RRC-13 | Documentation usability | QUICKSTART with copy-paste; CLI help; workflow docs | READY |
| RRC-14 | User burden | ~60-70% reduction from pre-P4 baseline | READY |
| RRC-15 | Non-overclaim discipline | No superiority, no production readiness claims | READY |
| RRC-16 | Coverage reconciliation | Source/manifest/zip/extraction 4-layer audit | READY |
| RRC-17 | RC extraction/smoke | Extract bundle, verify VERSION, scripts, no forbidden | READY |
| RRC-18 | User review readiness | Chinese summary available; clear next steps | READY |

---

**Summary:** 17 READY, 1 READY_MINOR_WARN, 0 NOT_READY

### READY_MINOR_WARN Detail
- **RRC-08 (Phase close reliability):** P5 trial caught verifier mismatch; missing verifier = warn, not block. P6 hardening doc added to clarify boundary. Acceptable for documentation phases.

---

**Status:** CRITERIA_DEFINED_AND_AUDITED
**Verdict:** 18/18 categories defined, 17 READY
