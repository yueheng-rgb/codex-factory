# AGENT_LEDGER_UPDATE_POLICY.md
> Part of: FACTORY-MULTI-AGENT-ORCHESTRATION-1 / I

## Policy
- Every agent spawn → ledger entry (ACTIVE)
- Every agent handoff → ledger entry (verdict, outputs, caveats)
- Every Integrator decision → ledger entry (ACCEPT/REJECT, attribution)
- projectId mandatory in ALL entries
- Missing projectId → entry rejected
- Anonymous output → not accepted
- Ledger append-only, immutable per PROJECT-ISOLATION-0 + RECOVERY-0

## Required Fields Per Entry
agent_id, agent_role, contractId, projectId, timestamp, phase, input_artifacts, output_artifacts, verdict, known_caveats, handoff_to, foreign_references, scope_violations, contract_compliance

## Dashboard Visibility
- `factory state --agents` shows all ledger entries
- Missing entries → WARNING
- FAIL verdicts → highlighted
- No integrator verdict → WARNING
