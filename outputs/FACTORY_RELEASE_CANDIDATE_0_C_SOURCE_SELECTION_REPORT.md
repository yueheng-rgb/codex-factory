# FACTORY-RELEASE-CANDIDATE-0 — Section C: Source Selection from P8 Staging Report

**Phase:** FACTORY-RELEASE-CANDIDATE-0
**Section:** C
**Generated:** 2026-06-28T20:30:00+08:00
**Status:** COMPLETE

---

## 1. Source Basis

Source selection is based on P8 staging pack definition (`factory-build-pack-staging-p8-manifest-bundle.json`),
which defines the bundle as `codex-factory-core-v0.9.0-pre-P8-STAGING`.
The actual source is the current project state at `C:\Codex_App_Factory`, which includes all P8 integrations
(memory-quality policies, schemas, templates, prompts, cleanup planner, CLI integration, phase close integration).

## 2. Source Verification

| Check | Result |
|---|---|
| P8 verifier PASS exists | YES (45/45) |
| Memory Quality P2 integrated | YES |
| Memory Quality P3 integrated | YES |
| Cleanup planner present | YES (`runtime/scripts/factory-cleanup-planner.ps1`) |
| VERSION flags per P8 | YES (releaseAllowed=false, v05Package=false) |
| memory-quality/ directory exists | YES |
| CLI integration exists | YES |
| Phase close integration exists | YES |

## 3. Selected Source Files by Module

### CORE — Always Included

| Module | Path | Status |
|---|---|---|
| Factory Rules | `AGENTS.md` | CORE |
| Global Rules | `GLOBAL_CODEX_RULES.md` | CORE |
| App Router | `APP_TYPE_ROUTER.md` | CORE |
| Stack Guide | `STACK_DECISION_GUIDE.md` | CORE |
| Resource Pack | `factory-resource-pack/` | CORE |
| Factory CLI | `scripts/factoryctl.ps1` | CORE |
| State Tracking | `governance/factory-state/` | CORE |
| Release Gov | `governance/factory-release/` | CORE |
| Build Gov | `governance/factory-build/` | CORE |
| AB Gov | `governance/factory-ab/` | CORE |
| Memory Gov | `governance/factory-memory/` | CORE |
| Eval Gov | `governance/factory-eval/` | CORE |
| Agent Gov | `governance/factory-agent/` | CORE |
| Context Space | `governance/context-space/` | CORE |
| Contracts | `governance/contracts/` | CORE |
| Diagnosis | `governance/diagnosis/` | CORE |
| Manual Router | `governance/manual-router/` | CORE |
| Memory Quality | `memory-quality/` | CORE |
| Cleanup Planner | `runtime/scripts/factory-cleanup-planner.ps1` | CORE |
| Schemas | `schemas/` | CORE |
| Prompts | `prompts/` | CORE |
| Templates | `templates/` | CORE |
| Blueprints | `blueprints/` | CORE |
| Starters | `starters/` | CORE |
| Skills | `skills/` | CORE |
| Scripts (core) | `scripts/` (excl. monitoring/) | CORE |
| Research | `EXTERNAL_SKILLS_RESEARCH.md` | CORE |

### EXPERIMENTAL — Included with Caveats

| Module | Path | Status |
|---|---|---|
| Plugin | `codex-factory-plugin/` | EXPERIMENTAL |
| MCP | `codex-factory-plugin/mcp/` | EXPERIMENTAL |
| Automation | `codex-factory-plugin/automation/` | EXPERIMENTAL |
| Monitoring | `scripts/monitoring/` | EXPERIMENTAL |

### EXCLUDED — Explicitly Omitted

| Category | Examples |
|---|---|
| Real Projects | `ecommerce_homework/`, `bigdata_homework/`, `habit-tracker-*/`, `tiny-typescript-service/` |
| Working Copies | `fresh-install-target*/`, `i-test-target/`, `harness-control/` |
| Trial/Harness | `runs/`, `trials/`, `harness/`, `blind-test-results/`, `benchmark-results/` |
| Historical | Historical scoring, failure-router |
| Old Packages | `final-package/`, `final-package-dry-run/`, `packages/`, `factory-resource-pack-v0.4-*` |
| Misc Excluded | `node_modules/`, `.codex-factory/`, `external-conversation-space/`, `workspace/` |

## 4. Source Selection Decision

- **Source:** Current project state at `C:\Codex_App_Factory`
- **Basis:** P8 staging pack definition + verifier-confirmed P8 PASS
- **Governed by:** RC_BOUNDARY.md inclusion/exclusion rules
- **Memory Quality:** Confirmed integrated per P8 verifier V005-V009

**Section C verdict: COMPLETE**
