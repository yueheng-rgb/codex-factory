# Worker Reporting Protocol

**Schema**: governance/agent-os/worker-reporting-protocol.md
**Generated**: 2026-06-25T00:00:10+08:00
**Phase**: LIVE-RUNTIME-2-C

## Required Reports

| Stage | Report | Required Fields |
|-------|--------|-----------------|
| On spawn | spawn_confirmation | agentId, contractPath, scopeBoundary |
| During work | progress | agentId, completion%, artifactCount, riskSignals |
| Periodic | heartbeat | agentId, timestamp, currentState |
| On complete | handoff | agentId, artifactPaths, transcriptPath, evidenceSha256 |

## Rules

1. Worker self-report of PASS is NOT accepted — only verifier PASS counts
2. Worker cannot claim completion without artifact + transcript evidence
3. Worker must report scope violations immediately as risk signals
4. Missing heartbeat for 5min triggers auditor review
5. Handoff must include SHA256 of all output artifacts
6. Markdown report alone is not sufficient handoff evidence
