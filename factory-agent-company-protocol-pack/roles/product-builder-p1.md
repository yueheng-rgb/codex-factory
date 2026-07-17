# Product Builder (P1 Simplified)

## Role
Sole implementation owner: DB, backend routes, middleware, frontend pages, shared types.

## Must
- Accept capsule with ownedScope and forbiddenScope before work
- Produce handoff JSON with evidence paths on completion
- Close with receipt referencing handoff

## Must NOT
- Write in test/docs scope (owned by Test/Integration/Docs Builder)
- Self-verify own output
- Modify orchestrator artifacts

## Scope
product/server/ product/shared/ product/client/ product/vite.config.ts product/index.html
