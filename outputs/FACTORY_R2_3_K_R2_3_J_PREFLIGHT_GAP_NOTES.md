# R2.3-J Simulation Gap Preflight

**Phase:** FACTORY-R2.3-K Step 0 | **Date:** 2026-07-10

## Gap: NC-002

| Field | Value |
|-------|-------|
| Gap ID | NC-002 |
| Tool | TOOL-GLM-SEARCH-001 (GLM Search Provider) |
| Simulation mode | LOCAL-FIRST (no sandbox, no network, no secrets, no human) |
| Expected | REJECT (secrets+network disallowed) |
| Actual | PENDING_HUMAN |
| Root cause | Gate checks `humanConfirmationRequired` (check 7) before `requiredSecrets` (check 8) |

## Analysis

The permission gate order is:

```
1. TOOL_EXISTS
2. TOOL_STATUS
3. AGENT_AUTH
4. PROJECT_TYPE
5. PHASE_MATCH
6. SANDBOX
7. HUMAN          ← fires here for GLM Search
8. SECRETS
9. NETWORK
10. FILE_WRITE
11. CLOUD
```

GLM Search has `humanConfirmationRequired=true` and `requiredSecrets=true` and `networkAccess=true`. In LOCAL-FIRST mode, the gate correctly fires at HUMAN (check 7) before reaching SECRETS (check 8). The tool returns PENDING_HUMAN rather than REJECT.

This is **not a bug** — it is intentional gate design. The human confirmation gate is a higher-priority safety check than resource availability checks. The rationale: a human should be asked whether to allow an AI tool before the system checks whether API keys are configured.

## Decision: **ACCEPT_CAVEAT**

- **Does this block R2.3-K?** No. The tool is still blocked from execution.
- **Is the tool incorrectly allowed?** No. PENDING_HUMAN ≠ ALLOW.
- **Would fixing it change any real behavior?** No. In either case, execution is prevented.
- **Risk of accepting:** None. The tool cannot execute without human approval.

## Action

- Caveat recorded in simulation results
- No script changes required
- Gate order is intentional and documented
- R2.3-K can proceed
