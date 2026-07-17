# Simulation Scenario 1: Project A active, Project B selected
> Part of: FACTORY-PROJECT-ISOLATION-0 / K — Simulation
> Scenario: 1 of 10

## Setup
- Project A is ACTIVE and mounted
- User selects Project B folder

## Expected Behavior
1. Project A context flushed to Project A storage
2. Active context cleared
3. Project B mount gate executes
4. Project B identity loaded (or UNKNOWN_NEEDS_CONFIRMATION if new)
5. Project A artifacts NOT visible in Project B context
6. Global preferences preserved

## Expected Verdict: ✅ PASS (A context blocked for B)
