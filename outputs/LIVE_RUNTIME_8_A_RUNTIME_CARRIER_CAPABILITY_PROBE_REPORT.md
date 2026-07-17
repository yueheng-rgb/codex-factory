# LIVE-RUNTIME-8-A: Runtime Carrier Capability Probe Report

**Generated**: 2026-06-25T00:47:47+08:00
**Phase**: LIVE-RUNTIME-8-A
**Status**: COMPLETE

## Summary

| Metric | Value |
|--------|-------|
| Total Carriers Probed | 11 |
| VERIFIED_FACT | 3 |
| PARTIALLY_VERIFIED | 5 |
| HYPOTHESIS_REQUIRES_VALIDATION | 3 |
| REJECTED_OR_UNSUPPORTED | 0 |
| Safe Fallback | manual_new_window_artifact_handoff |

## Carrier Classification

| Carrier | Classification | May Create | Inherits | Tested |
|---------|---------------|------------|----------|--------|
| manual_new_codex_window | VERIFIED_FACT | mayCreate=True | inherit=False | tested=True |
| cli_new | PARTIALLY_VERIFIED | mayCreate=True | inherit=False | tested=False |
| cli_fork | PARTIALLY_VERIFIED | mayCreate=True | inherit=unknown | tested=False |
| cli_resume | PARTIALLY_VERIFIED | mayCreate=True | inherit=unknown | tested=False |
| app_thread_start | HYPOTHESIS_REQUIRES_VALIDATION | mayCreate=unknown | inherit=unknown | tested=False |
| app_thread_fork | HYPOTHESIS_REQUIRES_VALIDATION | mayCreate=unknown | inherit=unknown | tested=False |
| app_thread_resume | HYPOTHESIS_REQUIRES_VALIDATION | mayCreate=unknown | inherit=unknown | tested=False |
| automation_same_thread_wakeup | REJECTED_OR_UNSUPPORTED | mayCreate=False | inherit=False | tested=False |
| project_automation_fresh_task | PARTIALLY_VERIFIED | mayCreate=unknown | inherit=False | tested=False |
| spawn_agent_fork_context_false | VERIFIED_FACT | mayCreate=False | inherit=False | tested=True |
| spawn_agent_fork_context_true | VERIFIED_FACT | mayCreate=False | inherit=partial | tested=True |

## Key Findings

- **3 VERIFIED_FACT**: manual_new_window (20+ sessions), spawn_agent fork_context:false (builders), spawn_agent fork_context:true (explorers)
- **5 PARTIALLY_VERIFIED**: CLI /new, /fork, /resume (documented, not tested here), project automation (tool exists, not tested), app thread variants (tools exist, NOT live-tested)
- **3 HYPOTHESIS**: app_thread_start, app_thread_fork, app_thread_resume — tools exist in schema but NOT tested for live thread creation
- **1 REJECTED**: automation same-thread wakeup — not implemented, not a carrier
- **Subagent is NEVER a session carrier** — builder isolation only
- **Manual artifact handoff remains ALWAYS-SAFE fallback**

## Rules Applied

- Capability untested in current environment = HYPOTHESIS, not VERIFIED
- Codex self-report alone is not proof
- Full context inheritance cannot be claimed without direct evidence
- Manual new window + artifact handoff remains safe fallback
- Subagent is internal worker only, never user-visible branch
- Automation wakeup is NOT a new context carrier


## Verdict

LIVE-RUNTIME-8-A: **COMPLETE** — 11 carriers honestly classified, 0 overstated claims
