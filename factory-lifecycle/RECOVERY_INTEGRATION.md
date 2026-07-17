# RECOVERY_INTEGRATION.md
> Recovery respects lifecycle: CORRUPT → recovery mandatory before any transition. FROZEN/ARCHIVED → query-only recovery. DELETED → restore requires plan + double confirmation. Recovery NEVER auto-transitions state without user confirmation.
