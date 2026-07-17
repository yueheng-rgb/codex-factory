# Minimal Memory Ingestion Policy v1.0.0

## Scope

Applies ONLY to memory ingestion:
- External Conversation Space writes
- Snapshot generation
- Attach Packet creation
- Phase ledger entries
- Risk ledger entries
- Decision ledger entries

Does NOT apply to normal user-facing answers (those remain detailed).

---

## Principles

1. **Normal answers remain detailed** — Minimal Mode is ingestion-only
2. **Self-contained** — Every record must include evidence_path and caveat
3. **No overclaim** — design ≠ execution, local ≠ production, observation ≠ proof
4. **No stale** — retired claims carry RETIRED marker with reason
5. **No contamination** — secrets, production endpoints, real project data excluded

---

## Rules

| ID | Rule | Required |
|----|------|----------|
| MIN-001 | Evidence path pointing to source artifact | ✅ |
| MIN-002 | Caveat if claim is partial/conditional/design-only | ✅ |
| MIN-003 | Body ≤ 500 chars; longer → reference full report | ✅ |
| MIN-004 | No score/verdict without evidence_path | ✅ |
| MIN-005 | Design analysis tagged DESIGN_ONLY | ✅ |
| MIN-006 | Local trial tagged LOCAL_ONLY | ✅ |
| MIN-007 | Retired claims carry RETIRED + reason | ✅ |
| MIN-008 | No secrets, endpoints, real data | ✅ |

---

## Anti-Patterns

- ❌ Using minimal summary as replacement for full report
- ❌ Omitting caveat to make claim look stronger
- ❌ Citing design score as execution evidence
- ❌ Presenting local trial as production validation
- ❌ Keeping retired claims without RETIRED marker

---

**Version:** 1.0.0 | **Status:** ACTIVE
