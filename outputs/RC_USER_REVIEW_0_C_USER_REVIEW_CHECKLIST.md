# RC-USER-REVIEW-0 — Section C: User Review Checklist

**Phase:** RC-USER-REVIEW-0
**Section:** C
**Generated:** 2026-06-28T21:00:00+08:00
**Status:** COMPLETE

---

## User Review Checklist — RC0 Inspection

For each item, check ✓ when reviewed:

### Package Identity
- [ ] 1. **Package name reviewed** — `codex-factory-core-v0.9.0-pre-RC0.zip` — understand this is a release candidate, not a release
- [ ] 2. **RC status understood** — This is `RELEASE_CANDIDATE`, artifactType confirmed in `RC0_METADATA.json`
- [ ] 3. **"Not a release" understood** — RC0 is NOT v0.5, NOT production, NOT deployable

### Documentation
- [ ] 4. **Install instructions readable** — See `RC0_USER_REVIEW_GUIDE.md` for extraction and inspection steps
- [ ] 5. **Quickstart readable** — Factory CLI (`scripts/factoryctl.ps1`) accessible after extraction

### Governance Gates
- [ ] 6. **Security/Deploy Gate present** — Preserved in governance, not triggered (no deployment in RC)
- [ ] 7. **Package QA Gate present** — Preserved, not triggered (RC is candidate, not final handoff)
- [ ] 8. **Context Space present** — `factory-context-space/` module included (173 files)
- [ ] 9. **Memory Quality / Cleanup present** — `factory-build-mode/memory-quality/` includes policies, schemas, cleanup planner

### Safety
- [ ] 10. **No secrets/projects visible** — Verified: no real projects, no real `.env`, no API keys, no credentials
- [ ] 11. **Blockers understood** — BLOCK-001 (STRONG_PARTIAL_EVIDENCE), BLOCK-002/003/004 (ACTIVE), v0.5 BLOCKED
- [ ] 12. **Next decision understood** — After review, choose: RC-SMOKE-0, repair, AB trials, or keep as candidate

---

## Review Summary

| Item | Count |
|---|---|
| Total checklist items | 12 |
| Required for acceptance | All 12 |

**Section C verdict: COMPLETE**
