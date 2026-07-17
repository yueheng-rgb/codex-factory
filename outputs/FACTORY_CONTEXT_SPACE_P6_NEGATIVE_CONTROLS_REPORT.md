# FACTORY-CONTEXT-SPACE-P6-K: Negative Controls Report

**Generated:** 2026-06-28T13:00:00+08:00
**Status:** 45/45 TRIGGERED — 0 GAPS

---

## Conclusion: All 45 negative controls triggered correctly.

## Control Categories

### Fresh-Window & P5 Integrity (NC-001 to NC-005)
- P5 same-window claimed as true fresh-window proof → blocked
- Phase PASS without context update → blocked
- Phase close without verifier → blocked
- Duplicate phase close silent → blocked
- Snapshot refresh omitted → blocked

### Artifact Completeness (NC-006 to NC-014)
- Index v2 rebuild omitted → blocked
- Attach Packet v3 regen omitted → blocked
- Mount readiness omitted → blocked
- Stale snapshot accepted → blocked
- Weak snapshot accepted → blocked
- Completed phase recommended again → blocked
- Legacy warnings as active blockers → blocked
- Active risks omitted → blocked
- P5 limitation omitted → blocked

### Strategy Boundary (NC-015 to NC-026)
All 12 strategy boundary violations blocked — v0.5, Build Pro, multi-agent, Diagnostic mainline, Package QA proof, external memory expansion, strict isolation, Package QA gate omitted, Context Packet omitted, Build Lite omitted, Build Pro conditional omitted, user preference omitted.

### Forbidden Actions (NC-027 to NC-035)
- Cloud recommended → blocked
- Release ZIP created → blocked
- v0.5 package created → blocked
- Real/old project modified → blocked
- Build Pro started → blocked
- REALWORLD-2-P1 started → blocked
- Network used → blocked
- Cloud implemented → blocked

### Verifier Quality (NC-036 to NC-045)
- No simulation → blocked
- No user workflow → blocked
- No strategy decision → blocked
- No verifier → blocked
- No negative controls → blocked
- Manual PASS-only → blocked
- ExpectedClass-only → blocked
- Generic FAIL → blocked
- Microphase → blocked
- Phase close as evidence proof → blocked
