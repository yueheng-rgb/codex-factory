# FACTORY-BUILD-6: Matched Baseline Comparison — Final Report

**Phase**: FACTORY-BUILD-6  
**Date**: 2026-06-27  
**Status**: **PASS** (39/39 verifier checks)  

---

## 1. Executive Summary

Three runs of SkillForge Hub were compared under a sealed requirements packet:

| Run | Mode | Agents | Memory | Gate | Files | Verdict |
|-----|------|--------|--------|------|-------|---------|
| **RUN-A** | Vanilla | 1 (real) | None | None | 15 | Viable, no safeguards |
| **RUN-B** | Build Lite | 1 (real) | Yes (.codex-factory/) | Diagnostic | 17 | **Best cost/benefit** |
| **RUN-C** | Build Pro | 4 (simulated) | Yes (17 files) | Diagnostic | 36 | Most structured, unproven parallelism |

**Core finding**: Build Lite provides the best cost/benefit ratio for single-developer large projects. Build Pro's task graph and write-scope mapping show promise but cannot be validated without native `spawn_agent`.

---

## 2. Product Quality Comparison

All three runs produced functionally equivalent SkillForge Hub MVPs:
- Express + sql.js backend
- JWT + bcrypt auth with 4-role RBAC
- Skill catalog, approval workflow (7 states), order lifecycle (4 states)
- SPA frontend with catalog, auth, seller, admin, dashboard pages
- 8-table database with constraints and seed data
- Test suites

RUN-C has more API endpoints (30 vs 21-24) due to structured task graph planning, not inherently better product quality.

---

## 3. Process / Memory / Harness Comparison

| Dimension | RUN-A (Vanilla) | RUN-B (Build Lite) | RUN-C (Build Pro) |
|-----------|-----------------|-------------------|-------------------|
| Build overhead | Low | Medium (+15%) | High (+40%) |
| Checkpoint/recovery | None | Good | Excellent |
| Decision traceability | None | Decision log | Full memory system |
| Team handoff ready | No | Partial | Yes |
| Diagnostic confidence | Low | Medium | High |
| Role separation | None | None | Simulated only |

---

## 4. Causal Attribution

**What helps** (across all modes):
- Structured requirements specification
- External memory for checkpoint and recovery
- Task graph for complex project decomposition
- Diagnostic gate for quality confidence

**What doesn't help**:
- Agent role simulation without native parallelism
- Excessive memory files beyond core 8
- Process artifacts counted as product quality

---

## 5. Decision Matrix

| Criterion | Weight | RUN-A | RUN-B | RUN-C |
|-----------|--------|-------|-------|-------|
| Product Quality | High | Good | Good | Good |
| Build Overhead | Medium | Low | Medium | High |
| Checkpoint/Recovery | Medium | None | Good | Excellent |
| Team Handoff | Medium | No | Partial | Yes |
| Parallelism | High | No | No | Planned* |
| Diagnostic Confidence | Medium | Low | Medium | High |
| Simplicity | Low | Highest | High | Low |

---

## 6. Conclusion

- **Build Lite SUFFICES for single-developer large projects**
- **Build Pro has POTENTIAL but needs native spawn_agent testing**
- **Vanilla is viable but lacks safeguards**
- **v0.5 release: STILL BLOCKED**
- **Multi-agent default: REJECTED**
- **Recommended next: FACTORY-BUILD-7 (Native Spawn-Agent Trial) or user review**

---

## 7. References

- Comparison dir: `harness/build-trials/skillforge-hub-comparison/`
- Sealed spec: `harness/build-trials/skillforge-hub-comparison/sealed-spec/`
- RUN-A: `harness/build-trials/skillforge-hub-comparison/runs/vanilla/`
- RUN-B: `harness/build-trials/skillforge-hub-comparison/runs/build-lite/`
- RUN-C: `harness/build-trials/skillforge-hub/product/` (BUILD-5, unchanged)
- Evaluation: `harness/build-trials/skillforge-hub-comparison/evaluation/matched-baseline-comparison.json`
- Verifier: `scripts/factory-build-6-matched-baseline-comparison-verify.ps1`
- Result: `governance/factory-build/factory-build-6-matched-baseline-comparison-result.json`
