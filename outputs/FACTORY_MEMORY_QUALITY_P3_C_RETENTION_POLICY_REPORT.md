# FACTORY-MEMORY-QUALITY-P3 — C: Retention Policy

**Timestamp:** 2026-06-28T18:00:00+08:00

---

| ID | Rule | Category |
|----|------|----------|
| RET-001 | CORE_EVIDENCE: PERMANENT | CORE_EVIDENCE |
| RET-002 | PHASE_ARTIFACTS: PROJECT_LIFETIME | PHASE_ARTIFACTS |
| RET-003 | CACHE: PRUNABLE (keep last 5) | CACHE |
| RET-004 | STALE: RETIRE_OR_PRUNE | STALE |
| RET-005 | DUPLICATE: keep highest tier | DUPLICATE |
| RET-006 | FROZEN: preserve all, no auto-cleanup | ALL |
| RET-007 | ARCHIVED: evidence preserved, cache pruned | ALL |
| RET-008 | DELETE: 2-step, evidence requires --force | ALL |

---

**Status:** RETENTION_POLICY_DEFINED
