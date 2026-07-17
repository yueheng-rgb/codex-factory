# LIVE-RUNTIME-2: Negative Controls Report

**Verdict**: 28/28 DETECTED_AND_BLOCKED, 0 gaps, 0 unexpected passes

| # | Fault | Target | Result |
|---|-------|--------|--------|
| N01 | Worker report without artifact | handoff schema artifactPaths required | DETECTED |
| N02 | Worker artifact without transcript | handoff schema transcriptPath required | DETECTED |
| N03 | Worker self-claims PASS | role policy builder prohibited claim_PASS | DETECTED |
| N04 | Orchestrator marks completed without handoff | lifecycle schema HANDOFF required | DETECTED |
| N05 | Failed agent as success | state machine FAILED excluded | DETECTED |
| N06 | Quarantined toward floor | state machine QUARANTINED excluded | DETECTED |
| N07 | Archived as active | archive index activeCount | DETECTED |
| N08 | Orchestrator writes worker scope | authority matrix FORBIDDEN | DETECTED |
| N09 | Post-hoc contract | lifecycle CONTRACTED before SPAWN | DETECTED |
| N10 | Hash chain broken | event schema hashChained | DETECTED |
| N11 | Missing evidence SHA | handoff schema evidenceSha256 required | DETECTED |
| N12 | Duplicate handoff | handoff schema duplicateHandoffBlocked | DETECTED |
| N13 | Stale handoff | handoff schema staleHandoffDetected | DETECTED |
| N14 | Fabricated file path | handoff schema artifactPathsMustBeRealFiles | DETECTED |
| N15 | Claimed export not present | check-agent-report-honesty.ps1 | DETECTED |
| N16 | Claimed test not run | check-agent-report-honesty.ps1 | DETECTED |
| N17 | Scope contamination ignored | role policy CONTRACT_SCOPE_ONLY | DETECTED |
| N18 | Verifier writes implementation | authority matrix verifier write prohibited | DETECTED |
| N19 | Integrator bypassed | authority matrix integrator sole merge owner | DETECTED |
| N20 | Worker-to-worker direct | communication policy forbidden | DETECTED |
| N21 | Compressed summary as evidence | event schema compressedSummaryNotEvidence | DETECTED |
| N22 | Manual PASS accepted | honesty script + verifier prohibited | DETECTED |
| N23 | expectedClass-only | intake protocol verifier failureModes | DETECTED |
| N24 | Generic FAIL used | intake protocol verifier failureModes | DETECTED |
| N25 | Missing close receipt | receipt schema closeReceiptRequiresVerifierPass | DETECTED |
| N26 | Active stale ignored | state machine HEARTBEAT timeout | DETECTED |
| N27 | Capacity preflight skipped | scheduler SCH-01 | DETECTED |
| N28 | Cross-session recon skipped | result-collection-policy | DETECTED |

All negatives: machine-readable, verifier confirmed, no UNEXPECTED_PASS.
