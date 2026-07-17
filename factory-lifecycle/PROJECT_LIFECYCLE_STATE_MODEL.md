# PROJECT_LIFECYCLE_STATE_MODEL.md

> Part of: FACTORY-PROJECT-LIFECYCLE-0 / B
> Version: 1.0.0

---

## States

### 1. NEW
- **Meaning**: Project identity created, not yet active
- **Default Mount**: No (not mounted)
- **Write**: No
- **Memory Update**: No
- **Cleanup**: No
- **Phase Close**: No
- **Multi-Agent**: No
- **Recovery**: Not applicable
- **Dashboard**: Shows "NEW — awaiting activation"
- **User Confirmation**: Required to transition to ACTIVE

### 2. ACTIVE
- **Meaning**: Fully operational project
- **Default Mount**: Yes
- **Write**: Yes (all scoped paths)
- **Memory Update**: Yes
- **Cleanup**: PLAN only (per cleanup isolation)
- **Phase Close**: Yes
- **Multi-Agent**: Yes (with user confirmation)
- **Recovery**: All recovery levels allowed
- **Dashboard**: Shows full state
- **User Confirmation**: Not needed for normal ops

### 3. PAUSED
- **Meaning**: Temporarily inactive, state preserved
- **Default Mount**: No (must be explicitly activated)
- **Write**: Yes (after explicit mount + confirmation)
- **Memory Update**: No (preserved)
- **Cleanup**: No
- **Phase Close**: No
- **Multi-Agent**: No
- **Recovery**: LEVEL_1 only (auto-repair derived)
- **Dashboard**: Shows "PAUSED" with preserved state
- **User Confirmation**: Required to resume

### 4. FROZEN
- **Meaning**: Read-only protected state
- **Default Mount**: No
- **Write**: No (BLOCKED)
- **Memory Update**: No (BLOCKED)
- **Cleanup**: No (BLOCKED)
- **Phase Close**: No (BLOCKED — attempted close → blocked)
- **Multi-Agent**: No (BLOCKED)
- **Recovery**: Query only; no auto-repair
- **Dashboard**: Shows "FROZEN — read only"
- **User Confirmation**: Required to unfreeze

### 5. ARCHIVED
- **Meaning**: Completed, preserved, not default-mounted
- **Default Mount**: No (manual view only)
- **Write**: No (BLOCKED)
- **Memory Update**: No
- **Cleanup**: No
- **Phase Close**: No
- **Multi-Agent**: No
- **Recovery**: Query only
- **Dashboard**: Shows "ARCHIVED"
- **User Confirmation**: Required to reactivate or delete

### 6. DELETED
- **Meaning**: Marked deleted, identity preserved for audit
- **Default Mount**: No (BLOCKED)
- **Write**: No (BLOCKED)
- **Memory Update**: No (BLOCKED)
- **Cleanup**: Files may be removed per deletion plan (separate protocol)
- **Phase Close**: No (BLOCKED)
- **Multi-Agent**: No (BLOCKED)
- **Recovery**: Restore only via explicit restore plan with confirmation
- **Dashboard**: Shows "DELETED"
- **User Confirmation**: Required for restore

### 7. MIGRATED
- **Meaning**: Moved to new identity; old identity preserved
- **Default Mount**: No (redirect to new identity)
- **Write**: No (BLOCKED on old identity)
- **Memory Update**: No (BLOCKED)
- **Cleanup**: No (old project preserved for audit)
- **Phase Close**: No
- **Multi-Agent**: No
- **Recovery**: Not applicable (old identity)
- **Dashboard**: Shows "MIGRATED → [new projectId]"
- **User Confirmation**: Required to redirect

### 8. UNKNOWN_NEEDS_CONFIRMATION
- **Meaning**: Path exists but identity unconfirmed
- **Default Mount**: No
- **Write**: No (BLOCKED until confirmed)
- **Memory Update**: No (BLOCKED)
- **Cleanup**: No (BLOCKED)
- **Phase Close**: No (BLOCKED)
- **Multi-Agent**: No (BLOCKED)
- **Recovery**: Identity confirmation flow
- **Dashboard**: Shows "UNKNOWN — confirm identity"
- **User Confirmation**: REQUIRED (must confirm or register)

### 9. CORRUPT_NEEDS_RECOVERY
- **Meaning**: State corrupted, recovery required
- **Default Mount**: No (BLOCKED)
- **Write**: No (BLOCKED — except recovery plan writes)
- **Memory Update**: No (BLOCKED)
- **Cleanup**: No (BLOCKED)
- **Phase Close**: No (BLOCKED)
- **Multi-Agent**: No (BLOCKED)
- **Recovery**: Mandatory (RECOVERY_LEVEL_2 or LEVEL_3)
- **Dashboard**: Shows 🔴 "CORRUPT — recovery required"
- **User Confirmation**: Required before any transition
