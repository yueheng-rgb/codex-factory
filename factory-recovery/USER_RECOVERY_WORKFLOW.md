# USER_RECOVERY_WORKFLOW.md

> Part of: FACTORY-RECOVERY-0 / L
> Version: 1.0.0

## Trigger Phrases

| Chinese | English | Action |
|---------|---------|--------|
| "检查这个项目状态" | "check this project status" | Run recovery scan |
| "修复 Factory 状态" | "repair Factory state" | Run scan + auto-fix LEVEL_1 |
| "恢复这个项目" | "recover this project" | Full recovery with plan |
| "重新生成 snapshot" | "regenerate snapshot" | AUTO_REGENERATE_SNAPSHOT |
| "修复外接对话空间" | "repair external conversation space" | Context repair |
| "不要自动修复，只给计划" | "don't auto-repair, just give plan" | Dry-run scan only |
| "确认这是当前项目" | "confirm this is the current project" | USER_CONFIRM_IDENTITY |

## Default Behavior
1. PLAN first — never auto-execute LEVEL_2/3
2. Auto-repair only derived artifacts (LEVEL_1)
3. User confirms identity/migration
4. No destructive cleanup
5. No auto-confirming project identity

## Workflow

### User says "检查这个项目状态"
```
1. Run recovery scan (factory-recovery-scan.ps1)
2. Show recovery level + findings summary
3. If LEVEL_0: "Factory state is healthy."
4. If LEVEL_1: "Minor issues found. Auto-repair?" (y/n)
5. If LEVEL_2/3: "Recovery plan generated. Review?"
```

### User says "修复 Factory 状态"
```
1. Run scan
2. Auto-execute LEVEL_1 repairs
3. For LEVEL_2/3 findings → present plan, ask confirmation
4. Execute confirmed actions
5. Show recovery completion summary
```

### User says "不要自动修复，只给计划"
```
1. Run scan with --DryRun
2. Output recovery plan only (no execution)
3. Show: "Recovery plan saved. Review and run with --Force to execute."
```

## Prompts
- `prompts/recovery-plan.prompt.md` — generates recovery plan from scan
- `prompts/recovery-repair-derived.prompt.md` — repairs derived artifacts
- `prompts/recovery-confirm-identity.prompt.md` — confirms project identity
