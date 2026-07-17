# LIVE-RUNTIME-8-E: Negative Controls Report

**Generated**: 2026-06-25T00:49:00+08:00
**Phase**: LIVE-RUNTIME-8-E
**Status**: COMPLETE

## Summary

| Metric | Value |
|--------|-------|
| Total Negatives | 26 |
| Detected & Blocked | 26 |
| Gaps | 0 |
| Unexpected Passes | 0 |

## All 26 Negatives

| ID | Name | Fault | Result |
|----|------|-------|--------|
| N01 | fork_full_inheritance | Fork claims full context inheritance without proof | DETECTED_AND_BLOCKED |
| N02 | new_thread_no_startup | New thread starts major phase without startup verification | DETECTED_AND_BLOCKED |
| N03 | resume_trusts_compressed | Resume thread trusts compressed summary | DETECTED_AND_BLOCKED |
| N04 | wakeup_as_new_context | Automation wakeup treated as new context | DETECTED_AND_BLOCKED |
| N05 | subagent_as_branch | Subagent treated as user-visible branch | DETECTED_AND_BLOCKED |
| N06 | carrier_no_files | Fork/new carrier omits required read files | DETECTED_AND_BLOCKED |
| N07 | carrier_no_mcp | Carrier skips MCP memory query | DETECTED_AND_BLOCKED |
| N08 | carrier_no_verify | Carrier skips factoryctl verify | DETECTED_AND_BLOCKED |
| N09 | carrier_no_recon | Carrier skips cross-session reconciliation | DETECTED_AND_BLOCKED |
| N10 | rejected_verified | Rejected claim becomes verified | DETECTED_AND_BLOCKED |
| N11 | fallback_removed | Manual fallback removed despite unverified fork | DETECTED_AND_BLOCKED |
| N12 | self_report_proof | Codex self-report used as sole proof | DETECTED_AND_BLOCKED |
| N13 | unavailable_verified | Unavailable carrier marked VERIFIED | DETECTED_AND_BLOCKED |
| N14 | thread_error_ignored | Thread API error ignored | DETECTED_AND_BLOCKED |
| N15 | fork_no_evidence | Fork experiment missing transcript/evidence | DETECTED_AND_BLOCKED |
| N16 | startup_fail_continues | Startup verification failure still allows continuation | DETECTED_AND_BLOCKED |
| N17 | carrier_mutate_phase | Carrier mutates currentTrustedPhase | DETECTED_AND_BLOCKED |
| N18 | carrier_mark_pass | Carrier marks phase PASS | DETECTED_AND_BLOCKED |
| N19 | carrier_create_zip | Carrier creates final ZIP | DETECTED_AND_BLOCKED |
| N20 | compressed_evidence | Compressed summary used as evidence | DETECTED_AND_BLOCKED |
| N21 | branch_as_memory | Branch treated as reliable memory expansion | DETECTED_AND_BLOCKED |
| N22 | fork_true_default | spawn_agent fork_context:true used as default builder isolation | DETECTED_AND_BLOCKED |
| N23 | markdown_only | Carrier result markdown-only | DETECTED_AND_BLOCKED |
| N24 | no_evidence_path | No evidence path in carrier capability record | DETECTED_AND_BLOCKED |
| N25 | auto_window | Automatic window creation claimed without proof | DETECTED_AND_BLOCKED |
| N26 | persistent_state | Carrier test creates persistent state without cleanup | DETECTED_AND_BLOCKED |

## Verdict

LIVE-RUNTIME-8-E: **26/26 negatives DETECTED_AND_BLOCKED, 0 gaps**
