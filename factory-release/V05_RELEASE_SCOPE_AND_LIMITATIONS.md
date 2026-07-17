# V0.5 Release Scope and Limitations

## What v0.5 IS
- **Local workflow/tooling release** of Codex App Factory
- Contains: Factory rules, app type router, stack decision guide, blueprints, starters, skills, prompts, governance infrastructure, memory quality, cleanup planner, CLI, verifier framework, Package QA Gate, Security/Deploy Gate, Context Space
- Built with Build Lite (default)
- Includes `.env.example` templates in starter projects (NOT real secrets)

## What v0.5 IS NOT
- NOT a production deployment tool
- NOT a cloud service or SaaS platform
- NOT proof of universal Factory superiority over vanilla Codex
- NOT a production-ready application platform
- NOT a replacement for production security/DevOps tooling
- NOT a secret rotation or credential management tool

## Limitations
1. Factory advantage is STRONG_PARTIAL — supported for tested tasks (+25 delta on AB-1), NOT universally proven
2. No production deployment validation has been performed
3. Local tool readiness does not equal production readiness
4. Gates, memory quality, and cleanup are policy-verified; full end-to-end live execution in production environments has not been tested
5. User is responsible for secret rotation, production actions, and server configuration

## Package Contents
- 18 modules (blueprints, codex-factory-plugin, factory-ab, factory-build-mode, factory-context-space, factory-diagnostic-pack, factory-release, factory-resource-pack, governance, outputs, prompts, runnable-starters, schemas, scripts, skills, src, starters, templates)
- 7 root documentation files
- Total: ~2,755 files, ~3.2 MB compressed

## Installation
1. Extract the ZIP to a clean directory
2. Run `Get-Help .\scripts\factoryctl.ps1` to see available commands
3. Run `.\scripts\factoryctl.ps1 status` to see current state

## Version History
- v0.5.0: Initial local tooling release (2026-06-28)
