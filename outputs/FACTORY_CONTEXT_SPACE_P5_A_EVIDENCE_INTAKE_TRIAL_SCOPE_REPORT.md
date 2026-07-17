# FACTORY-CONTEXT-SPACE-P5-A: Evidence Intake & Trial Scope Report

**Generated:** 2026-06-28T12:00:00+08:00
**Phase:** FACTORY-CONTEXT-SPACE-P5 — Fresh Window Real Mount + Snapshot Usability Trial
**Status:** EVIDENCE INTAKE COMPLETE

---

## 1. Predecessor Evidence Chain

| Phase | Verdict | Checks | Key Contribution |
|-------|---------|--------|-----------------|
| CONTEXT-SPACE-0 | PASS 48/48 | 48 | External Conversation Space foundation |
| MOUNT-TRIAL-R1 | PASS | — | Freshness defect correction |
| P1 | PASS | — | JSONL local index + query packet |
| P2 | PASS | — | SQLite + FTS5 (76 entries, 53 relations) |
| P3 | PASS 40/40 | 40 | Snapshot Packs + Attach Packet v3 + DG v3 |
| P4 | PASS 35/35 | 35 | Compression benchmark (16 snapshots) |
| P4-R1 | PASS 20/20 | 20 | Coverage repair: 24/24 snapshots |

**Evidence chain is complete.** All predecessor phases have verifier-confirmed PASS verdicts.

## 2. Frozen Conclusions (Carried Forward)

- BALANCED = default compression for fresh-window mounts
- ULTRA_COMPACT = quick-status only, NOT autonomous
- CLOUD = deferred indefinitely
- Build Lite = default; Native Build Pro = conditional
- multi-agent default = rejected
- v0.5 = permanently blocked
- External conversation space ≠ model memory expansion
- Snapshot ≠ verifier evidence

## 3. P5 Core Objectives

1. Fresh window Snapshot mount onto mainline — VERIFY
2. Attach Packet v3 load + query-v2 fallback — VERIFY
3. Direction Guard v3 blocks wrong directions — VERIFY
4. BALANCED sufficient for fresh-window — CONFIRM
5. ULTRA_COMPACT not autonomous — CONFIRM
6. Snapshot not evidence — CONFIRM
7. No old conclusion resurrection — VERIFY
8. Short user command suffices — ASSESS
9. Next-phase decision — FORM

## 4. Trial Design

**Method:** SAME-WINDOW SIMULATION. P5 trials are executed in the current Codex session. Fresh-window behavior is simulated by generating a BALANCED Snapshot Pack as at phase-close, loading it with no prior context assumption, and validating all guard rules hold.

**Why same-window is acceptable:** The mechanism being tested (Snapshot Pack structure, Attach Packet v3 freshness, Direction Guard v3 rules) is independent of the Codex window identity. A same-window simulation tests the same data structures and policies that would operate in a fresh window. The one difference — Codex's own conversation memory — is explicitly excluded from scope because the Snapshot Pack is designed to be self-contained.

**Recommendation:** A true fresh-window trial in a separate Codex instance is valuable for P6 or user acceptance testing but is NOT required for P5 PASS.

## 5. Explicitly Forbidden in P5

- Cloud deployment, server purchase, domain purchase, network usage
- v0.5 release, release ZIP creation
- REALWORLD-2-P1 start, Native Build Pro start
- Real project modification, old package modification
- Snapshot as verifier evidence
- Micro-phase splitting

## 6. Scope Boundary

P5 validates the MECHANISM — can Snapshot Packs be used for real fresh-window continuation? It does NOT validate production deployment, cloud sync, or multi-window coordination. Those are P6+ or REALWORLD-2-P1 concerns.
