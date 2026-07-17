# FACTORY R2.3-B — Capability Priority Matrix

> **Phase:** FACTORY-R2.3-B
> **Date:** 2026-07-09

---

## P0 — Must Have (Foundation, Already Operational or Trivial)

These 21 capabilities are either already in use or can be added with zero friction.

| ID | Name | Type | Action | Agent |
|----|------|------|--------|-------|
| CAP-SKILL-004 | AGENTS.md ecosystem | skill | import | PM-001 |
| CAP-SKILL-005 | supabase-postgres-best-practices | skill | import | IMPL-DB-001 |
| CAP-MCP-004 | playwright-mcp | mcp_server | import | VER-001 |
| CAP-MCP-007 | filesystem-mcp | mcp_server | import | all |
| CAP-CLI-001 | nextjs-cli | cli_tool | import | IMPL-FE/BE |
| CAP-CLI-002 | prisma-cli | cli_tool | import | IMPL-DB |
| CAP-CLI-003 | vite-cli | cli_tool | import | IMPL-FE |
| CAP-CLI-004 | vitest | cli_tool | import | VER-001 |
| CAP-CLI-005 | eslint-prettier | cli_tool | import | VER-001 |
| CAP-CLI-006 | playwright-test | cli_tool | import | VER-001 |
| CAP-SDK-001 | next-auth | sdk | import | IMPL-BE |
| CAP-SDK-005 | prisma-client | sdk | import | IMPL-BE/DB |
| CAP-SDK-006 | react-hook-form-zod | sdk | import | IMPL-FE |
| CAP-GEN-004 | prisma-generate | generator | import | IMPL-DB |
| CAP-VER-001 | typescript-compiler | verifier | import | VER-001 |
| CAP-VER-002 | eslint-verifier | verifier | import | VER-001 |
| CAP-VER-003 | vitest-verifier | verifier | import | VER-001 |
| CAP-VER-004 | playwright-verifier | verifier | import | VER-001 |
| CAP-VER-005 | npm-audit | verifier | import | SEC-001 |
| CAP-VER-006 | build-verifier | verifier | import | VER-001 |
| CAP-RUN-001 | local-windows-runner | runner | import | all |
| CAP-RUN-005 | browser-runner | runner | import | VER-001 |
| CAP-SRCH-005 | google-search | search_provider | import | RSRC-001 |
| CAP-SRCH-007 | official-docs-search | search_provider | import | RSRC-001 |
| CAP-KNOW-001 | official-framework-docs | knowledge_source | import | RSRC-001 |

## P1 — Should Have (High Value, Moderate Effort)

These 23 items provide significant capability upgrade but need integration work or have some risk.

| ID | Name | Type | Action | Risk |
|----|------|------|--------|------|
| CAP-SKILL-001 | openai-codex-skills | skill | import | Low |
| CAP-SKILL-003 | cursor-rules | skill | adapt | Low |
| CAP-SKILL-006 | playwright-interactive | skill | import | Medium (sandbox) |
| CAP-SKILL-007 | skill-creator | skill | import | Low |
| CAP-SKILL-008 | skill-installer | skill | adapt | Medium (network) |
| CAP-SKILL-011 | trailofbits-security-skills | skill | import | Low |
| CAP-MCP-001 | stitch-mcp | mcp_server | monitor | Medium (AI code, needs review) |
| CAP-MCP-002 | figma-mcp | mcp_server | monitor | Medium (token, privacy) |
| CAP-MCP-003 | browser-mcp | mcp_server | import | Medium (sandbox) |
| CAP-MCP-005 | github-mcp | mcp_server | import | High (token, write) |
| CAP-CLI-008 | wechat-miniapp-cli | cli_tool | import | Medium (WeChat ToS) |
| CAP-SDK-003 | wechat-miniapp-sdk | sdk | import | High (secrets MUST stay server) |
| CAP-TMPL-004 | shadcn-ui-blocks | template | import | Low |
| CAP-GEN-001 | v0-dev | generator | monitor | Medium (AI code) |
| CAP-VER-007 | api-contract-verifier | verifier | import | Medium |
| CAP-VER-008 | architecture-drift-verifier | verifier | import | Medium (needs implementation) |
| CAP-VER-009 | package-qa-verifier | verifier | import | Low |
| CAP-SRCH-001 | glm-search | search_provider | import | Medium (API key) |
| CAP-SRCH-002 | chatgpt-search | search_provider | import | Medium (API/source verify) |
| CAP-SRCH-004 | perplexity-search | search_provider | import | Medium (API key) |
| CAP-SRCH-006 | github-repo-search | search_provider | import | Low |
| CAP-RUN-003 | docker-runner | runner | import | Low |
| CAP-RUN-006 | miniapp-devtools-runner | runner | import | Medium |
| CAP-KNOW-003 | big-tech-engineering-blogs | knowledge_source | import | Low |

## P2 — Nice to Have (Defer, Lower Priority)

24 items. Include: CAP-SKILL-002 (claude-agent-skills), CAP-SKILL-009 (openai-docs), CAP-MCP-006 (postgres-mcp), CAP-MCP-008 (brave-search), CAP-MCP-009 (context7), CAP-MCP-010 (memory-mcp), CAP-MCP-011 (sequential-thinking), CAP-CLI-007 (expo-cli), CAP-SDK-004 (openai-sdk), CAP-TMPL-001/002/005/006/007, CAP-GEN-002/003/005, CAP-VER-010, CAP-SRCH-003/008, CAP-RUN-002/004, CAP-KNOW-002/004.

## P3 — Defer Indefinitely (Only If Specifically Needed)

22 items. Include: CAP-SKILL-010/012, CAP-MCP-012/013/014 (quarantine), CAP-SDK-002 (stripe), CAP-TMPL-003/008/009, CAP-SRCH-009/010, all 6 cloud_service entries (CAP-CLD-001 through 006).

---

## R2.3-C Priority Recommendation

Based on the P0/P1 analysis, R2.3-C should implement:

1. **P0 Verifier Integration** (biggest impact, lowest risk)
   - playwright-test + vitest + eslint + tsc + build + npm-audit as VER-001 verifier chain
2. **P0 CLI/SDK Defaults** (already in use, formalize)
   - Formalize nextjs/prisma/vite/vitest/eslint as default toolchain in agent loader
3. **P1 MCP Sandbox** (critical for safe MCP adoption)
   - filesystem-mcp + playwright-mcp + browser-mcp with sandbox + scope restriction
4. **P1 Search Provider Adapter** (enables RSRC-001 research intake)
   - glm-search + perplexity-search adapter for Research Intake pipeline

