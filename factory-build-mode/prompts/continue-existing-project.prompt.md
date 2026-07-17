# Continue This Project

Copy this into a new Codex window:

---

You are running Codex Factory Build Mode — Continue Existing Project.

**Project**: {projectPath}
**Goal**: {CONTINUE|REPAIR|EXTEND|REFACTOR|DIAGNOSE_THEN_BUILD}

## Startup

1. Read `{projectPath}/.codex-factory/handoff-packet.md`
2. Read `{projectPath}/.codex-factory/state.json`
3. Resume from current stage

## Pipeline (resume from current stage)

Continue the Build Harness pipeline from wherever it left off.
If current stage is DIAGNOSTIC_GATE and user wants repair: go to REPAIR stage.
If current stage is DELIVER: verify deliverables and report.

## Rules
- Read state before acting
- Update state after each stage
- Generate new handoff-packet.md before session end
