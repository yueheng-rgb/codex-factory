# DASHBOARD_INTEGRATION.md
> Part of: FACTORY-RECOVERY-0 / I

## Integration Points
- Recovery scan uses dashboard health categories as initial assessment
- Recovery LEVEL determined by dashboard CRITICAL/WARNING counts
- Recovery plan actions displayed in dashboard warnings section
- `factory state` shows active recovery plan path
- Recovery status integrated into dashboard header (🟢/🟡/🔴)
- Dashboard CORRUPT_OR_INCONSISTENT → triggers full recovery scan
- Recovery completion → dashboard auto-refresh

## Non-Integration
- Dashboard is NOT used as evidence for repair (Tier 2 derived)
- Dashboard does NOT auto-trigger destructive recovery
- Dashboard does NOT replace recovery plan
