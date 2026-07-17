# Simulation Scenario 2: Archived project selected
> Part of: FACTORY-PROJECT-ISOLATION-0 / K — Simulation
> Scenario: 2 of 10

## Setup
- Project X status = ARCHIVED
- User selects Project X folder

## Expected Behavior
1. Mount gate detects ARCHIVED status
2. Project NOT default-mounted
3. User shown: "Project [X] is archived. View as reference?"
4. If yes: read-only view, no writes allowed
5. If no: mount cancelled

## Expected Verdict: ✅ PASS (archived not default-mounted)
