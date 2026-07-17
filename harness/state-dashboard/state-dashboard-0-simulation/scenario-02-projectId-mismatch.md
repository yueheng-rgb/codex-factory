# Sim 2: projectId mismatch
> FACTORY-STATE-DASHBOARD-0 / I — Simulation / Scenario 2 of 10

## Setup
- Active project has projectId=A, but snapshot references projectId=B

## Expected
- FOREIGN_PROJECT_CONTEXT warning generated
- Path shown with 🟡 FOREIGN indicator
- Dashboard header: 🟡 WARNING
- Warning section lists foreign context

## Verdict: ✅ PASS
