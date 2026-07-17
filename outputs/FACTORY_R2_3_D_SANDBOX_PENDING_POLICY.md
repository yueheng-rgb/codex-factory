# FACTORY R2.3-D Sandbox Pending Policy

## Policy Statement

Capabilities with `securityRisk` = "high" or "critical" MUST NOT be allowed without a sandbox environment. The gate returns `PENDING_SANDBOX` when `HasSandbox=false`.

## Scope

Applies to: MCP servers (Stitch, Figma, Browser, Playwright, Postgres, GitHub), SDKs with network/secrets access, runners with file system write, cloud-integrated tools.

## Gate Logic (CHECK 12 in permission gate)

```
if securityRisk in ("high", "critical") AND HasSandbox=false:
    return PENDING_SANDBOX
elif securityRisk in ("high", "critical") AND HasSandbox=true:
    continue to next checks (secrets, network, fileWrite, cloud)
```

## Capabilities Requiring Sandbox (Current Registry)

| Capability | Risk | Type | Agent |
|-----------|------|------|-------|
| CAP-MCP-005 (github-mcp) | high | mcp_server | RSRC-001, LIB-001 |
| CAP-MCP-006 (postgres-mcp) | high | mcp_server | VER-001, IMPL-DB-001 |
| CAP-SDK-002 (stripe-sdk) | high | sdk | IMPL-BE-001 |
| CAP-SDK-003 (wechat-miniapp-sdk) | high | sdk | IMPL-FE-001, IMPL-BE-001 |
| CAP-SDK-004 (openai-sdk) | high | sdk | IMPL-BE-001 |
| CAP-MCP-014 (cloud-provider-mcp) | critical | mcp_server | INTG-001 (quarantined) |

## MCP Tool Classifications

| MCP Tool | Current secRisk | Recommended Sandbox | Reason |
|----------|----------------|---------------------|--------|
| Stitch MCP (CAP-MCP-001) | medium | OPTIONAL | Design tool, no code execution |
| Figma MCP (CAP-MCP-002) | medium | OPTIONAL | Design tool, no code execution |
| Browser MCP (CAP-MCP-003) | medium | RECOMMENDED | Can access network, render untrusted content |
| Playwright MCP (CAP-MCP-004) | low | RECOMMENDED | Headless browser, DOM manipulation |
| Postgres MCP (CAP-MCP-006) | high | REQUIRED | Database access with connection strings |
| GitHub MCP (CAP-MCP-005) | high | REQUIRED | Repository access with tokens |

## Resolution Path

1. **PENDING_SANDBOX returned** → Project must either:
   - Enable sandbox environment (set `HasSandbox=true`)
   - Reject the capability (set `recommendedAction=reject`)
   - Downgrade to monitor_only (set `recommendedAction=monitor`)

2. **Sandbox enabled** → Gate continues to evaluate:
   - Secrets check (auth required?)
   - Network access (permitted in phase?)
   - File write scope (agent has write scope?)
   - Cloud requirement (local-first compatible?)

## Prohibited Patterns

- ❌ No: automatically ALLOW high-risk capabilities without sandbox
- ❌ No: bypass sandbox check via "trusted" agent override
- ❌ No: downgrade secRisk to bypass sandbox without security review

## Verified (R2.3-D Simulation)

- Scenario B: IMPL-DB-001 + CAP-MCP-006, no sandbox → PENDING_SANDBOX ✓
- With sandbox + auth → ALLOW_WITH_CONTROLS ✓
