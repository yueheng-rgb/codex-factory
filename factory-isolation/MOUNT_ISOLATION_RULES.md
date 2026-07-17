# MOUNT_ISOLATION_RULES.md

> Part of: FACTORY-PROJECT-ISOLATION-0
> Section: D — Mount Isolation Rules
> Version: 1.0.0

---

## Purpose

Define what can and cannot be mounted (loaded into active context) when a project is selected. Prevent one project's artifacts from being silently mounted into another project's context.

---

## Mountable Artifacts (Per Project)

| Artifact | Mount Rule | Cross-Project |
|----------|-----------|---------------|
| Source code | Current projectId only | Blocked |
| Phase ledger | Current projectId only | Blocked |
| Risk records | Current projectId only | FOREIGN_PROJECT_CONTEXT |
| Blocker records | Current projectId only | FOREIGN_PROJECT_CONTEXT |
| Agent ledger | Current projectId only | Blocked |
| Cleanup state | Current projectId only | Blocked |
| Working copy | Current projectId only | Blocked |
| External conversation space | Current projectId only | Blocked |
| Snapshot | Must match projectId + pathFingerprint | Blocked |
| Attach Packet | Must match projectId + pathFingerprint | Blocked |
| Verifier results | Current projectId only | Blocked |

## Cross-Project Artifacts (Global)

| Artifact | Mount Rule |
|----------|-----------|
| Global user preferences | Always mountable |
| Global policy (e.g., anti-overengineering rules) | Always mountable |
| Factory version/config | Always mountable |
| Project registry | Always readable |
| Skill definitions | Always mountable |

---

## Mount Validation Rules

### Rule 1: Attach Packet Validation
```
IF attachPacket.projectId != currentProject.projectId
   OR attachPacket.pathFingerprint != currentProject.pathFingerprint
THEN REJECT: "Attach packet belongs to a different project."
```

### Rule 2: Snapshot Validation
```
IF snapshot.projectId != currentProject.projectId
THEN REJECT: "Snapshot belongs to a different project."
```

### Rule 3: Phase Ledger Validation
```
IF phaseLedger.projectId != currentProject.projectId
THEN REJECT: "Phase ledger belongs to a different project."
```

### Rule 4: Foreign Context Marking
```
IF artifact.projectId != currentProject.projectId
   AND artifact.type IN (risk, blocker)
THEN ACCEPT but MARK as FOREIGN_PROJECT_CONTEXT
   "This risk/blocker is from project [name]. Viewing as reference only."
```

### Rule 5: Foreign Context Usage
- FOREIGN_PROJECT_CONTEXT artifacts can be **viewed** as reference
- FOREIGN_PROJECT_CONTEXT artifacts **cannot** be mounted as current state
- FOREIGN_PROJECT_CONTEXT artifacts **cannot** block current project actions
- FOREIGN_PROJECT_CONTEXT artifacts **cannot** be modified

---

## Mount Gate Sequence

When user selects a project:

1. Resolve rootPath → canonical path
2. Look up pathFingerprint in registry
3. If not found → UNKNOWN_NEEDS_CONFIRMATION
4. If found but status is ARCHIVED/FROZEN/DELETED/MIGRATED → apply status rules
5. If found and ACTIVE/PAUSED → validate all mountable artifacts
6. Run mount validation for snaps/attachments/phase-ledgers
7. Mark any foreign context as FOREIGN_PROJECT_CONTEXT
8. Confirm mount to user

---

## Anti-Patterns (Blocked)

| Anti-Pattern | Why Blocked |
|-------------|-------------|
| Foreign attach packet silently mounted | Context contamination |
| Foreign snapshot treated as current state | Wrong project state |
| Foreign phase ledger merged into current | Phase confusion |
| Foreign risk/blocker blocks current project | Incorrect blocking |
| Foreign context editable | Cross-project mutation |
