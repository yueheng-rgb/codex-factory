# FACTORY-BUILD-REALWORLD-2-E: Staging Bundle Usability Check Report

**Date**: 2026-06-27
**Phase**: E — Staging Bundle Usability Check
**Bundle**: Codex Factory v0.9.0-pre staging

---

## 1. Staging Bundle Inventory

| Resource Type | Count | Available |
|---------------|-------|-----------|
| Starters | 7 | api-service, content-site, fullstack-admin, miniapp, mobile-app, saas-tool, threejs-interactive |
| Blueprints | 8 | All 7 starter blueprints + saas-auto-test-template |
| Skills | 9 | anti-overengineering, app-type-classifier, auth-permission-security, backend-api-design, database-schema-design, frontend-ui-system, mobile-miniapp-patterns, product-architecture, webapp-preview-testing |
| Prompts | 6 | (in prompts/ directory) |
| Governance | ✓ | governance/ hierarchy present |
| Harness | ✓ | harness/realworld/ created |

---

## 2. Relevance to TCM Project Ledger (Django)

### Matching Starters

| Starter | Relevance | Match Score |
|---------|-----------|-------------|
| fullstack-admin-starter | Django admin panel + CRUD + role-based access | **HIGH (8/10)** |
| api-service-starter | REST API patterns | MEDIUM (4/10) |
| saas-tool-starter | Multi-tenant patterns | LOW (2/10) |

### Matching Skills

| Skill | Applicability | Notes |
|-------|--------------|-------|
| auth-permission-security | **HIGH** | Project has 3 roles (admin/doctor/auditor/patient), login rate limiting, password policies |
| database-schema-design | **HIGH** | 15 models with relationships, indexes, unique constraints |
| backend-api-design | MEDIUM | Django template-based, not API-heavy; but chart data API exists |
| webapp-preview-testing | MEDIUM | Django runserver testing applicable |
| product-architecture | MEDIUM | Feature completeness review applicable |
| anti-overengineering | MEDIUM | Project appropriate for its scope — no microservices detected |
| frontend-ui-system | LOW | Bootstrap 5 + Django Templates, minimal custom CSS |
| app-type-classifier | LOW | Already classified as Django fullstack admin |
| mobile-miniapp-patterns | N/A | No mobile component in this project |

---

## 3. Capability Gaps

| Gap | Severity | Mitigation |
|-----|----------|------------|
| No Django-specific starter | MEDIUM | Use fullstack-admin blueprint patterns adapted for Django |
| No Python/Django skill | MEDIUM | Relies on agent's built-in Django knowledge |
| No deployment safety skill | LOW | REALWORLD-2 phases C/D provide manual audit |
| No secrets scanning automation | LOW | Manual audit completed in Phase C |

---

## 4. Bundle Readiness Assessment

| Criterion | Status |
|-----------|--------|
| Can classify project type | YES (app-type-classifier) |
| Can recommend architecture | YES (product-architecture) |
| Can audit security | YES (auth-permission-security + manual audit) |
| Can audit database schema | YES (database-schema-design) |
| Can generate working-copy plan | YES (harness/realworld/ structure) |
| Can generate validation plan | YES (webapp-preview-testing) |
| Can generate context packet | YES (governance/ + outputs/ structure) |
| Native Build Pro required? | NO — not needed for read-only intake |
| Django-specific automation? | PARTIAL — agent Django knowledge sufficient |

---

## 5. Verdict

The staging bundle is **sufficient** for REALWORLD-2 intake. Key strengths:
- Governance and evidence-lock structure supports read-only audit well
- Security and deploy audit can be done manually (Phases C/D)
- Skill set covers relevant cross-cutting concerns (auth, DB, architecture)

Limitations:
- No Django-specific templates in starters (but not needed for read-only intake)
- No automated secrets scanner (manual audit done)

---

## 6. Phase E Status: COMPLETE

Staging bundle v0.9.0-pre is usable for REALWORLD-2 intake of the TCM Project Ledger Django project.
