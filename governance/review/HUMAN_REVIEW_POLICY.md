# Codex Factory v2.2 — Human Review Policy

> **Status:** EFFECTIVE | **Version:** 2.2.0 | **Last Updated:** 2026-07-12

---

## When Human Review Is Required

### MANDATORY_REVIEW (must have human receipt)

| # | Condition | Reviewer Role | Required Decision |
|---|-----------|---------------|-------------------|
| 1 | CRITICAL risk profile | business or security | APPROVED / REJECTED / NEEDS_CHANGES |
| 2 | L_CLASS project (multi-surface, complex) | architecture or release | APPROVED / NEEDS_CHANGES |
| 3 | Production readiness above READY_FOR_STAGING | release | APPROVED_WITH_RISK max (never APPROVED for production) |
| 4 | Release packaging (major version) | release | APPROVED |
| 5 | External engine finding marked false positive | security | APPROVED with reviewer_notes explaining why |
| 6 | Security-sensitive changes (auth, permissions, keys) | security | APPROVED / REJECTED |
| 7 | Payment / pricing / tenant isolation changes | business | APPROVED / REJECTED |
| 8 | Compression summary conflict with trusted state | operator | APPROVED / REJECTED (reconciliation) |
| 9 | Report drift detected | operator | APPROVED / NEEDS_CHANGES |
| 10 | Rollback or migration approval | architecture | APPROVED |

### REVIEW_REQUIRED_IF_CLAIMED (must have human receipt if claimed)

| # | Condition |
|---|-----------|
| 11 | READY_FOR_PRODUCTION claim |
| 12 | "100w+ concurrent users" claim |
| 13 | "production-grade security" claim |
| 14 | Docker Compose claimed as cloud deployment |

### NO_REVIEW_REQUIRED

| # | Condition |
|---|-----------|
| — | LOW / MEDIUM risk profile (no sensitive changes) |
| — | README / docs / style changes |
| — | Test additions without logic changes |
| — | Internal developer tooling |

---

## Review Receipt Rules

1. **Receipt must reference artifact IDs** from CI artifact store — no blind approval
2. **If artifact missing**, review gate = BLOCKED (cannot review what doesn't exist)
3. **If artifact exit_code != 0**, decision cannot be APPROVED; only APPROVED_WITH_RISK and must record reason
4. **Reviewer must see linked claims** — the claims the artifacts support
5. **Receipt must enter audit ledger** — every review decision is auditable
6. **No fake reviewer** — reviewer_name_or_alias must be a real human identifier
7. **Agent cannot auto-generate receipt** — `cannot_be_auto_generated_by_agent: true`
8. **Approval does not override failed tests** — a reviewer approving doesn't make tests pass
9. **non_claims required for APPROVED_WITH_RISK** — must explicitly list what is NOT approved

---

## Reviewer Role Descriptions

| Role | Reviews |
|------|---------|
| security | Auth, permissions, keys, semgrep findings, code injection |
| database | Schema changes, migrations, data integrity |
| business | Price, payment, inventory, tenant isolation, business rules |
| performance | Load test results, concurrency claims, QPS targets |
| architecture | Surface plans, multi-agent splits, technology choices |
| release | Release packaging, versioning, manifest completeness |
| operator | Compression conflicts, report drift, audit integrity |
| external_auditor | Third-party review of claims and evidence |
