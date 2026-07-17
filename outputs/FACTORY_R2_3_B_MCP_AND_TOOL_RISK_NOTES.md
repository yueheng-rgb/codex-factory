# FACTORY R2.3-B — MCP and Tool Risk Notes

> **Phase:** FACTORY-R2.3-B
> **Date:** 2026-07-09
> **MCP/Tool Candidates:** 14

---

## Risk Classification

### CRITICAL Risk (4) — Must Quarantine or Strict Sandbox

| MCP | Risk | Why |
|-----|------|-----|
| cloud-provider-mcp | CRITICAL | Full cloud infrastructure access, credential exposure, cost risk |
| cloud-queue-service | CRITICAL | Production infrastructure, cost, data in cloud |
| cloud-secrets-manager | CRITICAL | Central secret store access, breach blast radius |
| github-mcp (write mode) | HIGH→CRITICAL | Can push to repos, modify code, trigger deployments |

### HIGH Risk (4) — Needs Read-Only + Sandbox

| MCP | Risk | Mitigation |
|-----|------|------------|
| postgres-mcp | HIGH | Read-only mode only, no DDL, connection string in sandbox |
| github-mcp (read mode) | HIGH | Read-only token, no write scope, public repos only |
| stitch-mcp | HIGH | Generated code must pass VER-001, never direct-to-project |
| figma-mcp | HIGH | Read-only design access, token in sandbox |

### MEDIUM Risk (4) — Needs Sandbox

| MCP | Risk | Mitigation |
|-----|------|------------|
| browser-mcp | MEDIUM | Sandbox execution, no persistent state outside test dir |
| playwright-mcp | MEDIUM | Already sandboxed by Playwright, limit to test env |
| filesystem-mcp | MEDIUM | Scope-restricted to project dir, no system paths |
| security-scanner-mcp | MEDIUM | Read-only, but supply chain risk from scanner itself |

### LOW Risk (2) — Safe with Basic Precautions

| MCP | Risk | Mitigation |
|-----|------|------------|
| sequential-thinking-mcp | LOW | No network, no file access, pure computation |
| brave-search-mcp | LOW | Read-only search, API key managed |

---

## Permission Matrix for MCP Integration

| MCP | Network | File Write | External Service | Secrets | Sandbox | Human Confirm |
|-----|---------|------------|-----------------|---------|---------|---------------|
| filesystem-mcp | No | Yes | No | No | ✅ Yes | No |
| playwright-mcp | Yes | Yes (test) | No | No | ✅ Yes | No |
| browser-mcp | Yes | Yes (test) | No | No | ✅ Yes | No |
| github-mcp | Yes | Yes | Yes | Token | ✅ Yes | Write: Yes |
| postgres-mcp | Yes | No | Yes | ConnStr | ✅ Yes | Write: Yes |
| stitch-mcp | Yes | Yes | Yes | API key | ✅ Yes | ✅ Yes |
| figma-mcp | Yes | Yes | Yes | Token | ✅ Yes | ✅ Yes |
| brave-search | Yes | No | Yes | API key | No | No |
| context7-mcp | Yes | No | Yes | No | No | No |
| memory-mcp | No | Yes | No | No | No | No |
| sequential-thinking | No | No | No | No | No | No |
| security-scanner | Yes | No | Yes | No | ✅ Yes | No |
| package-manager | Yes | No | Yes | No | No | No |
| cloud-provider | Yes | Yes | Yes | Credentials | ✅ Yes | ✅ Yes |

---

## Integration Rules

1. **No MCP gets write access to project source without sandbox.**
2. **No MCP with externalServiceAccess gets network without explicit allowlist.**
3. **All MCP with secrets must store secrets outside project directory.**
4. **All MCP with CRITICAL risk require human confirmation for every invocation.**
5. **MCP output that writes files must pass through VER-001 before merge.**
6. **MCP with supplyChainRisk=high must be isolated in container/Docker.**

