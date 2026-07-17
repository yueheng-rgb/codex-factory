# FACTORY-PROJECT-ISOLATION-0 — C: Project Registry Report

> Phase: FACTORY-PROJECT-ISOLATION-0
> Section: C — Project Registry
> Date: 2026-06-29

## Deliverables

| File | Path |
|------|------|
| Registry Doc | `factory-isolation/PROJECT_REGISTRY.md` |
| JSON Schema | `factory-isolation/schemas/project-registry.schema.json` |
| Template | `factory-isolation/templates/project-registry.template.json` |
| Governance JSON | `governance/factory-isolation/factory-project-isolation-0-project-registry.json` |

## Registry Summary

- **Location**: `%USERPROFILE%\.codex-factory\project-registry.json` (global, user-scoped)
- **Structure**: version + updatedAt + projects map + active/last pointers
- **Behaviors**: list, default-active (one), archived/frozen (no auto-mount), deleted (blocked), migrated (redirect), unknown (confirm)
- **Integrity**: no secrets, atomic writes, audit trail
