# Simulation Scenario 4: Deleted project selected
> Part of: FACTORY-PROJECT-ISOLATION-0 / K — Simulation
> Scenario: 4 of 10

## Setup
- Project Z status = DELETED
- User selects Project Z folder

## Expected Behavior
1. Mount gate detects DELETED status
2. Mount BLOCKED
3. User shown: "Project [Z] has been deleted. Mount is blocked."
4. No state loaded
5. No context established

## Expected Verdict: ✅ PASS (mount blocked for deleted project)
