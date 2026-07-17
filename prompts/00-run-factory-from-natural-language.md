# 00 ? Run Factory from Natural Language

> Copy the block below, replace `REQUIREMENT`, and send it to Codex.

---

Read `C:\Codex_App_Factory\RUN_CODEX_APP_FACTORY.md`.
Use the Codex App Factory full workflow to create a project from the requirement below.

REQUIREMENT:
{{user's natural-language requirement}}

TARGET_ROOT:
{{optional target root directory, e.g., C:\Codex_Real_Projects}}

PROJECT_NAME:
{{optional project name}}

Unless a mandatory pause condition in RUN_CODEX_APP_FACTORY.md is triggered,
do NOT ask for stage-by-stage confirmation.
Automatically complete: project classification, starter selection, copy,
minimal business closure, runtime validation, defect classification,
factory backflow, and final report.

---

## Phase 5B Audit Additions

Based on the first blind test audit (campus-club-registration), the following rules are now mandatory:

### Risk Classification
- Multi-role + capacity/concurrent writes → risk ≥ **medium** (not low)
- Low risk ONLY for single-role or read-only projects

### Functional Tests
- Fullstack-admin projects MUST run real browser functional tests (not just build+dev)
- Use Playwright with system Chrome/Edge channel (do NOT download Chromium)

### Run-State
- Create `.codex-factory/run-state.json` at initialization, not at the end
- Update after each completed stage
- `finalStatus: "completed"` ONLY after functional tests pass

### Final Report
- Must distinguish: first attempt / fixes / post-audit verification
- Never claim "all pass" with pending functional tests
- Never mark unverified features as PASS
---

## Phase 5C Evidence Trail (v2)

The orchestrator MUST maintain an auditable evidence trail:

1. **run-state.json** — Created at Stage 4 initialization, updated after each stage. Tracks current state.
2. **run-events.jsonl** — Append-only event log from run_started onward. Preserves process history (including first failures).

Before the final report:
- Execute `validate-factory-run.ps1 -ProjectPath <TARGET_PATH>`
- Only claim orchestration complete when the validator passes

The user does NOT need to send Phase A/B/C/D instructions.