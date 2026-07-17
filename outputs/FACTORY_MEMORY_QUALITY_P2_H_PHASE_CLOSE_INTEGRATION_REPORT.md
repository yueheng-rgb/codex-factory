# FACTORY-MEMORY-QUALITY-P2 — H: Phase Close Integration

**Timestamp:** 2026-06-28T17:50:00+08:00

---

## Flow (factory.ps1 phase-close)

1. Run verifier as normal
2. Generate minimal memory record (TPL-001)
3. Run validator (15 checks)
4. If PASS/PASS_WITH_WARNINGS → write to External Conversation Space
5. If BLOCKED → log rejection, surface to user
6. Generate Snapshot if Context Space active
7. Generate Attach Packet if NBP/long-horizon
8. Update phase ledger (≤500 chars)

---

**Status:** PHASE_CLOSE_INTEGRATION_DEFINED
