# User Cleanup Workflow

## Safety First

- **Default mode is PLAN** — preview only, no changes
- **DELETE requires 2 steps:** PLAN preview → review → re-run with --Confirm
- **CORE_EVIDENCE preserved** unless --ForceEvidence flag used
- **Real project files never touched** by Context Space cleanup

## Cleanup Modes

| Mode | Effect | Reversible |
|------|--------|:---:|
| PLAN | Preview what would happen | N/A |
| ARCHIVE | Prune cache, preserve evidence, disable mount | ✅ |
| FREEZE | Preserve all, disable mount | ✅ |
| PRUNE | Remove cache + stale + duplicates | ❌ (cache only) |
| DELETE | Full removal (2-step confirm) | ❌ |

## User Commands

- "只列出外接对话空间占用，不删除"
- "冻结这个项目，不再默认挂载"
- "归档这个项目，但保留证据"
- "裁剪旧快照和临时缓存"
- "删除这个项目外接对话空间，先给我计划"

## After Cleanup

All operations generate a report:
- What was kept (category + reason)
- What was deleted (category + reason)
- Size reclaimed
- Warnings and caveats
- Whether operation is reversible
