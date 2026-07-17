# I: Dashboard / Recovery / Evidence Integration — R1 Embedding

## Integration Targets from STATE-DASHBOARD-0 (38/38), RECOVERY-0 (28/28), EVIDENCE-TAXONOMY-0 (29/29)

| Asset | Source Path | R1 Target Path | Category |
|-------|------------|----------------|----------|
| Dashboard Data Model | `factory-dashboard/STATE_DASHBOARD_DATA_MODEL.md` | `governance/factory-dashboard/` | DASHBOARD |
| CLI Dashboard Contract | `factory-dashboard/CLI_DASHBOARD_CONTRACT.md` | `governance/factory-dashboard/` | CLI_COMMAND |
| Dashboard Template | `factory-dashboard/templates/state-dashboard.template.md` | `templates/` | SCHEMA_TEMPLATE |
| Dashboard Prototype | `factory-dashboard/scripts/state-dashboard-prototype.ps1` | `scripts/` | SCRIPT_RUNTIME |
| Recovery Failure Catalog | `factory-recovery/RECOVERY_FAILURE_MODE_CATALOG.md` | `governance/factory-recovery/` | GOVERNANCE_RULE |
| Recovery Decision Matrix | `factory-recovery/RECOVERY_DECISION_MATRIX.md` | `governance/factory-recovery/` | GOVERNANCE_RULE |
| Recovery Script MVP | `factory-recovery/scripts/recovery-scan-mvp.ps1` | `scripts/` | SCRIPT_RUNTIME |
| Evidence Level Model | `factory-evidence/EVIDENCE_LEVEL_MODEL.md` | `governance/factory-evidence/` | GOVERNANCE_RULE |
| Claim Support Matrix | `factory-evidence/CLAIM_SUPPORT_MATRIX.md` | `governance/factory-evidence/` | GOVERNANCE_RULE |
| Evidence Record Schema | `factory-evidence/schemas/evidence-record.schema.json` | `schemas/` | SCHEMA_TEMPLATE |
| Evidence Validator MVP | `factory-evidence/scripts/evidence-validator-mvp.ps1` | `scripts/` | SCRIPT_RUNTIME |

## R1 Integration Rules
- Dashboard shows lifecycle state, agent ledger, evidence levels, paths, warnings.
- Recovery scan runs at startup; missing/corrupt/stale/foreign state detected.
- Evidence validator blocks overclaim: snapshot/attach/dashboard NOT primary evidence.
- Production claims require E7; universal claims require E8.
- Local readiness NEVER promoted to production readiness.
- Missing verifier cannot be auto-faked; blocks full PASS.
- Dashboard/Recovery/Evidence scripts are fixture-level in R1; not production-hardened.
- CLI commands: `factory state`, `factory recover --dry-run`, `factory evidence check`.
