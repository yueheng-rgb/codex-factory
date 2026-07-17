# V2.5 — Runtime Toolchain Reliability Closure

**Stage**: v2.5
**Date**: 2026-07-12
**Final Classification**: A — V2_5_RUNTIME_TOOLCHAIN_RELIABILITY_CLOSED

---

## Summary

All four toolchain issues from v2.4 have been addressed: one fixed (path), two resolved to PASS (tsx, playwright), one classified with clear install path (C++ sanitizers).

| Issue | v2.4 Status | v2.5 Status | Resolution |
|-------|------------|------------|------------|
| Evidence path | outputs/R2_4 | outputs/V2_4 | Renamed, references updated |
| Miniapp autocannon | BLOCKED (tsx) | PASS (276k/0err) | BOM removed from package.json |
| Playwright | TOOL_FAILED | PASS (canvas smoke) | @playwright/test installed, chromium OK |
| C++ sanitizer | TOOL_UNAVAILABLE | UNAVAILABLE + INSTALL PATH | winget LLVM.LLVM documented |

---

## Detail

### 1. Evidence Path Reconciliation
- `outputs/R2_4` → `outputs/V2_4`
- Internal report references updated
- Naming convention: R2_X for early stages, V2_X for mature stages

### 2. Miniapp Autocannon
- **Root cause**: UTF-8 BOM in `testbeds/miniapp-runtime-validation/package.json` caused tsx parser failure
- **Fix**: Stripped BOM, re-encoded UTF-8 without BOM
- **Result**: Server starts on :3200, autocannon runs 276k requests, 0 errors
- **Note**: Local smoke only, not production capacity proof

### 3. Playwright Reliability
- **Playwright 1.61.1** + **Chromium 149.0.7827.55 (v1228)**
- **Target**: `runnable-starters/vite-threejs-interactive` on :5200
- **Result**: page navigation PASS, canvas exists PASS, page title PASS
- **Note**: Canvas smoke only, not full E2E test suite

### 4. C++ Sanitizer
- **No C++ compiler** on host (no g++, clang, MSVC)
- **Install path**: `winget install LLVM.LLVM` + `winget install Kitware.CMake`
- **Classification**: SANITIZER_UNAVAILABLE_WITH_CLEAR_INSTALL_PATH
- **No fake PASS**

---

## Regression

| Testbed | Tests | Result |
|---------|-------|--------|
| miniapp-runtime-validation | 27/27 | PASS |
| game-threejs-runtime-validation | 30/30 | PASS |
| cpp-memory-safety-runtime-validation | 41/41 | PASS |
| ecommerce-runtime-validation | 29/29 | PASS |
| saas-runtime-validation | 27/27 | PASS |
| admin-system-runtime-validation | 58/58 | PASS |
| products-api | 23/23 | PASS |
| **TOTAL** | **235/235** | **PASS** |

---

## Boundary Compliance

| Rule | Status |
|------|--------|
| No Independent Search Agent | COMPLIANT |
| No Dual Search Channel | COMPLIANT |
| No Implementer direct search | COMPLIANT |
| No chat URL extraction as canonical evidence | COMPLIANT |
| No mock/dry_run as live | COMPLIANT |
| No API key leaked | COMPLIANT |
| No fake sanitizer PASS | COMPLIANT |
| No fake performance PASS | COMPLIANT |
| No production exaggeration | COMPLIANT |
| Deprecated locks preserved | COMPLIANT |

---

## Files Changed

- `outputs/V2_4/` — renamed from R2_4, report updated
- `testbeds/miniapp-runtime-validation/package.json` — BOM removed
- `outputs/V2_5/` — 5 new reports
- `runnable-starters/vite-threejs-interactive/package.json` — @playwright/test added

---

## Known Risks

- C++ sanitizers require manual toolchain install (~2-3 GB)
- Playwright smoke is canvas-only, not full interaction test
- autocannon smoke is health-endpoint only, not API-level load test
- No Vite server permanent start mechanism (ad-hoc per test)

---

## Recommended Next Big Capability

**v2.6: Cross-Pack Integration Smoke** — exercise miniapp + api-service + admin-system packs in a single scenario, validating cross-pack invariant interaction, surface plan accuracy for multi-pack projects, and gate behavior across pack boundaries.
