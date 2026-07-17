# FACTORY-V05-R1-INTEGRATION-0 — H: Default Workflow Integration

## Integrated Protocols from DEFAULT-WORKFLOW-0 (60/60)

| Protocol | File | R1 Behavior |
|----------|------|-------------|
| Default Startup Protocol | DEFAULT_FACTORY_STARTUP_PROTOCOL.md | Step 0: detect Factory, Bootstrap, Router, Preflight |
| User Requirement Entry | USER_REQUIREMENT_ENTRY_CONTRACT.md | Select folder + state requirement -> auto-enter flow |
| Multi-Agent Decision Gate | MULTI_AGENT_DECISION_GATE.md | Large project triggers mandatory multi-agent question |
| Project Path Handoff | PROJECT_PATH_HANDOFF_CONTRACT.md | Final handoff requires full paths, no omissions |
| Natural Language Cleanup | NATURAL_LANGUAGE_CLEANUP_CONTRACT.md | "Delete project cache" triggers PLAN, not execution |
| Agent Ledger Contract | AGENT_LEDGER_CONTRACT.md | Every agent run tracked with projectId |
| CLI Name Reconciliation | CLI_NAME_RECONCILIATION.md | factory.ps1 canonical, factoryctl.ps1 alias |
| Cloud Deferral Record | CLOUD_DEFERRAL_RECORD.md | Cloud explicitly deferred; no server/domain |
| State Dashboard Reqs | STATE_DASHBOARD_REQUIREMENTS.md | Dashboard requirements carried into R1 |
| Multi-Agent Role Draft | MULTI_AGENT_ROLE_PROFILE_DRAFT.md | Role profile scaffolding |

## R1 Enforcement
- Startup: Bootstrap before code. Always.
- Cleanup: PLAN-first. Never destructive by default.
- Handoff: Full paths mandatory. UNKNOWN_WITH_REASON for missing.
- Cloud: Deferred. Not in scope.
