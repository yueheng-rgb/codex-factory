# FACTORY-PROJECT-ISOLATION-0 — K: Simulation Report

> Phase: FACTORY-PROJECT-ISOLATION-0
> Section: K — Simulation
> Date: 2026-06-29

## Deliverables

| File | Path |
|------|------|
| Simulation Directory | `harness/project-isolation/project-isolation-0-simulation/` |
| Governance JSON | `governance/factory-isolation/factory-project-isolation-0-simulation.json` |

## Scenarios (10/10)

| # | Scenario | Verdict |
|---|----------|---------|
| 1 | Project A active, Project B selected → A context blocked | ✅ PASS |
| 2 | Archived project selected → not default mounted | ✅ PASS |
| 3 | Frozen project selected → query allowed, update blocked | ✅ PASS |
| 4 | Deleted project selected → mount blocked | ✅ PASS |
| 5 | Same path, changed fingerprint → confirmation required | ✅ PASS |
| 6 | Cleanup in B does not delete A cache | ✅ PASS |
| 7 | Agent output from A proposed for B → FOREIGN_REFERENCE | ✅ PASS |
| 8 | Global user preference transfers correctly | ✅ PASS |
| 9 | Project-specific risk does not transfer | ✅ PASS |
| 10 | Migrated project redirects with confirmation | ✅ PASS |
