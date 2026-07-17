# USER_REQUIREMENT_ENTRY_CONTRACT.md

> Part of: FACTORY-DEFAULT-WORKFLOW-0
> Section: C — User Requirement Entry Contract
> Version: 1.0.0

---

## Purpose

Define the natural-language phrases and conditions under which Codex should automatically activate Factory mode, without the user needing to paste long instructions or remember specific CLI commands.

---

## Trigger Phrases (Chinese)

When the user says any of the following while a project folder is selected (or immediately after selecting one), Factory mode activates:

| # | Trigger Phrase | Notes |
|---|---------------|-------|
| 1 | "用工厂模式做这个项目" | Explicit Factory request |
| 2 | "使用 Codex Factory 接手" | Explicit Factory takeover |
| 3 | "用 v0.5 做这个项目" | Version-specific trigger |
| 4 | "帮我做这个项目" | General help request when Factory is installed |
| 5 | "接手这个文件夹" | Take over this folder |
| 6 | "做一个 XXX 系统/平台/应用" | Build request with project type keyword |
| 7 | "帮我开发一个..." | Development request |
| 8 | "新建一个项目..." | New project creation |
| 9 | "构建/打包/部署这个项目" | Build/package/deploy request |

## Trigger Phrases (English)

| # | Trigger Phrase | Notes |
|---|---------------|-------|
| 1 | "use Factory mode for this project" | Explicit |
| 2 | "use Codex Factory to take over" | Explicit |
| 3 | "use v0.5 for this project" | Version-specific |
| 4 | "help me build this project" | General |
| 5 | "take over this folder" | Takeover |
| 6 | "build a XXX system/platform/app" | With project type keyword |

## Auto-Detection Conditions

Even without explicit trigger phrases, Factory should activate when:

1. **Factory is installed** (`.codex-factory/` exists) AND user gives a project requirement
2. **AGENTS.md references Factory** in the project tree
3. **Project complexity keywords** are detected: 系统, 平台, 管理, 后台, API, 数据库, 全栈, 前后端, CRUD, 权限, 用户系统

## Expected Default Response

When triggered, Codex should respond with the Factory Boot Summary format:

```
## Factory Boot Summary

**Project Type:** [classified type]
**Complexity:** [simple | moderate | complex | large-fullstack]
**Recommended Architecture:** [stack recommendation]
**Recommended Mode:** Build Lite / Native Build Pro
**Multi-Agent:** [recommended / not recommended]

Shall I proceed with the full design discussion before writing any code?
```

## Non-Trigger Conditions

Factory should NOT activate when:
- User is asking a general question (not a project request)
- User is editing a single file
- User is asking about Factory itself (meta-questions)
- User explicitly says "不用 Factory" or "skip Factory"

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| User gives requirement before folder is selected | Wait for folder selection, then trigger |
| User switches folders mid-requirement | Re-evaluate with new folder context |
| Multiple trigger phrases in one message | Activate once, not multiple times |
| User says "不，等等" after trigger | Pause and wait for clarification |
