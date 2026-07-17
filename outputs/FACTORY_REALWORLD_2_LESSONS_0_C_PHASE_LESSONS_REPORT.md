# FACTORY-REALWORLD-2-LESSONS-0 Section C: Phase-by-Phase Lessons

**Timestamp**: 2026-06-28T10:57:00+08:00
**Status**: LESSONS_EXTRACTED — 15 lessons across 5 phase groups

---

## Intake + R1 (3 lessons)

| ID | Lesson | Action |
|----|--------|--------|
| L-RW2-001 | Real deployed projects carry production secrets — intake MUST audit first | Security/Deploy Gate: check .env, SSH, tokens BEFORE working copy |
| L-RW2-002 | Finding issues does NOT prove Factory smarter than vanilla | Never claim superiority from discovery alone |
| L-RW2-003 | Complexity triggers Diagnostic Gate suggestion | Auto-suggest for multi-role, 15+ models, 75+ URLs |

## P1: Working Copy (3 lessons)

| ID | Lesson | Action |
|----|--------|--------|
| L-RW2-004 | Working-copy isolation works — original untouched | Mandatory for all realworld phases |
| L-RW2-005 | Baseline validation catches issues before changes | Step 1 after working-copy creation |
| L-RW2-006 | Django 6.x issues are environment, not app bugs | CLASSIFY before FIX |

## P2: Security Hardening (3 lessons)

| ID | Lesson | Action |
|----|--------|--------|
| L-RW2-007 | 9 security files, 0 app code — surgical hardening | Security must not touch app logic |
| L-RW2-008 | Codex cannot rotate secrets for user | User rotation boundary: document-only |
| L-RW2-009 | Structured gate checks provide confidence | Formalize Security/Deploy Gate checklist |

## P3/P4: Test Repair (3 lessons)

| ID | Lesson | Action |
|----|--------|--------|
| L-RW2-010 | 13→21 (+54%) without app code changes | CLASSIFICATION_FIRST repair policy |
| L-RW2-011 | 2 skipped = honest, not failure | HONEST_SKIP_ALLOWED policy |
| L-RW2-012 | 21/2/0 is not 23/23 | Verifier must detect skip-hiding |

## P5: Delivery (3 lessons)

| ID | Lesson | Action |
|----|--------|--------|
| L-RW2-013 | User needs security rotation checklist | Gate must produce user checklist |
| L-RW2-014 | Local safe ≠ production ready | Separate production readiness gate |
| L-RW2-015 | REALWORLD-2 success does not unblock v0.5 | Re-confirm v0.5 BLOCKED each phase |

---

## Factory Rule Implications

**New rules needed:**
- Security/Deploy Gate: mandatory for deployed-trace projects
- Test repair: CLASSIFICATION_FIRST, HONEST_SKIP_ALLOWED, no fake pass
- User secret rotation: document-only boundary
- Production readiness: separate gate from local validation

**Existing rules confirmed:** Build Lite default, working-copy isolation, original protection, v0.5 blocked, no superiority overclaim

**Existing rules strengthened:** Context Packet for realworld, Diagnostic Gate auto-suggest, phase close for long-horizon
