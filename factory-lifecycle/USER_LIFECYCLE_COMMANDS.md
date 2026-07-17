# USER_LIFECYCLE_COMMANDS.md
> Part of: FACTORY-PROJECT-LIFECYCLE-0 / F

## Commands
| Trigger | Action |
|---------|--------|
| "激活这个项目" / "activate this project" | NEW/PAUSED → ACTIVE (with confirmation) |
| "暂停这个项目" / "pause this project" | ACTIVE → PAUSED |
| "冻结这个项目" / "freeze this project" | ACTIVE → FROZEN (with confirmation) |
| "归档这个项目" / "archive this project" | ACTIVE/PAUSED/FROZEN → ARCHIVED |
| "删除这个项目" / "delete this project" | ACTIVE/ARCHIVED → DELETED (deletion plan + double confirm) |
| "恢复这个项目" / "restore this project" | CORRUPT/UNKNOWN → ACTIVE (after recovery/confirm) |
| "移动到..." / "migrate to..." | ACTIVE → MIGRATED (new identity required) |

## Default Behavior
- Destructive transitions: PLAN first, double confirmation
- All transitions logged to event log
- projectId mandatory in all logs
- User command supports user-intent, not technical validation
