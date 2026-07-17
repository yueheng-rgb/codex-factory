# FACTORY-MEMORY-QUALITY-P3 — D: Cleanup Modes

**Timestamp:** 2026-06-28T18:00:00+08:00

---

| Mode | Default | Confirm | Reversible | Effect |
|------|:---:|:---:|:---:|--------|
| **PLAN** | ✅ | — | N/A | Preview only |
| ARCHIVE | — | ✅ | ✅ | Prune cache, keep evidence |
| FREEZE | — | ✅ | ✅ | Preserve all, no mount |
| PRUNE | — | ✅ | ❌ | Remove cache+stale+dupes |
| DELETE | — | ✅✅ | ❌ | 2-step: PLAN→CONFIRM |

---

**Status:** CLEANUP_MODES_DEFINED
