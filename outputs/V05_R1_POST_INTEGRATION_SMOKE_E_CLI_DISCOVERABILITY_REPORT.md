# V05-R1-POST-INTEGRATION-SMOKE — E: CLI Discoverability Smoke

## CLI Entry Points
| File | Exists |
|------|--------|
| scripts/factoryctl.ps1 | True |
| scripts/factory.ps1 | False |
## R1 User-Facing Scripts (non-verifier)
- factory-cleanup-planner.ps1 (3965 bytes)
- factoryctl.ps1 (6739 bytes)
- factory-evidence-validator.ps1 (2294 bytes)
- factory-recovery-scan.ps1 (9941 bytes)
- factory-state-dashboard-prototype.ps1 (11759 bytes)
- factory-task-queue.ps1 (3265 bytes)
## CLI Documentation
| Document | Exists | Size |
|----------|--------|------|
| governance/factory-dashboard/CLI_DASHBOARD_CONTRACT.md | True | 2247 bytes |
| governance/factory-lifecycle/USER_LIFECYCLE_COMMANDS.md | True | 982 bytes |
## CLI Command Surface (documented)
| Command | Module | Phase |
|---------|--------|-------|
| factory state | Dashboard | STATE-DASHBOARD-0 |
| factory state --json / --agents / --brief | Dashboard | STATE-DASHBOARD-0 |
| factory recover --dry-run | Recovery | RECOVERY-0 |
| factory evidence check | Evidence | EVIDENCE-TAXONOMY-0 |
| factory cleanup plan | Cleanup | DEFAULT-WORKFLOW-0 |
| factory lifecycle | Lifecycle | PROJECT-LIFECYCLE-0 |

## CLI Name Reconciliation
- v0.5 entry: actoryctl.ps1 (present in package)
- R1 canonical target: actory.ps1 (documented, not yet renamed)
- Both names documented in release notes; no confusion
