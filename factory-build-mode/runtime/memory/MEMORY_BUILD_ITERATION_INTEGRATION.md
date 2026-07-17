# Memory Integration with Build Iteration

## When Memory Is Read

| Build Stage | Read | Purpose |
|-------------|------|---------|
| INTAKE | project-state.json | Check if project already exists |
| CLASSIFY | architecture-map.json | Use existing architecture for classification |
| ROUTE | project-state.json | Resume previous mode |
| BLUEPRINT | architecture-map.json, requirement-map.json | Extend existing design |
| TASK_GRAPH | task-graph.json | Resume incomplete tasks |
| BUILD | task-graph.json, decision-log.jsonl | Know what to build and why |
| DIAGNOSTIC_GATE | verifier-history.json, active-risks.json | Historical results, known issues |
| DELIVER | ALL | Generate complete handoff |

## When Memory Is Written

| Build Stage | Write | Content |
|-------------|-------|---------|
| After INTAKE | init-memory OR update-state | Stage complete, project manifest |
| After CLASSIFY | update-state + append-decision | Complexity decision |
| After ROUTE | update-state | Mode selection |
| After BLUEPRINT | architecture-map.json update | Design decisions |
| After TASK_GRAPH | task-graph.json | All tasks defined |
| During BUILD | update-task per task | Task progress |
| After DIAGNOSTIC_GATE | verifier-history.json append + update-state | Gate results |
| After REPAIR | update-task + append-decision | Fixes applied |
| After DELIVER | generate-handoff | Final handoff packet |

## Session Boundary Protocol

Before session end:
1. Run generate-handoff.ps1
2. Verify all tasks have status
3. Verify all decisions logged
4. Update project-state.json to current stage

New session startup:
1. Run recover-startup.ps1
2. Read handoff-packet.json
3. Read task-graph.json for pending tasks
4. Read active-risks.json for known issues
5. Resume from currentStage
