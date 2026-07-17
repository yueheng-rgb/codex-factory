# FACTORY-DEFAULT-WORKFLOW-0 — G: Natural Language Cleanup Contract Report

> Phase: FACTORY-DEFAULT-WORKFLOW-0
> Section: G — Natural Language Cleanup Contract
> Date: 2026-06-28

## Deliverables

| File | Path |
|------|------|
| Contract Definition | `factory-workflow/NATURAL_LANGUAGE_CLEANUP_CONTRACT.md` |
| Governance JSON | `governance/factory-workflow/factory-default-workflow-0-natural-language-cleanup-contract.json` |

## Contract Summary

Defines a 4-step safe cleanup protocol:
1. **Interpret** — map natural language to scope
2. **PLAN** — produce cleanup plan (never execute immediately)
3. **Confirm** — require explicit user confirmation
4. **Execute** — only confirmed items

### Safety Tiers
- **NEVER Delete**: project source, CORE_EVIDENCE, user docs, git, secrets
- **Require Confirmation**: Factory state, build artifacts, cache
- **Safe to Auto-Clean** (in plan): stale temp files, orphaned harness outputs

### Key Principle
"删除该项目缓存" must NEVER be interpreted as "delete project source".
