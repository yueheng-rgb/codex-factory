# FACTORY-PROJECT-ISOLATION-0 — G: Cleanup Isolation Report

> Phase: FACTORY-PROJECT-ISOLATION-0
> Section: G — Cleanup Isolation
> Date: 2026-06-29

## Deliverables

| File | Path |
|------|------|
| Isolation Doc | `factory-isolation/CLEANUP_ISOLATION.md` |
| Governance JSON | `governance/factory-isolation/factory-project-isolation-0-cleanup-isolation.json` |

## Summary

Defines 5 cleanup isolation rules:
1. Resolve project identity first (before any action)
2. Scope all paths to project (reject foreign paths)
3. Never cross project boundaries (warn + remove from plan)
4. Global cache requires separate scope + escalated confirmation
5. Project deletion is separately gated (not cleanup)

Cleanup state stored per-project at `{governancePath}/cleanup-state.json`.
