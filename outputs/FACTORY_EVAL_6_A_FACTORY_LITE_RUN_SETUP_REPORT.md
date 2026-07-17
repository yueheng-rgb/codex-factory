# FACTORY-EVAL-6 Phase A — Factory Lite Run Setup Report

**Created**: 2026-06-25T17:29:32+08:00
**Run ID**: FACTORY-EVAL-6-RUN-B-FACTORY-LITE
**Run Type**: FACTORY_LITE

## Preflight Verification

| Check | Result |
|-------|--------|
| FACTORY-EVAL-5 PASS exists | COMPLETED (factory-eval-5-vanilla-baseline-result.json) |
| Benchmark spec exists | FOUND (factory-eval-4-benchmark-spec.json, SHA: 21F3729D...) |
| Factory Lite directory status | CLEAN (newly created) |
| Vanilla product exists | YES (not inspected) |
| FINAL package SHA | N/A (no FINAL package exists) |
| Final ZIPs | NONE |
| Prior Factory Lite artifacts | NONE |

## Run Directory Structure

- harness/benchmarks/factory-eval-real-project/runs/factory-lite/ — root
- harness/benchmarks/factory-eval-real-project/runs/factory-lite/product/ — product code
- harness/benchmarks/factory-eval-real-project/runs/factory-lite/proof-of-read/ — receipts
- harness/benchmarks/factory-eval-real-project/runs/factory-lite/logs/ — logs
- harness/benchmarks/factory-eval-real-project/runs/factory-lite/tests/ — test evidence

## Allowed Factory Lite Mechanisms

1. Always-On Constitution
2. Manual Router
3. Proof-of-Read
4. Required-Reading Gate
5. Evidence Hierarchy
6. Process Integrity Checks

## Forbidden Mechanisms

- Role-Specialized Agent Company Model
- Specialist role agents
- Agent OS multi-agent orchestration
- Context OS/MCP Memory as implementation assistant
- Factory governance code as product code
- Vanilla product code reuse

## Governance Documents Loaded

| Document | SHA256 |
|----------|--------|
| factory-always-on-constitution.md | E573F43267537EF567EAEA6A50480038DF086B45E6B7A7B2BA6DB844E14EAF48 |
| evidence-hierarchy-policy.json | A8DDFE8CC65D9551218D130CE40CE65102C002B633CBEDC5A89F5BF97AE1ACF8 |
| required-reading-gate-policy.json | 2EF34EA29FA437333082902A39F4006571596B6A1D7FB7A88B4B895195A21D8E |
| factory-eval-4-anti-gaming-policy.json | C02B938C7B7568D820119B2490A7DFF269C2DCBABA85BE0EEE8EEBB5DBD52250 |
| factory-eval-4-evaluation-rubric.json | CBD46DF1CB4CC7D1B585885FBEE840715D1EEFEA279A0B52831A828919F17322 |
| factory-eval-4-benchmark-spec.json | 21F3729D8FBABF6DCDDAF40BDA5E1DA13A5143E857811BA5A1E643626D98CBD2 |

## Next Step

Phase B: Required-reading gate and proof-of-read receipts
