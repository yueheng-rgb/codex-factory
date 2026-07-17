# FACTORY-CONTEXT-SPACE-P5-B: Fresh Window Mount Command Report

**Generated:** 2026-06-28T12:00:00+08:00
**Status:** DEFINED

---

## Fresh Window Mount Command

**User command (minimal):**
> 加载最新 Snapshot，判断当前方向

**User command (explicit):**
> 请加载最新的 Fresh Window Snapshot (BALANCED)，挂载到当前上下文，判断当前阶段和下一步方向。

## What Codex Must Execute

1. Read `SNAP-FW-BALANCED` from `factory-context-space/snapshots/`
2. Validate `freshnessStatus == FRESH`
3. Fallback chain: Snapshot → attach-packet-v3 → query-v2 (P2 SQLite)
4. Load `frozen_conclusions`, `current_strategy`, `active_risks`
5. Consult `direction-guard.json` for blocked/allowed directions
6. Output: current phase, next recommended, frozen conclusions, active blockers
7. NEVER treat snapshot as verifier evidence

## Anti-Patterns Blocked

| Anti-Pattern | Blocked By |
|---|---|
| ULTRA_COMPACT for autonomous continuation | DG-011 |
| Snapshot as PASS evidence | DG-008 |
| Stale snapshot without fallback | FRESH-001 |
| Build Pro as default | DG-003 |
| v0.5 release suggested | DG-004 |
| Cloud deploy suggested | DG-006 |
| Old conclusion resurrection | DG-009 |

## User Burden

**Single short command.** User does NOT need to:
- Know file paths
- Select snapshots manually
- Paste long summaries
- Understand compression levels

## Fallback Chain

```
SNAP-FW-BALANCED (FRESH?)
  ├─ YES → Mount directly
  └─ NO/STALE/MISSING
      └─ attach-packet-v3-latest.json (FRESH?)
          ├─ YES → Mount from packet
          └─ NO/STALE/MISSING
              └─ query-v2 (P2 SQLite index)
                  └─ Manual direction guard consultation
```
