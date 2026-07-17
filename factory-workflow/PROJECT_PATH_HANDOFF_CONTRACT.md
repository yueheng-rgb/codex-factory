# PROJECT_PATH_HANDOFF_CONTRACT.md

> Part of: FACTORY-DEFAULT-WORKFLOW-0
> Section: F — Project Path Handoff Contract
> Version: 1.0.0

---

## Purpose

Define what file paths MUST be output at project completion (handoff) to ensure the user can find, verify, and use all deliverables without guessing.

---

## Mandatory Path Categories

At every project handoff, the following paths MUST be included:

### 1. Project Root
- Absolute path to the project root directory

### 2. Source Code
- All source directories and key entry points
- Format: `src/`, `src/index.ts`, `src/main.py`, etc.

### 3. Configuration Files
- `package.json` / `requirements.txt` / `Cargo.toml` / etc.
- Environment configuration (`*.env.example`, not secrets)
- Build configuration

### 4. Database Artifacts
- Migration files
- Schema definition files
- Seed data files (if any)

### 5. Documentation
- `README.md`
- Any generated design docs
- API documentation

### 6. Build / Run Artifacts
- Build output directory
- How to run (command)
- Test results (if generated)

### 7. Governance / Factory Artifacts
- Phase reports
- Strategy decisions
- Verification results
- Agent ledger (if multi-agent was used)

---

## Path Format Requirements

| Rule | Example |
|------|---------|
| Always use absolute paths | `C:\project\src\index.ts` |
| No relative paths unless scoped to project root | `src/index.ts` is acceptable when root is stated |
| No URIs (`file://`, `vscode://`) | ❌ |
| One path per line in lists | ✅ |
| Group by category | ✅ |

---

## UNKNOWN Paths

If a path exists but its exact location is unknown at handoff time:

| Instead of | Use |
|-----------|-----|
| Omitting the path | `UNKNOWN_WITH_REASON: <reason>` |
| Guessing | `UNKNOWN_WITH_REASON: <reason>` |
| Saying "check the folder" | `UNKNOWN_WITH_REASON: <reason>` |

---

## Handoff Template

```
## Project Handoff — [Project Name]

**Root:** [absolute path]

### Source Code
- [absolute path 1]
- [absolute path 2]

### Configuration
- [absolute path 3]

### Database
- [absolute path 4]

### Documentation
- [absolute path 5]

### How to Run
[command]

### Factory Artifacts
- [absolute path 6]

### Known Gaps
- UNKNOWN_WITH_REASON: [explanation]
```

## Anti-Patterns (Blocked)

| Anti-Pattern | Why Blocked |
|-------------|-------------|
| "Check the output folder" | User cannot find deliverables |
| Omitting a path category entirely | Incomplete handoff |
| Relative paths without root context | Ambiguous |
| Guessing paths | UNKNOWN_WITH_REASON is required |
| Omitting UNKNOWN paths silently | User assumes everything is delivered |
