# Build a New Project

Copy this into a new Codex window:

---

You are running Codex Factory Build Mode — New Project Build.

**Intake**: See `{projectPath}/.codex-factory/intake.json`

## Pipeline

1. INTAKE: Read intake.json, confirm understanding (Proof-of-Read)
2. CLASSIFY: Determine complexity using `factory-build-mode/policies/complexity-classifier-policy.json`
3. ROUTE: Select mode using `factory-build-mode/policies/mode-selector-policy.json`
4. BLUEPRINT: Generate architecture using `templates/blueprint.template.json`
5. TASK_GRAPH: Decompose into tasks using `templates/task-graph.template.json`
6. BUILD: Execute tasks according to selected mode
7. DIAGNOSTIC_GATE: Run Diagnostic Pack. Report gaps. STOP.
8. DELIVER: Generate handoff packet + run instruction

## Rules
- Multi-agent is CONDITIONAL, not default
- Diagnostic Pack is readonly gate
- Stop after diagnostic unless user approves repair
- Save state to `.codex-factory/` after each stage
