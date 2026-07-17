# FACTORY R2.3-B — External Capability Ecosystem Survey

> **Phase:** FACTORY-R2.3-B-EXTERNAL-CAPABILITY-ECOSYSTEM
> **Date:** 2026-07-09
> **Status:** COMPLETED
> **Capabilities Registered:** 90 across 11 types

---

## 1. Executive Summary

Codex Factory R2.3-B has systematically surveyed, classified, and registered **90 external capability candidates** spanning 11 types. Each candidate was evaluated across 25 fields including trust level, security risk, privacy risk, supply chain risk, recommended action, and priority.

### Key Findings

| Metric | Count |
|--------|-------|
| Total candidates | **90** |
| P0 (must have) | **21** (23%) |
| P1 (should have) | **23** (26%) |
| P2 (nice to have) | **24** (27%) |
| P3 (defer) | **22** (24%) |
| Recommended: import | **55** (61%) |
| Recommended: adapt | **11** (12%) |
| Recommended: monitor | **20** (22%) |
| Recommended: quarantine | **4** (4%) |
| VERIFIED trust | **57** (63%) |
| TRUSTED trust | **23** (26%) |
| AVAILABLE trust | **10** (11%) |

### Type Distribution

| Type | Count | P0 | P1 | Key Action |
|------|-------|----|----|------------|
| skill | 12 | 2 | 5 | Import 8, Adapt 4 |
| mcp_server | 14 | 2 | 4 | Import 5, Monitor 8, Quarantine 1 |
| cli_tool | 8 | 6 | 1 | Import 8 |
| sdk | 6 | 3 | 1 | Import 6 |
| template | 9 | 0 | 1 | Adapt 3, Import 3, Monitor 3 |
| generator | 5 | 1 | 1 | Import 2, Monitor 3 |
| verifier | 10 | 6 | 3 | Import 10 |
| search_provider | 10 | 2 | 4 | Import 9, Monitor 1 |
| runner | 6 | 2 | 2 | Import 5, Monitor 1 |
| cloud_service | 6 | 0 | 0 | Monitor 4, Quarantine 2 |
| knowledge_source | 4 | 1 | 1 | Import 4 |

---

## 2. Critical Answers

### 2.1 Which capabilities should be prioritized for Factory integration?

**P0 (21 items):** AGENTS.md ecosystem, supabase-postgres-best-practices, filesystem-mcp, playwright-mcp, nextjs-cli, prisma-cli, vite-cli, vitest, eslint-prettier, playwright-test, next-auth, prisma-client, react-hook-form-zod, prisma-generate, typescript-compiler, eslint-verifier, vitest-verifier, playwright-verifier, npm-audit, build-verifier, browser-runner, official-docs-search, google-search, official-framework-docs, local-windows-runner.

These are the **non-negotiable foundation** — already used or trivially added.

### 2.2 Which should only be observed, not imported yet?

**Monitor (20 items):** stitch-mcp, figma-mcp, context7-mcp, memory-mcp, security-scanner-mcp, package-manager-mcp, next-enterprise, django-admin-starter, rag-app-starter, v0-dev, bolt-new, lovable-dev, zhihu-juejin-csdn, mac-mini-runner, all cloud services.

Reasons: immature, high risk, requires API keys, or not needed for current Factory scope.

### 2.3 Which must be quarantined?

**Quarantine (4 items):** cloud-provider-mcp, cloud-queue-service, cloud-secrets-manager. These require cloud credentials with CRITICAL security implications. Not needed for local-first Factory.

### 2.4 Which can replace hand-written skills?

- **playwright-mcp** → replaces browser testing skill
- **filesystem-mcp** → replaces raw shell_command for file access
- **prisma-generate** → replaces manual DB client code
- **shadcn-ui-blocks** → replaces manual UI component coding
- **openapi-generator** → replaces manual API client writing

### 2.5 Which capabilities are suitable for each agent?

| Agent | Primary Capabilities |
|-------|---------------------|
| IMPL-FE-001 | shadcn-ui-blocks, v0-dev (monitor), stitch-mcp (monitor), figma-mcp (monitor), nextjs-cli, vite-cli, react-hook-form-zod |
| IMPL-BE-001 | prisma-cli, prisma-client, next-auth, fastify-prisma-starter, wechat-miniapp-sdk |
| IMPL-DB-001 | prisma-cli, prisma-client, prisma-generate, postgres-mcp (P2), supabase-postgres-best-practices |
| VER-001 | playwright-mcp, playwright-test, vitest, build-verifier, eslint, npm-audit, typescript-compiler, browser-runner, frontend-visual-verifier |
| SEC-001 | npm-audit, trailofbits-security-skills, eslint, security-scanner-mcp (monitor) |
| RSRC-001 | official-docs-search, google-search, github-repo-search, glm-search, perplexity-search, big-tech-engineering-blogs |
| ARCH-001 | sequential-thinking-mcp, official-framework-docs, rfc-and-standards, bulletproof-react, next-enterprise |
| LIB-001 | skill-creator, skill-installer, github-mcp, github-repo-search |
| AUD-001 | architecture-drift-verifier, api-contract-verifier |

### 2.6 Which need human confirmation?

- stitch-mcp (file write + external service)
- figma-mcp (design file access + token)
- github-mcp (write mode)
- postgres-mcp (DB access)
- cloud-provider-mcp (infrastructure changes)
- v0-dev, bolt-new, lovable-dev (AI-generated code needs review)
- All cloud services

### 2.7 Which need sandbox?

- All MCP servers with fileWriteAccess (filesystem-mcp, playwright-mcp, github-mcp, browser-mcp)
- All generators (code output needs validation)
- postgres-mcp (read-only mode)
- docker-runner (container isolation)

### 2.8 Which need hardware?

- mac-mini-runner (iOS builds only)
- miniapp-devtools-runner (local WeChat DevTools)

### 2.9 Which need cloud?

- All cloud_service types (by definition)
- ci-runner (GitHub Actions — already free tier)
- None are needed for current Factory operations.

### 2.10 Stitch MCP management strategy

Stitch MCP should be:
1. **Imported** into capability registry as monitor priority
2. **Sandboxed** — never given direct project file write access
3. **Human-confirmed** — every code generation requires approval
4. **Output-reviewed** — generated code goes through VER-001 before merge
5. **Not auto-loaded** — never loaded by default for any agent

### 2.11 GLM search and Research Intake separation

`
GLM Search (External)          Research Intake (RSRC-001)
     │                                │
     │ Raw results                    │ Receives raw results
     │ + citations                    │ Cleans + normalizes
     │ + confidence                   │ Cross-references
     │                                │ Produces Research Packet
     ▼                                ▼
[Search Provider Adapter] → [Research Intake Pipeline] → [Knowledge Bank]
`

The adapter is the boundary. GLM never writes to Factory directly. RSRC-001 never searches directly.

---

## 3. Recommended Actions Summary

| Action | Count | Examples |
|--------|-------|----------|
| **import** (use as-is or with minimal config) | 55 | playwright-test, eslint, typescript-compiler, prisma-cli |
| **adapt** (convert to Factory format) | 11 | cursor-rules, claude-agent-skills, create-t3-app |
| **monitor** (watch, don't integrate yet) | 20 | stitch-mcp, figma-mcp, v0-dev, cloud services |
| **quarantine** (block until security review) | 4 | cloud-provider-mcp, cloud-queue-service |

---

> **Survey complete.** 90 capabilities registered, classified, and prioritized. Ready for R2.3-C implementation.

