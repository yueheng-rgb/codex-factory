# FACTORY-REALWORLD-2-LESSONS-0 Section D: Build Lite Rule Update

**Timestamp**: 2026-06-28T10:58:00+08:00
**Status**: CONFIRMED_AND_STRENGTHENED

---

## DG-002: Build Lite = Default — CONFIRMED

REALWORLD-1 and REALWORLD-2 both validated Build Lite as sufficient for real-project intake, security hardening, test repair, and delivery. No Native Build Pro was needed.

## Working-Copy Requirements (Strengthened)

| Requirement | Status |
|-------------|--------|
| Context Packet | MANDATORY |
| Working-copy isolation | MANDATORY |
| Baseline validation (check/lint/smoke) | MANDATORY |
| Security/Deploy Gate (deployed projects) | MANDATORY |

## Context Packet Minimum Fields

`project_type`, `risk_count`, `build_mode`, `phase_scope`, `original_path`, `working_copy_path`
