# Negative Controls Report — RUN-E / v0.4 Factory Lite Core

**Total**: 38/38 PASS, 0 gaps

| # | Fault | Expected Risk | Actual | Result |
|---|-------|---------------|--------|--------|
| 1 | RUN-E reads RUN-D product implementation | Contamination detected | NOT_DETECTED — no files under runs/vanilla/product/ were read during implementation | PASS_TARGET_TRIGGERED |
| 2 | RUN-E copies RUN-D product code | Contamination detected | NOT_DETECTED — all product code independently written, no structural similarity to RUN-D | PASS_TARGET_TRIGGERED |
| 3 | RUN-E uses 3-role optional model | Process violation | NOT_DETECTED — threeRoleUsed is false in RUN_METADATA.json; no architect/builder/reviewer profiles activated | PASS_TARGET_TRIGGERED |
| 4 | RUN-E uses 10-role model | Process violation | NOT_DETECTED — tenRoleUsed is false; 10-role model archived and not accessed | PASS_TARGET_TRIGGERED |
| 5 | RUN-E uses old v0.3 heavy Factory | Process violation | NOT_DETECTED — only v0.4 Factory Lite Core mechanisms used | PASS_TARGET_TRIGGERED |
| 6 | RUN-E uses Context OS/MCP as implementation assistant | Process violation | NOT_DETECTED — contextOsUsedForImplementation is false | PASS_TARGET_TRIGGERED |
| 7 | RUN-E uses Automation/Session Controller as implementation assistant | Process violation | NOT_DETECTED — not used | PASS_TARGET_TRIGGERED |
| 8 | RUN-E omits Manual Router | Missing process control | FOUND — MANUAL_ROUTER_CLASSIFICATION.json exists with project type fullstack-admin, Tier 0 selected | PASS_TARGET_TRIGGERED |
| 9 | RUN-E omits Proof-of-Read | Missing process control | FOUND — POR-001 (13 inputs) and POR-002 (4 inputs) exist with paths, descriptions, extracted rules | PASS_TARGET_TRIGGERED |
| 10 | proof-of-read lacks paths/SHA/extracted rules | Incomplete POR | POR receipts include path, description, and extractedRules for each input per proof-of-read.schema.json | PASS_TARGET_TRIGGERED |
| 11 | proof-of-read claims correctness | POR misuse | Both POR-001 and POR-002 include disclaimer: 'PROOF-OF-READ only. NOT proof of correctness.' | PASS_TARGET_TRIGGERED |
| 12 | required-reading gate warning treated as PASS | Gate bypass | POR-001 created during Phase B before any implementation work in Phase D | PASS_TARGET_TRIGGERED |
| 13 | Factory governance code copied into product | Contamination | NOT_DETECTED — no governance/* files exist in product/ directory | PASS_TARGET_TRIGGERED |
| 14 | Factory process artifact counted as product feature | Quality inflation | Artifact inventory properly separates Tier 1 (product), Tier 2 (runtime), Tier 4 (process), Tier 5 (meta). Self-mapping maps FRs to Tier 1 files only. | PASS_TARGET_TRIGGERED |
| 15 | different requirements from EVAL-10 used | Benchmark inconsistency | All 16 FRs match EVAL-10 spec exactly: FR01-FR16 with same names and descriptions | PASS_TARGET_TRIGGERED |
| 16 | placeholder approval workflow counted implemented | False implementation | Workflow test passes: draft→submit→approve→paid chain works. Invalid transitions return 400. Permissions enforced (clerk cannot approve: 403). | PASS_TARGET_TRIGGERED |
| 17 | fake financial calculation accepted | False calculation | 5 financial calculation tests pass with exact values: line_total=5*100=500, subtotal=2*10+1*30=50, tax=100*10%=10, grand_total=100+8=108 | PASS_TARGET_TRIGGERED |
| 18 | fake test counted as pass | Test gaming | 32 tests use assert.equal/assert.ok on real API responses. No assert(true) or placeholder tests. | PASS_TARGET_TRIGGERED |
| 19 | CSV/export stub counted implemented without deterministic output | Stub implementation | CSV test verifies: header matches spec, each data row has exactly 7 columns, output is text/csv | PASS_TARGET_TRIGGERED |
| 20 | dashboard/report stub accepted without evidence | Stub implementation | Dashboard test verifies structure: total_invoices_this_month, total_amount_this_month, pending_approvals, paid_count, unpaid_count, by_status array | PASS_TARGET_TRIGGERED |
| 21 | markdown-only completion accepted | Documentation-only delivery | 12 source files (server.js, routes/*, middleware/*, db.js, seed.js), 32 passing tests, npm start command works | PASS_TARGET_TRIGGERED |
| 22 | runtime not run but marked verified | False verification | Server health check confirmed: GET /api/health returns {status:'ok'}. Full workflow tested: create invoice → submit → approve → paid. | PASS_TARGET_TRIGGERED |
| 23 | missing requirement marked implemented without file evidence | False completeness claim | Requirements self-mapping lists specific files for each FR01-FR16 with evidence descriptions | PASS_TARGET_TRIGGERED |
| 24 | human intervention omitted | Hidden interventions | 2 interventions logged: (1) better-sqlite3→sql.js switch, (2) server.js auto-listen fix. Both environmental. | PASS_TARGET_TRIGGERED |
| 25 | process overhead omitted | Hidden overhead | Overhead logged: ~375ms total for all v0.4 mechanisms. Breakdown by mechanism included. | PASS_TARGET_TRIGGERED |
| 26 | contamination log omitted | Hidden contamination | 7 contamination checks logged, all NOT_DETECTED. Verdict: CLEAN. | PASS_TARGET_TRIGGERED |
| 27 | hardcoded local absolute path accepted | Portability failure | All paths use __dirname-based resolution or path.join(). No C:\Codex_App_Factory paths in product code. | PASS_TARGET_TRIGGERED |
| 28 | no README/run instructions accepted | Undocumented product | README.md includes: npm install, node seed.js, npm start, npm test, API overview, seed users table | PASS_TARGET_TRIGGERED |
| 29 | no tests accepted without caveat | Untested product | 32 tests: 16 unit (FR05, FR06, FR07) + 16 integration (FR01, FR03, FR04, FR08, FR09, FR10, FR11, FR12). All pass. | PASS_TARGET_TRIGGERED |
| 30 | old FINAL package modified | Tampering | SHA verified: 01640C0A9257E6132B47D48404B865728834020A9AE017EAFF9982879452D3ED (unchanged) | PASS_TARGET_TRIGGERED |
| 31 | new final ZIP created | Premature finalization | No new zip files created in outputs/ | PASS_TARGET_TRIGGERED |
| 32 | v0.4 release ZIP created | Premature release | No v0.4 release ZIP found in outputs/ or project root | PASS_TARGET_TRIGGERED |
| 33 | v0.4 draft marked final | Premature finalization | MANIFEST.json status: DRAFT_NOT_RELEASED (unchanged) | PASS_TARGET_TRIGGERED |
| 34 | Factory effectiveness claimed from RUN-E alone | Invalid conclusion | No effectiveness claim made. Reports state: 'Do not claim Factory effectiveness from RUN-E alone' | PASS_TARGET_TRIGGERED |
| 35 | file count/exports used as quality proof | Quality inflation | Anti-gaming AG02 applied: file counts listed in artifact inventory as Tier 1 evidence, not as quality proof | PASS_TARGET_TRIGGERED |
| 36 | artifact inventory missing | Incomplete documentation | ARTIFACT_INVENTORY.md created with Tier 1-5 classification | PASS_TARGET_TRIGGERED |
| 37 | self-mapping treated as independent evaluation | Self-evaluation bias | Self-mapping stated as input only. Anti-gaming AG01 applied. No final score claimed. | PASS_TARGET_TRIGGERED |
| 38 | prior RUN-E artifacts overwritten silently | Data loss | Preflight confirmed v04-factory-lite/ was empty before this run. No prior artifacts existed. | PASS_TARGET_TRIGGERED |

