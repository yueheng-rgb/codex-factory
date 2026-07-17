# Simulation Scenario 2: Project with Factory Installed

> Part of: FACTORY-DEFAULT-WORKFLOW-0 / L — Default Workflow Simulation
> Scenario: 2 of 8

---

## Setup
- User selects folder: `C:\existing-project\`
- `.codex-factory/` exists (Factory v0.5 installed)
- `AGENTS.md` exists with Factory instructions

## User Input
> "接手这个文件夹，继续开发"

## Expected Factory Behavior

1. **Step 1 — Detection**: `.codex-factory/` FOUND → skip installation
2. **Step 3 — AGENTS.md**: Read and apply AGENTS.md
3. **Step 4 — Bootstrap**: Reads existing Factory state, Router runs
4. **Step 5 — Router**: Classifies based on existing project structure
5. **Step 7 — Code Gate**: No code written yet
6. **Step 8 — Discussion**: Outputs current project state + recommendations
7. **Step 9 — Multi-Agent Gate**: Evaluated based on project complexity

## Expected Verdict: ✅ PASS (Factory recognized, flow followed)
