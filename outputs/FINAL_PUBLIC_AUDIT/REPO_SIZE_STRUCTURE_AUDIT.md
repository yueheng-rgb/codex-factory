# Repo Size & Structure Audit

## Audit Date: 2026-07-17

## Size Summary

| Metric | Value |
|---|---|
| Total on-disk (excl node_modules/.next/zip) | 1638.9 MB |
| Git-tracked files | ~4659 files |
| Top-level items | 168 |
| Max directory depth | 13 levels |
| `.gitignore` configured | Yes (node_modules, .next, dist, *.zip, artifacts/remote) |
| `.gitattributes` configured | Yes (LF normalization) |

## Largest Directories (on disk)

| Directory | Size | Notes |
|---|---|---|
| `runnable-starters/` | 770.9 MB | Contains node_modules (gitignored), starter templates |
| `testbeds/` | 511.7 MB | Contains node_modules (gitignored), 8 testbeds |
| `workspaces/` | 115.4 MB | Run artifacts (in .gitignore) |
| `pilots/` | 57.9 MB | Trial runs |
| `missions/` | 57.9 MB | Trial runs |
| `runtime/` | 26.1 MB | Core PowerShell modules (committed) |
| `outputs/` | 18.5 MB | Reports & manifests (committed) |

## Structural Observations

1. **168 top-level items** — high but acceptable for a framework repo
2. **Deep nesting** (13 levels) — primarily in `governance/` tree, by design
3. **Git-tracked size** is much smaller than on-disk (~200MB vs 1.6GB)
4. **`runnable-starters/` and `testbeds/`** contain their own `node_modules/` — already gitignored

## Recommendations (non-blocking)

1. Consider moving `missions/`, `pilots/`, `trials/` into a `trials-archive/` parent directory
2. Consider adding `workspaces/runs/` to `.gitignore` (already done)
3. Consider a `RELEASE_ASSETS.md` explaining directory purpose to newcomers
4. No structural changes required for public release

## Verdict
**ACCEPTABLE_FOR_PUBLIC** — Size is within GitHub limits. Structure is complex but functional. No blocking issues.
