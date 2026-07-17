# FACTORY-BUILD-8: Native Build Pro Matched Trial — Final Report

**Phase**: FACTORY-BUILD-8 | **Date**: 2026-06-27 | **Status**: **PASS** (29/29)

---

## 1. Executive Summary

Build Lite and Native Build Pro were compared on the same AtlasOps Portal Lite sealed spec. **Both modes produced complete, functional products.** Native Build Pro (3 agents with fork_context:false) produced richer output with more polish. Build Lite produced leaner, faster output.

---

## 2. Run Comparison

| Dimension | RUN-LITE | RUN-PRO |
|-----------|----------|---------|
| Mode | Build Lite | Native Build Pro |
| Agents | 1 (main window) | 3 (Lorentz/Lovelace/Maxwell) |
| Native spawn | No | Yes (fork_context:false) |
| Product files | 31 source | 31+ source + deps |
| Memory files | 10 | 9 |
| Backend routes | 9 modules | 9 modules |
| Frontend pages | 7 pages + app.js | 7 pages + search + notifications |
| UI polish | Basic | Rich (392-line CSS, pagination, modals) |
| Tests | 4 test cases | 10 test cases |
| Write-scope violations | N/A (single agent) | 0 |

---

## 3. Native Agent Execution

| Agent | Nickname | Role | Output |
|-------|----------|------|--------|
| `019f071c-621b` | Lorentz | worker-backend | 18 files, Express + sql.js, 8 DB tables, JWT+bcrypt, 3 default users |
| `019f071c-6281` | Lovelace | worker-frontend | 13 files, SPA with 7 pages, search, notifications, 4-state handling |
| `019f071c-62d5` | Maxwell | worker-verify | 4 files, test runner, integration, diagnostic, recovery |

All 3 completed successfully with fork_context:false and 0 write-scope overlaps.

---

## 4. Key Findings

1. **Both modes produce complete, functional products** for medium-complexity projects
2. **Native Build Pro agents produce more polished output** (richer UI, more test cases)
3. **Build Lite is leaner and faster** for single-developer workflows
4. **Native Build Pro adds dependency management by agents** — useful but adds overhead
5. **0 write-scope violations across all native agents**
6. **v0.5 release: STILL BLOCKED** — packaging decision is separate from capability proof
7. **Multi-agent default: REJECTED** — CONDITIONAL only

---

## 5. Recommendation

- **For single developers**: Build Lite remains best cost/benefit
- **For teams / complex projects**: Native Build Pro shows real value
- **Next phase**: User review or FACTORY-BUILD-LITE-PACK-PREP

## 6. References

- `C:\Codex_App_Factory\harness\build-trials\native-build-pro-matched-trial\`
- `C:\Codex_App_Factory\scripts\factory-build-8-native-build-pro-matched-trial-verify.ps1`
