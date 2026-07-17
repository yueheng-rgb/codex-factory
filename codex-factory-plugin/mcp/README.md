# Factory Verifier MCP — H19 Feasibility Scaffold

MCP server design for exposing factory verification tools.

## Files

- `factory-verifier-mcp-design.md` — Architecture and feasibility analysis
- `factory-verifier-tool-schema.json` — MCP tool input/output schemas
- `sample-factoryctl-verify-output.json` — Current factoryctl verify output
- `README.md` — This file

## Status

**SCAFFOLD ONLY.** Not a working MCP server. H19 evaluates feasibility.
Full implementation deferred to H20 after install/portability stress test.

## Rules

- MCP output must remain machine-readable
- MCP tool FAIL must not be converted to markdown PASS
- MCP wrapper must not replace verifier scripts
