# FACTORY-CONTEXT-SPACE-P4-R1 — Verifier Hardening Report

**Date**: 2026-06-28
**Sub-step**: E

---

## Changes to P4 Verifier

The original P4 verifier (`factory-context-space-p4-snapshot-compression-quality-verify.ps1`) had:

| Original Check | Issue | Fix |
|---------------|-------|-----|
| V05: `benchmark snapshots >= 10` | Too weak — allows 10 when 24 required | Changed to `>= 24` |
| No type-level check | Could not detect missing NBP/QA | Added 6-type coverage check |
| No level-per-type check | Could not detect incomplete coverage | Added 4-level per type check |

## Hardened Checks Added

1. **V05-H**: Minimum 24 benchmark snapshots
2. **V05A**: All 6 required types present (FW, CD, RSK, RD, NBP, QA)
3. **V05B**: Each type has at least 4 compression levels
4. **V05C**: Benchmark results include every generated snapshot
5. Missing coverage now **blocks PASS**
