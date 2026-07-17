# USER-HANDOFF-R1 — G: Safety & Scope Reminder

## What R1 IS
- Local tooling/workflow patch for Codex App Factory
- Theory baseline integration (7 phases, 263 checks)
- Documentation-driven: policies, schemas, scripts

## What R1 IS NOT
- **NOT** a production deployment tool
- **NOT** a cloud service
- **NOT** a secret rotation or security management tool
- **NOT** proof that Factory is universally better than vanilla Codex
- **NOT** v0.6

## Critical Safety Rules
1. Multi-agent requires user confirmation — never auto-starts
2. Cleanup DELETE requires user confirmation — defaults to PLAN
3. Dashboard/snapshot/attach are NOT primary evidence — working context only
4. Security Gate is a safety check — not deployment permission
5. Package QA is handoff hygiene — not product correctness proof
6. Local readiness is NOT production readiness

## Scope Boundaries
- Local workspace only
- No server connections
- No cloud operations
- No production data access
- No automatic destructive operations
