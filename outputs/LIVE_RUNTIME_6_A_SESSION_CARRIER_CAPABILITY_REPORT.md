# LIVE-RUNTIME-6-A: Session Carrier Capability Verification Report

**Generated**: 2026-06-25T00:37:56+08:00
**Phase**: LIVE-RUNTIME-6-A
**Status**: COMPLETE

## Summary

| Metric | Value |
|--------|-------|
| Total Carriers Classified | 9 |
| VERIFIED_FACT | 3 |
| PARTIALLY_VERIFIED | 3 |
| HYPOTHESIS_REQUIRES_VALIDATION | 2 |
| REJECTED_OR_UNSUPPORTED | 10 |
| Safe Fallback | manual_new_window_artifact_handoff |

## Carrier Classification Table

| Carrier | Classification | May Create Carrier | Inherits Context | User Action | Artifact Verification |
|---------|---------------|-------------------|------------------|-------------|----------------------|
| manual_new_codex_window | VERIFIED_FACT | True | False | True | True |
| cli_new | PARTIALLY_VERIFIED | True | False | True | True |
| cli_fork | PARTIALLY_VERIFIED | True | unknown | True | True |
| app_thread_start | HYPOTHESIS_REQUIRES_VALIDATION | True | unknown | unknown | True |
| automation_wakeup | REJECTED_OR_UNSUPPORTED | False | False | True | True |
| spawn_agent_fork_false | VERIFIED_FACT | False | False | False | False |
| spawn_agent_fork_true | PARTIALLY_VERIFIED | False | partial | False | False |
| project_automation_fresh | HYPOTHESIS_REQUIRES_VALIDATION | True | False | unknown | True |
| manual_new_window_artifact_handoff | VERIFIED_FACT | True | False | True | True |

## Rules Applied

- no_auto_window_claim_without_proof
- no_full_inheritance_claim_without_proof
- unavailable_classified_honestly
- manual_fallback_always_safe


## Key Findings

- **manual_new_window_artifact_handoff** is the ALWAYS-SAFE fallback, verified through 20+ session rotations in this repo.
- **spawn_agent with fork_context:false** is VERIFIED_FACT for builder isolation — NOT a session carrier.
- **automation_wakeup** is REJECTED as session carrier — cannot restore full context.
- **Fork/new thread** carriers are optional only; startup verification remains mandatory.
- No carrier claims automatic window creation without proof.
- No carrier claims full context inheritance without proof.

## Verdict

LIVE-RUNTIME-6-A: **COMPLETE**
