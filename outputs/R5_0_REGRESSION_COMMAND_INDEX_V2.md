# R5.0 — Regression Command Index v2
# Codex Factory Foundation RC
# Generated: 2026-07-11
# Total commands: 20

## Category 1: Search Baseline Regression

### CMD-001: Search Doctrine Regression Tests
- command: `powershell -File .\runtime\search-doctrine-regression-tests.ps1`
- working_directory: `C:\Codex_App_Factory`
- expected_result: All doctrine regression tests PASS
- estimated_runtime: ~30s
- required_tools: PowerShell
- skip_condition: None

### CMD-002: Search Result Quality Gate Check
- command: `powershell -File .\runtime\search-result-quality-gate.ps1`
- working_directory: `C:\Codex_App_Factory`
- expected_result: Quality gate validates search results
- estimated_runtime: ~10s
- required_tools: PowerShell
- skip_condition: None

### CMD-003: Workflow Search Consistency Check
- command: `powershell -File .\runtime\workflow-search-consistency-check.ps1`
- working_directory: `C:\Codex_App_Factory`
- expected_result: No search boundary violations
- estimated_runtime: ~5s
- required_tools: PowerShell
- skip_condition: None

## Category 2: Pre-Build Research Gate

### CMD-004: Need Search Detector
- command: `powershell -File .\runtime\need-search-detector.ps1`
- working_directory: `C:\Codex_App_Factory`
- expected_result: Correctly classifies P0 vs P2
- estimated_runtime: ~5s
- required_tools: PowerShell
- skip_condition: None

## Category 3: Starter Consistency

### CMD-005: Starter Type Consistency Check (All)
- command: `powershell -File .\runtime\starter-type-consistency-check.ps1`
- working_directory: `C:\Codex_App_Factory`
- expected_result: 6/6 checks PASS
- estimated_runtime: ~60s
- required_tools: PowerShell, Node.js, npm
- skip_condition: None

## Category 4: Products API Testbed

### CMD-006: Products API Tests
- command: `npx vitest run --reporter=verbose`
- working_directory: `C:\Codex_App_Factory\testbeds\products-api`
- expected_result: 23/23 PASS
- estimated_runtime: ~5s
- required_tools: Node.js, npm
- skip_condition: None

### CMD-007: Products API Start
- command: `npx tsx src/server.ts`
- working_directory: `C:\Codex_App_Factory\testbeds\products-api`
- expected_result: Server starts on :3001, health OK
- estimated_runtime: ~3s (startup)
- required_tools: Node.js, npm, tsx
- skip_condition: Port 3001 occupied

## Category 5: Mini Inventory Admin Pilot

### CMD-008: Pilot Tests
- command: `npx vitest run --reporter=verbose`
- working_directory: `C:\Codex_App_Factory\pilots\mini-inventory-admin`
- expected_result: 22/22 PASS
- estimated_runtime: ~5s
- required_tools: Node.js, npm
- skip_condition: None

### CMD-009: Pilot Start
- command: `npx tsx src/server.ts`
- working_directory: `C:\Codex_App_Factory\pilots\mini-inventory-admin`
- expected_result: Server starts on :3100, health OK
- estimated_runtime: ~3s (startup)
- required_tools: Node.js, npm, tsx
- skip_condition: Port 3100 occupied

## Category 6: Business Invariant Engine

### CMD-010: Invariant Engine Demo
- command: `powershell -File .\runtime\business-invariant-engine.ps1`
- working_directory: `C:\Codex_App_Factory`
- expected_result: Generates invariants for given risk profile
- estimated_runtime: ~10s
- required_tools: PowerShell
- skip_condition: None

## Category 7: Risk Enforcement Gate

### CMD-011: Risk Enforcement Gate v3
- command: `powershell -File .\runtime\risk-enforcement-gate-v3.ps1`
- working_directory: `C:\Codex_App_Factory`
- expected_result: Gate decision: ALLOWED or BLOCKED with evidence
- estimated_runtime: ~10s
- required_tools: PowerShell
- skip_condition: None

## Category 8: Automated Gate Detection

### CMD-012: Gate Detection Demo
- command: `powershell -File .\runtime\R2_14_demo_runner.ps1`
- working_directory: `C:\Codex_App_Factory`
- expected_result: 6 demo cases, CRITICAL/L_CLASS blocked when missing evidence
- estimated_runtime: ~30s
- required_tools: PowerShell
- skip_condition: None

### CMD-013: Products API Gate Detection
- command: `powershell -File .\runtime\R2_14_products_api_gate_detection.ps1`
- working_directory: `C:\Codex_App_Factory`
- expected_result: Gate detection report for products-api
- estimated_runtime: ~15s
- required_tools: PowerShell
- skip_condition: None

## Category 9: External Engine Broker

### CMD-014: Engine Broker Demo (R3.0)
- command: `powershell -File .\runtime\R3_0_demo_runner.ps1`
- working_directory: `C:\Codex_App_Factory`
- expected_result: 6 demo cases, unavailable tools SKIPPED
- estimated_runtime: ~60s
- required_tools: PowerShell, semgrep (optional), npx (optional)
- skip_condition: None (will skip unavailable engines gracefully)

### CMD-015: Engine Live Activation Demo (R3.1)
- command: `powershell -File .\runtime\R3_1_demo_runner.ps1`
- working_directory: `C:\Codex_App_Factory`
- expected_result: Real engine runs for available tools
- estimated_runtime: ~60s
- required_tools: PowerShell, semgrep, npx
- skip_condition: None (degrades gracefully)

## Category 10: Semgrep Run

### CMD-016: Semgrep on Products API
- command: `semgrep --config=auto --json .\testbeds\products-api\`
- working_directory: `C:\Codex_App_Factory`
- expected_result: Findings report (3 WARNING on testbed, 0 on pilot)
- estimated_runtime: ~30s
- required_tools: semgrep (pip install semgrep)
- skip_condition: semgrep not installed

### CMD-017: Semgrep on Pilot
- command: `semgrep --config=auto --json .\pilots\mini-inventory-admin\`
- working_directory: `C:\Codex_App_Factory`
- expected_result: 0 findings
- estimated_runtime: ~30s
- required_tools: semgrep (pip install semgrep)
- skip_condition: semgrep not installed

## Category 11: Autocannon Run

### CMD-018: Autocannon on Products API (requires server running)
- command: `npx autocannon -d 5 -c 10 http://localhost:3001/api/products`
- working_directory: `C:\Codex_App_Factory`
- expected_result: Requests/sec report, 0 errors
- estimated_runtime: ~10s
- required_tools: npx (autocannon), server running on :3001
- skip_condition: Server not running or port occupied

## Category 12: Benchmark Suite

### CMD-019: Benchmark Suite v2 Runner
- command: `powershell -File .\runtime\R4_0_benchmark_runner.ps1`
- working_directory: `C:\Codex_App_Factory`
- expected_result: 8 benchmark results with capability matrix
- estimated_runtime: ~120s
- required_tools: PowerShell, semgrep, npx
- skip_condition: None (some benchmarks design-only)

## Category 13: Calibration Rerun

### CMD-020: Surface Router + Risk Classifier Calibration
- command: `powershell -Command "& { .\runtime\project-surface-router.ps1; .\runtime\runtime-risk-classifier.ps1 }"`
- working_directory: `C:\Codex_App_Factory`
- expected_result: Surface detection + risk classification validation
- estimated_runtime: ~10s
- required_tools: PowerShell
- skip_condition: None

---

*Regression Command Index v2 — 20 commands across 13 categories*
*All commands verified executable on 2026-07-11*
