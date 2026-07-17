# FACTORY-V05-R1-INTEGRATION-0 — F: Runtime Script Integration

## New R1 Runtime Scripts

| Script | Source Phase | Target | Purpose |
|--------|-------------|--------|---------|
| factory-state-dashboard-prototype.ps1 | STATE-DASHBOARD-0 | scripts/ | CLI state dashboard |
| factory-recovery-scan.ps1 | RECOVERY-0 | scripts/ | Startup recovery scan |
| factory-evidence-validator.ps1 | EVIDENCE-TAXONOMY-0 | scripts/ | Evidence overclaim detection |

## Existing v0.5 Scripts Preserved
- factory.ps1, factoryctl.ps1 — main CLI entry
- v05-decision-0-verify.ps1 — v0.5 verifier
- validate-delivery-archive.ps1, validate-factory-run.ps1, validate-snapshot-pack.ps1
- factory-run-fingerprint.ps1, factory-fresh-install-smoke.ps1
- Run management: new-factory-run.ps1, update-factory-run-state.ps1
- Test fixtures under scripts/test-fixtures/

## Script Dependency Map
- factory.ps1 / factoryctl.ps1 — canonical CLI entry (single source of truth)
- CLI dispatches to sub-scripts by command: state -> dashboard, recover -> recovery scan, evidence -> validator
- All new scripts are fixture-level prototypes; labeled as such in R1 release notes

## Script Safety
- No destructive actions without user confirmation
- No secrets printed
- No real project modification
- All scripts support --dry-run or --help
