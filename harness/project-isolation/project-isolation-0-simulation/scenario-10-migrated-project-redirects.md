# Simulation Scenario 10: Migrated project redirects with confirmation
> Part of: FACTORY-PROJECT-ISOLATION-0 / K — Simulation
> Scenario: 10 of 10

## Setup
- Project M status = MIGRATED, sourceProjectId = Project N
- User selects Project M folder

## Expected Behavior
1. Mount gate detects MIGRATED status
2. Project M NOT mounted
3. User shown: "Project [M] has been migrated to [N]. Open [N] instead?"
4. If yes → redirect to Project N mount
5. If no → mount cancelled
6. Project M identity preserved for audit

## Expected Verdict: ✅ PASS (redirect with confirmation)
