# Codex Factory v2.0 — Known Risks and Non-Claims

> **Release:** v2.0.0 | **Date:** 2026-07-12

---

## What v2.0 Is NOT

1. **NOT a production system** — In-memory stores, no real auth, minimal UI surfaces
2. **NOT the "Final" version** — v2.x, v3.0, and beyond are planned
3. **NOT a deployment-ready platform** — No CI/CD, no cloud deployment, no artifact store
4. **NOT production-capable at scale** — Local smoke tests do NOT prove "1M concurrent users"
5. **NOT a replacement for human engineering teams** — Human audit still required for CRITICAL/L_CLASS
6. **NOT a complete ecommerce/SaaS/admin product** — Expert Packs are invariants, not full products
7. Docker Compose example is NOT a production cloud deployment
8. READY_FOR_STAGING is NOT READY_FOR_PRODUCTION
9. Compression summaries are NOT trusted memory
10. Local smoke is NOT production capacity proof

---

## Known Risks

### Architecture Risks

| Risk | Severity | Details | Mitigation |
|------|----------|---------|------------|
| In-memory store (all projects) | MEDIUM | Data lost on restart | Documented limitation; Postgres starter exists |
| No real authentication | MEDIUM | x-user-id header only | Expert packs define auth invariants |
| No distributed audit ledger | LOW | Audit trail is local file | Hash chain verifier detects tampering |
| Multi-agent stress simulated | LOW | v1.3 stress was simulated | v2.0-RC validated with real mission |
| No CI/CD pipeline | MEDIUM | Manual regression only | Regression index provides CLI reference |

### Tool Reliability Risks

| Risk | Severity | Details |
|------|----------|---------|
| Playwright browser mismatch | LOW | npm playwright vs browser version mismatch; unresolved since R3.1 |
| CodeQL not installed | MEDIUM | Requires manual installation; SKIPPED_WITH_REASON |
| k6 not installed | MEDIUM | Requires manual installation; SKIPPED_WITH_REASON |
| Firecrawl no API key | LOW | Requires API key; NOT canonical search anyway |
| autocannon tsx/Node v24 skip | LOW | Some projects use tsx which blocks autocannon |

### Classifier Risks

| Risk | Severity | Details |
|------|----------|---------|
| Keyword-based classification | LOW | Risk/stale detection uses keywords, not semantic understanding |
| Manual state initialization | LOW | Trusted Project State requires manual setup |
| Performance claims under-classified | LOW | Large-scale claims now correctly mapped to CRITICAL (fixed R3.1) |

### Expert Pack Risks

| Risk | Severity | Details |
|------|----------|---------|
| No inter-pack conflict resolution | LOW | Overlapping invariants between packs not resolved |
| Packs are additive only | LOW | No mechanism to remove or override pack components |
| Only 3 packs exist | MEDIUM | miniapp, game/threejs, C/C++ memory safety packs not yet built |

---

## Non-Claims

The following capabilities are NOT claimed by v2.0:

1. ❌ Production-grade security (no real auth, no HTTPS, no secrets management)
2. ❌ Production-grade scalability (no load balancing, no distributed system capability)
3. ❌ Production-grade reliability (no failover, no backups, in-memory state)
4. ❌ Support for 100w+ concurrent users (local smoke only)
5. ❌ Cloud deployment capability
6. ❌ CI/CD pipeline integration
7. ❌ Real-time monitoring or alerting
8. ❌ GDPR/HIPAA/SOC2 compliance
9. ❌ Payment processing capability
10. ❌ Complete miniapp/game/C++ support

---

## User Responsibility

- **Human audit** is required for CRITICAL and L_CLASS risk profiles
- **Security review** is required before any deployment
- **Performance testing** must be done at target scale before production claims
- **Data persistence** must be added (real database, not in-memory) before any real use
- **Authentication** must use real auth (OAuth/JWT/bcrypt), not x-user-id header
- Risk Gate BLOCKED verdicts must not be overridden without documented justification
- External engine TOOL_UNAVAILABLE must not be relabeled PASS
