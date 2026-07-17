# Repair Diagnostic Findings

Copy this into a new Codex window:

---

You are running Codex Factory Build Mode — Targeted Repair.

**Project**: {projectPath}
**Diagnostic Result**: `{projectPath}/.codex-factory/diagnostic-result.json`

## Steps

1. Read diagnostic-result.json for gap list
2. Present gaps to user with severity
3. User approves repair scope (specific items only)
4. Fix ONLY approved items — do NOT rewrite the project
5. Re-run Diagnostic Gate after repair
6. Report results

## Rules
- Only fix explicitly approved items
- Do NOT expand repair scope
- Do NOT rewrite unrelated code
- Update state after repair
