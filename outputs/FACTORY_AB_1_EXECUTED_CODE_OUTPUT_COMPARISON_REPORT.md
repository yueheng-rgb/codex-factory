# FACTORY-AB-1 — Main Report: Executed Code Output Comparison

**Timestamp:** 2026-06-28T18:30:00+08:00
**Verdict:** FACTORY_ADVANTAGE — **90 vs 65 (+25)**

---

## ⚡ Key Difference from AB-0-R1: Actual Code Artifacts

| | AB-0-R1 | AB-1 |
|---|:---:|:---:|
| Code artifacts | ❌ Harness empty | ✅ 13 files across both runs |
| Score provenance | ⚠️ Identical to AB-0 design | ✅ Independent (65/90 ≠ 50/87) |
| Evidence type | Governance/report analysis | Actual code inspection |

---

## Results

| Dimension | Vanilla | Factory | Δ |
|-----------|:---:|:---:|:---:|
| Requirements Coverage | 14 | 19 | +5 |
| Architecture Design | 9 | 14 | +5 |
| Code Correctness | 17 | 22 | +5 |
| Safety & Boundary | 12 | 18 | +6 |
| Documentation | 7 | 9 | +2 |
| User Burden | 6 | 8 | +2 |
| **Total** | **65** | **90** | **+25** |

---

## Artifacts Produced

| RUN-A (5 files) | RUN-B (8 files) |
|-----------------|-----------------|
| backend/main.py | design/architecture.md |
| frontend/index.html | backend/main.py (with safety annotations) |
| tests/test_api.py (7 tests) | frontend/index.html (with low-stock highlighting) |
| .env.production.example | tests/test_api.py (10 + 1 HONEST_SKIP) |
| README.md | tests/classification-log.md |
| | MANIFEST.json |
| | .env.production.example (security reviewed) |
| | README.md (comprehensive) |

---

**Verdict:** AB-1_PASS — actual code artifacts, independent scoring, provenance issue resolved.
