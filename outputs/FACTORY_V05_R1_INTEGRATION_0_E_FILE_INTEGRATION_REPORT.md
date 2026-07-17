# FACTORY-V05-R1-INTEGRATION-0 — E: File Integration Report

## Integration Summary
| Phase | Source Count | Files Copied | Target Category |
|-------|-------------|-------------|-----------------|
| DEFAULT-WORKFLOW-0 | 10 | 10 | governance/factory-workflow |
| PROJECT-ISOLATION-0 | 12 | 12 | governance/factory-isolation, schemas |
| STATE-DASHBOARD-0 | 17 | 17 | governance/factory-dashboard, scripts, schemas, templates, fixtures |
| RECOVERY-0 | 13 | 13 | governance/factory-recovery, scripts, schemas, prompts |
| MULTI-AGENT-ORCHESTRATION-1 | 12 | 12 | governance/factory-multi-agent, schemas |
| EVIDENCE-TAXONOMY-0 | 7 | 7 | governance/factory-evidence, scripts, schemas |
| PROJECT-LIFECYCLE-0 | 11 | 11 | governance/factory-lifecycle, schemas |
| **Total** | **82** | **82** | |

## Key Integrated Files
- governance/factory-workflow/DEFAULT_FACTORY_STARTUP_PROTOCOL.md — Step 0 bootstrap
- governance/factory-workflow/MULTI_AGENT_DECISION_GATE.md — Large project gate
- governance/factory-isolation/PROJECT_IDENTITY_MODEL.md — projectId/pathFingerprint
- governance/factory-isolation/MOUNT_ISOLATION_RULES.md — Cross-project mount rules
- governance/factory-dashboard/factory-state-dashboard-prototype.ps1 — CLI dashboard
- governance/factory-recovery/scripts/factory-recovery-scan.ps1 — Recovery scan
- governance/factory-evidence/scripts/factory-evidence-validator.ps1 — Evidence validator
- governance/factory-lifecycle/PROJECT_LIFECYCLE_STATE_MODEL.md — 9-state model
- schemas/ — 12 JSON schemas (identity, registry, dashboard, recovery, contract, handoff, evidence, lifecycle)

## v0.5 Core Preserved
- actory.ps1, actoryctl.ps1, AGENTS.md, APP_TYPE_ROUTER.md, STACK_DECISION_GUIDE.md
- Starters (7), Blueprints (7), Skills (9), Templates, Scripts
- codex-factory-plugin (skills, MCP servers, automation)
