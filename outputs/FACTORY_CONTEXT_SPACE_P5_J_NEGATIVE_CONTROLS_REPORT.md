# FACTORY-CONTEXT-SPACE-P5-J: Negative Controls Report

**Generated:** 2026-06-28T12:00:00+08:00
**Status:** 42/42 TRIGGERED — 0 GAPS

---

## Conclusion: All 42 negative controls triggered correctly. Zero gaps. Zero UNEXPECTED_PASS. Zero FAIL_TARGET_NOT_TRIGGERED.

## Control Categories

### Fresh-Window Integrity (NC-001 to NC-007)
- fake fresh-window evidence → blocked
- same-window claimed as fresh → blocked
- snapshot without validation → blocked
- weak snapshot for continuation → blocked
- ultra compact autonomous → blocked
- stale snapshot without fallback → blocked
- poisoned Build Pro → blocked

### Strategy Boundary (NC-008 to NC-013)
- v0.5 release → blocked
- Build Pro default → blocked
- multi-agent default → blocked
- diagnostic mainline → blocked
- packaging mainline → blocked
- Package QA bypass → blocked

### Evidence Boundary (NC-014 to NC-018)
- Snapshot as PASS evidence → blocked
- external space = model memory → blocked
- strict isolation claimed → blocked
- REALWORLD-2 proves smarter → blocked
- TCM secret printed → blocked

### Completeness (NC-019 to NC-030)
All 12 completeness gaps blocked — risks, defaults, gates, paths, preferences, fallback, usability, direction guard, compression, user burden.

### Forbidden Actions (NC-031 to NC-037)
- cloud recommended → blocked
- release ZIP → blocked
- v0.5 package → blocked
- real project modified → blocked
- old package modified → blocked
- Native Build Pro started → blocked
- REALWORLD-2-P1 started → blocked

### Verifier Quality (NC-038 to NC-042)
- no verifier → blocked
- no negative controls → blocked
- manual PASS-only → blocked
- expectedClass-only → blocked
- generic FAIL → blocked
