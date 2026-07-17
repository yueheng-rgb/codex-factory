# AGENTS.md Ecosystem Skill

## Trigger
This skill activates when working in a project that contains `AGENTS.md` files at any directory level. It applies to agents involved in project analysis, architecture, implementation planning, and contract generation.

## Purpose
Parse and apply AGENTS.md instructions from a project's directory tree. AGENTS.md files provide scoped rules for agents — build commands, coding conventions, security boundaries, handoff requirements, and architectural constraints.

## Core Rules

### 1. AGENTS.md Discovery
Walk the project directory tree from root to leaves. Collect all `AGENTS.md` files. Record their directory paths to establish rule scopes. The root-level AGENTS.md has the widest scope; nested AGENTS.md files override parent rules within their subtree.

### 2. Content Extraction
Parse each AGENTS.md and extract:

| Category | Pattern | Output |
|----------|---------|--------|
| Build commands | ``` `npm run build` ```, `make`, `cargo build` | Array of build commands with source file and line |
| Test commands | `npm test`, `pytest`, `go test` | Array of test commands with source file and line |
| Lint commands | `eslint`, `ruff`, `clippy` | Array of lint commands with source file and line |
| Security boundaries | "do not commit", "must validate", "must hash", "never expose" | Array of security rules with source file |
| Coding conventions | naming, formatting, architecture rules | Array of convention rules with source file |
| Handoff requirements | handoff format, required fields | Handoff specification map |

### 3. Scope Resolution
When two AGENTS.md files conflict on the same rule:
- More-deeply-nested AGENTS.md takes precedence
- Report the conflict as a `scopeConflict` warning
- Do NOT silently merge or resolve — surface to the human

### 4. Contract Input Generation
Translate extracted AGENTS.md rules into contract fragments:
- Build/test/lint commands → Project Intent Contract (PIC) inputs
- Architecture rules → Architecture Contract (AC) inputs
- Security boundaries → Security boundary for all contracts
- Directory scope rules → Feature Contract (FC) scope annotations

### 5. User Instruction Priority
AGENTS.md rules are advisory, NOT absolute authority:
- If current user instructions contradict an AGENTS.md rule, **flag the conflict** — do not follow AGENTS.md silently
- If AGENTS.md says "use TypeScript strict" and the user says "use plain JavaScript", generate: `CONFLICT: AGENTS.md requires TypeScript strict, user requests JavaScript — escalate to human`
- Never override explicit user instructions with AGENTS.md defaults

### 6. Tool Restrictions
- This skill may READ AGENTS.md files and EXTRACT structured information
- This skill may NOT execute build/test/lint commands from AGENTS.md
- This skill may NOT modify AGENTS.md files
- This skill may NOT write project files based on AGENTS.md content
- Execution of extracted commands is reserved for IMPL and VER agents under separate permission

## Output Format

```json
{
  "agentsMdSummary": {
    "filesFound": ["/AGENTS.md", "/src/api/AGENTS.md"],
    "totalRules": 15,
    "scopeConflicts": 0
  },
  "buildCommands": [
    { "command": "npm run build", "source": "/AGENTS.md", "line": 42 }
  ],
  "testCommands": [
    { "command": "npm test", "source": "/AGENTS.md", "line": 45 }
  ],
  "lintCommands": [
    { "command": "eslint src/", "source": "/AGENTS.md", "line": 48 }
  ],
  "securityBoundaries": [
    { "rule": "All API routes must validate JWT", "source": "/src/api/AGENTS.md" }
  ],
  "conventions": [
    { "rule": "Use kebab-case for filenames", "source": "/AGENTS.md" }
  ],
  "directoryRules": {
    "/": { "scope": "global", "rules": ["kebab-case filenames", "TypeScript strict"] },
    "/src/api/": { "scope": "api-layer", "rules": ["JWT validation", "rate limiting"] }
  },
  "contractInputs": {
    "pic": ["build: npm run build", "test: npm test"],
    "ac": ["TypeScript strict mode", "kebab-case naming"],
    "security": ["JWT validation on all API routes"]
  },
  "conflictWarnings": [],
  "caveats": [
    "AGENTS.md rules are advisory — user instructions take precedence",
    "Command extraction is pattern-based — verify commands before execution"
  ]
}
```

## Example: Fixture AGENTS.md

```markdown
# AGENTS.md

## Build
Run `npm run build` to compile.

## Test
Run `npm test` for all tests.

## Lint
Run `eslint src/` before committing.

## Security
- Do not commit .env files
- All API routes must validate JWT

## Conventions
- Use kebab-case for filenames
- Component files in src/components/
- API handlers in src/api/

## Handoff
- Implementer must handoff to Verifier with build PASS evidence
```

Expected extraction: 3 commands (build/test/lint), 2 security rules, 2 conventions, 2 directory patterns, 1 handoff rule.
