# FACTORY-CONTEXT-SPACE-P3 — Evidence Intake and Compression Problem Statement

**Date**: 2026-06-28
**Phase**: FACTORY-CONTEXT-SPACE-P3
**Sub-step**: A

---

## 1. Foundation (P0–P2 Recap)

| Phase | Status | Key Result |
|-------|--------|-----------|
| CONTEXT-SPACE-0 | PASS 48/48 | External Conversation Space, Mount Protocol, Attach Packet, Direction Guard |
| MOUNT-TRIAL-R1 | PASS 25/25 | Freshness validation, state source policy, mount.ps1 v0.2.0 |
| CONTEXT-SPACE-P1 | PASS | JSONL local index, basic query, query packet, direction guard |
| CONTEXT-SPACE-P2 | PASS 37/37 | SQLite + FTS5, 76 entries, 13 relations, 38 ordered phases, relation chains, timeline, usability 10/10, negative controls 57/57 |

## 2. Remaining Problem

P2 proved: **queryable memory works**. Codex can query the SQLite index and get structured results with relations, evidence paths, and trust tiers.

But P2 does not solve: **Codex still has to construct context ad-hoc from raw query results**. Every new window, every phase start — the agent re-derives the same working context. This is wasteful and error-prone.

## 3. Problem Classification

| Classification | Status |
|----------------|--------|
| QUERYABLE_INDEX_SUPPORTED | P2 SQLite works |
| SNAPSHOT_PACK_NEEDED | Ad-hoc context assembly still required |
| CLOUD_NOT_NEEDED | Local P2+P3 sufficient for current needs |
| COMPRESSION_RISK_REAL | Without curated packs, Codex generates low-quality summaries |
| USER_OVERHEAD_HIGH | User must still explain mainline to each new window |

## 4. Core Hypothesis

If we pre-generate **curated Snapshot Packs** from the P2 SQLite index — each tailored to a specific scenario — then new windows and phase starts can load a Snapshot instead of ad-hoc query assembly. This reduces overhead while maintaining evidence traceability.

## 5. What Snapshot Packs ARE

- Curated JSON bundles extracted from the P2 SQLite index
- Scenario-specific: Fresh Window, Current Direction, Phase Start, User Summary, Risk, Release Decision, Native Build Pro, Package QA
- Self-describing: freshness timestamp, evidence paths, trust tier, compression level, refresh triggers
- NOT evidence — always reference back to P2 index/ledger/verifier

## 6. What Snapshot Packs ARE NOT

- Compressed summaries (no lossy compression of facts)
- Verifier evidence (verifier results live in governance)
- Model memory expansion (file-backed, not injected)
- Replacements for query (query remains available for ad-hoc needs)
- Cloud-synced (local only for MVP)

## 7. Verdict

P3 is needed. P2 gave us queryable memory. P3 gives us **ready-to-use working packs** derived from that memory.
