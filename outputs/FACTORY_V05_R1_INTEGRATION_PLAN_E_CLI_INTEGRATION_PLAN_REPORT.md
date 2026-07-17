# E: CLI Integration Plan

## Canonical CLI Name
`factory` (canonical). If existing is `factoryctl.ps1`, create alias. Per DEFAULT-WORKFLOW-0 Section H.

## R1 CLI Commands
| Command | Source | Category |
|---------|--------|----------|
| `factory state` | STATE-DASHBOARD-0 | DASHBOARD |
| `factory state --json` | STATE-DASHBOARD-0 | DASHBOARD |
| `factory state --brief` | STATE-DASHBOARD-0 | DASHBOARD |
| `factory state --agents` | STATE-DASHBOARD-0 | DASHBOARD |
| `factory state --paths` | STATE-DASHBOARD-0 | DASHBOARD |
| `factory state --risks` | STATE-DASHBOARD-0 | DASHBOARD |
| `factory state --cleanup` | STATE-DASHBOARD-0 | DASHBOARD |
| `factory state --mount` | STATE-DASHBOARD-0 | DASHBOARD |
| `factory recover` | RECOVERY-0 | RECOVERY |
| `factory recover --dry-run` | RECOVERY-0 | RECOVERY |
| `factory evidence validate` | EVIDENCE-TAXONOMY-0 | EVIDENCE |
| `factory project list` | PROJECT-ISOLATION-0 | LIFECYCLE |
| `factory project status` | PROJECT-LIFECYCLE-0 | LIFECYCLE |
| `factory project activate` | PROJECT-LIFECYCLE-0 | LIFECYCLE |
| `factory project pause` | PROJECT-LIFECYCLE-0 | LIFECYCLE |
| `factory project freeze` | PROJECT-LIFECYCLE-0 | LIFECYCLE |
| `factory project archive` | PROJECT-LIFECYCLE-0 | LIFECYCLE |
| `factory project delete` | PROJECT-LIFECYCLE-0 | LIFECYCLE |
| `factory cleanup plan` | DEFAULT-WORKFLOW-0 | CLEANUP |
| `factory cleanup execute` | DEFAULT-WORKFLOW-0 | CLEANUP |

## CLI Name Reconciliation
If `factoryctl.ps1` exists → canonical name is `factory`. Create `factory.ps1` wrapper or alias. Warning on `factoryctl` per reconciliation policy.
