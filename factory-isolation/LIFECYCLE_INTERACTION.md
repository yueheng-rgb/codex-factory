# LIFECYCLE_INTERACTION.md

> Part of: FACTORY-PROJECT-ISOLATION-0
> Section: J — Lifecycle Interaction
> Version: 1.0.0

---

## Purpose

Define how project status transitions work and what cross-project effects (if any) are allowed when a project's lifecycle state changes.

---

## Status Transition Matrix

| From \ To | ACTIVE | PAUSED | ARCHIVED | FROZEN | DELETED | MIGRATED | UNKNOWN |
|-----------|--------|--------|----------|--------|---------|----------|---------|
| ACTIVE | — | ✅ | ✅ | ✅ | ❌ (gate) | ✅ | ❌ |
| PAUSED | ✅ | — | ✅ | ✅ | ❌ (gate) | ✅ | ❌ |
| ARCHIVED | ✅ | ❌ | — | ✅ | ✅ | ✅ | ❌ |
| FROZEN | ✅ | ❌ | ✅ | — | ✅ | ✅ | ❌ |
| DELETED | ❌ | ❌ | ❌ | ❌ | — | ❌ | ❌ |
| MIGRATED | ❌ | ❌ | ❌ | ❌ | ❌ | — | ❌ |
| UNKNOWN | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | — |

- ✅ = allowed transition
- ❌ = blocked transition
- ❌ (gate) = allowed only through dedicated gated protocol (project deletion)

---

## Transition Effects

### ACTIVE → PAUSED
- Working copy preserved
- Memory flushed to project-specific storage
- Active context cleared
- Other projects unaffected

### ACTIVE → ARCHIVED
- Working copy preserved, read-only
- All state persisted
- Removed from default mount rotation
- Other projects unaffected

### ACTIVE → FROZEN
- Working copy read-only
- All state persisted
- Query allowed, update blocked
- Other projects unaffected

### ACTIVE → DELETED (via gate)
- Triggers PROJECT DELETION protocol (separate phase)
- CORE_EVIDENCE preservation option
- Registry entry retained with DELETED status
- Other projects unaffected

### ACTIVE → MIGRATED
- New project identity created
- Old identity status = MIGRATED
- Old identity points to new (sourceProjectId)
- New identity points to old (parentProjectId)
- Other projects unaffected

### UNKNOWN → ACTIVE
- User confirmation required
- Path fingerprint verified
- Identity fields populated
- Other projects unaffected

---

## Cross-Project Transition Effects

### Rule: No Automatic Cross-Project Effects
```
WHEN project A status changes:
  Project B, C, D... are NOT automatically affected.
  No automatic cleanup, freeze, or status change cascades.
```

### Exception: Parent/Child Relationships
```
WHEN parent project is DELETED:
  Child projects are NOT automatically deleted.
  Child projects retain their own identity.
  parentProjectId becomes a dangling reference (audit trail).

WHEN parent project is FROZEN:
  Child projects are NOT automatically frozen.
```

### Exception: Global Registry Updates
```
WHEN any project status changes:
  Project registry is updated (global, read-only to other projects).
  This is a read of the registry, not a project state change.
```

---

## Lifecycle Audit Trail

Every status transition logs:
```json
{
  "projectId": "uuid",
  "fromStatus": "ACTIVE",
  "toStatus": "ARCHIVED",
  "timestamp": "ISO 8601",
  "reason": "user_requested | phase_complete | migration | deletion",
  "affectedProjects": []
}
```

---

## Anti-Patterns (Blocked)

| Anti-Pattern | Why Blocked |
|-------------|-------------|
| Status change cascades to unrelated projects | Unintended side effects |
| Child project auto-deleted with parent | Loss of independent project data |
| Deleted project revived without gate | Integrity violation |
| Frozen project silently updated | Data corruption |
| Migrated project still accepting writes | Split-brain |
