# WORKING_COPY_ISOLATION.md

> Part of: FACTORY-PROJECT-ISOLATION-0
> Section: I — Working Copy Isolation
> Version: 1.0.0

---

## Purpose

Ensure that working copies (temporary edit areas, build staging, parallel development branches) are scoped per project and never shared across project boundaries.

---

## Working Copy Model

Each project may have:
- **Primary working copy**: the active edit area (typically the project root itself)
- **Parallel working copies**: temporary branches for experimentation, multi-agent work, or build staging

---

## Isolation Rules

### Rule 1: Working Copy Scoped to Project
```
All working copies MUST be under the project's root path or a designated
project-specific working directory.

IF workingCopyPath is outside project.rootPath
   AND not explicitly linked in project identity
THEN REJECT: "Working copy path outside project boundary."
```

### Rule 2: No Shared Working Copies Across Projects
```
IF two projects reference the same workingCopyPath
THEN REJECT the second registration
   "Path [X] is already a working copy for project [A].
    Cannot also be a working copy for project [B]."
```

### Rule 3: Working Copy Lifecycle
```
Working copies follow project lifecycle:
- ACTIVE project → working copy writable
- PAUSED project → working copy preserved, optionally frozen
- ARCHIVED project → working copy preserved, read-only
- FROZEN project → working copy read-only
- DELETED project → working copy included in deletion PLAN
- MIGRATED project → working copy path updated in new identity
```

### Rule 4: Multi-Agent Working Copies
```
IF multi-agent mode is active:
  Each agent gets a DISJOINT working copy sub-path
  Agent A: {project.rootPath}/.factory-working/agent-{id}/
  Agent B: {project.rootPath}/.factory-working/agent-{id}/

  Agents MUST NOT write to each other's working copies
  Integrator merges from agent working copies to primary
```

### Rule 5: Working Copy Cleanup
```
Working copy cleanup follows project cleanup isolation:
- Cleanup scoped to project's working copies only
- Cross-project working copy cleanup REJECTED
- Multi-agent working copies cleaned up after integration
```

---

## Working Copy Registry

Each project's identity stores its working copy paths:
```json
{
  "workingCopyPath": "C:\\project-a\\",
  "parallelWorkingCopies": [
    "C:\\project-a\\.factory-working\\agent-abc123\\",
    "C:\\project-a\\.factory-working\\agent-def456\\"
  ]
}
```

---

## Anti-Patterns (Blocked)

| Anti-Pattern | Why Blocked |
|-------------|-------------|
| Working copy shared across projects silently | Cross-project mutation |
| Agent writes to another agent's working copy | Merge conflicts, attribution loss |
| Working copy orphaned after project deletion | Path leak |
| Working copy outside project boundary | Scope violation |
