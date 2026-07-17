# FACTORY-V05-R1-INTEGRATION-0 — O: CLI Smoke

## Results: 4/4 scripts validated

| Script | Lines | Params | Functions | Syntax |
|--------|-------|--------|-----------|--------|
| scripts/factoryctl.ps1 | 110 | Yes | Yes | OK |
| scripts/factory-state-dashboard-prototype.ps1 | 270 | Yes | No | OK |
| scripts/factory-recovery-scan.ps1 | 220 | Yes | No | OK |
| scripts/factory-evidence-validator.ps1 | 22 | Yes | No | OK |

## CLI Command Discovery
- factoryctl.ps1 — main CLI entry (v0.5 canonical)
- New R1 sub-commands via dispatch: state, recover, evidence, cleanup, lifecycle
- All new scripts support --help and --dry-run patterns

## Note on CLI Name
- v0.5 shipped with `factoryctl.ps1` as entry point
- R1 integration plan targets `factory.ps1` as canonical name
- Both names coexist; `factoryctl.ps1` documented as alias in release notes
- Future R1-R2 can complete the rename
