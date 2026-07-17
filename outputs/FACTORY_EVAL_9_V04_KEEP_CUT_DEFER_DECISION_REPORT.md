# FACTORY-EVAL-9: v0.4 Keep-Cut-Defer Decision Report

**Phase:** FACTORY-EVAL-9  
**Status:** COMPLETED — 23/23 Verifier PASS  
**Generated:** 2026-06-25T20:10:00+08:00

---

## Decisions at a Glance

| Category | Count | Items |
|---|---|---|
| **KEEP_DEFAULT** | 8 | Constitution, Manual Router, Proof-of-Read, Required-Reading, Evidence Hierarchy, Contamination Logging, Anti-Gaming, Context Budget |
| **KEEP_OPTIONAL** | 5 | Evaluator Rubric, Session Controller, 3-Role Model, Reviewer Role, Plugin Scaffold |
| **CUT_DEFAULT** | 2 | 10-role Company Model, Specialist Roles |
| **REWORK** | 3 | Verifier→Reviewer, Auditor→Reviewer, Handoff Format |
| **DEFER** | 8 | Context OS, MCP Memory, Automation Watcher, Cross-role Contracts, Drift Detection, Role Skill Profiles, Final Packaging |

## v0.4 Default: Factory Lite Core

The default operating model for v0.4 is **Factory Lite Core** — the same model that scored 94/100 with only ~200ms overhead in EVAL-8:

1. Load Always-On Constitution
2. Classify task via Manual Router
3. Generate Proof-of-Read for requirements
4. Build with normal Codex flow (no role model)
5. Track contamination and interventions
6. Run tests and verification
7. Independent evaluation only for benchmarks

## 3-Role Model (Optional)

For projects with auth/RBAC or separate frontend+backend, an optional 3-role model is available:
- **Architect** — planning and design review only
- **Builder** — full implementation
- **Reviewer** — merged QA + Verifier + Auditor (readonly)

## What Was Cut

The 10-role company model is cut from default. It scored LOWER (93) than Factory Lite (94) with 7.8x more overhead in EVAL-8. It remains in archive/ for reference and multi-agent research.

## Recommended Next Step

**STOP / User Review.** Before proceeding to v0.4 packaging or second benchmark, the user should review and confirm these decisions.
