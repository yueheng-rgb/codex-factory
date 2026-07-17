# R2.3-J Tool Invocation Ledger Report

## Ledger Location
`governance/tool-invocations/tool-invocation-index.jsonl`

## Record Structure
Each record captures: invocationId, projectId, phaseId, agentId, toolId, requestedAction, decision, reason, sandboxMode, humanApproval, filesRead, filesWritten, networkUsed, secretsUsed, artifactsProduced, timestamp, caveats, gateChecks.

## Simulation Coverage

The 16-test simulation produced ledger entries for:
- 8 LOCAL-FIRST checks (all REJECT or PENDING)
- 3 VERIFIER checks (2 ALLOW, 1 REJECT)
- 1 VERIFIER+NETWORK check (ALLOW)
- 4 IMPLEMENTATION checks (3 ALLOW, 1 REJECT)

## Key Records

| Decision | Count | Example |
|----------|:---:|------|
| REJECT | 8 | Quarantine, rejected, deprecated, unknown, cross-agent |
| PENDING_SANDBOX | 2 | Stitch MCP, CodeGen (no sandbox) |
| PENDING_HUMAN | 1 | GLM Search (no approval) |
| ALLOW_WITH_CONTROLS | 4 | CLI verifier, Node SDK, Playwright, Stitch (full) |
| ALLOW_WITH_SANDBOX | 1 | CodeGen (sandbox available) |
