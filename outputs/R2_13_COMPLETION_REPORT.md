# R2.13 — Runtime Risk & Business Invariant Enforcement

> Completion Report
> Date: 2026-07-11
> Classification: A — R2_13_RUNTIME_RISK_AND_INVARIANT_ENFORCEMENT_READY

---

## Final Classification: A

Runtime Risk Classifier, Business Invariant Engine, and Risk Enforcement Gate all built and verified. 6 demo cases executed across LOW/MEDIUM/HIGH/CRITICAL/L_CLASS. BLOCKED correctly enforced when risk requirements not met. No search/multi-agent/verifier/harness/AGENTS.md subsystems modified.

---

## 1. Deliverables

### 1A. Runtime Risk Classifier

| File | Purpose |
|------|---------|
| `schemas/runtime-risk-profile.schema.json` | JSON Schema for risk profiles |
| `runtime/runtime-risk-classifier.ps1` | Keyword-based classifier: LOW/MEDIUM/HIGH/CRITICAL/L_CLASS |

**Risk Level Logic:**
- **LOW**: Documentation, style, README, typo, formatting
- **MEDIUM**: CRUD, API, components, pagination, search, tests
- **HIGH**: Auth, permissions, file upload, database writes, schema changes
- **CRITICAL**: Price, inventory, orders, payment, destructive ops, permission bypass, secrets
- **L_CLASS**: Multi-surface, microservice, platform+payment combos

**Output fields:** riskLevel, riskScore, riskReasons, affectedSurfaces, criticalFields, requiredReviewers, requiredTests, humanAuditRequired, implementationBlockers, verifierRequirements, invariantsSuggested

### 1B. Business Invariant Engine

| File | Purpose |
|------|---------|
| `schemas/business-invariant.schema.json` | JSON Schema for invariants |
| `runtime/business-invariant-engine.ps1` | Invariant spec generation from risk profiles |
| `testbeds/products-api/business-invariants.json` | Products API invariant spec (3 invariants) |

**9 Invariant Library:**
| ID | Name | Severity | Category |
|----|------|----------|----------|
| INV-001 | price_non_negative | BLOCKER | financial |
| INV-002 | price_not_zero_unless_explicit_free | CRITICAL | financial |
| INV-003 | inventory_non_negative | BLOCKER | data-integrity |
| INV-004 | order_total_matches_items | BLOCKER | financial |
| INV-005 | status_transition_allowed | BLOCKER | state-machine |
| INV-006 | archived_entity_not_mutable | BLOCKER | data-integrity |
| INV-007 | user_cannot_modify_protected_fields | BLOCKER | access-control |
| INV-008 | payment_idempotency_required | BLOCKER | idempotency |
| INV-009 | destructive_action_requires_confirmation | BLOCKER | security |

### 1C. Risk Enforcement Gate

| File | Purpose |
|------|---------|
| `runtime/risk-enforcement-gate.ps1` | Enforces risk rules: BLOCKED if requirements not met |

**Enforcement Rules:**
- L_CLASS: Requires decomposition + human audit + invariants + reviewer → BLOCKED if missing
- CRITICAL: Requires invariants + tests + human audit + reviewer → BLOCKED if missing
- HIGH: Requires tests → BLOCKED if missing
- MEDIUM: Tests recommended but not blocking
- LOW: No enforcement

---

## 2. Demo Cases

| # | Description | Risk | Status | Blocked? |
|---|-------------|------|--------|----------|
| 1 | Update README wording | LOW | ALLOWED | No |
| 2 | Add search filter to GET /api/products | MEDIUM | ALLOWED | No |
| 3 | Modify product status transition rules | HIGH | ALLOWED (tests provided) | No |
| 4 | Change product price calculation logic | CRITICAL | ALLOWED (all gates provided) | No |
| 5 | Modify user role permission checks | CRITICAL | BLOCKED | Yes — no invariants, tests, audit, reviewer |
| 6 | Build mini-program mall with payment | L_CLASS | BLOCKED | Yes — no decomposition, audit, invariants, reviewer |

---

## 3. Products API Invariant Result

File: `testbeds/products-api/business-invariants.json`

3 invariants active:
- INV-001: price_non_negative — verified by existing test (rejects negative price)
- INV-005: status_transition_allowed — verified by existing test (rejects invalid transitions)
- INV-006: archived_entity_not_mutable — partially covered (discontinued status blocks transitions)

---

## 4. Files Changed

| File | Action |
|------|--------|
| `schemas/runtime-risk-profile.schema.json` | Created |
| `schemas/business-invariant.schema.json` | Created |
| `runtime/runtime-risk-classifier.ps1` | Created |
| `runtime/business-invariant-engine.ps1` | Created |
| `runtime/risk-enforcement-gate.ps1` | Created |
| `testbeds/products-api/business-invariants.json` | Created |

---

## 5. Workflow Boundary

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
| BLOCKED enforces hard stop, not just warning | PASS |
| Products API has invariant spec | PASS |

---

## 6. Known Risks

- Risk classification is keyword-based — may need refinement for edge cases (e.g., "price" in non-financial contexts)
- Invariant library covers 9 common patterns but domain-specific invariants (healthcare, education) not yet covered
- Enforcement gate requires manual flag passing (HasInvariantSpec, HasTests, etc.) — not yet auto-detected from project state
- The `escalat` pattern matching demonstrated regex boundary sensitivity — complex patterns may need tuning

---

## 7. Recommended Next Big Capability

1. **Automated Gate Detection**: Auto-detect whether invariants/tests/reviewers/audit are present from project state rather than requiring manual flags.

2. **Products API Invariant Test Expansion**: Add explicit invariant tests to the Products API testbed that directly verify the 3 invariants.

3. **Domain-Specific Invariant Packs**: Build invariant libraries for healthcare, education, e-commerce domains.
