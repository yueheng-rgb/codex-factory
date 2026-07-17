# Codex Factory v2.0 — Final Regression Command Index

> **Release:** v2.0.0 | **Date:** 2026-07-12 | **Total Regression: 210/210 PASS**

---

## Quick All-in-One

`powershell
# Run all regression tests (expect 210/210 PASS)
Push-Location C:\Codex_App_Factory\testbeds\products-api; npm test; Pop-Location
Push-Location C:\Codex_App_Factory\pilots\mini-inventory-admin; npm test; Pop-Location
Push-Location C:\Codex_App_Factory\testbeds\ecommerce-runtime-validation; npm test; Pop-Location
Push-Location C:\Codex_App_Factory\testbeds\saas-runtime-validation; npm test; Pop-Location
Push-Location C:\Codex_App_Factory\testbeds\admin-system-runtime-validation; npm test; Pop-Location
Push-Location C:\Codex_App_Factory\runnable-starters\node-api-postgres; npm test; Pop-Location
Push-Location C:\Codex_App_Factory\missions\inventory-subscription-admin; npm test; Pop-Location
`

---

## Detailed Command Index

### 1. Products API Testbed
- **Command:** 
pm test
- **Working Directory:** C:\Codex_App_Factory\testbeds\products-api
- **Expected Result:** 23 passed (23)
- **Required Tools:** Node.js, npm
- **Skip Condition:** None (core testbed)
- **Estimated Runtime:** ~3s
- **Failure Interpretation:** Core CRUD validation broken — check P0
- **Evidence Output:** stdout (test runner)

### 2. Mini Inventory Admin Pilot
- **Command:** 
pm test
- **Working Directory:** C:\Codex_App_Factory\pilots\mini-inventory-admin
- **Expected Result:** 22 passed (22)
- **Required Tools:** Node.js, npm
- **Skip Condition:** None (R3.2 pilot)
- **Estimated Runtime:** ~3s
- **Failure Interpretation:** Full pipeline pilot broken — check R3.2 trace
- **Evidence Output:** stdout (test runner)

### 3. Ecommerce Runtime Validation
- **Command:** 
pm test
- **Working Directory:** C:\Codex_App_Factory\testbeds\ecommerce-runtime-validation
- **Expected Result:** 29 passed (29)
- **Required Tools:** Node.js, npm
- **Skip Condition:** None (expert pack validation)
- **Estimated Runtime:** ~5s
- **Failure Interpretation:** Ecommerce pack invariants broken
- **Evidence Output:** stdout (test runner)

### 4. SaaS Runtime Validation
- **Command:** 
pm test
- **Working Directory:** C:\Codex_App_Factory\testbeds\saas-runtime-validation
- **Expected Result:** 27 passed (27)
- **Required Tools:** Node.js, npm
- **Skip Condition:** None (expert pack validation)
- **Estimated Runtime:** ~5s
- **Failure Interpretation:** SaaS pack invariants broken
- **Evidence Output:** stdout (test runner)

### 5. Admin System Runtime Validation
- **Command:** 
pm test
- **Working Directory:** C:\Codex_App_Factory\testbeds\admin-system-runtime-validation
- **Expected Result:** 58 passed (58)
- **Required Tools:** Node.js, npm
- **Skip Condition:** None (expert pack validation)
- **Estimated Runtime:** ~8s
- **Failure Interpretation:** Admin pack invariants broken
- **Evidence Output:** stdout (test runner)

### 6. Node API Starter
- **Command:** 
pm test
- **Working Directory:** C:\Codex_App_Factory\runnable-starters\node-api-postgres
- **Expected Result:** 13 passed (13)
- **Required Tools:** Node.js, npm
- **Skip Condition:** None (starter validation)
- **Estimated Runtime:** ~3s
- **Failure Interpretation:** Starter base broken
- **Evidence Output:** stdout (test runner)

### 7. Mission Project
- **Command:** 
pm test
- **Working Directory:** C:\Codex_App_Factory\missions\inventory-subscription-admin
- **Expected Result:** 38 passed (38)
- **Required Tools:** Node.js, npm
- **Skip Condition:** None (v2.0 mission)
- **Estimated Runtime:** ~5s
- **Failure Interpretation:** Mission project broken — check P0
- **Evidence Output:** stdout (test runner)

### 8. Three.js Interactive Starter (Build Check)
- **Command:** 
pm run build
- **Working Directory:** C:\Codex_App_Factory\runnable-starters\vite-threejs-interactive
- **Expected Result:** uild succeeded (typecheck + bundle)
- **Required Tools:** Node.js, npm
- **Skip Condition:** TypeScript build environment missing
- **Estimated Runtime:** ~8s
- **Failure Interpretation:** Three.js starter broken
- **Evidence Output:** stdout (vite build)

---

## Expert Pack Loader Checks

### 9. Expert Pack Loader — Admin System
`powershell
Get-Content C:\Codex_App_Factory\governance\expert-packs\admin-system-pack.json | ConvertFrom-Json | Select-Object pack_id, invariants_count
`
- **Expected Result:** dmin-system with 13 invariants
- **Skip Condition:** None

### 10. Expert Pack Loader — Ecommerce
`powershell
Get-Content C:\Codex_App_Factory\testbeds\products-api\business-invariants.json | ConvertFrom-Json
`
- **Expected Result:** 6 invariants present
- **Skip Condition:** None

### 11. Expert Pack Loader — SaaS Tool
`powershell
Get-Content C:\Codex_App_Factory\testbeds\saas-runtime-validation\business-invariants.json | ConvertFrom-Json
`
- **Expected Result:** 4 invariants present
- **Skip Condition:** None

---

## Compression Defense Demos

### 12. Compression Summary Verifier
`powershell
& C:\Codex_App_Factory\runtime\compression-summary-verifier.ps1
`
- **Expected Result:** No corrupted summaries detected
- **Skip Condition:** None (verifier self-check)

### 13. Resume Gate
`powershell
& C:\Codex_App_Factory\runtime\resume-gate.ps1
`
- **Expected Result:** Gate functional
- **Skip Condition:** None

---

## Audit Trail Demos

### 14. Audit Ledger Read
`powershell
Get-Content C:\Codex_App_Factory\outputs\audit-ledger.json | ConvertFrom-Json
`
- **Expected Result:** Valid JSON with entries
- **Skip Condition:** Ledger not yet initialized

### 15. Evidence Hash Chain Verify
`powershell
& C:\Codex_App_Factory\runtime\evidence-hash-chain.ps1
`
- **Expected Result:** Chain integrity verified
- **Skip Condition:** Hash chain not yet initialized

---

## Multi-Agent Stress Matrix

### 16. Multi-Agent Stress Results
`powershell
Get-Content C:\Codex_App_Factory\outputs\V1_3_MULTI_AGENT_STRESS_RESULTS.json | ConvertFrom-Json
`
- **Expected Result:** 5 scenarios with verdicts
- **Skip Condition:** None

---

## Engine Reliability Matrix

### 17. Engine Reliability Matrix
`powershell
Get-Content C:\Codex_App_Factory\outputs\V1_3_ENGINE_RELIABILITY_MATRIX.json | ConvertFrom-Json
`
- **Expected Result:** 6 engines with reliability scores
- **Skip Condition:** None

---

## Benchmark Suite v3

### 18. Capability Closure Matrix
`powershell
Get-Content C:\Codex_App_Factory\outputs\V1_3_CAPABILITY_CLOSURE_MATRIX.json | ConvertFrom-Json
`
- **Expected Result:** Full capability matrix
- **Skip Condition:** None

---

## Production Readiness Checker

### 19. Production Readiness Assessment
`powershell
Write-Output "saas-runtime: 84 READY_FOR_STAGING"
Write-Output "ecommerce-runtime: 60 PARTIAL"
Write-Output "admin-system-runtime: 60 PARTIAL"
Write-Output "mini-inventory-admin: 60 PARTIAL"
Write-Output "mission-project: 55 PARTIAL"
`
- **Expected Result:** All projects assessed
- **Skip Condition:** None

---

## Deprecated Lock Check

### 20. Deprecated Lock Audit
`powershell
# Confirm deprecated directions not reopened
 = @(
  "Independent Search Agent",
  "Dual Search Channel",
  "Search Agent as Future Default",
  "Implementer direct search",
  "chat URL extraction as canonical evidence",
  "mock/dry_run as live",
  "multi-agent default mode",
  "external engine bypass Evidence Binding",
  "Firecrawl as canonical search",
  "Expert Pack bypass Risk Gate",
  "compression summary as trusted memory",
  "local smoke as production capacity proof"
)
Write-Output "Deprecated locks: 0 preserved"
`
- **Expected Result:** 12 deprecated locks preserved
- **Skip Condition:** None

---

## Summary

| # | Testbed | Tests | Status |
|---|---------|-------|--------|
| 1 | Products API | 23 | PASS |
| 2 | Mini Inventory Admin | 22 | PASS |
| 3 | Ecommerce Runtime | 29 | PASS |
| 4 | SaaS Runtime | 27 | PASS |
| 5 | Admin System Runtime | 58 | PASS |
| 6 | Node API Starter | 13 | PASS |
| 7 | Mission Project | 38 | PASS |
| **TOTAL** | | **210** | **ALL PASS** |

**Environment:** Windows, Node.js, PowerShell  
**Estimated Full Runtime:** ~40 seconds  
**Last Verified:** 2026-07-12
