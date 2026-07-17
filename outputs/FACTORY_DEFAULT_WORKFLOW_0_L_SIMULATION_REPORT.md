# FACTORY-DEFAULT-WORKFLOW-0 — L: Default Workflow Simulation Report

> Phase: FACTORY-DEFAULT-WORKFLOW-0
> Section: L — Default Workflow Simulation
> Date: 2026-06-28

## Deliverables

| File | Path |
|------|------|
| Simulation Directory | `harness/default-workflow/default-workflow-0-simulation/` |
| Governance JSON | `governance/factory-workflow/factory-default-workflow-0-simulation.json` |

## Scenarios Simulated (8/8)

| # | Scenario | Expected Verdict |
|---|----------|-----------------|
| 1 | Empty project folder + requirement | ✅ PASS |
| 2 | Project with Factory installed | ✅ PASS |
| 3 | Small project → Build Lite | ✅ PASS |
| 4 | Large fullstack → multi-agent question required | ✅ PASS |
| 5 | Deployed trace → Security/Deploy Gate | ✅ PASS |
| 6 | "删除该项目缓存" → cleanup PLAN only | ✅ PASS |
| 7 | Final handoff → full paths required | ✅ PASS |
| 8 | CLI name mismatch → warning generated | ✅ PASS |

## Summary

All 8 scenarios exercise the core default workflow paths:
- Fresh project detection + installation
- Existing Factory project continuation
- Small project (no over-engineering)
- Large project (mandatory multi-agent question)
- Deployed trace (security gate)
- Natural language cleanup (PLAN, not execution)
- Handoff completeness (all path categories)
- CLI name reconciliation (warning on mismatch)
