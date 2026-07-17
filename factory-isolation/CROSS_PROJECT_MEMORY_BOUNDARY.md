# CROSS_PROJECT_MEMORY_BOUNDARY.md

> Part of: FACTORY-PROJECT-ISOLATION-0
> Section: E — Cross-Project Memory Boundary
> Version: 1.0.0

---

## Purpose

Define what memory/context is scoped to a project versus what is global/user-scoped. Prevent project-specific context from leaking into another project's active memory.

---

## Memory Categories

### Project-Scoped (Never Transfer)

| Memory Type | Scope | Transfer Rule |
|------------|-------|---------------|
| Phase history | projectId | Never transfer |
| Phase reports | projectId | Never transfer |
| Agent ledger entries | projectId | Never transfer |
| Build outputs | projectId | Never transfer |
| Risk records | projectId | Never transfer by default |
| Blocker records | projectId | Never transfer by default |
| Cleanup state | projectId | Never transfer |
| External conversation space | projectId | Never transfer |
| Working copy diffs | projectId | Never transfer |
| Snapshot contents | projectId | Never transfer |
| Attach packet contents | projectId | Never transfer |
| Project-specific config | projectId | Never transfer |

### Global-Scoped (Always Transfer)

| Memory Type | Scope | Transfer Rule |
|------------|-------|---------------|
| User preferences | Global | Always transfer |
| Factory version | Global | Always transfer |
| Global policies (anti-overengineering, etc.) | Global | Always transfer |
| Skill definitions | Global | Always transfer |
| CLI name registry | Global | Always transfer |
| Project registry | Global | Always transfer (read) |

### Conditionally Transferable

| Memory Type | Scope | Transfer Rule |
|------------|-------|---------------|
| Risk patterns (anonymized) | Global (opt-in) | Transfer only if user opts in |
| Blocker patterns (anonymized) | Global (opt-in) | Transfer only if user opts in |
| Build mode preferences | User | Transfer (user preference) |
| Multi-agent preferences | User | Transfer (user preference) |

---

## Memory Boundary Enforcement

### On Project Switch
1. Flush project-scoped memory to project-specific storage
2. Clear active context of all project-scoped items
3. Load new project's project-scoped memory
4. Preserve global-scoped memory
5. Mark any foreign references detected in loaded memory

### On Cross-Project Reference Detection
```
IF loaded artifact references a different projectId
THEN mark as FOREIGN_REFERENCE
   AND log warning
   AND do NOT mount as active state
```

### On Memory Persistence
- Project-scoped memory persists only in project-specific paths
- Global-scoped memory persists in `%USERPROFILE%\.codex-factory\`
- Never persist project-scoped memory in global paths

---

## Anti-Patterns (Blocked)

| Anti-Pattern | Why Blocked |
|-------------|-------------|
| Phase history from Project A visible in Project B | Context leak |
| Agent ledger from Project A queried from Project B | Attribution confusion |
| Risk from Project A blocks Project B | Incorrect blocking |
| Cleanup state from Project A affects Project B | Wrong project cleanup |
| Snapshot from Project A restored in Project B | Data corruption |
