# V0.5-RELEASE-CREATION-0 — Section G: Release Notes and User Guide

**Phase:** V0.5-RELEASE-CREATION-0 | **Section:** G | **Status:** COMPLETE

## Release Notes — Codex App Factory v0.5.0

### Overview
v0.5.0 is the first local tooling release of Codex App Factory.
It provides a structured workflow for building projects with Codex,
including project type routing, architecture decision guidance,
blueprints, starters, skills, governance infrastructure, memory quality,
cleanup, and verification tooling.

### What's Included
- Factory bootstrap rules (AGENTS.md, APP_TYPE_ROUTER.md, STACK_DECISION_GUIDE.md)
- 7 blueprints + 7 starters + 9 skills + 6 prompts
- Factory CLI (scripts/factoryctl.ps1): status, agents, watch, verify
- Memory Quality: minimal ingestion + Socratic Gate + retention cleanup
- Cleanup Planner: PLAN/ARCHIVE/FREEZE/PRUNE/DELETE modes
- Package QA Gate, Security/Deploy Gate, Context Space
- Governance infrastructure: state tracking, verifier framework, phase management
- Runnable starters: next-fullstack-admin, next-saas-ai-tool, node-api-postgres, vite-react-content-site, vite-threejs-interactive

### What's NOT Included
- Production deployment capability (out of scope)
- Native Build Pro (conditional, not activated)
- Real projects, secrets, or working copies
- Universal Factory superiority proof (supported for tested tasks only)

### Quick Start
```powershell
Expand-Archive -Path codex-factory-core-v0.5.0.zip -DestinationPath .\factory
cd .\factory
Get-Help .\scripts\factoryctl.ps1
.\scripts\factoryctl.ps1 status
```

### Limitations
See `factory-release/V05_RELEASE_SCOPE_AND_LIMITATIONS.md` for full scope.

**Section G verdict: COMPLETE**
