# FACTORY-PROJECT-ISOLATION-0 — B: Project Identity Model Report

> Phase: FACTORY-PROJECT-ISOLATION-0
> Section: B — Project Identity Model
> Date: 2026-06-29

## Deliverables

| File | Path |
|------|------|
| Identity Model | `factory-isolation/PROJECT_IDENTITY_MODEL.md` |
| JSON Schema | `factory-isolation/schemas/project-identity.schema.json` |
| Governance JSON | `governance/factory-isolation/factory-project-isolation-0-project-identity-model.json` |

## Model Summary

Defines 18 identity fields including:
- **Core identity**: projectId (UUID v4, immutable), projectName, rootPath
- **Path resolution**: workingCopyPath, factoryInstallPath, externalConversationSpacePath
- **Governance paths**: governancePath, outputsPath, agentLedgerPath, cleanupStatePath
- **Lifecycle**: createdAt, lastMountedAt, status (7 values)
- **Provenance**: parentProjectId, sourceProjectId
- **Integrity**: pathFingerprint, contentFingerprint (SHA256)
- **User gate**: userConfirmedIdentity

### Status Lifecycle
ACTIVE ↔ PAUSED → ARCHIVED | FROZEN | DELETED | MIGRATED | UNKNOWN_NEEDS_CONFIRMATION
