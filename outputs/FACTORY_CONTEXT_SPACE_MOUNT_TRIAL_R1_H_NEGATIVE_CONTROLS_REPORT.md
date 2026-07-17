# FACTORY-CONTEXT-SPACE-MOUNT-TRIAL-R1 — Negative Controls Report

**Date**: 2026-06-28
**Sub-step**: H — Negative Controls

---

## Summary

| Metric | Value |
|--------|-------|
| Total controls | 32 |
| PASS_DETECTED | 31 |
| PASS_PENDING (verifier in step I) | 1 |
| FAIL | 0 |
| UNEXPECTED_PASS | 0 |
| FAIL_TARGET_NOT_TRIGGERED | 0 |
| Generic FAIL | 0 |
| expectedClass-only | 0 |
| manual PASS-only | 0 |

## Control Categories

| Category | Controls | Count |
|----------|----------|-------|
| Freshness / stale state | NC-001,002,003,004,008,009,022,023 | 8 |
| Legacy risk separation | NC-005,006,007 | 3 |
| Frozen conclusions enforcement | NC-011,012,013,017,018,019,020 | 6 |
| Evidence hierarchy | NC-010,014,015,016 | 4 |
| User preferences | NC-021 | 1 |
| Script/runtime hardening | NC-024,025,026,027 | 4 |
| Premature action blocking | NC-028,029,030,031,032 | 5 |

## Control Details

| NC | Fault | Expected Risk Signal | Result |
|----|-------|---------------------|--------|
| NC-001 | Completed Context-Space-0 shown as pending | STALE freshness; FRESH-002 warning | PASS_DETECTED |
| NC-002 | next_actions says continue E-N | STALE; next_actions replaced | PASS_DETECTED |
| NC-003 | Latest verifier ignored | Phase-ledger used instead | PASS_DETECTED |
| NC-004 | Phase ledger ignored | Mount v0.2.0 reads phase-ledger | PASS_DETECTED |
| NC-005 | Legacy risk overrides current strategy | Archived in archivedLegacyWarnings | PASS_DETECTED |
| NC-006 | Archived warning as active blocker | activeBlocker field separates them | PASS_DETECTED |
| NC-007 | Active TCM secret risk omitted | RISK-CS-002 present CRITICAL | PASS_DETECTED |
| NC-008 | Attach Packet lacks freshnessStatus | REJECT or UNKNOWN | PASS_DETECTED |
| NC-009 | Attach Packet lacks sourceOfTruthPaths | freshnessStatus=UNKNOWN | PASS_DETECTED |
| NC-010 | Attach Packet treated as proof | Model doc: not final evidence | PASS_DETECTED |
| NC-011 | v0.5 marked ready | DG-004 blocks | PASS_DETECTED |
| NC-012 | Build Pro default claimed | DG-003 blocks; FROZEN-002 | PASS_DETECTED |
| NC-013 | Multi-agent default claimed | DG-005 blocks; RC001 | PASS_DETECTED |
| NC-014 | External memory as model expansion | Not injected into model weights | PASS_DETECTED |
| NC-015 | Compressed summary > verifier | TIER-4 rejected | PASS_DETECTED |
| NC-016 | New window as strict isolation | Shared persistent file state | PASS_DETECTED |
| NC-017 | Package QA gate omitted | Present in strategy | PASS_DETECTED |
| NC-018 | Context Packet status omitted | context_packet_required_for_pro=true | PASS_DETECTED |
| NC-019 | Build Lite default omitted | build_lite_default=true | PASS_DETECTED |
| NC-020 | NBP conditional omitted | native_build_pro_conditional=true | PASS_DETECTED |
| NC-021 | Big-phase preference omitted | TIER-1 user_preference | PASS_DETECTED |
| NC-022 | Stale packet accepted as current | freshnessStatus=STALE | PASS_DETECTED |
| NC-023 | No regenerated packet | FRESH packet from Mount #5 | PASS_DETECTED |
| NC-024 | No runtime hardening | mount.ps1 v0.2.0 | PASS_DETECTED |
| NC-025 | No simulation | 8 scenarios PASS | PASS_DETECTED |
| NC-026 | No verifier | Created in Step I | PASS_PENDING |
| NC-027 | No negative controls report | This file (32 entries) | PASS_DETECTED |
| NC-028 | Cloud started prematurely | DG-006 blocks | PASS_DETECTED |
| NC-029 | SQLite P1 started prematurely | No artifacts | PASS_DETECTED |
| NC-030 | REALWORLD-2-P1 started prematurely | Listed as option only | PASS_DETECTED |
| NC-031 | Release ZIP created | release_allowed=false | PASS_DETECTED |
| NC-032 | v0.5 package created | v0_5_blocked=true | PASS_DETECTED |

## Verdict

**31/32 PASS_DETECTED, 0 FAIL, 1 PASS_PENDING (verifier in step I). 0 UNEXPECTED_PASS. 0 generic FAIL. 0 expectedClass-only. 0 manual PASS-only.**
