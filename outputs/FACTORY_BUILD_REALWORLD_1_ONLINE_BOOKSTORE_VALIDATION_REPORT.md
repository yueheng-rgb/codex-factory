# FACTORY_BUILD_REALWORLD_1_ONLINE_BOOKSTORE_VALIDATION_REPORT

> Phase: REALWORLD-1 — Full Validation Assessment
> Project: Online Bookstore (第36组)
> Factory Version: codex-factory-core v0.9.0-pre staging
> Date: 2026-06-27

---

## Assessment Questions

### 1. Did Build Lite safely handle a real user project?

**YES.** Build Lite performed a full read-only intake, created an isolated working copy, ran baseline verification (mvnw clean test, JaCoCo, H2 startup), applied only documentation-targeted repairs, re-verified, and preserved the original submission package throughout.

### 2. Did working-copy isolation prevent original package modification?

**YES.** All modifications were confined to `harness/realworld/online-bookstore-36/working-copy/`. The original `C:\Users\90961\Desktop\实验五_在线书店系统开发_第36组_提交包` was never written to. Verified via `LastWriteTime` check and file inventory record.

### 3. Did external memory help organize validation?

**YES.** The `.codex-factory/` directory (8 files) provided structured tracking of project state, decisions, task graph, architecture, requirements, active risks, verification history, and handoff context. The Context Packet preserved active risks from REALWORLD-0 and enforced rejected claims.

### 4. Did Context Packet reduce noise and preserve active risks?

**YES.** The PHASE_START_PACKET carried all 7 risks from REALWORLD-0, 3 rejected claims, and boundary constraints, preventing scope creep into Build Pro or v0.5 territory.

### 5. Did Diagnostic Gate catch real report/source inconsistencies?

**YES.** The gate confirmed: OpenAPI 10→24 endpoint gap, README 9→24 undercount, error codes 7→11 undercount, endpoint count 28→24 overcount, and comment coverage inconsistency. All were fixed with source-backed evidence.

### 6. Did targeted repair improve project consistency?

**YES.** Three files were repaired: `openapi/openapi.yaml` (100% coverage now), `README.md` (accurate endpoint table + consistency note), `EXPERIMENT_FINAL_REPORT.md` (accurate error codes + coverage caveat).

### 7. Did this provide useful evidence toward v0.5?

**YES.** The REALWORLD-1 validation demonstrates that Build Lite can intake, verify, and repair a real project safely on a working copy. Key capabilities proven: intake → baseline → repair → gate → verify loop.

### 8. What remains before release?

- docker profile (application-docker.yml) needs creation by user
- Empty evidence folders are manual tasks
- External service integration (MySQL/Redis) not tested
- JMeter load tests not run (JMeter not installed)
- Jenkins pipeline not executed (Jenkins not installed)

### 9. Should next phase be REALWORLD-1-P1, REALWORLD-2, or Pack Staging Bundle?

**Recommendation**: REALWORLD-2 (next real project) or Pack Staging Bundle. REALWORLD-1 is complete. REALWORLD-1-P1 (Docker profile repair) can be deferred as a user action item.

---

## Summary

| Dimension | Result |
|-----------|--------|
| Build Lite safe on real project | ✅ YES |
| Working copy isolation | ✅ YES |
| External memory utility | ✅ YES |
| Context Packet effectiveness | ✅ YES |
| Diagnostic Gate accuracy | ✅ YES (7/7 gates) |
| Targeted repair effectiveness | ✅ YES (3 files, 3 doc gaps fixed) |
| Tests preserved | ✅ 30/0/0 pre and post repair |
| Original package untouched | ✅ YES |
| No Build Pro/v0.5/release ZIP | ✅ YES |
