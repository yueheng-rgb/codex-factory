# INTEGRATOR_PROTOCOL.md
> Part of: FACTORY-MULTI-AGENT-ORCHESTRATION-1 / H

## Integrator Responsibilities
1. **Contract Validation**: Verify every agent handoff against its contract
2. **Output Merging**: Merge accepted agent outputs into final deliverable
3. **Failure Attribution**: Attribute every FAIL/PARTIAL to specific agent + reason
4. **Rejection Handling**: Reject outputs that violate contract; do NOT silently merge
5. **Final Verdict**: ACCEPT or REJECT the overall multi-agent phase

## Rules
- Integrator is the SOLE final merger — no worker output bypasses Integrator
- Integrator MUST NOT introduce new features
- Integrator MUST attribute every failure
- Integrator MUST log acceptance/rejection to agent ledger
- Rejected output → agent must rework or phase blocked
- Anonymous output → auto-REJECT

## Integrator Output
```json
{
  "integratorVerdict": "ACCEPT | REJECT",
  "mergedOutputs": ["path"],
  "contractValidations": [{ "contractId": "...", "compliant": true }],
  "failureAttribution": [{ "agentId": "...", "failure": "...", "recommendation": "..." }],
  "rejectedOutputs": [{ "agentId": "...", "reason": "..." }],
  "finalHandoff": "path to final deliverable"
}
```

## Anti-Patterns
- ❌ Worker output becomes final without Integrator review
- ❌ Integrator silently accepts rejected output
- ❌ Integrator introduces new features
- ❌ Failure attribution omitted
