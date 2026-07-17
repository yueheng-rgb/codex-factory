# CPM-001 Human Review Preparation Notes

> **REVIEW_REQUIRED_NOT_RUN** — This document prepares for human review.
> It does NOT constitute approval. No fake approval is being issued.
> Review has NOT been conducted yet.

---

## 1. Mission Overview

| Field | Value |
|---|---|
| **Mission ID** | CPM-001 |
| **Title** | Miniapp Ecommerce Admin — Cross-Pack Integration |
| **Packs** | miniapp, ecommerce, admin-system |
| **Risk Level** | **CRITICAL** |
| **Integrator** | CPM-001-INTEGRATOR |
| **Worker C (this doc)** | CPM-001-WORKER-C |

## 2. What the Human Reviewer Needs to Check

### 2.1 Cross-Pack Boundaries
- [ ] **API contract alignment** between miniapp ↔ ecommerce ↔ admin-system packs
  - Request/response shapes, error codes, auth token format
  - Are the three packs using compatible API versions?
- [ ] **Shared type definitions** — are DTOs consistent across pack boundaries?
- [ ] **Auth token propagation** — does the miniapp JWT flow through ecommerce to admin correctly?

### 2.2 Security Boundaries (CRITICAL)
- [ ] **Payment flow** — CRITICAL. Verify:
  - Payment callbacks are server-side verified (not client-trusted)
  - No payment secrets in miniapp frontend bundle
  - Idempotency keys on payment processing
- [ ] **Production AppID** — Verify:
  - Miniapp AppID is configurable, not hardcoded
  - Admin backend has no hardcoded production secrets
- [ ] **Admin escalation** — CRITICAL. Verify:
  - All admin endpoints enforce server-side role check
  - No privilege escalation via direct API calls
  - RBAC is enforced at the middleware/guard level, not just UI hiding

### 2.3 Data Integrity
- [ ] **Transaction boundaries** — order creation, payment, inventory deduction
- [ ] **Audit fields** present on all DB tables (created_at, updated_at, deleted_at or equivalent)
- [ ] **Unique constraints** on business keys (order number, user phone, SKU codes)

### 2.4 API Contract
- [ ] Request validation on all endpoints
- [ ] Error response format consistent across all three packs
- [ ] Pagination, filtering, sorting on list endpoints
- [ ] Rate limiting considered for public-facing miniapp endpoints

## 3. Risk Summary

### CRITICAL Risks

| # | Risk | Packs Affected | Mitigation Check |
|---|---|---|---|
| R1 | **Payment callback trust** — client-side verification of payment success | ecommerce, miniapp | Server-side signature verification required |
| R2 | **Production AppID leakage** — hardcoded in miniapp source | miniapp | Must be env-configurable, not in repo |
| R3 | **Admin privilege escalation** — missing server-side RBAC checks | admin-system | Every admin endpoint must verify role |
| R4 | **Cross-pack auth inconsistency** — different JWT secrets or formats | all three | Single auth service or shared secret config |

### HIGH Risks

| # | Risk | Packs Affected | Mitigation Check |
|---|---|---|---|
| R5 | **Inventory race condition** — concurrent order placement | ecommerce | Pessimistic lock or transactional decrement |
| R6 | **Order idempotency** — duplicate payment processing | ecommerce | Idempotency key on payment gateway calls |
| R7 | **Sensitive data in logs** — PII or tokens logged | all three | Log scrubbing / redaction in production |

## 4. Invariant Coverage Summary

> **Status: PENDING** — Worker B has not yet delivered `invariant-contracts.json`.
> The following is a placeholder list of expected invariants for this mission type.

| Invariant ID | Description | Status |
|---|---|---|
| INV-001 | User identity is verified server-side on every authenticated request | UNVERIFIED |
| INV-002 | Payment amount is calculated server-side, never trusted from client | UNVERIFIED |
| INV-003 | Order state transitions are validated (no impossible transitions) | UNVERIFIED |
| INV-004 | Admin operations are logged with operator identity | UNVERIFIED |
| INV-005 | Inventory cannot go below zero | UNVERIFIED |
| INV-006 | Refund amount ≤ original payment amount | UNVERIFIED |
| INV-007 | API responses never leak internal stack traces in production | UNVERIFIED |

## 5. Test Coverage Summary

> **Status: PENDING** — Worker A has not yet delivered test harness and test suite.
> The following is a placeholder coverage matrix.

| Layer | Expected Coverage | Actual Coverage |
|---|---|---|
| Unit — miniapp utils/services | ≥ 80% | UNKNOWN |
| Unit — ecommerce core logic | ≥ 80% | UNKNOWN |
| Unit — admin RBAC guards | ≥ 90% | UNKNOWN |
| Integration — API endpoints | All CRUD paths | UNKNOWN |
| Integration — Payment flow | Happy + error + timeout | UNKNOWN |
| E2E — User checkout journey | Full path | UNKNOWN |
| E2E — Admin CRUD journey | Full path | UNKNOWN |

## 6. Code Review Checklist

### What to Look For
1. **No hardcoded secrets** — grep for `appid`, `appsecret`, `apikey`, `password`, `token=` in all source
2. **Server-side validation** — every mutation endpoint must validate input
3. **RBAC enforcement** — decorators/middleware, not just `v-if` in UI
4. **Error handling** — no bare `try {} catch (e) {}` without logging or user feedback
5. **SQL injection** — all DB queries use parameterized statements
6. **XSS** — user-generated content rendered in admin or miniapp must be sanitized
7. **File upload security** — file type validation, size limits, storage isolation
8. **Dependency audit** — no known vulnerable packages in package.json / requirements.txt

## 7. Final Declaration

```
REVIEW_REQUIRED_NOT_RUN
=======================
This review-notes.md is a PREPARATION document.
Human review has NOT been conducted.
No approval is implied or granted.
The integrator (CPM-001-INTEGRATOR) MUST perform the actual review
and sign off explicitly before this mission can proceed to implementation.
```
