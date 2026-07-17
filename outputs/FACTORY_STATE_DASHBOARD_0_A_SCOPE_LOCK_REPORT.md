# FACTORY-STATE-DASHBOARD-0 — A: Scope Lock Report

> Phase: FACTORY-STATE-DASHBOARD-0
> Section: A — Dashboard Scope Lock
> Date: 2026-06-29
> Status: ACTIVE

---

## 1. Inherited Baseline

- **USER-HANDOFF-0**: PASS, v0.5 delivered
- **FACTORY-DEFAULT-WORKFLOW-0**: PASS, 60/60
- **FACTORY-PROJECT-ISOLATION-0**: PASS, 48/48
- v0.5: `outputs/codex-factory-core-v0.5.0.zip`, SHA256 `9FD3A5F9...`

## 2. What This Phase IS

Define and prototype a local CLI/Markdown/JSON state dashboard that makes Factory state visible to the user. Covers project identity, phase, paths, gates, memory, cleanup, warnings, and agent ledger accountability.

### In Scope

| Item | Description |
|------|-------------|
| Dashboard Data Model | All visible fields in a unified schema |
| CLI Dashboard Contract | `factory state` command family |
| Markdown Dashboard Format | Human-readable state report |
| Agent Ledger View | Per-agent accountability display |
| Path Visibility Contract | What paths must always be shown |
| Health & Warning Rules | Stale/missing/corrupt/foreign detection |
| Prototype Script | PS1 that generates dashboard from fixtures |
| Simulation (10 scenarios) | Walk-through of dashboard behaviors |
| Integration Points | Links to DEFAULT-WORKFLOW-0 |
| Strategy Decision | Answers to key questions |
| Negative Controls (31) | Preventing dashboard failures |
| Verifier | Automated verification |

## 3. What This Phase IS NOT

| Excluded | Reason |
|----------|--------|
| Web UI | First version is CLI/Markdown/JSON only |
| Cloud service | Cloud is deferred |
| Graphical application | CLI + text output |
| New release | Not a release phase |
| v0.5 zip modification | v0.5 is frozen |
| v0.6 creation | Premature |
| Real project validation | Theory + prototype phase |
