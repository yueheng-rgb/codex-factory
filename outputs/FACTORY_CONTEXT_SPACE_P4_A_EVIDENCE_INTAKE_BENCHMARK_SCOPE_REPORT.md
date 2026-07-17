# FACTORY-CONTEXT-SPACE-P4 — Evidence Intake and Benchmark Scope

**Date**: 2026-06-28
**Phase**: FACTORY-CONTEXT-SPACE-P4
**Sub-step**: A

---

## 1. Foundation

| Phase | Status | Key Result |
|-------|--------|-----------|
| CONTEXT-SPACE-0 | PASS 48/48 | External Conversation Space + Mount Protocol |
| MOUNT-TRIAL-R1 | PASS | Freshness validation |
| CONTEXT-SPACE-P1 | PASS | JSONL local index |
| CONTEXT-SPACE-P2 | PASS 37/37 | SQLite+FTS5, 76 entries, 13 relations |
| CONTEXT-SPACE-P3 | PASS 40/40 | 8 Snapshot Packs, Attach Packet v3, DG v3, Cloud Deferred |

## 2. Remaining Question

P3 proved: **Snapshots can be generated and validated.** But are they compressed well enough to trust as working context?

## 3. Benchmark Purpose

- NOT feature expansion
- NOT release preparation
- NOT cloud migration
- **Quality evaluation only** — systematically assess whether snapshot compression preserves critical information

## 4. What We Need to Know

1. Does compression lose frozen conclusions?
2. Does compression lose active risks?
3. Does compression revive retired/rejected conclusions?
4. Does compression produce over-strong claims?
5. Does compression cause mainline drift?
6. Which compression level is optimal for fresh-window continuation?
7. Can Attach Packet v3 detect and reject weak/stale/poisoned snapshots?

## 5. Scope: IN

- 4 compression levels: FULL, BALANCED, COMPACT, ULTRA_COMPACT
- Quality scoring across 8 criteria
- Benchmark runner + evaluator scripts
- Adversarial poisoning tests
- Default compression decision
- Attach Packet v3 integration with quality thresholds

## 6. Scope: OUT

- New snapshot types
- New features beyond quality evaluation
- Cloud, network, server
- Release, packaging
- Real project modification
- REALWORLD-2-P1, Native Build Pro execution
