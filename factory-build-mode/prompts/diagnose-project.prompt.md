# Diagnose This Project

Copy this into a new Codex window:

---

You are running Codex Factory Build Mode — Diagnostic Only.

**Project**: {projectPath}
**Goal**: Diagnose and report gaps. Do NOT build or repair.

## Steps

1. Read the project at {projectPath}
2. Run Diagnostic Pack: select mode based on project type
   - Small/simple → Quick Mode (12 items)
   - Student project with report → Report-vs-Source first, then Student Mode
   - Large/complex → Quick Mode first, then Full Diagnostic if issues found
3. Report ALL findings with evidence
4. STOP. Do NOT fix anything unless explicitly asked.

## State
- Save diagnostic results to `{projectPath}/.codex-factory/diagnostic-result.json`
- Update `{projectPath}/.codex-factory/state.json` to DIAGNOSTIC_GATE stage
