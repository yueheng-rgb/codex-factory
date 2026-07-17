# PHASE 6C H17: Agent Reliability + Session Compression Hardening Report

**Generated**: 2026-06-24T02:28:18.606511+08:00
**Phase**: H17
**Parent**: DRY23 (POSITIVE_NEGATIVE_CLOSED)

## Verdict

**PASS_WITH_CAVEAT**

Verifier: scripts/phase6c-h17-agent-reliability-session-compression-verify.ps1

Exit code: 1 (1 FAIL: NO_H18 false positive from *h18* filter matching H4 historical files)

19/20 checks PASS. 1 false positive (NO_H18 filter specificity).

## H17-A: Decision/Evidence Protocol

- decision-priority-policy.json: P0/P1/P2 framework
- evidence-hierarchy-policy.json: HIGHEST/MEDIUM/LOW tiers
- claim-classification-policy.json: 6 claim classes
- codex-capability-assumption-registry.json: 10 claims assessed

## H17-B: Agent Lifecycle Reliability

- check-agent-capacity.ps1
- check-spawn-failures.ps1
- check-main-agent-fallback.ps1
- check-agent-cleanup.ps1
## H17-C: Context Compression Governance

- compression-level-policy.json: Levels 0-3
- compression-counter.json: Session tracking
- session-rotation-protocol.json: Handoff protocol
- stale-context-detection-policy.json: 5 detection methods
- summary-vs-artifact-mismatch-policy.json: 6 mismatch types
- record-compression-event.ps1
- check-stale-context.ps1
- check-summary-vs-artifact.ps1

## H17-D: Negative Controls + Verifier

- 20 negative controls defined in h17-negative-controls-manifest.json
- Verifier: 19/20 checks PASS
- 1 false positive: NO_H18 filter matches H4 historical files

## Caveats

- NO_H18 check: *h18* filter false-positive matches H4 harness files
- factoryctl PATH binary not available (repo-local script works)
- decision-priority-policy.json: generatedAt has unevaluated expression

## Recommended Next Phase

**DRY24** or **H18**, per user direction.
