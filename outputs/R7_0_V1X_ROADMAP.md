# Codex Factory v1.0 — v1.x Roadmap

**Generated:** 2026-07-11
**Applies to:** Post-v1.0 planning
**Status:** DIRECTIONAL — not committed schedule

---

## v1.0 Baseline (Current)

Codex Factory v1.0 delivers:
- 16 integrated capabilities
- 114 regression tests (all PASS)
- 10 benchmarks (all PASS)
- 2 expert packs (ecommerce, saas-tool)
- 3 external engines (semgrep, autocannon, playwright)
- 6 runnable starters
- Production readiness foundation

---

## Recommended v1.x Big Capabilities

### 1. v1.1 — Expert Pack Expansion
**Why:** Only 2 expert packs exist. Key domains uncovered.

- **Miniapp Expert Pack** — WeChat/Alipay mini-program invariants (login, payment, subscription message, privacy, audit)
- **Admin System Expert Pack** — RBAC, audit log, data export, batch operations, approval workflow
- **Game/ThreeJS Expert Pack** — Asset pipeline, WebGL performance invariants, mobile compatibility, interaction patterns
- **C/C++ Memory Safety Expert Pack** — ASAN/TSAN/UBSAN integration, buffer overflow invariants, use-after-free patterns

### 2. v1.2 — External Engine Expansion
**Why:** CodeQL and k6 are planned but not live. Firecrawl is candidate but not integrated.

- **CodeQL Live Integration** — Install, configure, run on testbeds, parse results, bind to evidence
- **k6 Live Integration** — Install, write k6 scripts for products-api and ecommerce, parse results, calibrate performance classifier
- **Firecrawl Reader/Extractor** — Formal integration as optional Reader/Extractor (NOT search replacement)
- **Deeper Playwright E2E** — Per-project Playwright configs, multi-page flows, visual regression

### 3. v1.3 — Production Hardening Extension
**Why:** Readiness checker exists but only foundation. Docker, real Postgres, and observability missing.

- **Docker Compose Templates** — Per-project-type Docker setup with Postgres, Redis, app container
- **Real Postgres Deploy Path** — Migration runner, seed data automation, connection pooling config
- **Rollback Automation** — Migration down scripts, deployment rollback procedures
- **Observability Foundation** — Structured logging, health check aggregation, basic metrics endpoint

### 4. v2.0 — Long-Horizon Complex Project Orchestration
**Why:** Current system handles single-surface and simple multi-surface projects. Large projects need deeper orchestration.

- **Larger Multi-Worker Execution** — Projects with 4+ workers, parallel worktree management, merge conflict resolution
- **Human Review Console** — Structured review interface, approve/reject/needs-changes workflow, evidence presentation
- **Release Approval Workflow** — Multi-stage approval gates, stakeholder sign-off tracking
- **Cross-Domain Project Generation** — Projects combining multiple expert packs (e.g., ecommerce + SaaS marketplace)

---

## What NOT to Do in v1.x

- Do NOT rebuild search / multi-agent / verifier / harness / AGENTS.md (FROZEN)
- Do NOT reopen deprecated search patterns (LOCKED)
- Do NOT claim v1.0 as final version
- Do NOT add microservices or over-engineer for small projects
- Do NOT build complete production ecommerce/SaaS platforms (testbeds are testbeds)
- Do NOT claim local smoke as production capacity proof

---

## Priority Order

| Priority | Capability | Rationale |
|----------|-----------|-----------|
| 1 | Expert Pack Expansion (v1.1) | Broadens domain coverage; each pack is self-contained |
| 2 | External Engine Expansion (v1.2) | CodeQL fills security gap; k6 fills performance gap |
| 3 | Production Hardening (v1.3) | Docker/Postgres needed for real-world validation |
| 4 | Complex Project Orchestration (v2.0) | Requires stable v1.x foundation first |
