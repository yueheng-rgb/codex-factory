# V4.1 Task Decomposition Engine & Agent Execution Plan

## Classification: V4_1_TASK_DECOMPOSITION_ENGINE_READY

## Deliverables

| Module | Status | Files |
|---|---|---|
| Task Decomposition Engine | DONE | runtime/task-decomposition-engine.ps1 (~230 lines) |
| Task Graph Schema | DONE | schemas/task-graph.schema.json |
| Worker Plan Schema | DONE | schemas/worker-plan.schema.json |
| Validation Plan Schema | DONE | schemas/validation-plan.schema.json |
| Evidence Requirements Schema | DONE | schemas/evidence-requirements.schema.json |
| Demo: admin-system | DONE | 6 output files, 12 tasks, P0 risk |
| Demo: ecommerce-miniapp | DONE | 6 output files, 12 tasks, P0 risk |
| Docs | DONE | docs/task-decomposition.md, docs/multi-agent-execution-plan.md |
| README update | DONE | Complex Project Workflow section |
| V4.0.1 fix | DONE | line_or_section_reference added to build-evidence |

## Engine Capabilities

| Capability | Demo Verified |
|---|---|
| Project type detection (8 types) | ✅ admin-system (high), ecommerce+miniapp (medium) |
| Risk classification P0-P3 | ✅ Both demos: P0 (auth/payment) |
| Task graph (8-12 nodes) | ✅ 12 nodes each |
| Skill pack matching | ✅ auto-matched to project type |
| Knowledge referencing | ✅ source_file + source_hash |
| Search strategy (provider-aware) | ✅ respects search_provider=none |
| Validation plan (per-task) | ✅ artifact + test + review + static_check |
| Worker plan (main+integrator+workers) | ✅ 3 agents: main, integrator, workers |
| Agent execution plan | ✅ phase order + gates + acceptance criteria |

## Regression: 10/10 PASS
- V3.4.2 strict remote verification intact
- All schemas valid
- 2 demos produce 6 output files each
- search_provider defaults to none
