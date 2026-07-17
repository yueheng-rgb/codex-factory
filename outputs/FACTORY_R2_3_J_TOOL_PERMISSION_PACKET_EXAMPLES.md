# R2.3-J Tool Permission Packet Examples

## Generated TPPs

### 1. IMPL-FE Fullstack (`tpp-impl-fe-fullstack.json`)
- Agent: IMPL-FE-001
- Allowed: TOOL-STITCH-MCP-001, TOOL-CLI-VER-001, TOOL-PLAYWRIGHT-VER-001
- Sandbox: disposable for Stitch+Playwright, dryRun for CLI verifier

### 2. IMPL-DB Fullstack (`tpp-impl-db-fullstack.json`)
- Agent: IMPL-DB-001
- Allowed: TOOL-DB-MCP-001, TOOL-NODE-SDK-001
- Blocked: TOOL-STITCH-MCP-001 (cross-agent rejection)

### 3. VER Fullstack (`tpp-ver-fullstack.json`)
- Agent: VER-001
- Allowed: TOOL-CLI-VER-001, TOOL-NODE-SDK-001, TOOL-PLAYWRIGHT-VER-001
- Sandbox: dryRun for CLI verifier, disposable for Playwright

## TPP Schema
Each TPP contains: allowedTools, blockedTools, pendingHumanTools, pendingSandboxTools, dryRunTools, forbiddenToolActions, toolRiskSummary, sandboxInstructions, humanApprovalInstructions.
