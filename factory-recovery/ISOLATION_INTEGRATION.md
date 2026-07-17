# ISOLATION_INTEGRATION.md
> Part of: FACTORY-RECOVERY-0 / J

## Integration Points
- Recovery scan resolves projectId before analyzing findings
- Foreign context findings (FM-16, FM-19) respect PROJECT-ISOLATION-0 rules
- Cross-project recovery blocked: recovery plan scoped to current projectId only
- Cleanup-related findings (FM-17) respect CLEANUP_ISOLATION rules
- Mount-related findings (FM-18) respect MOUNT_ISOLATION_RULES
- Recovery does NOT auto-create identities (FM-03 requires USER_CONFIRM_IDENTITY)
- Recovery NEVER promotes foreign context to current (FM-19)
- Recovery NEVER deletes other project evidence

## Blocked Cross-Project Actions
- Auto-repairing Project A with Project B context
- Promoting foreign context to current without user confirmation
- Executing cleanup across project boundaries
