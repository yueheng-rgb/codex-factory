# RC Boundary — Release Candidate 0

## Identity
- **Name:** codex-factory-core-v0.9.0-pre-RC0
- **Type:** RELEASE_CANDIDATE
- **Not:** release, v0.5, production artifact

## Boundary Rules

### Inclusion Boundary
Source: P8 staging pack definition + current project state (post P8 memory-quality integration).

CORE modules (included):
- `AGENTS.md`, `GLOBAL_CODEX_RULES.md`, `APP_TYPE_ROUTER.md`, `STACK_DECISION_GUIDE.md`
- `factory-resource-pack/` (CORE, portable resource distribution)
- `scripts/factoryctl.ps1` (CORE, Factory CLI)
- `governance/factory-state/` (CORE, state tracking)
- `governance/factory-release/` (CORE, release governance)
- `governance/factory-build/` (CORE, build governance)
- `governance/factory-ab/` (CORE, AB trial governance)
- `governance/factory-memory/` (CORE, memory governance)
- `governance/factory-eval/` (CORE, evaluation governance)
- `governance/factory-agent/` (CORE, agent governance)
- `governance/context-space/` (CORE, context space policies)
- `governance/contracts/` (CORE, contract enforcement)
- `governance/diagnosis/` (CORE, diagnosis records)
- `governance/manual-router/` (CORE, manual routing)
- `memory-quality/policies/` (CORE, memory quality policies)
- `memory-quality/schemas/` (CORE, memory quality schemas)
- `memory-quality/templates/` (CORE, memory quality templates)
- `memory-quality/prompts/` (CORE, memory quality prompts)
- `runtime/scripts/factory-cleanup-planner.ps1` (CORE, cleanup planner)
- `schemas/` (CORE, schema definitions)
- `prompts/` (CORE, prompt templates)
- `templates/` (CORE, templates)
- `blueprints/` (CORE, design blueprints)
- `starters/` (CORE, starter templates)
- `skills/` (CORE, skills)
- `scripts/` (CORE, scripts excluding monitoring/)
- `EXTERNAL_SKILLS_RESEARCH.md` (CORE)

EXPERIMENTAL modules (included with caveats):
- `codex-factory-plugin/` (EXPERIMENTAL, development preview)
- `codex-factory-plugin/mcp/` (EXPERIMENTAL, prototype reference)
- `codex-factory-plugin/automation/` (EXPERIMENTAL, design reference)
- `scripts/monitoring/` (EXPERIMENTAL, prototype reference)

EXCLUDED:
- All real projects
- All working copies
- All trial/harness/run artifacts
- All historical scoring/failure-router
- All old student packages

### Version Boundary
- RC version: `0.9.0-pre-rc0`
- Underlying staging: `0.9.0-pre` (from P8)
- Not: `0.5.0`, `1.0.0`, `v0.5`

### Release Boundary
- RC is a candidate, not a release
- releaseAllowed = false
- v05Package = false
- finalRelease = false
- rcCandidate = true
- v0.5 remains BLOCKED

## Session Rotation
- RC creation is a major phase → session rotation recommended after completion
- RC extraction smoke creates clean target directories
- No auto-window triggers
- No full-context-inheritance across RC boundary
