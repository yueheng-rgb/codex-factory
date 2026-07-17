# FACTORY-MEMORY-QUALITY-P3 — F: Cleanup Planner

**Script:** `scripts/factory-cleanup-planner.ps1`

```
factory-cleanup-planner.ps1 -ProjectId {id} -Mode PLAN
factory-cleanup-planner.ps1 -ProjectId {id} -Mode ARCHIVE -Confirm
factory-cleanup-planner.ps1 -ProjectId {id} -Mode DELETE -Confirm
factory-cleanup-planner.ps1 -ProjectId {id} -Mode DELETE -Confirm -ForceEvidence
```

**Safety:** PLAN default. DELETE=PLAN→review→--Confirm. CORE_EVIDENCE requires --ForceEvidence.

---

**Status:** CLEANUP_PLANNER_CREATED
