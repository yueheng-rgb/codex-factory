# Factory Memory MCP Server

**Status**: PROTOTYPE_LOCAL_ONLY — not production-ready
**Phase**: LIVE-RUNTIME-4

## Tools

| Tool | Description |
|------|-------------|
| factory.memory.currentState | Current factory state from Context OS |
| factory.memory.search | Query memory by type/phase/confidence |
| factory.memory.openRisks | Active risks + rejected claims |
| factory.memory.buildStartupPacket | Build startup packet for new windows |
| factory.memory.validate | Validate memory index integrity |
| factory.verify | Run factoryctl verify |

## Rules

- Output is machine-readable JSON
- FAIL remains FAIL — never converted to PASS
- Never mutates governance state
- Never marks phase PASS
- Evidence paths always included
- Configurable repo path — no hardcoded absolutes
- Compressed summary never returned as evidence

## Architecture

MCP Memory Server wraps Context OS scripts:
- query-memory.ps1 → factory.memory.search
- validate-context-memory.ps1 → factory.memory.validate
- build-context-packet.ps1 → factory.memory.buildStartupPacket
- FACTORY_CURRENT_CONTEXT_PACKET.json → factory.memory.currentState
- factoryctl.ps1 verify -Json → factory.verify

## Requirements

- PowerShell 5.1+
- Context OS memory index populated (LIVE-RUNTIME-3)
- Agent OS event bus (LIVE-RUNTIME-2)
- Factory repo path configured via FACTORY_REPO env var or -RepoPath parameter
