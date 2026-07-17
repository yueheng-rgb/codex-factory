# V2.9 — Immutable Release Snapshot & Reproducibility Package

**Stage**: v2.9
**Date**: 2026-07-17
**Snapshot ID**: CODEX-FACTORY-V2-20260717
**Final Classification**: A — V2_9_IMMUTABLE_RELEASE_SNAPSHOT_READY

---

## Summary

Immutable release snapshot of Codex Factory V2.0-V2.8 audit results. 59 file hashes, 8 bundles, 24 frozen claims, verifier PASS, handoff capsule ready.

| Component | Result |
|-----------|--------|
| Snapshot Manifest | 59 files across 7 categories, all SHA256-hashed |
| Bundle Index | 8 bundles covering all evidence domains |
| Claim Snapshot | 24 claims frozen (13 ARTIFACT, 10 REPORT, 1 SELF_DECLARED) |
| Restore/Verify Checklist | 10-step recovery procedure |
| Snapshot Verifier | 14/14 PASS |
| Handoff Capsule | Trusted state + forbidden directions + next phase |

---

## 1. Snapshot Manifest

- **59 files** with SHA256 hashes, sizes, categories, evidence status, modification policy
- 7 categories: governance_core, v2_0_reports, v2_1_v2_3_reports, v2_4_v2_7_reports, v2_8_audit, expert_packs, reviews
- AGENTS.md SHA256 verified: matched

## 2. Bundle Index

| Bundle | Contents | Count |
|--------|----------|-------|
| BUNDLE-001 | Governance Core | 3 files |
| BUNDLE-002 | V2.0 Release Reports | 14 files |
| BUNDLE-003 | V2.1-V2.3 Reports | 4 files |
| BUNDLE-004 | V2.4-V2.7 Stage Reports | 4 files |
| BUNDLE-005 | V2.8 Audit Package | 7 files |
| BUNDLE-006 | Expert Packs | 21 files |
| BUNDLE-007 | Review Receipts | 10 files |
| BUNDLE-008 | Artifact Store | 21 files |

## 3. Verifier Result

```
14 checks: 14 PASS, 0 PARTIAL, 0 FAIL
Overall: PASS
```

- manifest SHA256 verified
- 8 bundles confirmed
- 24 claims frozen
- 14 V2.0 reports exist
- 8 review receipts exist
- 21 artifact files exist
- Deprecated locks intact
- No API key patterns in outputs
- Restore checklist exists

## 4. Handoff Capsule

Contains: trusted phase, accepted classification, trusted claims, known limitations, forbidden directions (10), next recommended phase, verification paths, compression summary warning.

---

## Files Changed

- `outputs/V2_9/V2_9_IMMUTABLE_SNAPSHOT_MANIFEST.json`
- `outputs/V2_9/V2_9_BUNDLE_INDEX.json`
- `outputs/V2_9/V2_9_CLAIM_SNAPSHOT.json`
- `outputs/V2_9/V2_9_RESTORE_VERIFY_CHECKLIST.md`
- `outputs/V2_9/V2_9_SNAPSHOT_VERIFY_RESULT.json`
- `outputs/V2_9/V2_9_HANDOFF_CAPSULE.json`
- `runtime/snapshot-verifier.ps1`

---

## Known Risks

- Snapshot is NOT cryptographically signed — SHA256 verifies integrity, not authenticity
- V2.0 evidence remains VERIFIED_WITH_REPORT only
- Human review receipts remain self_declared_automated
- Compression summary warning included in handoff capsule

---

## Recommended Next

**v3.0: External Execution Platform RC** — cloud/sandbox runner, isolated execution, persistent artifact store, stronger human review identity, real CI integration.
