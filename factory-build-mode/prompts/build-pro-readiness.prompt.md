# Build Pro Readiness Check

Copy into a Codex window to check if a project is ready for Build Pro 4-Agent:

---

Check this project for Build Pro readiness:

1. Complexity must be LARGE or HIGH_RISK
2. External memory (.codex-factory/) must be initialized and valid
3. Task graph must have >=20 nodes with parallelizable groups
4. Write scopes must be pre-defined per agent
5. Vanilla baseline should exist for comparison
6. All critical gaps from diagnostic gate must be resolved
7. User must explicitly approve multi-agent mode

Run: validate-memory.ps1 first, then check classification.json for complexity level.
