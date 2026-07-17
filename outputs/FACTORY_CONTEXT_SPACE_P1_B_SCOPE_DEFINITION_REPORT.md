# FACTORY-CONTEXT-SPACE-P1-B: Local Index Scope Definition Report

**Phase:** FACTORY-CONTEXT-SPACE-P1
**Section:** B — Local Index Scope Definition
**Date:** 2026-06-28
**Status:** COMPLETE

---

## Deliverables

| Artifact | Path | Status |
|---|---|---|
| Scope definition | `factory-context-space/LOCAL_INDEX_SCOPE.md` | ✅ |
| Data model | `factory-context-space/DATA_MODEL.md` | ✅ |

## Scope Summary

- **9 entity types**: phase, decision, claim, risk, evidence, user_preference, rejected, blocker, strategy
- **7 trust tiers**: TIER_1 (verifier) through TIER_7 (legacy)
- **Source priority**: verifier > phase-ledger > factory-state > active-thread > direction-guard > attach-packet > legacy
- **Local only**: No cloud, no network, no external API
- **Storage**: JSONL flat file with manifest
- **Query engine**: PowerShell script with in-memory scoring

## Data Model

Each JSONL entry carries: entry_id, entity_type, content, source_file, source_last_modified, indexed_at, trust_level, freshness, evidence_paths, tags, status, relations.

## Verdict: PASS
