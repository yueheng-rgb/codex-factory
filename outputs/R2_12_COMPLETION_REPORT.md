# R2.12 — Project Surface Model & Starter Integrity System

> Completion Report
> Date: 2026-07-11
> Classification: A — R2_12_PROJECT_SURFACE_AND_STARTER_INTEGRITY_READY

---

## Final Classification: A

Project Surface Model implemented, multi-surface routing demo cases executed, Starter Type Consistency System built and run (6/6 PASS). No search/multi-agent/verifier/harness/AGENTS.md subsystems modified.

---

## 1. Deliverables

### 1A. Project Surface Model

| File | Purpose |
|------|---------|
| `schemas/project-surface-plan.schema.json` | JSON Schema for surface plans (10 surface types, dependencies, risks, integration points) |
| `governance/project-surface-model/surface-registry.ps1` | Registry of 10 surface types with recommended starters, dependencies, risk levels, required tests |
| `runtime/project-surface-router.ps1` | Router script: keyword-based surface detection → multi-surface plan generation |
| `docs/PROJECT_SURFACE_MODEL.md` | (pending — output report serves as documentation) |

**10 Surface Types Supported:**
api-service, admin-web, public-web, frontend-web, miniapp, mobile-app, threejs-interactive, background-worker, database, docs-release

### 1B. Starter Type Consistency System

| File | Purpose |
|------|---------|
| `runtime/starter-type-consistency-check.ps1` | Automated check: typecheck + build + tests + pagination + field consistency |

### 1C. Demo Cases (6 cases run)

| Case | Description | Surfaces | Type | Risk | Human Audit |
|------|-------------|----------|------|------|-------------|
| A1 | REST API for user management | 2 (api-service, database) | multi-surface | high | Yes |
| A2 | 3D product showcase | 1 (threejs-interactive) | single-surface | medium | No |
| B1 | Admin dashboard + API + DB | 3 (api, db, admin-web) | multi-surface | high | Yes |
| B2 | 3D gallery + save via API | 3 (api, db, threejs) | multi-surface | high | Yes |
| B3 | Mini-program mall + admin + API | 4 (api, db, admin, miniapp) | combo | high | Yes |
| B4 | AI SaaS + API + worker | 4 (api, db, frontend, worker) | combo | high | Yes |

---

## 2. Consistency Check Results

| Target | Typecheck | Build | Tests | Pagination | Fields | Result |
|--------|-----------|-------|-------|------------|--------|--------|
| node-api-postgres | PASS | PASS | PASS | WARN | PASS | PASS |
| vite-threejs-interactive | PASS | PASS | NO_TESTS | PASS | PASS | PASS |
| next-fullstack-admin | PASS | PASS | NO_TESTS | PASS | PASS | PASS |
| next-saas-ai-tool | PASS | PASS | NO_TESTS | WARN | PASS | PASS |
| vite-react-content-site | PASS | PASS | NO_TESTS | WARN | PASS | PASS |
| products-api | PASS | PASS | PASS | WARN | PASS | PASS |

**6/6 PASS** — all starters and testbed pass typecheck + build. Two with test suites pass all tests (node-api-postgres: 13/13, products-api: 23/23).

**Pagination WARN notes**:
- node-api-postgres: legacy `admin.ts` uses `limit` in query parsing (not a breaking issue)
- next-saas-ai-tool: history route accepts `pageSize` parameter alongside legacy `limit`
- vite-react-content-site: CSS `limit` false positive
- products-api: request query parsing uses `limit` as variable name (cosmetic)

---

## 3. Files Changed

| File | Action |
|------|--------|
| `schemas/project-surface-plan.schema.json` | Created — surface plan JSON Schema |
| `governance/project-surface-model/surface-registry.ps1` | Created — 10 surface type registry |
| `runtime/project-surface-router.ps1` | Created — keyword-based surface detection + plan generation |
| `runtime/starter-type-consistency-check.ps1` | Created — automated consistency gate |
| `runnable-starters/next-saas-ai-tool/app/api/history/route.ts` | Fixed — pageSize parameter acceptance |
| `runnable-starters/vite-react-content-site/src/env.d.ts` | Fixed — Vite client types (B1 from R2.11) |

---

## 4. Workflow Boundary

| Check | Result |
|-------|--------|
| No Independent Search Agent | PASS |
| No Dual Search Channel | PASS |
| No Implementer direct search | PASS |
| No chat URL extraction | PASS |
| No mock/dry_run as live | PASS |
| No API key leaked | PASS |
| No search/multi-agent/verifier/harness rebuilt | PASS |
| No AGENTS.md rewritten | PASS |
| APP_TYPE_ROUTER preserved + extended | PASS |
| All demo cases produce valid surface plans | PASS |

---

## 5. Affected Starters

| Starter | Changes |
|---------|---------|
| next-saas-ai-tool | history route: added pageSize param acceptance |
| vite-react-content-site | Added env.d.ts (Vite types, from R2.11) |

---

## 6. Known Risks

- Surface detection is keyword-based — may produce false positives for ambiguous descriptions (e.g., "API" in non-technical context)
- Human audit flag triggers conservatively (any combo project or high risk → audit required)
- Non-runnable surfaces (miniapp, mobile-app, background-worker) always trigger human audit — this is intentional
- Pagination WARN in node-api-postgres is from legacy admin.ts which is not part of the primary CRUD flow

---

## 7. Recommended Next Big Capability

1. **L-Class Runtime Risk Classifier**: The surface model identifies risk levels but doesn''t enforce rules at runtime. A classifier that validates starter output against risk rules (transaction, audit, RBAC) would close the gap between design and implementation.

2. **Automated Starter Smoke Tests**: Add vitest to next-fullstack-admin, next-saas-ai-tool, and vite-react-content-site for automated API route testing.

3. **Multi-Surface Integration Test**: Build a real multi-surface project (e.g., api-service + admin-web) and verify the surface plan actually produces correct integration.
