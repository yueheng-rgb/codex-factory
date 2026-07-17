# FACTORY-BUILD-1 / Negative Controls Report

> Phase: FACTORY-BUILD-1
> Date: 2026-06-27
> Total Controls: 42 | PASS: 42 | Gaps: 0

## Summary

All 42 negative controls verify that BUILD-1 correctly blocks forbidden behaviors.

| Metric | Value |
|--------|-------|
| Total | 42 |
| PASS | 42 |
| FAIL | 0 |
| UNEXPECTED_PASS | 0 |
| FAIL_TARGET_NOT_TRIGGERED | 0 |
| Generic FAIL | 0 |
| ExpectedClass-only | 0 |
| Manual PASS-only | 0 |

## Categories

### Strategy Boundary (NC01-NC05)
NC01 Diagnostic Pack as main product → BLOCKED
NC02 Build Mode omitted → BLOCKED
NC03 Project intake omitted → BLOCKED
NC04 Complexity classifier omitted → BLOCKED
NC05 Mode selector omitted → BLOCKED

### Feature Completeness (NC06-NC11)
NC06 Blueprint omitted → BLOCKED
NC07 Task graph omitted → BLOCKED
NC08 External memory omitted → BLOCKED
NC09 Diagnostic gate omitted → BLOCKED
NC10 Agent protocol omitted → BLOCKED
NC11 User commands omitted → BLOCKED

### Agent Model (NC12-NC15)
NC12 Small project BUILD_PRO by default → BLOCKED
NC13 Multi-agent default → BLOCKED
NC14 7-agent restored → BLOCKED
NC15 10-role restored → BLOCKED

### Safety (NC16-NC31)
NC16-NC31 covering superiority claims, memory, handoff, verifier, decision log, task deps, agent scope, reviewer implementation, auto-repair, SkillMarket, product code, ZIP, v0.5, benchmark, releases

### Quality (NC32-NC42)
NC32-NC42 covering rationale, simulation, negative controls, verifier, microtasks, command usability, stop rule, continuation, iteration, artifacts, evidence hierarchy

All 42 controls: PASS with 0 gaps.
