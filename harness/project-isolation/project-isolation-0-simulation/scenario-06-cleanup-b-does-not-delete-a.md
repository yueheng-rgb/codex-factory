# Simulation Scenario 6: "删除该项目缓存" in Project B → does not delete Project A cache
> Part of: FACTORY-PROJECT-ISOLATION-0 / K — Simulation
> Scenario: 6 of 10

## Setup
- Project A and Project B both registered
- Project B is ACTIVE
- User says "删除该项目缓存"

## Expected Behavior
1. Resolve current projectId → Project B
2. Cleanup plan scoped to Project B paths only
3. Project A cache paths NOT in plan
4. If plan accidentally includes Project A path → REJECT, warn, remove
5. Confirmation shows: "Cleanup target: Project B"

## Expected Verdict: ✅ PASS (Project A cache preserved)
