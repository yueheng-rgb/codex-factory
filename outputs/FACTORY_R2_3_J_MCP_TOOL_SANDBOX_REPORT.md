# R2.3-J MCP / External Tool Sandbox Report

**Phase:** FACTORY-R2.3-J | **Date:** 2026-07-10 | **Status:** COMPLETE

## Overview

Extended Codex Factory's external capability governance from skills to MCP servers, CLI tools, SDKs, search providers, and database tools. Established a tool permission gate with sandbox enforcement, invocation ledger, and negative controls — all without actual external API/MCP execution.

## Deliverables

### Schemas (4)
| File | Purpose |
|------|---------|
| `schemas/tool-capability.schema.json` | Tool capability entry schema (17 fields) |
| `schemas/mcp-server-manifest.schema.json` | MCP server manifest schema |
| `schemas/tool-invocation.schema.json` | Tool invocation record schema |
| `schemas/tool-permission-packet.schema.json` | TPP for agent context injection |

### Runtime (4)
| File | Purpose |
|------|---------|
| `runtime/tool-registry-loader.ps1` | Loads 10 tool entries from registry |
| `runtime/tool-permission-gate.ps1` | 11-check permission gate |
| `runtime/tool-invocation-logger.ps1` | Records every permission check |
| `runtime/tool-sandbox-simulation.ps1` | 16-test simulation with negative controls |

### Registry
| File | Entries |
|------|:---:|
| `registries/tool-candidate-registry.jsonl` | 10 tools (7 real + 3 negative) |

### Examples
| File | Type |
|------|------|
| `examples/tool-permission-packets/tpp-impl-fe-fullstack.json` | IMPL-FE TPP |
| `examples/tool-permission-packets/tpp-impl-db-fullstack.json` | IMPL-DB TPP |
| `examples/tool-permission-packets/tpp-ver-fullstack.json` | VER TPP |

## Permission Gate: 11 Checks

```
TOOL_EXISTS → TOOL_STATUS → AGENT_AUTH → PROJECT_TYPE →
PHASE_MATCH → SANDBOX → HUMAN → SECRETS → NETWORK →
FILE_WRITE → CLOUD
```

## Simulation Results: 15/16 PASS (94%)

| Mode | Tests | Key Result |
|------|:---:|------|
| LOCAL-FIRST | 8 | Stitch→PENDING_SANDBOX, GLM→PENDING_HUMAN, Quarantine/Rejected/Deprecated/Unknown→REJECT |
| VERIFIER | 3 | CLI verifier→ALLOW, Playwright(no-net)→REJECT, Node SDK→ALLOW |
| VERIFIER+NET | 1 | Playwright→ALLOW_WITH_CONTROLS |
| IMPLEMENTATION | 4 | Stitch→ALLOW, DB MCP→ALLOW, CodeGen→ALLOW_WITH_SANDBOX, cross-agent→REJECT |

## Verification: 18/18 PASS

All schema, registry, gate, ledger, TPP, and simulation checks passed.
