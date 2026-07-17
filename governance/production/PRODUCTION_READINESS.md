# Production Hardening Foundation
# Codex Factory R6.0

## Architecture

The Production Hardening Foundation adds a layer on top of Foundation RC
that evaluates projects for production readiness without making false
claims about production capability.

## Components

1. **Production Readiness Schema** (`schemas/production-readiness.schema.json`) — defines the structure of a readiness check
2. **Production Readiness Checker** (`runtime/production-readiness-checker.ps1`) — evaluates a project against the schema
3. **Postgres Migration Foundation** — SQL schema + config for testbed migration
4. **CI/CD Template** — GitHub Actions workflow for Node.js projects
5. **Deployment Manifest Template** — standardized deployment documentation

## Readiness Levels

| Level | Meaning | Typical For |
|-------|---------|-------------|
| NOT_READY | Missing critical infrastructure | Prototype without tests or config |
| PARTIAL | Some dimensions covered | Testbed with tests but no production config |
| READY_FOR_STAGING | All non-production dimensions green | Testbed with env config, CI, migrations |
| READY_FOR_PRODUCTION_REVIEW | All dimensions covered, needs human review | Project with full config, CI/CD, security scan, load smoke |

## Check Dimensions (15)

1. environment_variables — .env.example exists, vars documented
2. secrets_handling — no hardcoded secrets, key management
3. database_configuration — connection config, pool settings
4. migrations — schema files, migration commands
5. seed_data — seed scripts for dev/staging
6. logging — structured logging, log levels
7. error_handling — unified error format, error boundaries
8. health_check — /health endpoint
9. test_command — test runner, test pass rate
10. build_command — typecheck, compile
11. start_command — single command to start
12. deployment_target — where/how to deploy
13. security_scan — semgrep or equivalent
14. load_smoke — autocannon or k6
15. rollback_notes — how to revert

## Non-Claims

- Production Hardening Foundation does NOT make any project production-ready
- It identifies gaps and provides templates
- READY_FOR_PRODUCTION_REVIEW means "ready for a human to decide" — not "ready for production"
- Local load smoke does NOT prove production concurrency capacity
- In-memory stores are NOT production database configurations
