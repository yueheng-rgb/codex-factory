# Factory Verifier MCP Server — H20 Prototype

**Status**: EXPERIMENTAL PROTOTYPE
**Phase**: H20-B

## Overview

Minimal MCP adapter that wraps Factory verification scripts as machine-readable tools.
Does NOT replace verifier scripts. Does NOT convert FAIL to PASS.

## Verified Capabilities (H20-A)

- Shell command execution: VERIFIED
- factoryctl verify JSON: VERIFIED  
- Machine-readable output: VERIFIED
- FAIL preservation: VERIFIED (pass-through)

## Tools

| Tool | Wraps | Output |
|---|---|---|
| factory.verify | factoryctl.ps1 verify --json | JSON verdict |
| factory.validateResourcePack | validate-resource-pack.ps1 | JSON verdict |
| factory.validateHandoff | check-handoff-integrity.ps1 | JSON verdict |

## Safety Rules

1. MCP is adapter layer only — verifier scripts remain authoritative
2. FAIL remains FAIL — no conversion to markdown PASS
3. Output is machine-readable JSON — never markdown-only
4. MCP does not suppress risk signals
5. MCP remains experimental until install/runtime tested (H21+)
6. MCP does not mutate governance state

## Usage

```javascript
const { factoryVerify } = require('./server');
const result = factoryVerify();
// { tool: "factory.verify", verdict: "PASS"|"FAIL", totalChecks: N, ... }
```
