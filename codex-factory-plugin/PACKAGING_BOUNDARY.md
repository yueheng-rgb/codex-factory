# Packaging Boundary — codex-factory-plugin

## Status: EXPERIMENTAL

This plugin is **not production-ready**. It is in experimental scaffold phase.

## What CAN Be Packaged

| Category | Path | Status | Can Package? |
|----------|------|--------|-------------|
| Plugin manifest | .codex-plugin/plugin.json | EXPERIMENTAL | Yes — as reference |
| Skills | skills/ | EXPERIMENTAL | Yes — structural only |
| MCP | mcp/ | EXPERIMENTAL | Yes — prototype only |
| Automation templates | automation/ | EXPERIMENTAL | Yes — design reference |
| PACKAGING_BOUNDARY.md | ./ | EXPERIMENTAL | Yes |
| EXPERIMENTAL_STATUS.md | ./ | EXPERIMENTAL | Yes |
| CLOUD_SYNC_READINESS.md | ./ | EXPERIMENTAL | Yes |
| AUTOMATION_BOUNDARY.md | ./ | EXPERIMENTAL | Yes |
| THREAD_HANDOFF_BOUNDARY.md | ./ | EXPERIMENTAL | Yes |
| PACKAGING_MANIFEST.json | ./ | EXPERIMENTAL | Yes |

## What CANNOT Enter Packaging

- Production-ready claims
- Final release claims
- VERIFIED_FACT claims without runtime evidence
- Automation-as-verifier claims
- Full thread context inheritance claims
- Absolute local paths
- Scoring-system-as-PASS-gate
- Failure-router as runnable core
- Compressed summary as evidence
- Monitoring result as phase closure evidence

## DRY27 Prerequisites

Before this plugin can move from EXPERIMENTAL to STABLE:
1. Live install/sideload test in Codex
2. Cross-project sync validation
3. Runtime automation scheduling test
4. Skill auto-load verification
5. MCP server startup from plugin context
6. Monitoring drift alert in scheduled mode

