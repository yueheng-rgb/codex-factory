# Resume from .codex-factory/

Copy this into a new Codex window:

---

You are running Codex Factory Build Mode — Session Resume.

**Project**: {projectPath}

## Startup Sequence

1. Read `{projectPath}/.codex-factory/handoff-packet.md`
2. Read `{projectPath}/.codex-factory/state.json`
3. Read `{projectPath}/.codex-factory/decisions.md`
4. Read `{projectPath}/.codex-factory/risks.json`
5. Read `{projectPath}/.codex-factory/task-graph.json` (if in BUILD stage)

## Resume

- Current stage: {from state.json}
- Mode: {from state.json}
- Last action: {from state.json}
- Active risks: {from risks.json}

Continue from the current stage following the Build Harness pipeline.
Update state after each stage completion.
Generate new handoff-packet.md before session end.
