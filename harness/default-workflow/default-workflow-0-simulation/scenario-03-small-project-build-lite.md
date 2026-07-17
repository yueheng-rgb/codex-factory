# Simulation Scenario 3: Small Project → Build Lite

> Part of: FACTORY-DEFAULT-WORKFLOW-0 / L — Default Workflow Simulation
> Scenario: 3 of 8

---

## Setup
- User selects a folder with a small project
- Estimated: 3-4 files, no database, no auth
- `.codex-factory/` exists

## User Input
> "修复 README 里的姓名"

## Expected Factory Behavior

1. **Router**: Classifies as simple (documentation change)
2. **Mode**: Build Lite (default, correct for this size)
3. **Multi-Agent**: NOT suggested (too small)
4. **No Native Build Pro**: Not appropriate

## Expected Verdict: ✅ PASS (Build Lite correctly selected, no over-engineering)
