# LIVE-RUNTIME-6: Negative Controls Report

**Generated**: 2026-06-25T00:38:25+08:00
**Phase**: LIVE-RUNTIME-6-F
**Status**: COMPLETE

## Summary

| Metric | Value |
|--------|-------|
| Total Negatives | 28 |
| Passed | 28 |
| Gaps | 0 |
| Unexpected Passes | 0 |
| No Generic FAIL | True |
| No ExpectedClass-Only | True |
| No Manual PASS-Only | True |
| No Preclassified-Only | True |

## Negative Controls Detail

| ID | Name | Fault | Result |
|----|------|-------|--------|
| N01 | controller_mutate_phase | Controller mutates currentTrustedPhase | DETECTED_AND_BLOCKED |
| N02 | controller_mark_PASS | Controller marks phase PASS | DETECTED_AND_BLOCKED |
| N03 | controller_create_ZIP | Controller creates final ZIP | DETECTED_AND_BLOCKED |
| N04 | controller_start_phase | Controller starts new phase | DETECTED_AND_BLOCKED |
| N05 | auto_window_no_proof | Claims automatic window creation without proof | DETECTED_AND_BLOCKED |
| N06 | full_inheritance_claim | Claims full context inheritance | DETECTED_AND_BLOCKED |
| N07 | fork_as_memory | Treats fork as memory expansion | DETECTED_AND_BLOCKED |
| N08 | subagent_as_branch | Treats subagent as user-visible branch | DETECTED_AND_BLOCKED |
| N09 | compressed_evidence | Uses compressed summary as evidence | DETECTED_AND_BLOCKED |
| N10 | omit_startup_verification | Omits startup verification | DETECTED_AND_BLOCKED |
| N11 | pkt_no_read_files | Startup packet omits required read files | DETECTED_AND_BLOCKED |
| N12 | pkt_no_mcp | Startup packet omits MCP queries | DETECTED_AND_BLOCKED |
| N13 | pkt_no_verifier | Startup packet omits verifier commands | DETECTED_AND_BLOCKED |
| N14 | startup_fail_allows_phase | Startup verification fail still allows new phase | DETECTED_AND_BLOCKED |
| N15 | wakeup_as_context | Automation wakeup treated as new context | DETECTED_AND_BLOCKED |
| N16 | fork_true_builder_default | fork_context:true used as default builder isolation | DETECTED_AND_BLOCKED |
| N17 | fork_false_ignored | fork_context:false ignored for builders | DETECTED_AND_BLOCKED |
| N18 | stale_handoff_accepted | Stale handoff accepted | DETECTED_AND_BLOCKED |
| N19 | factoryctl_fail_ignored | factoryctl verify FAIL ignored | DETECTED_AND_BLOCKED |
| N20 | memory_fail_ignored | Context OS memory validation FAIL ignored | DETECTED_AND_BLOCKED |
| N21 | mcp_fail_ignored | MCP memory FAIL ignored | DETECTED_AND_BLOCKED |
| N22 | capacity_risk_ignored | Capacity preflight risk ignored | DETECTED_AND_BLOCKED |
| N23 | stale_agent_ignored | Unsafe active stale agent ignored | DETECTED_AND_BLOCKED |
| N24 | unsupported_carrier_verified | Selected carrier unsupported but marked verified | DETECTED_AND_BLOCKED |
| N25 | user_action_omitted | Manual user action required but omitted | DETECTED_AND_BLOCKED |
| N26 | rejected_becomes_verified | Rejected claim becomes verified | DETECTED_AND_BLOCKED |
| N27 | no_evidence_path | No evidence path in execution packet | DETECTED_AND_BLOCKED |
| N28 | markdown_only_controller | Markdown-only controller result accepted | DETECTED_AND_BLOCKED |

## Verdict

LIVE-RUNTIME-6-F: **28/28 negatives DETECTED_AND_BLOCKED, 0 gaps**
