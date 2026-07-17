# FACTORY-V05-R1-INTEGRATION-0 — J: Isolation / Lifecycle / Cleanup Integration

## Integrated from PROJECT-ISOLATION-0 (48/48) + PROJECT-LIFECYCLE-0 (30/30)

### Isolation Rules
| Rule | File | R1 Behavior |
|------|------|-------------|
| Project Identity | PROJECT_IDENTITY_MODEL.md | projectId, pathFingerprint, contentFingerprint |
| Project Registry | PROJECT_REGISTRY.md | Known projects list; only one active |
| Mount Isolation | MOUNT_ISOLATION_RULES.md | DELETED/ARCHIVED not default-mounted |
| Memory Boundary | CROSS_PROJECT_MEMORY_BOUNDARY.md | Context per-project; no cross-contamination |
| Output Isolation | OUTPUT_GOVERNANCE_ISOLATION.md | Outputs scoped to projectId |
| Cleanup Isolation | CLEANUP_ISOLATION.md | Cleanup resolves projectId first |
| Agent Ledger Isolation | AGENT_LEDGER_ISOLATION.md | Agent outputs scoped to projectId |
| Working Copy Isolation | WORKING_COPY_ISOLATION.md | No shared working copies |

### Lifecycle States (9)
NEW -> ACTIVE -> PAUSED/FROZEN/ARCHIVED/DELETED/MIGRATED
+ UNKNOWN_NEEDS_CONFIRMATION, CORRUPT_NEEDS_RECOVERY

### Lifecycle Permission Matrix
| State | Mount | Write | Cleanup | Multi-Agent | Phase Close |
|-------|-------|-------|---------|-------------|-------------|
| ACTIVE | Yes | Yes | PLAN | After confirm | Yes |
| PAUSED | Yes | No | PLAN | No | No |
| FROZEN | Query | No | PLAN+confirm | No | No |
| ARCHIVED | No | No | Confirm | No | No |
| DELETED | No | No | No | No | No |
| MIGRATED | Redirect | No | N/A | N/A | N/A |
| UNKNOWN | No | No | No | No | No |
| CORRUPT | No | No | No | No | No |

### Key Rules
- Destructive transitions (DELETE, ARCHIVE) require user confirmation.
- Lifecycle transitions logged via event log schema.
- Multi-agent only on ACTIVE projects.
- Cleanup scoped to projectId; foreign context blocked.
