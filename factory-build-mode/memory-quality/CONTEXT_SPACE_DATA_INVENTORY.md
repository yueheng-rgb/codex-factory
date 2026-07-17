# Context Space Data Inventory

## Categories

| Category | Retention | Deletable |
|----------|-----------|:---:|
| CORE_EVIDENCE | PERMANENT | ❌ (--force-evidence) |
| PHASE_ARTIFACTS | PROJECT_LIFETIME | ❌ |
| CACHE | PRUNABLE | ✅ |
| STALE | RETIRE_OR_PRUNE | ✅ |
| DUPLICATE | DEDUP_LOWEST | ✅ |

## Source Tiers

| Tier | Name | Priority |
|------|------|----------|
| 0 | RAW_EVIDENCE | HIGHEST |
| 1 | GOVERNANCE | HIGH |
| 2 | REPORTS | MEDIUM |
| 3 | CACHE | LOW |

## Per-Project Inventory

- project_id
- total_size_kb
- categories: {CORE_EVIDENCE, PHASE_ARTIFACTS, CACHE, STALE, DUPLICATE}
- last_active: ISO8601
- status: ACTIVE | FROZEN | ARCHIVED | DELETED
