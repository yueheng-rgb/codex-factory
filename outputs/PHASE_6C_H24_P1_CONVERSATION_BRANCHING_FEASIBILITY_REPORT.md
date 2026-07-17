# PHASE 6C — H24-P1 / Conversation Branching + Session Rotation Feasibility Clarification

**Phase**: H24-P1 | **Parent**: H24 (PASS) | **Status**: PASS
**Verdict**: 10/10 negatives, 18/18 checks
**Completed**: 2026-06-24T21:53:33+08:00

---

## 1. Terminology (11 terms defined)

| Term | Scope | Classification |
|------|-------|---------------|
| new conversation / thread | Codex CLI | PARTIALLY_VERIFIED |
| fork conversation / thread | Codex CLI | PARTIALLY_VERIFIED |
| resume thread | Codex CLI | PARTIALLY_VERIFIED |
| compacted thread | Codex CLI internal | VERIFIED_FACT |
| subagent (spawn_agent) | Codex CLI | VERIFIED_FACT |
| fork_context:true/false | Codex CLI | VERIFIED_FACT |
| thread handoff | Codex CLI | CODEX_SELF_REPORT_ONLY |
| session rotation handoff | Factory repo-local | VERIFIED_FACT |
| user-visible new Codex window | Codex App UI | PARTIALLY_VERIFIED |
| background thread / automation wakeup | Codex CLI | CODEX_SELF_REPORT_ONLY |

---

## 2. Claim Classification (15 claims A-O)

| # | Classification | Count |
|---|---------------|-------|
| VERIFIED_FACT | 6 |
| PARTIALLY_VERIFIED | 5 |
| HYPOTHESIS_REQUIRES_VALIDATION | 1 |
| REJECTED_OR_UNSUPPORTED | 2 |
| CODEX_SELF_REPORT_ONLY | 1 |

### REJECTED claims:
- **F**: Automatic window creation after compact — NO mechanism observed
- **G**: Fork inherits full pre-compact context — compressed summaries are lossy

### CRITICAL finding:
- **E** (compact detection): HYPOTHESIS — no compact-detection API observed. "After one compact" rules cannot be automated.

---

## 3. Experiments (5 designed, 0 executed)

Live thread fork/create experiments NOT performed (would create side-effect threads). All experiments designed with safe parameters for future testing.

---

## 4. Decision Matrix (8 use cases)

| Use Case | Recommended Mechanism |
|----------|----------------------|
| Isolated builder | spawn_agent + fork_context:false |
| Verifier/explorer | spawn_agent + fork_context:true |
| Session rotation after compact | Manual new window + artifact handoff |
| Major phase transition | Session rotation + startup verification |
| Alt architecture exploration | spawn_agent + fork_context:true |
| Stale-context recovery | Manual new window + artifact handoff |
| Automation monitoring | automation_update (CODEX_SELF_REPORT) |
| Background check | spawn_agent + fork_context:false |

---

## 5. Policy Tiers (5 tiers)

| Tier | Rule |
|------|------|
| CONFIRMED_COMPACT_CURRENT_TASK | Finish current task only |
| CONFIRMED_COMPACT_BEFORE_MAJOR_PHASE | Session rotation before new H/DRY/FINAL |
| MULTIPLE_COMPACTIONS | Mandatory rotation; no new phase |
| UNKNOWN_BRANCH_CAPABILITY | Manual window + artifact handoff (always safe) |
| VERIFIED_THREAD_FORK | Fork + artifact startup verification |

---

## 6. Final Package Wording

**May claim** (5 items): artifact-based rotation, fork as carrier, startup verification required, compressed summary not evidence, sub-agents provide isolation.

**Must NOT claim** (5 items): auto-window creation, full pre-compact context inheritance, subagent = user branch, fork = memory expansion, automation = new context.

---

## 7. Negatives: 10/10 PASS, 0 unexpected

All branching/fork/session rotation boundaries hold.

---

## Recommended: H24-P2

Update final package rules with clarified branching policy before FINAL-PREP.
