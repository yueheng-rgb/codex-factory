# Experimental Status — codex-factory-plugin

## Current Status: EXPERIMENTAL

| Field | Value |
|-------|-------|
| scaffoldStatus | EXPERIMENTAL |
| scaffoldPhase | H19 |
| installabilityTested | DRY26 (structural only) |
| productionReady | NO |
| runtimeTested | NO |
| requiresDRY27 | YES |
| finalZipExists | false |

## Evidence Chain

- **H19**: Scaffold created. Plugin directory structure, plugin.json, skills/, mcp/, automation/ established.
- **DRY26**: Installability structural check — POSITIVE_NEGATIVE_CLOSED. plugin.json valid. Directory conforms.
- **H20**: MCP prototype created. Standalone verifier MCP server.
- **H21**: Automation/monitoring governance. Monitor prototype (MONITORING_PASS). Automation claims bounded.
- **H22**: Packaging boundary defined. Capability claims classified.

## What Would Make This Production-Ready

1. Live Codex plugin install/sideload succeeds
2. Skills auto-load in Codex runtime
3. MCP server starts as plugin sub-component
4. Automation scheduling works in runtime
5. Monitoring runs scheduled and detects drift
6. Cross-project packaging preserves manifest SHA
7. No absolute path dependencies in distribution

## Current Forbidden Claims

- This plugin is NOT production-ready
- Automation does NOT replace verifier
- Monitoring does NOT close phases
- Thread handoff does NOT provide full context inheritance
- No final release ZIP exists

