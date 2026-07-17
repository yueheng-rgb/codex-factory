# RC-SMOKE-1 — Section C: Live Fixture Setup Report

**Phase:** RC-SMOKE-1 | **Section:** C | **Status:** COMPLETE

## Fixtures Created

| # | Fixture | Purpose | State |
|---|---|---|---|
| 1 | `simple-project` | Baseline: no gates triggered | IN_PROGRESS |
| 2 | `deployed-trace-project` | Security/Deploy Gate trigger | DEPLOY_PREP, has deploy.sh + .env.example |
| 3 | `package-handoff-project` | Package QA Gate trigger | PACKAGE_HANDOFF, finalZipExists=true |
| 4 | `long-horizon-project` | Context Space trigger | PHASE-20 |
| 5 | `phase-close-project` | Phase close verifier test | AWAITING_VERIFIER |

## Safety
- All placeholders: `placeholder.example.com`
- No real secrets, servers, endpoints
- No real projects, student packages, or working copies
- `.env.example` only (no real `.env`)

**Section C verdict: COMPLETE**
