# LIVE-RUNTIME-6-D: Startup Verification Contract Report

**Generated**: 2026-06-25T00:38:14+08:00
**Phase**: LIVE-RUNTIME-6-D
**Status**: COMPLETE

## Contract Summary

The startup verification contract ensures that any new session carrier (manual window, fork, thread) must pass artifact-based verification before any new phase can begin.

## Required Checks

1. **read_current_factory_state** — Verify current-factory-state.json is readable and consistent
2. **validate_final_zip_sha256** — Verify FINAL package SHA256 matches recorded hash
3. **run_factoryctl_verify** — Run factoryctl verify --json; must PASS
4. **run_cross_session_reconciliation** — Cross-session state reconciliation
5. **run_capacity_preflight** — Agent capacity preflight check
6. **confirm_no_new_phase_artifacts** — No unauthorized new phase artifacts
7. **confirm_compressed_summary_not_evidence** — Compressed summary is not trusted as evidence
8. **confirm_rejected_claims_remain_rejected** — Previously rejected claims stay rejected

## Contract Rules

- Contract cannot mark phase PASS
- Contract cannot mutate governance state
- Contract cannot create final ZIP
- Contract cannot start new phase
- Only produces its own result artifact

## Output States

| State | Meaning |
|-------|---------|
| STARTUP_VERIFICATION_PASS | All checks passed; new carrier may proceed |
| STARTUP_VERIFICATION_BLOCKED | One or more blocking checks failed |
| STARTUP_VERIFICATION_ERROR | Contract execution error |

## Verdict

LIVE-RUNTIME-6-D: **COMPLETE**
