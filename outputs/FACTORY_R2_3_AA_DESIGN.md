# Fastify Rate Limiting Middleware — Design

**Phase:** R2.3-AA
**Based on:** Evidence Pack v2 (30 sources, 10 official, QG 20/20 PASS_CLEAN)
**Confidence:** medium

---

## Adopted Approach

Use **@fastify/rate-limit** (official Fastify organization plugin, maintained as part of fastify org on GitHub).

### Selected Dependency

| Package | Version Constraint | Source |
|---------|-------------------|--------|
| @fastify/rate-limit | ^9.x (latest) | EP: fastify/fastify-rate-limit GitHub repo |

### Key Configuration

\\\js
await fastify.register(require('@fastify/rate-limit'), {
  max: 100,                    // requests per timeWindow (global default)
  timeWindow: '1 minute',     // '1 minute', 60000, or '1m'
  cache: 5000,                // internal cache size
  allowList: [],              // IPs to exclude from rate limiting
  trustProxy: true,           // trust X-Forwarded-For header
  keyGenerator: (req) => req.ip, // default: IP-based
  onExceeded: (req, reply) => {
    reply.code(429).send({
      error: 'Too Many Requests',
      message: 'Rate limit exceeded. Try again later.',
    });
  },
});
\\\

### Per-Route Overrides

Auth/login endpoints get stricter limits:

\\\js
fastify.post('/login', {
  config: { rateLimit: { max: 5, timeWindow: '1 minute' } }
}, loginHandler);
\\\

EP Reference: fastify/fastify-rate-limit GitHub repo shows \config.rateLimit\ pattern for per-route configuration.

---

## Rejected Alternatives

| Alternative | Reason for Rejection | EP Source |
|-------------|---------------------|-----------|
| express-rate-limit | Express-only, not Fastify compatible | EP Q1 official |
| Community forks (Szymx95, ghinks) | Not official Fastify org; maintenance risk | EP Q1 results |
| Custom in-memory counter | Reimplements well-tested plugin; risk of edge case bugs | Doctrine: prefer official |
| Cloudflare/nginx WAF rate limit | Infrastructure-level, different concern from app-level | Design judgment |

---

## Security & Availability Controls

1. **trustProxy: true** — Prevents IP spoofing via X-Forwarded-For
2. **Stricter auth limits** — 5 req/min for login vs 100 req/min global
3. **429 + Retry-After** — Standard HTTP response, clients can back off
4. **allowList** — Internal services (health checks, monitoring) exempt
5. **No Redis for MVP** — In-memory store sufficient; EP notes Redis for distributed

---

## Implementation Plan

1. \
pm install @fastify/rate-limit\ in project
2. Add plugin registration in server startup
3. Configure global: 100 req/min, trustProxy: true
4. Add per-route override for POST /login: 5 req/min
5. Add custom 429 response with error message
6. Test with sequential requests from same IP

---

## Test Plan

| Test | Expected |
|------|----------|
| 1 request → 200 | Rate limit not triggered |
| 101st request in 1 minute → 429 | Global limit enforced |
| 6th POST /login in 1 minute → 429 | Per-route stricter limit |
| Request from different IP → 200 | Per-IP isolation |
| GET /health with allowList → 200 | Allowlist bypass |
| 429 response has correct status | HTTP 429, not 500 |

---

## EP Source References

- fastify/fastify-rate-limit GitHub repo (official): issues #292, #207
- Security policy: github.com/fastify/fastify-rate-limit/security/policy
- 10 tier_1_gold sources in EP confirming API surface and configuration

## Rollback / Simplification Plan

- If @fastify/rate-limit is unavailable: use \@fastify/rate-limit\ from fastify org (not community fork)
- If rate limiting causes issues in dev: disable via \llowList: ['*']\ or env flag
- Simplification: remove per-route overrides, keep only global default
- Never ship to production without rate limiting on auth endpoints
