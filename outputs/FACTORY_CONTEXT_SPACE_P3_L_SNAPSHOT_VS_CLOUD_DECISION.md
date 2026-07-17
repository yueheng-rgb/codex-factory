# FACTORY-CONTEXT-SPACE-P3 — Snapshot vs Cloud Decision

**Date**: 2026-06-28
**Sub-step**: L

---

## 1. Question

Does P3 (Snapshot Packs) reduce the need for immediate cloud sync?

## 2. Answer

**Yes. P3 reduces cloud urgency to near zero for current Factory needs.**

## 3. What P3 Provides That Cloud Would

| Need | P3 Local Solution | Cloud Would Add |
|------|------------------|-----------------|
| Cross-window context | Snapshot Packs + Attach Packet v3 | Remote sync |
| Context freshness | Freshness metadata + expiry rules | Real-time sync |
| Context quality | Lifecycle rules + validation | Centralized quality enforcement |
| Multi-machine sync | NOT COVERED by P3 | Primary cloud value |
| Team collaboration | NOT COVERED by P3 | Primary cloud value |
| Backup/recovery | File-based (git or copy) | Automated backups |

## 4. Cloud Decision

| Decision | Value |
|----------|-------|
| **CLOUD_STILL_DEFERRED** | YES |
| **LOCAL_SNAPSHOT_PACKS_FIRST** | YES — P3 validates the concept locally before any cloud consideration |
| **SERVER_NOT_NEEDED_YET** | YES — single-user, single-machine Factory |
| **DOMAIN_NOT_NEEDED_YET** | YES |
| **NETWORK_NOT_NEEDED_YET** | YES |

## 5. When Cloud Should Be Considered

1. After P4+ (Snapshot Quality Benchmark) validates snapshot quality at scale
2. After at least one REALWORLD project is fully validated end-to-end
3. When user explicitly requests multi-machine sync
4. When team collaboration becomes a requirement
5. Only after local security hardening (encryption at rest, access control)

## 6. Security Requirements Before Cloud

- All snapshots must be encrypted at rest
- TCM secrets must be fully rotated and verified
- Access control: only authorized users can read snapshots
- Network transport must be TLS 1.3 minimum
- No secrets in any snapshot content ever

## 7. Verdict

**CLOUD_DEFERRED. P3 Snapshot Packs are the right local foundation. Cloud is a future consideration, not a current need.**
