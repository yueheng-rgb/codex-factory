# USER-HANDOFF-R1 — E: Usage Quickstart

## Default Flow

1. **Select project folder** containing Codex Factory
2. **State your requirement** — e.g., "build a fullstack admin dashboard"
3. **Factory auto-starts:** Bootstrap → Router → Preflight → Text Discussion
4. **No code is written** until design is confirmed

## Multi-Agent Decision
For **large/complex projects**, Factory asks:
> "This project triggers the multi-agent question. Choose:
> 1. Build Lite (single agent, recommended for simple tasks)
> 2. Multi-Agent Build Pro (requires confirmation)
> 3. Build Lite first, escalate later"

- Multi-agent **never auto-starts** — you must confirm
- Build Lite remains the safe default

## Cleanup
Say **"delete this project cache"** → Factory generates a **cleanup PLAN**
- No files are deleted without your confirmation
- Cleanup is scoped to the current project only

## Final Handoff
Every completed project handoff includes:
- Full file paths (no omissions)
- projectId reference
- Phase close record

## Key Commands
| User Need | Command/Phrase |
|-----------|---------------|
| Check project state | `factory state --brief` |
| See agent activity | `factory state --agents` |
| Scan for issues | `factory recover --dry-run` |
| Validate evidence | `factory evidence check` |
| Plan cleanup | `factory cleanup plan` |
| Check lifecycle | `factory lifecycle` |
