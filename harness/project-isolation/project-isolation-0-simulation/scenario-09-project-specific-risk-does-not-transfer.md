# Simulation Scenario 9: Project-specific risk does not transfer
> Part of: FACTORY-PROJECT-ISOLATION-0 / K — Simulation
> Scenario: 9 of 10

## Setup
- Project A has risk: "SQLite not suitable for >100k rows"
- Switch to Project B (also uses SQLite)

## Expected Behavior
1. Project A risks flushed with Project A context
2. Project B loads its own risk records
3. Project A risk NOT visible in Project B unless marked FOREIGN_PROJECT_CONTEXT
4. Project A risk does NOT block Project B

## Expected Verdict: ✅ PASS (project-specific risk does not transfer)
