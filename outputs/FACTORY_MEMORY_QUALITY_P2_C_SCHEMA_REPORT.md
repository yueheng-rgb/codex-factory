# FACTORY-MEMORY-QUALITY-P2 — C: Memory Record Schema

**Timestamp:** 2026-06-28T17:50:00+08:00
**Version:** 1.0.0

---

## Required Fields

| Field | Type | Description |
|-------|------|-------------|
| record_id | string | MEM-{category}-{timestamp}-{hash4} |
| timestamp | ISO8601 | Creation time |
| category | enum | PHASE_RESULT, BLOCKER_UPDATE, DECISION, RISK, EVIDENCE, POLICY, LESSON, RETIRED |
| summary | ≤500 chars | What happened, decided, evidence |
| evidence_path | string | Path to source artifact |
| status | enum | ACTIVE, PARTIAL, RETIRED, SUPERSEDED |

## Optional Fields

caveat (≤200 chars), score, related_phases, retired_reason, socratic_triggered

---

**Status:** SCHEMA_DEFINED
