# FACTORY-V05-R1-INTEGRATION-0 — C: R1 Workspace Assembly

## Assembly Method
1. v0.5 base extracted to temp
2. Base files copied to R1 workspace (excluding runtime noise: real projects, AB outputs, old packages, secrets)
3. 7 theory phase files overlaid into governance/, schemas/, scripts/, templates/

## File Counts
| Category | Count |
|----------|-------|
| Total R1 workspace files | 488 |
| Governance docs | 55 |
| Schemas | 16 |
| Scripts | 283 |

## Theory Phase Files Integrated
| Phase | Files | Destination |
|-------|-------|-------------|
| DEFAULT-WORKFLOW-0 | 10 | governance/factory-workflow/ |
| PROJECT-ISOLATION-0 | 12 | governance/factory-isolation/, schemas/ |
| STATE-DASHBOARD-0 | 17 | governance/factory-dashboard/, scripts/, schemas/, templates/, fixtures/ |
| RECOVERY-0 | 13 | governance/factory-recovery/, scripts/, schemas/, prompts/ |
| MULTI-AGENT-ORCHESTRATION-1 | 12 | governance/factory-multi-agent/, schemas/ |
| EVIDENCE-TAXONOMY-0 | 7 | governance/factory-evidence/, scripts/, schemas/ |
| PROJECT-LIFECYCLE-0 | 11 | governance/factory-lifecycle/, schemas/ |

## Excluded from R1
- Simulations (harness/)
- AB test outputs (factory-ab/, blind-test-results/)
- Real projects (ecommerce_*, habit-tracker-*, bigdata_*, tiny-typescript-service)
- Working copies, secrets, .env files
- Student packages
- Nested zips
