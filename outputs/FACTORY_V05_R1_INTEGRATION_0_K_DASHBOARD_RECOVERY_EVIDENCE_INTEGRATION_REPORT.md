# FACTORY-V05-R1-INTEGRATION-0 — K: Dashboard / Recovery / Evidence Integration

## Integrated from STATE-DASHBOARD-0 (38/38), RECOVERY-0 (28/28), EVIDENCE-TAXONOMY-0 (29/29)

### Dashboard
| Feature | R1 Behavior |
|---------|-------------|
| CLI Dashboard | factory state — Markdown/JSON output |
| Data Model | projectId, paths, phase, gates, blockers, risks |
| Agent Ledger View | factory state --agents — per-agent tracking |
| Health Warnings | Stale, missing, corrupt, foreign-context detection |
| Path Visibility | All relevant paths shown; UNKNOWN_WITH_REASON for missing |
| Dashboard Template | templates/state-dashboard.template.md |

### Recovery
| Feature | R1 Behavior |
|---------|-------------|
| Failure Mode Catalog | 20 failure modes cataloged |
| Decision Matrix | AUTO_REBUILD / USER_CONFIRM / BLOCK_AND_REPORT |
| Trusted Source Hierarchy | Raw output > governance report > snapshot > chat |
| Startup Protocol | Check registry, fingerprints, verifier, ledger |
| Phase Close Recovery | Interrupted close -> DRAFT_RECOVERY_STATE |
| Recovery Scan | factory recover --dry-run |
| Repair Prompts | recovery-plan.prompt.md, recovery-repair-derived.prompt.md |

### Evidence Taxonomy
| Level | Name | R1 Claim Support |
|-------|------|-----------------|
| E0 | UNSUPPORTED | No claim support |
| E1 | DESIGN_ANALYSIS | Architecture design only |
| E2 | POLICY_REVIEW | Document review only |
| E3 | LIVE_INSPECTED | File/script inspected |
| E4 | LIVE_EXECUTED_FIXTURE | Fixture-level execution |
| E5 | RAW_OUTPUT_EXECUTION | Generated code/output exists |
| E6 | REALWORLD_LOCAL | Local validation (R1 ceiling) |
| E7 | PRODUCTION_VALIDATED | Out of R1 scope |
| E8 | UNIVERSAL_PROOF | Out of R1 scope |

### Key Rules
- Dashboard/snapshot/attach NOT primary evidence.
- Production claims require E7 (out of R1 scope).
- Universal claims require E8 (out of R1 scope).
- Evidence validator blocks overclaim.
- Recovery never auto-repairs; PLAN first.
- Missing verifier cannot be auto-faked.
