# Simulation Scenario 1: Empty Project Folder + Requirement

> Part of: FACTORY-DEFAULT-WORKFLOW-0 / L — Default Workflow Simulation
> Scenario: 1 of 8

---

## Setup
- User selects an empty project folder: `C:\new-project\`
- No `.codex-factory/` exists
- No `AGENTS.md` exists

## User Input
> "帮我做一个任务管理系统"

## Expected Factory Behavior

1. **Step 1 — Detection**: `.codex-factory/` NOT found
2. **Step 2 — Installation Offer**:
   > "Codex Factory (v0.5) is not detected. Install it?"
   - User chooses "Install v0.5"
3. **Step 3 — AGENTS.md**: No AGENTS.md to read — skip
4. **Step 4 — Bootstrap**: Reads APP_TYPE_ROUTER.md → classifies as "管理系统" → reads STACK_DECISION_GUIDE.md → recommends monolith + SQLite
5. **Step 5 — Router**: Classifies as complex (server+client+database+CRUD+permission)
6. **Step 6 — Preflight**: Clean workspace, no blockers
7. **Step 7 — Code Gate**: No code written
8. **Step 8 — Discussion**: Outputs project type, complexity, risks, recommended Build Lite
9. **Step 9 — Multi-Agent Gate**: Project has 3+ criteria → asks multi-agent question

## Expected Verdict: ✅ PASS (correct flow followed)
