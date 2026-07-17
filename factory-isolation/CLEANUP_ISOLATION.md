# CLEANUP_ISOLATION.md

> Part of: FACTORY-PROJECT-ISOLATION-0
> Section: G — Cleanup Isolation
> Version: 1.0.0

---

## Purpose

Ensure that cleanup operations (triggered by natural language or CLI) are strictly scoped to the current project and never affect other projects' data.

---

## Cleanup Isolation Rules

### Rule 1: Resolve Project Identity First
```
BEFORE any cleanup action:
1. Resolve current projectId from active mount
2. Confirm project identity with user
3. Show: "Cleanup target: [projectName] ([projectId])"
4. Only proceed after user confirmation
```

### Rule 2: Scope All Paths to Project
```
All cleanup paths MUST be under one of:
- project.rootPath
- project.factoryInstallPath (within rootPath)
- project.externalConversationSpacePath
- project.governancePath
- project.outputsPath

Paths OUTSIDE the project tree:
- REJECT unless explicitly confirmed by user
- Never auto-include in cleanup plan
```

### Rule 3: Never Cross Project Boundaries
```
IF cleanupPlan contains paths from another project
THEN REJECT those paths
   AND warn: "Path [X] belongs to project [Y], not [currentProject]."
   AND remove from plan
```

### Rule 4: Global Cache Requires Separate Scope
```
IF user says "删除该项目缓存"
THEN scope = project-specific cache only
   NOT global Factory cache
   NOT other project caches

IF user says "清除所有 Factory 缓存"
THEN scope = all projects (requires escalated confirmation)
   List ALL affected projects
   Require double confirmation
```

### Rule 5: Project Deletion is Separately Gated
```
IF user says "删除这个项目"
THEN this is PROJECT DELETION, not cleanup
   Trigger PROJECT DELETION protocol (separate phase)
   Requires:
   - Explicit project name confirmation
   - Listing of all artifacts to be removed
   - CORE_EVIDENCE preservation option
   - Double confirmation
```

---

## Cleanup State Per Project

Each project maintains its own cleanup state:
```json
{
  "projectId": "uuid",
  "lastCleanupPlan": { ... },
  "lastCleanupExecuted": "ISO 8601 or null",
  "pendingCleanupPlan": { ... } or null,
  "cacheSizeBytes": 0,
  "cleanupHistory": [ ... ]
}
```

Stored at: `{project.governancePath}/cleanup-state.json`

---

## Anti-Patterns (Blocked)

| Anti-Pattern | Why Blocked |
|-------------|-------------|
| Cleanup deletes files from wrong project | Cross-project damage |
| "删除该项目缓存" clears global cache | Scope error |
| Cleanup plan includes foreign project paths | Boundary violation |
| Project deletion triggered by cleanup phrase | Escalation required |
| Cleanup state from Project A affects Project B | State leak |
