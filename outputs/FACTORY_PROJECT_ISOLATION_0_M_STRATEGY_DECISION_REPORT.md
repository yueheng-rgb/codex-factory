# FACTORY-PROJECT-ISOLATION-0 — M: Strategy Decision Report

> Phase: FACTORY-PROJECT-ISOLATION-0
> Section: M — Strategy Decision
> Date: 2026-06-29

---

## Q1: Does PROJECT-ISOLATION-0 define cross-project isolation sufficiently?

**YES, in theory.** The phase defines project identity (18 fields), a project registry with 7 lifecycle states, mount isolation rules (5 validation rules), memory boundaries (3 categories), output/governance isolation, cleanup isolation (5 rules), agent ledger isolation (5 rules), working copy isolation (5 rules), and lifecycle interaction (7×7 transition matrix). 10 simulation scenarios exercise all major isolation paths.

Implementation and real validation are deferred.

## Q2: What remains to implement?

| Item | Status |
|------|--------|
| Project identity schema | Defined (JSON Schema) |
| Project registry schema + template | Defined + template ready |
| Mount gate implementation | Protocol defined, code not written |
| Memory boundary enforcement | Protocol defined, code not written |
| Cleanup isolation enforcement | Protocol defined, code not written |
| Agent ledger projectId field | Schema updated |
| Working copy isolation | Protocol defined |
| Lifecycle transition engine | Protocol defined |
| CLI commands (`factory project list/status/switch`) | Not yet defined |
| Real project validation | Deferred |

## Q3: What should next be?

| Priority | Phase | Rationale |
|----------|-------|-----------|
| 1 | **FACTORY-STATE-DASHBOARD-0** | Dashboard needs project identity to show active project |
| 2 | **FACTORY-RECOVERY-0** | Recovery must respect project isolation |
| 3 | **FACTORY-MULTI-AGENT-ORCHESTRATION-1** | Agent isolation requires projectId |
| 4 | **FACTORY-PROJECT-LIFECYCLE-0** | Implement lifecycle transition engine |

## Q4: Should this be integrated into v0.5-R1 later?

**YES.** Once validated with real projects, isolation protocols should be integrated into a v0.5-R1 patch release. Not now.

## Q5: What should NOT be done now?

| Do NOT Do | Reason |
|-----------|--------|
| Create v0.6 | Isolation must be validated first |
| Real project validation | Theory phase — validation deferred |
| Go to cloud | Cloud is deferred |
| Modify v0.5 zip | v0.5 is frozen |
| Build isolation enforcement code | Protocol definition only in this phase |
| Start project deletion implementation | Requires separate PROJECT-DELETION phase |
