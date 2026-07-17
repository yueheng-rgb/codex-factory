# LIVE-RUNTIME-7-E: Negative Controls Report

**Generated**: 2026-06-25T00:44:33+08:00
**Phase**: LIVE-RUNTIME-7-E
**Status**: COMPLETE

## Summary

| Metric | Value |
|--------|-------|
| Total Negatives | 30 |
| Detected & Blocked | 30 |
| Gaps | 0 |
| Unexpected Passes | 0 |
| No Generic FAIL | true |
| No ExpectedClass-Only | true |
| No Manual PASS-Only | true |
| No Preclassified-Only | true |

## All 30 Negatives

| ID | Name | Fault | Result |
|----|------|-------|--------|
| N01 | compacted_memory_used | Old compacted conversation memory used as evidence | DETECTED_AND_BLOCKED |
| N02 | compressed_summary_trusted | Compressed summary accepted as source of truth | DETECTED_AND_BLOCKED |
| N03 | watcher_as_verifier | Watcher alert treated as verifier PASS | DETECTED_AND_BLOCKED |
| N04 | controller_as_verifier | Controller packet treated as verifier PASS | DETECTED_AND_BLOCKED |
| N05 | startup_verification_skipped | Startup verification skipped | DETECTED_AND_BLOCKED |
| N06 | startup_fail_continues | Startup verification FAIL allows continuation | DETECTED_AND_BLOCKED |
| N07 | auto_major_phase | New carrier starts major phase automatically | DETECTED_AND_BLOCKED |
| N08 | fork_full_inheritance | Fork/new thread claims full context inheritance | DETECTED_AND_BLOCKED |
| N09 | auto_window_no_proof | Automatic window creation claimed without proof | DETECTED_AND_BLOCKED |
| N10 | mcp_no_evidence_paths | MCP memory output lacks evidence paths | DETECTED_AND_BLOCKED |
| N11 | mcp_overrides_verifier | MCP memory conflict overrides verifier JSON | DETECTED_AND_BLOCKED |
| N12 | context_os_conflict_ignored | Context OS conflict ignored | DETECTED_AND_BLOCKED |
| N13 | stale_context_accepted | Stale context packet accepted | DETECTED_AND_BLOCKED |
| N14 | stale_handoff_accepted | Stale handoff accepted | DETECTED_AND_BLOCKED |
| N15 | zip_sha_mismatch_ignored | Final ZIP SHA mismatch ignored | DETECTED_AND_BLOCKED |
| N16 | plugin_production | Plugin marked production-ready | DETECTED_AND_BLOCKED |
| N17 | rejected_verified | Rejected claim becomes verified | DETECTED_AND_BLOCKED |
| N18 | pkt_no_read_files | Startup packet omits required read files | DETECTED_AND_BLOCKED |
| N19 | pkt_no_verifier_cmds | Startup packet omits verifier commands | DETECTED_AND_BLOCKED |
| N20 | pkt_no_mcp | Startup packet omits MCP queries | DETECTED_AND_BLOCKED |
| N21 | pkt_no_rejected_claims | Startup packet omits rejected claims | DETECTED_AND_BLOCKED |
| N22 | controller_mutate_phase | Controller mutates currentTrustedPhase | DETECTED_AND_BLOCKED |
| N23 | watcher_mutate_phase | Watcher mutates currentTrustedPhase | DETECTED_AND_BLOCKED |
| N24 | mini_modifies_final | Mini-task modifies FINAL package | DETECTED_AND_BLOCKED |
| N25 | mini_creates_zip | Mini-task creates ZIP | DETECTED_AND_BLOCKED |
| N26 | continuation_marks_pass | Safe continuation marks phase PASS | DETECTED_AND_BLOCKED |
| N27 | agent_os_break_ignored | Agent OS event chain break ignored | DETECTED_AND_BLOCKED |
| N28 | capacity_risk_ignored | Capacity preflight risk ignored | DETECTED_AND_BLOCKED |
| N29 | reconciliation_mismatch_ignored | Cross-session reconciliation mismatch ignored | DETECTED_AND_BLOCKED |
| N30 | markdown_only_pass | Markdown-only recovery PASS accepted | DETECTED_AND_BLOCKED |

## Verdict

LIVE-RUNTIME-7-E: **30/30 negatives DETECTED_AND_BLOCKED, 0 gaps**
