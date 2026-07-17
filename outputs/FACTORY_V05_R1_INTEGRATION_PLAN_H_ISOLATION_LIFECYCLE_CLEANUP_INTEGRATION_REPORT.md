# H: Isolation / Lifecycle / Cleanup Integration — R1 Embedding

## Integration Targets from PROJECT-ISOLATION-0 (48/48), PROJECT-LIFECYCLE-0 (30/30)

| Asset | Source Path | R1 Target Path | Category |
|-------|------------|----------------|----------|
| Project Identity Model | `factory-isolation/PROJECT_IDENTITY_MODEL.md` | `governance/factory-isolation/` | GOVERNANCE_RULE |
| Project Registry Schema | `factory-isolation/schemas/project-registry.schema.json` | `schemas/` | SCHEMA_TEMPLATE |
| Mount Isolation Rules | `factory-isolation/MOUNT_ISOLATION_RULES.md` | `governance/factory-isolation/` | GOVERNANCE_RULE |
| Cleanup Isolation Rules | `factory-isolation/CLEANUP_ISOLATION_RULES.md` | `governance/factory-isolation/` | GOVERNANCE_RULE |
| Lifecycle State Model | `factory-lifecycle/PROJECT_LIFECYCLE_STATE_MODEL.md` | `governance/factory-lifecycle/` | GOVERNANCE_RULE |
| State Transition Matrix | `factory-lifecycle/STATE_TRANSITION_MATRIX.md` | `governance/factory-lifecycle/` | GOVERNANCE_RULE |
| Operation Permission Matrix | `factory-lifecycle/OPERATION_PERMISSION_MATRIX.md` | `governance/factory-lifecycle/` | GOVERNANCE_RULE |
| Event Log Schema | `factory-lifecycle/schemas/project-lifecycle-event.schema.json` | `schemas/` | SCHEMA_TEMPLATE |
| Lifecycle User Commands | `factory-lifecycle/LIFECYCLE_USER_COMMANDS.md` | `governance/factory-lifecycle/` | CLI_COMMAND |

## R1 Integration Rules
- Project identity (projectId, pathFingerprint, contentFingerprint) checked at every mount.
- DELETED/ARCHIVED projects never default-mounted.
- FROZEN projects: query allowed, write/update blocked.
- Cleanup always resolves `projectId` first; scoped to one project.
- Foreign context (wrong projectId output) blocked from promotion to current.
- Lifecycle transitions logged via event log schema.
- Destructive transitions (DELETE, ARCHIVE) require user confirmation.
- Multi-agent allowed only on ACTIVE projects.
- UNKNOWN_NEEDS_CONFIRMATION requires identity confirmation before mount.
- CORRUPT_NEEDS_RECOVERY requires recovery plan before normal bootstrap.
