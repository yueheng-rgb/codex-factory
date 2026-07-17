# R2.3-L Network Boundary Model

## Levels (0-6)

| Level | Name | Localhost | LAN | External | Secrets | Human | Sandbox | Local-First |
|:---:|------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 0 | no_network | ❌ | ❌ | ❌ | No | No | No | ✅ |
| 1 | loopback_only | ✅ | ❌ | ❌ | No | No | No | ✅ |
| 2 | local_lan | ✅ | ✅ | ❌ | No | Yes | No | ✅ |
| 3 | external_readonly | ✅ | ✅ | GET only | No | Yes | Yes | ❌ |
| 4 | external_api | ✅ | ✅ | API only | Yes | Yes | Yes | ❌ |
| 5 | external_write | ✅ | ✅ | Write | Yes | Yes | Yes | ❌ |
| 6 | cloud_service | ✅ | ✅ | Cloud | Yes | Yes | Yes | ❌ |

## Tool Mapping

| Tool | Current Boundary | Reason |
|------|:---:|------|
| TOOL-CLI-VER-001 | no_network (0) | Local verification only |
| TOOL-NODE-SDK-001 | no_network (0) | Code execution, no network |
| TOOL-PLAYWRIGHT-VER-001 | loopback_only (1) | Tests localhost only |
| TOOL-CODEGEN-001 | no_network (0) | Scaffold generation |
| TOOL-SEARCH-ADAPTER-001 | no_network (0) | Manual intake only |
| TOOL-STITCH-MCP-001 | external_api (4) | Figma API calls |
| TOOL-GLM-SEARCH-001 | external_api (4) | GLM API calls |
| TOOL-DB-MCP-001 | external_api (4) | DB connection |

## Key Rules

- loopback_only tools are ALLOWED in local-first mode
- external_* tools are REJECTED or PENDING in local-first mode
- Any tool exceeding its declared boundary → boundary_violation → REJECT
