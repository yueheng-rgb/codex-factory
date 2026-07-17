# V2.7 — Known Risks & Non-Claims

**Mission**: CPM-001 Miniapp Ecommerce Admin
**Date**: 2026-07-17

---

## Known Risks

| # | Risk | Likelihood | Impact | Mitigation Status |
|---|------|-----------|--------|-------------------|
| R1 | Payment/order data loss on restart | HIGH | CRITICAL | NOT MITIGATED — in-memory store |
| R2 | Session token not cryptographically strong | LOW | MEDIUM | Math.random() — testbed only |
| R3 | No rate limiting on auth endpoints | MEDIUM | HIGH | NOT MITIGATED |
| R4 | Inventory inconsistency under concurrent access | LOW | HIGH | Not tested; single-threaded testbed |
| R5 | WeChat platform review not conducted | MEDIUM | BLOCKING | NOT STARTED |
| R6 | No persistent idempotency for payments | LOW | CRITICAL | In-memory Set — testbed only |

## Production Gaps

| Gap | Severity | Remediation |
|-----|----------|-------------|
| In-memory data store | BLOCKING | PostgreSQL + migrations |
| No migration scripts | BLOCKING | Versioned, reversible migrations |
| No rollback procedures | BLOCKING | Documented rollback plan |
| No structured logging | HIGH | JSON logger with request IDs |
| No WeChat platform review | BLOCKING | Submit to WeChat review |
| Mock payment gateway | BLOCKING | Real WeChat Pay integration |
| No load testing | HIGH | autocannon/k6 at production scale |
| No static analysis run | MEDIUM | semgrep on codebase |

---

## Non-Claims

1. **This pilot is NOT a production system.** It is a Factory pipeline validation exercise.

2. **The miniapp has NOT passed WeChat/platform review.** Production miniapps require WeChat review with real AppID.

3. **Local smoke testing is NOT production capacity proof.** No claims about concurrent user capacity or throughput are made.

4. **semgrep clean (if run) does NOT equal absolute security.** Static analysis is one layer; it cannot guarantee absence of vulnerabilities.

5. **In-memory store / mock payment does NOT equal real payment processing.** The payment callback is a mock for invariant validation only.

6. **Human review receipts are self_declared_automated.** They have NOT been reviewed by an external human engineering lead. A real human must provide final sign-off before any production consideration.

7. **READY_FOR_PRODUCTION_REVIEW ≠ READY_FOR_PRODUCTION.** This is the highest approval level achievable in this pilot given the documented gaps.

8. **This pilot does NOT replace senior engineer responsibility.** The Factory provides governance, evidence, and gates — the human engineering lead owns the final decision.

9. **No third-party dependency audit has been performed.** npm audit or equivalent has not been run on cross-pack testbed dependencies.

10. **No compliance review (GDPR, PCI-DSS, etc.) has been performed.** This pilot does not include legal/compliance assessment.
