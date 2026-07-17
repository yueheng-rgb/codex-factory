# Project Rules Ecosystem Skill

## Trigger
This skill activates when a project contains rule files beyond AGENTS.md — including `.cursorrules`, `.coderules`, `project-rules.md`, `CONVENTIONS.md`, `.githooks/`, or similar.

## Purpose
Parse and apply project-level rule files that define coding conventions, architecture constraints, and agent behavior boundaries. Extends CAP-SKILL-004 (AGENTS.md) to cover the broader project rules ecosystem.

## Core Rules

### 1. Rule File Discovery
Walk the project directory tree and identify rule files:
- `.cursorrules` — Cursor IDE project rules
- `.coderules` — Generic code rules
- `project-rules.md` — Explicit project rule documentation
- `CONVENTIONS.md` — Coding conventions document
- `.github/workflows/` — CI/CD rules
- `.githooks/` — Git hook rules

### 2. Rule Extraction
Parse each file and extract:
| Category | Pattern | Output |
|----------|---------|--------|
| File naming | `*.tsx`, `*.module.css` patterns | Naming convention rules |
| Directory structure | `src/components/`, `src/pages/` | Directory layout rules |
| Import rules | `import order`, `no default exports` | Import convention rules |
| Type rules | `no any`, `strict null checks` | TypeScript strictness rules |
| CI/CD rules | workflow triggers, required checks | Pipeline rules |
| Git rules | commit message format, branch naming | VCS rules |

### 3. Integration with AGENTS.md
- AGENTS.md (CAP-SKILL-004) has precedence for agent behavior
- Project rule files provide supplementary conventions
- If `.cursorrules` and AGENTS.md conflict on code style, AGENTS.md takes precedence
- Report all conflicts

### 4. Tool Restrictions
- This skill READS project rule files
- This skill does NOT modify rule files
- This skill does NOT enforce rules — it surfaces them to agents

## Output Format
```json
{
  "ruleFilesFound": [".cursorrules", "CONVENTIONS.md"],
  "namingRules": ["Component files: PascalCase.tsx", "Utils: camelCase.ts"],
  "directoryRules": ["Components in src/components/", "Pages in src/pages/"],
  "importRules": ["No default exports", "Type imports separate"],
  "typeRules": ["Strict mode on", "No implicit any"],
  "gitRules": ["Conventional commits", "Feature branches"],
  "ciRules": ["Lint on PR", "Build on push to main"],
  "conflicts": []
}
```
