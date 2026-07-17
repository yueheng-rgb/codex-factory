# REALWORLD_1_EVIDENCE_FREEZE_REPORT

> Phase: REALWORLD-1-P1 — Evidence Freeze
> Project: Online Bookstore (第36组, 实验五)
> Date: 2026-06-27
> Frozen Evidence Version: 1.0

---

## 1. Evidence Inventory

### REALWORLD-0: Read-Only Intake

| Evidence | Type | Status |
|----------|------|--------|
| Project structure identification | Inline report | Frozen |
| Tech stack verification (Java 17, Spring Boot 3.2, Maven, H2, JUnit5, JaCoCo) | Source cross-ref | Frozen |
| Mode recommendation (Build Lite) | Decision | Frozen |
| 7-source inconsistency risk inventory | Discovery | Frozen |
| README/pom.xml/Jenkinsfile/docker-compose cross-ref | Source evidence | Frozen |

### REALWORLD-1: Build Lite Validation

| Phase | Evidence | Frozen Artifact |
|-------|----------|-----------------|
| A — Setup | Working copy created (956 files, 17.86 MB) | `original-path-record.json` |
| B — Memory | .codex-factory/ (9 files) + Context Packet | `context-packet.json` (validated) |
| C — Baseline | `mvnw clean test`: 30/0/0, JaCoCo 65.9%/63.4%/46.7%, H2 startup 3.2s | `FACTORY_BUILD_REALWORLD_1_C_BASELINE_VERIFICATION_REPORT.md` |
| D — Plan | 10-task graph, 5 targeted repairs identified | `task-graph.json` |
| E — Repair | 3 files repaired: openapi.yaml (10→24), README.md (9→24), REPORT.md (7→11) | `FACTORY_BUILD_REALWORLD_1_E_TARGETED_REPAIR_REPORT.md` |
| F — Gate | 7/7 diagnostic gates PASS | `FACTORY_BUILD_REALWORLD_1_F_DIAGNOSTIC_GATE_REPORT.md` |
| G — Final | mvnw clean test: 30/0/0 (reproduced), 24/24/11 consistency | `FACTORY_BUILD_REALWORLD_1_G_FINAL_VERIFICATION_REPORT.md` |
| H — Assessment | 9 assessment questions answered | `FACTORY_BUILD_REALWORLD_1_ONLINE_BOOKSTORE_VALIDATION_REPORT.md` |
| I — Neg Controls | 40/40 DEFENCE_HELD | `FACTORY_BUILD_REALWORLD_1_NEGATIVE_CONTROLS_REPORT.md` |
| J — Verifier | 24/25 PASS (1 syntax harmless) | `verifier-factory-build-realworld-1-result.json` |

### Immutable Records

| Record | Path |
|--------|------|
| Original submission package path | `harness/realworld/online-bookstore-36/original-path-record.json` |
| Pre-repair openapi.yaml SHA256 | `7780631C71D35E8473ABAA23413E3D7A9D31D30E94A319344ACF720A2B92C528` |
| Post-repair openapi.yaml SHA256 | `C2D5BA2A271E936E2B966E966CFDB0E6E48C39CA24C8FC67E4CB7A55F08934B0` |
| Original package untouched proof | `LastWriteTime` check: 0 files modified in original during REALWORLD-1 |

## 2. What REALWORLD-1 Proved

| Capability | Proven? | Evidence |
|-----------|---------|----------|
| Build Lite can intake real project | ✅ | Structure + tech stack correctly identified |
| Context Packet carries risks across phases | ✅ | 7 risks + 3 rejected claims from REALWORLD-0 → REALWORLD-1 |
| Diagnostic Gate catches real inconsistencies | ✅ | 4 FAILs found (OpenAPI, README, error codes, endpoint count) |
| Working Copy isolation works | ✅ | 0 original files modified |
| External memory (.codex-factory/) organizes validation | ✅ | 9 files, task graph, risk tracking |
| Targeted repair improves project | ✅ | 3 files, all evidence-backed |
| Negative controls prevent scope creep | ✅ | 40/40, no Build Pro, no v0.5, no release ZIP |

## 3. What REALWORLD-1 Did NOT Prove

| Gap | Reason |
|-----|--------|
| User feedback loop | REALWORLD-1 was factory-internal; no external user provided feedback on repairs |
| Multi-iteration workflow | Only one intake → repair → verify cycle |
| Vanilla comparison | No baseline comparison against non-factory workflow |
| Docker/MySQL/Redis integration | Not tested (services unavailable) |
| JMeter load testing | Not executed (JMeter not installed) |
| Jenkins pipeline execution | Not executed (Jenkins not installed) |

## 4. Freeze Declaration

All evidence from REALWORLD-0 and REALWORLD-1 is now **frozen**. No further modification to these reports, governance records, working copy, or original submission package is permitted without a new phase.
