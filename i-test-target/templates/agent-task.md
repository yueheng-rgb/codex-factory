# Task: {{TASK_ID}} — {{TITLE}}

## Assigned to
{{AGENT_ROLE}} ({{AGENT_ID}})

## Scope
Allowed paths: {{ALLOWED_PATHS}}

## Dependencies
{{DEPENDENCIES}}

## Acceptance Criteria
{{ACCEPTANCE_IDS}}

## Handoff
When complete, run:
```powershell
.\scripts\submit-task.ps1 -TaskId {{TASK_ID}} -AgentId {{AGENT_ID}}
```

## Rules
- Only modify files within allowed paths
- Do NOT touch files owned by other agents
- Do NOT declare yourself PASS — only submit candidate_complete
- Record evidence as you work (not after)
