# Simulation Scenario 7: Agent output from Project A proposed for Project B
> Part of: FACTORY-PROJECT-ISOLATION-0 / K — Simulation
> Scenario: 7 of 10

## Setup
- Multi-agent session in Project A produces agent output
- User copies agent output path to Project B context

## Expected Behavior
1. Agent output metadata includes projectId = Project A
2. When referenced in Project B → projectId mismatch detected
3. Artifact marked as FOREIGN_REFERENCE
4. Viewable as reference only
5. NOT mounted as Project B active state
6. Warning: "This agent output belongs to Project A."

## Expected Verdict: ✅ PASS (foreign reference marked, not mounted)
