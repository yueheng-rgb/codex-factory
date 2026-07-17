# Codex Factory v1.0 — Regression Command Index (Final)

**Generated:** 2026-07-11
**Applies to:** Codex Factory v1.0

---

## Quick Run — All Tests

```powershell
# Run all regression tests (approx. 30 seconds)
Push-Location C:\Codex_App_Factory\testbeds\products-api; npm test; Pop-Location
Push-Location C:\Codex_App_Factory\pilots\mini-inventory-admin; npm test; Pop-Location
Push-Location C:\Codex_App_Factory\testbeds\ecommerce-runtime-validation; npm test; Pop-Location
Push-Location C:\Codex_App_Factory\testbeds\saas-runtime-validation; npm test; Pop-Location
Push-Location C:\Codex_App_Factory\runnable-starters\node-api-postgres; npm test; Pop-Location
```

---

## Individual Commands

### 1. Products API CRUD Testbed
- **Command:** `npm test`
- **Working directory:** `testbeds/products-api`
- **Expected result:** 23/23 PASS
- **Required tools:** Node.js, vitest
- **Skip condition:** Node.js not installed
- **Estimated runtime:** ~2 seconds
- **Failure interpretation:** Products API CRUD, validation, or business rules broken

### 2. Mini Inventory Admin Pilot
- **Command:** `npm test`
- **Working directory:** `pilots/mini-inventory-admin`
- **Expected result:** 22/22 PASS
- **Required tools:** Node.js, vitest
- **Skip condition:** Node.js not installed
- **Estimated runtime:** ~1 second
- **Failure interpretation:** Inventory pilot invariants or API tests broken

### 3. Ecommerce Runtime Validation
- **Command:** `npm test`
- **Working directory:** `testbeds/ecommerce-runtime-validation`
- **Expected result:** 29/29 PASS
- **Required tools:** Node.js, vitest
- **Skip condition:** Node.js not installed
- **Estimated runtime:** ~1 second
- **Failure interpretation:** Ecommerce invariants (price, inventory, status, payment, refund) broken

### 4. SaaS Runtime Validation
- **Command:** `npm test`
- **Working directory:** `testbeds/saas-runtime-validation`
- **Expected result:** 27/27 PASS
- **Required tools:** Node.js, vitest
- **Skip condition:** Node.js not installed
- **Estimated runtime:** ~1 second
- **Failure interpretation:** SaaS invariants (tenant, quota, subscription, API key, billing) broken

### 5. Node API Postgres Starter
- **Command:** `npm test`
- **Working directory:** `runnable-starters/node-api-postgres`
- **Expected result:** 13/13 PASS
- **Required tools:** Node.js, vitest
- **Skip condition:** Node.js not installed
- **Estimated runtime:** ~2 seconds
- **Failure interpretation:** Starter API or health check broken

### 6. Starter Type Consistency
- **Command:** `.\runtime\starter-type-consistency-check.ps1`
- **Working directory:** `C:\Codex_App_Factory`
- **Expected result:** typecheck PASS, build PASS, tests PASS for all starters
- **Required tools:** PowerShell, Node.js
- **Skip condition:** No starters exist
- **Estimated runtime:** ~30 seconds
- **Failure interpretation:** Type interface inconsistency between route/service/repo/schema in a starter

### 7. Expert Pack Loader
- **Command:** `.\runtime\expert-pack-loader.ps1`
- **Working directory:** `C:\Codex_App_Factory`
- **Expected result:** Both packs (ecommerce, saas-tool) loaded with status ACTIVE
- **Required tools:** PowerShell
- **Skip condition:** Expert pack registry missing
- **Estimated runtime:** ~1 second
- **Failure interpretation:** Expert pack file missing or malformed

### 8. Expert Pack Activation (Ecommerce)
- **Command:** `.\runtime\expert-pack-activation.ps1 -TaskDescription "Build inventory management with price and stock" -ProjectType "fullstack-admin"`
- **Working directory:** `C:\Codex_App_Factory`
- **Expected result:** ecommerce pack activated with 7 invariants
- **Required tools:** PowerShell
- **Skip condition:** Expert pack loader fails
- **Estimated runtime:** ~1 second
- **Failure interpretation:** Pack activation logic broken

### 9. Expert Pack Activation (SaaS)
- **Command:** `.\runtime\expert-pack-activation.ps1 -TaskDescription "Build SaaS platform with tenant isolation and billing" -ProjectType "backend-api"`
- **Working directory:** `C:\Codex_App_Factory`
- **Expected result:** saas-tool pack activated with 8 invariants
- **Required tools:** PowerShell
- **Skip condition:** Expert pack loader fails
- **Estimated runtime:** ~1 second
- **Failure interpretation:** Pack activation logic broken

### 10. Production Readiness Checker
- **Command:** `.\runtime\production-readiness-checker.ps1 -ProjectPath "testbeds/saas-runtime-validation"`
- **Working directory:** `C:\Codex_App_Factory`
- **Expected result:** Score ~84, level READY_FOR_STAGING
- **Required tools:** PowerShell
- **Skip condition:** Project path does not exist
- **Estimated runtime:** ~2 seconds
- **Failure interpretation:** Readiness dimensions broken or checker logic error

### 11. Semgrep Smoke
- **Command:** `semgrep --config=auto testbeds/products-api/src/`
- **Working directory:** `C:\Codex_App_Factory`
- **Expected result:** CLEAN or FINDINGS_PRESENT (not TOOL_FAILED)
- **Required tools:** semgrep (pip/brew)
- **Skip condition:** semgrep not installed
- **Estimated runtime:** ~5 seconds
- **Failure interpretation:** semgrep broken or not in PATH; check `semgrep --version`

### 12. Autocannon Smoke
- **Command:** `npx autocannon -d 5 http://localhost:3100/api/products`
- **Working directory:** `C:\Codex_App_Factory`
- **Expected result:** requests/sec > 0, errors = 0
- **Required tools:** Node.js, autocannon (npx)
- **Skip condition:** Service not running on expected port
- **Estimated runtime:** ~10 seconds
- **Failure interpretation:** Service not responding or port mismatch

### 13. Playwright Smoke
- **Command:** `npx playwright test --config=playwright.config.ts 2>&1` (requires per-project setup)
- **Working directory:** `C:\Codex_App_Factory`
- **Expected result:** RUN or SKIPPED_WITH_REASON
- **Required tools:** Node.js, playwright (npx), chromium
- **Skip condition:** Playwright not configured in project or browser not installed
- **Estimated runtime:** ~15 seconds
- **Failure interpretation:** Browser version mismatch or missing playwright dependency

### 14. Benchmark Suite v3
- **Command:** `.\runtime\R4_0_benchmark_runner.ps1 -SuitePath "outputs/R6_1_benchmark_suite_v3.json"`
- **Working directory:** `C:\Codex_App_Factory`
- **Expected result:** 10/10 PASS
- **Required tools:** PowerShell
- **Skip condition:** Suite file missing
- **Estimated runtime:** ~5 seconds
- **Failure interpretation:** Capability regression since last benchmark run

### 15. Deprecated Direction Lock Check
- **Command:** `Get-Content outputs\R7_0_DEPRECATED_DIRECTIONS_FINAL_LOCK.md | Select-String "FORBIDDEN"`
- **Working directory:** `C:\Codex_App_Factory`
- **Expected result:** 10 "FORBIDDEN" matches
- **Required tools:** PowerShell
- **Skip condition:** Lock file missing
- **Estimated runtime:** <1 second
- **Failure interpretation:** Deprecated lock file missing or fewer than 10 rules

---

## Total Tests Summary

| Category | Tests | Status |
|----------|-------|--------|
| Products API | 23 | PASS |
| Mini Inventory Admin | 22 | PASS |
| Ecommerce Runtime | 29 | PASS |
| SaaS Runtime | 27 | PASS |
| Node API Starter | 13 | PASS |
| **Code Tests Total** | **114** | **ALL PASS** |
| Starter Consistency | typecheck+build+tests | PASS |
| Expert Pack Loader | 2 packs | ACTIVE |
| Semgrep Smoke | CLEAN | AVAILABLE |
| Autocannon Smoke | requests/sec > 0 | AVAILABLE |
| Playwright Smoke | per-project | AVAILABLE |
| Benchmark Suite v3 | 10 benchmarks | ALL PASS |
| Deprecated Lock | 10 rules | LOCKED |
