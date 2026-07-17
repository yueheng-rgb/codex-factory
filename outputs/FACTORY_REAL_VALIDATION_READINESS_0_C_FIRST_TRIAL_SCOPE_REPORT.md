# FACTORY-REAL-VALIDATION-READINESS-0 — First Trial Validation Scope

**Date**: 2026-06-29
**Phase**: FACTORY-REAL-VALIDATION-READINESS-0
**Sub-step**: C

---

## 1. What the First Trial Validates (12 Behaviors)

| # | Behavior | What Success Looks Like |
|---|----------|------------------------|
| 1 | Select folder + state requirement entry | User can point Factory at a project folder; Factory records projectId and path |
| 2 | Bootstrap / router / preflight | Factory classifies project type, selects build mode, runs preflight checks |
| 3 | Project identity creation | `.codex-factory/project-id.json` created with correct metadata |
| 4 | Dashboard brief | `factory dashboard` outputs readable state: phase, mode, project, risks |
| 5 | Multi-agent decision gate (if qualifying) | Factory asks (not auto-starts) whether to use multi-agent; user must confirm |
| 6 | Working copy path handling | When working copy is created, original is untouched; paths are tracked |
| 7 | Cleanup PLAN behavior | `factory cleanup` outputs a PLAN (not execution); lists what would be removed |
| 8 | Phase close | `factory phase-close` updates phase-ledger, regenerates snapshot, reports verdict |
| 9 | Handoff paths | Factory can output handoff summary referencing v0.5-R1 artifacts |
| 10 | Evidence taxonomy caveats | Dashboard/snapshot marked as TIER-3 (navigation), not TIER-1 (evidence) |
| 11 | Context ledger freshness after phase close | Phase-ledger appends new entry; mount freshness re-verified |
| 12 | Direction guard does not resurrect stale phases | After phase close, nextRecommendedPhases does not include completed phases |

## 2. What the First Trial Does NOT Validate

| # | Excluded Behavior | Reason |
|---|-------------------|--------|
| X-01 | Production deployment | Not in R1 scope |
| X-02 | Cloud sync | DG-006: no cloud without local proof |
| X-03 | v0.6 | v0.5-R1 is current; v0.6 not started |
| X-04 | Native Build Pro as default | DG-003 / FROZEN-002 |
| X-05 | Real secret handling beyond detection | RISK-CS-002 pattern; detection only |
| X-06 | Destructive cleanup | Cleanup PLAN only; no DELETE |
| X-07 | TCM secret rotation | User responsibility; not Factory's |
| X-08 | Multi-agent auto-start | DG-005: multi-agent NOT default |
| X-09 | Performance benchmarking | Not in R1 scope |
| X-10 | Cross-project comparison | First trial uses single project |

## 3. Trial Sequence

```
1. User opens fresh Codex window at Factory install path
2. User states requirement: "validate project at <path>"
3. Factory bootstrap runs (router → mode selector → preflight)
4. Project identity created
5. Dashboard shown → user confirms
6. Multi-agent question asked if project qualifies (user decides)
7. Working copy created (if trial mode is working-copy)
8. Trial tasks executed per scope (items 1-12 above)
9. Cleanup PLAN output (no execution without confirmation)
10. Phase close: ledger updated, snapshot generated, verdict recorded
11. Mount freshness re-verified
12. Handoff summary output
```

## 4. PASS / WARN / FAIL Criteria

| Level | Definition |
|-------|------------|
| **PASS** | All 12 behaviors produce expected output; no safety boundary crossed; phase-ledger updates correctly |
| **WARN** | Expected output produced but with caveat (e.g., CLI name mismatch logged but not blocking) |
| **FAIL** | Any safety boundary crossed; any behavior produces wrong output; phase-ledger does not update; direction guard becomes stale |
