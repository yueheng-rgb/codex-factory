# Codex Factory v2.0 — v2.x Roadmap

> **Release:** v2.0.0 | **Date:** 2026-07-12  
> **NOT a commitment — a direction guide**

---

## Guiding Principles for v2.x

1. **Do not rebuild frozen trunk** — search, multi-agent, verifier, harness, AGENTS.md are OFF LIMITS
2. **Do not reopen deprecated directions** — all 15 locks remain in force
3. **No production claims** — local smoke is not production proof
4. **No new Expert Packs without runtime validation** — pack + runtime validation pair required
5. **Release packaging per major version** — v2.1, v2.2, etc. each have their own release package

---

## v2.1: Real CI Artifact Store

**Priority:** HIGH  
**Why:** Currently all regression is manual. Need automated artifact storage for trust.

**Scope:**
- Raw test logs with timestamps
- Exit code capture
- Git commit/diff binding per run
- Artifact retention policy
- CI runner script (local PowerShell → future GitHub Actions)
- Artifact manifest per run

**Depends on:** Nothing (standalone infrastructure)  
**Estimated effort:** 1 phase  
**Risk:** LOW — additive, no trunk modification

---

## v2.2: Human Review Console

**Priority:** HIGH  
**Why:** Risk Gate currently has no human-facing approval workflow. CRITICAL/L_CLASS tasks
need explicit reviewer sign-off.

**Scope:**
- Approval workflow with reviewer assignment
- Risk sign-off with evidence review
- Reviewer receipt schema
- Release approval gate
- Integration with Risk Enforcement Gate v2

**Depends on:** v2.1 (for artifact context) — optional  
**Estimated effort:** 1-2 phases  
**Risk:** LOW — extends existing Risk Gate

---

## v2.3: More Expert Packs

**Priority:** MEDIUM  
**Why:** Current 3 packs (admin-system, ecommerce, saas-tool) cover common domains.
Need expansion for broader project type coverage.

**Candidate packs:**
1. **miniapp pack** — WeChat/Alipay mini-program invariants (API key isolation, size limits,
   platform-specific constraints)
2. **game/threejs pack** — 3D interactive invariants (asset loading, WebGL context,
   render loop, memory budgets)
3. **C/C++ memory safety pack** — Buffer overflow, use-after-free, double-free detection rules
   (CodeQL-compatible)

**Depends on:** Nothing (new packs are additive)  
**Estimated effort:** 3 phases (one per pack with runtime validation)  
**Risk:** LOW — additive, each pack self-contained

---

## v2.4: Long-Horizon Multi-Agent Execution

**Priority:** MEDIUM  
**Why:** Current multi-agent validation is short-duration (single session).
Need to prove reliability over longer horizons with recovery.

**Scope:**
- Multi-day project with context persistence
- Conflicting worker outputs with reconciliation
- Partial rollback on worker failure
- Recovery from failed/crashed worker
- Stale handoff detection over long timelines

**Depends on:** v2.1 (artifact store for persistence)  
**Estimated effort:** 2 phases  
**Risk:** MEDIUM — touches multi-agent area but does not rebuild trunk

---

## v3.0: External Execution Platform

**Priority:** FUTURE  
**Why:** Factory currently runs locally. A cloud/isolated execution platform would
enable real CI, sandboxed runs, persistent artifacts, and deployment pipeline.

**Scope:**
- Cloud runner with isolated sandboxes
- Persistent artifact store
- Real deployment pipeline (staging → production)
- Multi-tenant isolation
- Usage metering and quotas

**Depends on:** v2.1, v2.2, v2.4  
**Estimated effort:** Major (multi-phase)  
**Risk:** HIGH — architectural change, not for v2.x

---

## Not Planned (Avoid These)

| Direction | Reason |
|-----------|--------|
| Rewrite search system | Frozen — R2.3-AB baseline |
| Rebuild multi-agent core | Frozen — R2.6 baseline |
| Replace Verifier | Frozen — R2.14 baseline |
| Modify AGENTS.md core rules | Frozen — may only add indices |
| Turn Products API into ecommerce system | Products API is a testbed only |
| Build complete production admin UI | Not the Factory's mission |
| Claim production readiness | Against all non-claims policy |
| Independent Search Agent revival | Permanently deprecated |
