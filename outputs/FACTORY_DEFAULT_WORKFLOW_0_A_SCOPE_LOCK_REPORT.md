# FACTORY-DEFAULT-WORKFLOW-0 — A: Scope Lock Report

> Phase: FACTORY-DEFAULT-WORKFLOW-0
> Section: A — Default Workflow Scope Lock
> Date: 2026-06-28
> Status: ACTIVE

---

## 1. Inherited Baseline

- v0.5 (`codex-factory-core-v0.5.0.zip`) is delivered and verified.
- SHA256: `9FD3A5F979FE1FDEA712F69CAC300E2F49F4E84705A0448D98186CA950AC16CB`
- v0.5 scope: local workflow/tooling release; not production, not cloud, not deployment.

## 2. What This Phase IS

This phase (FACTORY-DEFAULT-WORKFLOW-0) defines and solidifies the **default usage protocol** for Codex Factory after v0.5. It establishes the governance rules, command entry points, user phrasing recognition, multi-agent decision gate, handoff path contract, and cleanup natural-language contract so that Factory becomes a system that **automatically operates correctly** when a user selects a project folder and states a requirement.

### In Scope

| Item | Description |
|------|-------------|
| Default Startup Protocol | What happens when user selects folder + states requirement |
| User Requirement Entry Contract | What phrases trigger Factory mode |
| Multi-Agent Decision Gate | When and how to ask about multi-agent |
| Multi-Agent Role Profile Draft | Role definitions for agent orchestration |
| Project Path Handoff Contract | What paths must be output at project completion |
| Natural Language Cleanup Contract | Safe cleanup triggered by natural language |
| CLI Name Reconciliation | Handling CLI name mismatches |
| State Dashboard Requirements | What Factory state should be visible |
| Agent Ledger Contract | Agent accountability and traceability |
| Cloud Deferral Record | Formal record that cloud is deferred |
| Simulation (8 scenarios) | Walk-through of default workflow behavior |
| Strategy Decision | Answers to key strategy questions |
| Negative Controls (30+) | Preventing regressions and wrong defaults |
| Verifier Script | Automated verification of all artifacts |

## 3. What This Phase IS NOT

| Excluded | Reason |
|----------|--------|
| Creating a new release | Not a release phase |
| Modifying v0.5 zip | v0.5 is frozen |
| Creating v0.6 | Premature |
| Going to cloud | Cloud is deferred |
| Buying servers/domains | Not applicable |
| Connecting to servers | Not applicable |
| Executing deployment scripts | Not applicable |
| Accessing production databases | Not applicable |
| Starting Native Build Pro | Not a build phase |
| Deleting project files | Safety boundary |
| Real destructive cleanup | Cleanup is PLAN-only |
| Real project verification | Deferred to later phases |
| Micro-phase splitting | This is a single coherent phase |

## 4. Goal

Make Factory usable by:
1. User selects a project folder.
2. User states a requirement.
3. Codex automatically enters Factory flow: Bootstrap → Router → Preflight → discussion → complexity judgment → multi-agent decision → working copy strategy → full path output → phase close → cleanup/user forget.

## 5. Success Criteria

- [ ] Default startup protocol defined
- [ ] User phrasing contracts defined
- [ ] Multi-agent decision gate defined
- [ ] Handoff path contract defined
- [ ] Natural-language cleanup contract defined
- [ ] CLI name reconciliation defined
- [ ] State dashboard requirements defined
- [ ] Agent ledger contract defined
- [ ] Cloud deferral recorded
- [ ] 8-scenario simulation completed
- [ ] Strategy decision answered
- [ ] 30+ negative controls defined and passed
- [ ] Verifier script passes all checks
