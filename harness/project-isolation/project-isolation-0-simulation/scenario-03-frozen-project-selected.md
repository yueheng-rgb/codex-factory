# Simulation Scenario 3: Frozen project selected
> Part of: FACTORY-PROJECT-ISOLATION-0 / K — Simulation
> Scenario: 3 of 10

## Setup
- Project Y status = FROZEN
- User selects Project Y folder

## Expected Behavior
1. Mount gate detects FROZEN status
2. Query allowed (view project state, read files)
3. Update BLOCKED
4. User attempts to modify → REJECTED: "Project is frozen."
5. User can unfreeze by transitioning to ACTIVE (if allowed)

## Expected Verdict: ✅ PASS (query allowed, update blocked)
