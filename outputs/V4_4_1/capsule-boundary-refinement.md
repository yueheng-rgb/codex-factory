# V4.4.1 Capsule Boundary Refinement

## Problem
Backend worker capsule's `forbidden_files` contained `src/*/auth*` — a **domain-keyword pattern**.
The backend worker was assigned **T5 (Auth & Permission Module)**, which inherently requires
creating auth files. Result: 5 legitimate auth files were flagged as boundary violations.

**This was a capsule design conflict, not a worker violation.**

## Fix

| Aspect | Before (V4.4) | After (V4.4.1) |
|--------|--------------|----------------|
| forbidden_files principle | Domain keywords (`src/*/auth*`) | Cross-worker boundaries |
| Backend capsule | `src/*/auth*`, `config/secrets*` | `config/secrets*`, `src/worker-frontend/*`, `tests/worker-frontend/*`, `src/worker-qa/*`, `tests/worker-qa/*` |
| Auth files in own dir | Flagged as violation | Allowed (worker's own directory) |
| Frontend touching backend | Caught | Still caught |
| Rogue worker | Caught | Still caught |

## Conflict Detector
Added in `New-WorkerCapsule` function. Detects when an assigned task (e.g., auth module)
conflicts with forbidden_files. Auto-refines to cross-worker patterns and records
`capsule_boundary_refinement` note.

## Boundary Regression: 4/4 PASS

| Test | Result |
|------|--------|
| Backend auth files in own dir | PASS (0 violations) |
| Frontend files in own dir | PASS (0 violations) |
| QA files in own dir | PASS (0 violations) |
| Rogue frontend touching backend | PASS (2 violations correctly caught) |
