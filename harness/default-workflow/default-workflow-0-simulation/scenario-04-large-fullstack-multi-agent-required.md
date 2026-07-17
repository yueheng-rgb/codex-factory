# Simulation Scenario 4: Large Fullstack → Multi-Agent Question Required

> Part of: FACTORY-DEFAULT-WORKFLOW-0 / L — Default Workflow Simulation
> Scenario: 4 of 8

---

## Setup
- User selects a folder for a large fullstack project
- Requirements: server + client + database + auth + 5+ modules
- `.codex-factory/` exists

## User Input
> "做一个电商管理平台，包含商品管理、订单管理、用户管理、权限系统、数据统计"

## Expected Factory Behavior

1. **Router**: Classifies as large-fullstack
2. **Discussion**: Outputs project type, complexity matrix, risks
3. **Multi-Agent Gate**: 5 criteria met → **MUST ask multi-agent question**
4. **Question format**: Shows reasons, offers Enable/Single/Decide later
5. **Does NOT start multi-agent silently**: Must wait for user response

## Expected Verdict: ✅ PASS (multi-agent question required and asked)
