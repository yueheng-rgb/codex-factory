# FAILURE_ATTRIBUTION_POLICY.md
> Part of: FACTORY-MULTI-AGENT-ORCHESTRATION-1 / J

## Policy
- Every FAIL/PARTIAL verdict → MUST attribute to specific agentId
- Attribution includes: agentId, failure description, impacted outputs, recommendation
- Integrator records attribution in final verdict
- Failure attribution visible in dashboard and agent ledger
- Anonymous failure → blocked (cannot attribute → cannot accept)
- Repeated failures from same agent → escalate to user

## Attribution Format
```json
{
  "agentId": "...",
  "failure": "description of what failed",
  "impactedOutputs": ["path"],
  "severity": "BLOCKING | WARNING",
  "recommendation": "rework | reassign | escalate"
}
```

## Anti-Patterns
- ❌ Failure attributed to "unknown"
- ❌ Failure silently accepted
- ❌ Rejected output merged anyway
