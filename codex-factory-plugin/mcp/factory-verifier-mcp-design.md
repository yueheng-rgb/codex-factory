# MCP Factory Verifier — Feasibility Design

**Phase**: H19-D
**Status**: Feasibility scaffold (not production)

## Overview

Expose `factoryctl verify --json` and `validate-resource-pack` as MCP tools
for programmatic factory state verification from any Codex instance.

## Architecture

```
Codex → MCP Protocol → factory-verifier MCP Server
                              ├── tool: factoryctl_verify
                              ├── tool: validate_resource_pack
                              └── tool: validate_handoff
```

## Tools

### 1. factoryctl_verify
- **Input**: `phase` (string, default: "latest")
- **Output**: `{ verdict, totalChecks, modules[], checkedAt }`
- **Equivalent**: `powershell -File factoryctl.ps1 verify --json`

### 2. validate_resource_pack
- **Input**: `packPath` (string, required)
- **Output**: `{ overallVerdict, totalChecks, failureCount, checks[] }`
- **Equivalent**: `powershell -File validate-resource-pack.ps1`

### 3. validate_handoff
- **Input**: `handoffPath` (string, default: "governance/factory-state/session-rotation-handoff.json")
- **Output**: `{ verdict, checks[], sourceEvidenceHashes }`
- **Equivalent**: `powershell -File check-handoff-integrity.ps1 -Json`

## Safety Rules

1. MCP output must remain machine-readable — no conversion to markdown PASS
2. MCP tool FAIL must not be converted to markdown PASS
3. MCP wrapper must not replace verifier scripts — they remain the authoritative source
4. MCP tool output must include the raw verifier JSON verbatim
5. Scoring system prohibition applies to MCP tools

## Feasibility Assessment

| Factor | Status | Note |
|---|---|---|
| MCP protocol support | VERIFIED | node_repl MCP active |
| JSON input/output | VERIFIED | All factory tools already output JSON |
| PowerShell bridge | PARTIALLY_VERIFIED | MCP servers typically Node/Python; PowerShell bridge needs testing |
| Machine-readable output | VERIFIED | factoryctl verify --json is machine-readable |
| Readonly safety | VERIFIED | All verifier tools are readonly |

## Recommendation

**Feasible.** Build full MCP server in H20 after install/portability test.
Do not use MCP wrapper to replace direct verifier script invocation in this phase.
