# PROJECT_REGISTRY.md

> Part of: FACTORY-PROJECT-ISOLATION-0
> Section: C — Project Registry
> Version: 1.0.0

---

## Purpose

Maintain a registry of all known Factory-managed projects. The registry is the source of truth for which projects exist, their identities, and their lifecycle states.

---

## Registry Location

```
%USERPROFILE%\.codex-factory\project-registry.json
```

Global, user-scoped. Not stored inside any single project.

---

## Registry Schema

See: `factory-isolation/schemas/project-registry.schema.json`

Key structure:
```json
{
  "version": "1.0.0",
  "updatedAt": "ISO 8601",
  "projects": {
    "<projectId>": { ... ProjectIdentity ... }
  },
  "defaultActiveProjectId": "uuid or null",
  "lastSelectedProjectId": "uuid or null"
}
```

---

## Registry Behaviors

### List Known Projects
- All projects with status != DELETED are listed
- DELETED projects are retained for audit but not listed by default

### Default Active Project
- Only ONE project can be `defaultActiveProjectId` at a time
- Set when user explicitly selects a project folder
- Cleared when user closes/disconnects from project

### Archived/Frozen Projects
- NOT default-mounted
- Can be viewed as reference only
- ARCHIVED: no writes allowed
- FROZEN: no writes allowed, query allowed

### Deleted Projects
- NOT mountable
- Identity record retained for audit
- All project-specific paths may be cleaned up (with PLAN + confirmation)

### Migrated Projects
- Status = MIGRATED
- Points to new identity via `sourceProjectId` on the new project
- Mounting attempt → redirect with confirmation

### Unknown Projects
- Path exists but no identity in registry
- Status = UNKNOWN_NEEDS_CONFIRMATION
- User must confirm: "Register this as a new project or claim it as existing?"

---

## Registry Integrity Rules

| Rule | Enforcement |
|------|------------|
| One identity per rootPath (canonical) | Duplicate detection |
| projectId is immutable | Write-once |
| Registry must not contain secrets | Schema validation |
| Audit trail for status changes | Append-only log |
| Atomic writes | Write to temp + rename |

---

## Registry Template

See: `factory-isolation/templates/project-registry.template.json`
