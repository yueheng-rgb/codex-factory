# R2.3-T Pre-Build Research Gate & Search Necessity Policy — Final Report

**Phase:** FACTORY-R2.3-T  
**Date:** 2026-07-11  
**Classification:** **A = PRE_BUILD_RESEARCH_GATE_ESTABLISHED**

---

## 1. Verification Results

**18/18 PASS (0 failures)**

| Category | Tests | Result |
|----------|:---:|:---:|
| P0_MUST_SEARCH | 7 | 7/7 PASS |
| P1_SHOULD_SEARCH | 3 | 3/3 PASS |
| P2_NO_SEARCH_REQUIRED | 5 | 5/5 PASS |
| P2→P1 Escalation | 2 | 2/2 PASS |
| Implementer BLOCK | 1 | 1/1 PASS |

---

## 2. Search Necessity Levels

| Level | Search Required | EP Required | Budget (queries/sources) |
|-------|:---:|:---:|---|
| **P0_MUST_SEARCH** | true | true | 3-6 / 5-10 |
| **P1_SHOULD_SEARCH** | false | false | 1-3 / 2-5 |
| **P2_NO_SEARCH_REQUIRED** | false | false | 0/0 |

### P0 Triggers (10 categories)
new_project_start, architecture_selection, tech_stack_selection, third_party_integration, security_critical, database_design, user_asks_research, dependency_risk, major_rework_risk, uncertainty_with_p0_triggers

### P2→P1 Escalation
Uncertainty or new dependency in an otherwise P2 task escalates to P1 (NOT P0). Documentation tasks with install commands do NOT escalate.

---

## 3. Changed Files

| File | Description |
|------|-------------|
| `schemas/search-necessity-policy.schema.json` | Search Necessity Policy schema (P0/P1/P2, triggers, budget, stop conditions, bans) |
| `runtime/pre-build-research-gate.ps1` | Pre-Build Research Gate runtime (13.2KB) with P0/P1/P2 classification, escalation, implementer block |
| `harness/verification/verify-r2-3-t-pre-build-gate.ps1` | Verification harness: 18 test cases |
| `outputs/FACTORY_R2_3_T_GATE_VERIFICATION_RESULTS.json` | Verification results |

---

## 4. Hard Bans Enforced

- [x] Implementer direct search → FATAL (IMPLEMENTER_SEARCH_ATTEMPT)
- [x] Search bypassing Evidence Pack → architectural constraint
- [x] Plain LLM knowledge answer as search evidence → Quality Gate v4
- [x] API endpoint URL as external source → Quality Gate v4
- [x] Mock/dry_run as live search → Quality Gate v4
- [x] P0 search skipped due to user urgency → P0 is mandatory

---

## 5. Example Task Classifications

| Task | Level | Reason |
|------|-------|--------|
| Build a full-stack ecommerce platform | P0 | new_project_start |
| Design database schema for multi-tenant SaaS | P0 | database_design |
| Integrate Stripe payment gateway | P0 | third_party_integration |
| Choose between PostgreSQL and MongoDB | P0 | tech_stack_selection |
| Upgrade Next.js 13 to 15 | P0 | dependency_risk |
| Implement JWT auth with RBAC | P0 | security_critical |
| Add dark mode toggle | P1 | ui_ux_pattern |
| Multiple form validation approaches | P1 | multiple_routes |
| Fix login button disable bug | P2 | local_bug_fix |
| Change header color | P2 | small_change |
| Add unit tests | P2 | add_tests |
| Rename function across codebase | P2 | refactor_only |
| Write README with npm install instructions | P2 | pure_docs |
| Fix error — not sure if dependency conflict | P1 (escalated) | bug fix + uncertainty |
| Add date picker — not sure which library | P1 (escalated) | new dep + uncertainty |

---

## 6. Architecture Preserved

```
need_search → Provider Selector → WebSearch Tool → Quality Gate → Research Intake → Evidence Pack → Agents
```

- Independent Search Agent: DEPRECATED
- Dual Search Channel: DEPRECATED
- Implementer never calls provider directly
- Evidence Pack is sole fact carrier

---

## 7. Remaining Risks

- P0 triggers are regex-based and may have false positives/negatives
- No semantic understanding of task context beyond regex matching
- Users may still verbally pressure to skip P0 search

---

## 8. Next Step Recommendation

R2.3-T established the Pre-Build Research Gate. The factory can now classify tasks into P0/P1/P2 and enforce search before implementing high-risk work. User decides next phase.
