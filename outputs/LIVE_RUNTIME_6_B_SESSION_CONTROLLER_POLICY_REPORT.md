# LIVE-RUNTIME-6-B: Session Controller Policy + Decision Matrix Report

**Generated**: 2026-06-25T00:38:14+08:00
**Phase**: LIVE-RUNTIME-6-B
**Status**: COMPLETE

## Controller Policy Rules

| Rule | Enforced |
|------|----------|
| controllerIsRouterNotCloser | True |
| recommendationIsNotVerifierPass | True |
| carrierIsNotTrustedMemory | True |
| artifactStartupVerificationMandatory | True |
| manualNewWindowAlwaysSafeFallback | True |
| forkNewThreadOptionalCarrierOnly | True |
| subagentNotUserVisibleBranch | True |
| builderDefaultForkContextFalse | True |
| compressedSummaryNotEvidence | True |
| cannotMutateGovernanceState | True |
| cannotMarkPhasePASS | True |
| cannotCreateFinalZIP | True |
| cannotStartNewPhase | True |
| cannotClaimAutomaticWindowCreation | True |
| cannotClaimFullContextInheritance | True |

## Core Principles

- **Controller is a router, not a closer** — converts watcher recommendations into execution packets
- **Recommendation is not verifier PASS** — controller does not mark phases
- **Carrier is not trusted memory** — fork/thread/new window are carriers only
- **Artifact startup verification mandatory** — no phase advances without it
- **Manual new window is always-safe fallback** — proven 20+ times in this repo

## Decision Matrix Scenarios

| Scenario | Recommended Carrier | Fallback | User Action | Startup Packet |
|----------|-------------------|----------|-------------|---------------|
| clean_state | manual_new_window | manual_new_window | False | False |
| rotation_recommended | manual_new_window | manual_new_window | True | True |
| rotation_required | manual_new_window | manual_new_window | True | True |
| confirmed_compact | manual_new_window | manual_new_window | True | True |
| multiple_compactions | manual_new_window | manual_new_window | True | True |
| factoryctl_fail | manual_new_window | manual_new_window | True | True |
| builder_isolation | spawn_agent_fork_false | spawn_agent_fork_false | False | False |
| explorer_readonly | spawn_agent_fork_true | spawn_agent_fork_true | False | False |

## Verdict

LIVE-RUNTIME-6-B: **COMPLETE**
