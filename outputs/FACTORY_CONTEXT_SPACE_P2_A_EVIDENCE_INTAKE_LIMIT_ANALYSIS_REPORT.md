# FACTORY-CONTEXT-SPACE-P2-A: P1 Limit Analysis + P2 Evidence Intake

**Date:** 2026-06-28

---

## P1 Limitations (JSONL Index)

### 1. No Relation Traversal
P1 stores `relations` inline in each entry, but query-context-space.ps1 does not traverse them.
- "Which phase proved Build Lite default?" → cannot answer
- "What replaced RETIRED-001?" → cannot answer
- "Which claims support FROZEN-001?" → cannot answer

### 2. No Timeline Queries
P1 has no phase ordering. Cannot answer:
- "What was completed after BUILD-6?"
- "Timeline of all completed phases?"
- "When was Package QA Gate added?"

### 3. No Direction Guard Integration in Query
P1 has separate query-direction-guard.ps1 but query results itself don't carry direction guard status.
Direction guard only runs on query packet generation, not on raw queries.

### 4. Flat Scoring
P1 scoring is keyword-based with trust tier boost. No:
- Exact match prioritization
- Relation-based scoring (supports/contradicts chains)
- Freshness-weighted scoring

### 5. No Phase Map
P1 index has phase entries but no ordering/map. Each phase is independent.
Cannot generate a phase dependency graph.

### 6. No Index Integrity
P1 has manifest with entry counts but no:
- Content hash per entry
- Checksum of index file
- Atomic rebuild (current script overwrites)

### 7. Attach Packet Integration is Shallow
P1 adds `context_index_integration` block with freshness only.
Does not include relation chains, evidence paths from index, or query-generated evidence.

## P2 Evidence Intake (What P2 Must Ingest)

Same sources as P1, plus:
- P1 index itself (for migration/upgrade)
- Phase ordering metadata (timestamps from phase-ledger)
- Relation definitions (explicit replaces/replaced_by/supports/contradicts chains)
- Evidence index cross-references

## P2 Architecture Decision

Given Python sqlite3 is available:
- **Storage**: SQLite via Python (`scripts/_sqlite_core.py`)
- **Build**: `build-context-index-v2.ps1` → Python SQLite writes
- **Query**: `query-context-space-v2.ps1` → Python SQLite reads
- **Fallback**: If Python unavailable, degrade to enhanced JSONL with relation traversal in PowerShell
- **Direction Guard**: Integrated into query (not separate script)

## P2 Must Support

| Query Type | Example |
|---|---|
| Exact match | entry_id = 'FROZEN-001' |
| Relation chain | Which phases support Build Lite default? |
| Timeline | Phase completion order |
| Direction guard | Query + DG check in one call |
| Full-text | Content search across all entries |
| Tag filter | All entries tagged 'frozen' |
| Trust filter | Only TIER_1-TIER_3 results |
| Evidence tracked | Every result with source path |

## Verdict

P1 JSONL is insufficient for relation/timeline queries. P2 SQLite with Python is the appropriate upgrade.
