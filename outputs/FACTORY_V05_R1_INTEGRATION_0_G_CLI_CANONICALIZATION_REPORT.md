# FACTORY-V05-R1-INTEGRATION-0 — G: CLI Canonicalization

## Canonical CLI Name: actory.ps1
- **Canonical:** actory.ps1 (or actory via alias)
- **Alias:** actoryctl.ps1 (preserved for backward compatibility)
- **Decision:** The integration plan identified a CLI name reconciliation need. Both actory.ps1 and actoryctl.ps1 exist in v0.5. R1 standardizes on actory.ps1 as canonical, with actoryctl.ps1 as documented alias.

## R1 CLI Command Matrix

| Command | Module | Phase | Status |
|---------|--------|-------|--------|
| actory state | Dashboard | STATE-DASHBOARD-0 | NEW in R1 |
| actory state --json | Dashboard | STATE-DASHBOARD-0 | NEW in R1 |
| actory state --agents | Dashboard | STATE-DASHBOARD-0 | NEW in R1 |
| actory state --brief | Dashboard | STATE-DASHBOARD-0 | NEW in R1 |
| actory recover | Recovery | RECOVERY-0 | NEW in R1 |
| actory recover --dry-run | Recovery | RECOVERY-0 | NEW in R1 |
| actory evidence check | Evidence | EVIDENCE-TAXONOMY-0 | NEW in R1 |
| actory cleanup plan | Cleanup | DEFAULT-WORKFLOW-0 | NEW in R1 |
| actory lifecycle | Lifecycle | PROJECT-LIFECYCLE-0 | NEW in R1 |
| actory build | Build Lite | v0.5 | PRESERVED |
| actory phase close | Phase Close | v0.5 | PRESERVED |
| actory package qa | Package QA | v0.5 | PRESERVED |
| actory security gate | Security Gate | v0.5 | PRESERVED |

## CLI Discovery
- actory --help lists all commands
- actory <cmd> --help shows per-command help
- Dashboard brief shown on startup (from DEFAULT-WORKFLOW-0 protocol)
