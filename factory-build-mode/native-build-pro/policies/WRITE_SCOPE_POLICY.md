# Native Build Pro Write Scope Policy

## Rules
1. **Write-scope map must exist before spawning any agent.**
2. **Each agent has exclusive write scope** — no file in more than one agent's scope.
3. **Verifier scope is READONLY for product code.**
4. **Orchestrator scope is planning/integration only** — no product implementation.
5. **Scope violations = immediate diagnostic gate FAIL.**
6. **Post-build audit**: verifier checks 0 write-scope violations.

## Scope Categories
| Agent Role | Typical Scope | Forbidden |
|------------|--------------|-----------|
| worker-backend | server.js, db/, middleware/, routes/ | public/, tests/ |
| worker-frontend | public/ | server.js, routes/ |
| worker-test | tests/, docs/ | routes/, public/ |
| worker-verify | outputs/, integration/ | product/ (read-only) |
