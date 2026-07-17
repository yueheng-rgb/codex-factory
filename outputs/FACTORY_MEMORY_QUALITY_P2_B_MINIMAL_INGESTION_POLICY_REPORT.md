# FACTORY-MEMORY-QUALITY-P2 — B: Minimal Memory Ingestion Policy

**Timestamp:** 2026-06-28T17:50:00+08:00
**Policy:** `MINIMAL_MEMORY_INGESTION_POLICY.md`

---

## Scope

Memory ingestion ONLY (External Conversation Space, Snapshot, Attach Packet, ledgers).
Normal user answers remain detailed.

## 8 Rules

| ID | Rule | Required |
|----|------|:---:|
| MIN-001 | Evidence path to source artifact | ✅ |
| MIN-002 | Caveat for partial/conditional/design-only | ✅ |
| MIN-003 | Body ≤ 500 chars | ✅ |
| MIN-004 | No score without evidence_path | ✅ |
| MIN-005 | Design → DESIGN_ONLY tag | ✅ |
| MIN-006 | Local → LOCAL_ONLY tag | ✅ |
| MIN-007 | Retired → RETIRED + reason | ✅ |
| MIN-008 | No secrets/endpoints/real data | ✅ |

---

**Status:** POLICY_DEFINED
