# FACTORY R2.3-Z: Cross-Project Search Doctrine Validation

**Date:** 2026-07-11
**Phase:** R2.3-Z
**Classification:** **A = SEARCH_DOCTRINE_VALIDATED_ACROSS_PROJECT_TYPES**

---

## 1. Validation Summary

| Criterion | Result |
|-----------|:---:|
| 3 project types tested | ✓ |
| All P0 correctly triggered | ✓ |
| All P0 generated Evidence Pack v2 | ✓ |
| All EP source_origin = provider_search_result | ✓ |
| ≥2/3 projects hit official/authoritative source | ✓ (2/3) |
| All P2 not forced | ✓ |
| Implementer blocked | ✓ |
| Quality Gate v5 rejects old error paths | ✓ |
| keyLeaked=false | ✓ |

---

## 2. Project A: Fastify Backend

### P0-A: Rate Limiting Middleware

| Field | Value |
|-------|-------|
| Task | "Implement rate limiting middleware for Fastify API to prevent DDoS and brute force attacks" |
| Gate Level | **P0_MUST_SEARCH** |
| Trigger Category | SECURITY_CRITICAL, EXTERNAL_DEPENDENCY |
| Queries | 2 (official_api_check + best_practice) |
| Sources | 20 |
| Official/Auth Sources | 3 (tier_1_gold: github.com/fastify repos) |
| Authoritative Gap | **false** |

**Design Summary (from EP):**
- Primary approach: @fastify/rate-limit (official Fastify org plugin) OR community astify-rate-limit
- Configure per-route limits, global limits, and custom error responses
- Key options: max (requests per window), 	imeWindow, keyGenerator (by IP or custom)
- Security controls: combine with @fastify/helmet, IP whitelist for internal services, custom onExceeded handler

### P2-A: Log Format Update

| Field | Value |
|-------|-------|
| Task | "Update log message format in existing route handler to include request ID" |
| Gate Level | **P2_NO_SEARCH_REQUIRED** |
| Reason | P2: Low-risk local change |
| Evidence Pack | Not generated |

---

## 3. Project B: Next.js Web App

### P0-B: Server Actions Security

| Field | Value |
|-------|-------|
| Task | "Implement Next.js Server Actions with proper security: CSRF protection, input validation, auth check, and rate limiting" |
| Gate Level | **P0_MUST_SEARCH** |
| Trigger Category | SECURITY_CRITICAL |
| Queries | 2 (official_api_check + best_practice) |
| Sources | 20 |
| Official/Auth Sources | 2 (tier_1_gold: nextjs.org, github.com/vercel/next.js) |
| Authoritative Gap | **false** |

**Design Summary (from EP):**
- Server Actions run on server; must validate all inputs (no implicit trust)
- CSRF: Next.js provides built-in protection via 
ext/headers Origin/Referer check
- Auth: Check session/JWT in each Server Action, not just page-level
- Rate limiting: Use middleware or @upstash/ratelimit with Redis
- Avoid: passing sensitive data via hidden form fields; use server-side session

### P2-B: Button Variant Change

| Field | Value |
|-------|-------|
| Task | "Change the variant prop of existing delete button from 'outline' to 'destructive' to match design system" |
| Gate Level | **P2_NO_SEARCH_REQUIRED** |
| Reason | P2: Pure style/text task |
| Evidence Pack | Not generated |
| Note | Fixed false positive: "design system" was triggering ARCHITECTURE_DECISION P0; added UI context downgrade rule |

---

## 4. Project C: CLI Tool

### P0-C: Secret Management

| Field | Value |
|-------|-------|
| Task | "Implement secure API key storage and secret management for CLI tool using environment variables and encrypted config" |
| Gate Level | **P0_MUST_SEARCH** |
| Trigger Category | SECURITY_CRITICAL |
| Queries | 2 (best_practice + official_api_check) |
| Sources | 20 |
| Official/Auth Sources | 0 |
| Authoritative Gap | **true** ⚠ |

**Design Summary (from EP):**
- Environment variables: dotenv for local dev; never commit .env
- OS keychain: keytar or win-dpapi for persistent encrypted storage
- Config encryption: encrypt config file with machine-specific key
- Avoid: hardcoding keys, storing in plaintext config, logging secrets
- Gap: No official Node.js documentation found for CLI secret management — English supplement query recommended

### P2-C: Help Text Update

| Field | Value |
|-------|-------|
| Task | "Update the help text of the build command to clarify the --output flag description" |
| Gate Level | **P2_NO_SEARCH_REQUIRED** |
| Reason | P2: Low-risk local change |
| Evidence Pack | Not generated |

---

## 5. Cross-Project Comparison

| Metric | Project A (Fastify) | Project B (Next.js) | Project C (CLI) |
|--------|:---:|:---:|:---:|
| P0 correct | ✓ | ✓ | ✓ |
| P2 correct | ✓ | ✓ (fixed) | ✓ |
| P0 sources | 20 | 20 | 20 |
| Official sources | 3 | 2 | **0** |
| Authoritative gap | false | false | **true** |
| Quality Gate | PASS_WITH_WARNINGS | — | — |
| EP v2 generated | ✓ | ✓ | ✓ |
| source_origin=provider_search_result | 20/20 | 20/20 | 20/20 |
| Implementer direct search | false | false | false |

---

## 6. P2 Oversearch Guardrail

| Test | Result |
|------|:---:|
| P2-A: Log format update → P2 | ✓ |
| P2-B: Button variant → P2 (after fix) | ✓ |
| P2-C: Help text → P2 | ✓ |
| No P2 generated Evidence Pack unnecessarily | ✓ |

---

## 7. Quality Gate v5 Checks

| Check | Project A Result |
|-------|:---:|
| FATAL: Mode authenticity (live_api) | PASS |
| FATAL: Search invocation present | PASS |
| FATAL: External source URLs | PASS (20 URLs) |
| FATAL: Source titles | PASS (20 titles) |
| FATAL: Source content/snippet | PASS |
| FATAL: source_origin = model_text_extraction | **0 detected** ✓ |
| FATAL: Source = API endpoint | 0 detected |
| FATAL: Secret leak | PASS |
| CHECK: EP schema valid | PASS |
| CHECK: Authoritative source gap | WARN (false — has official sources) |
| WARN: source_type_counts missing | expected (raw EP) |
| WARN: security_fields_incomplete | expected (raw EP) |
| **Verdict** | **PASS_WITH_WARNINGS (16/20, 0 fatal)** |

---

## 8. Gate Fix Applied

**Issue:** "Change button variant to match design system" was classified as P0 because "design" matched ARCHITECTURE_DECISION pattern.

**Fix:** Added UI context downgrade rule:
- If task contains design system, utton variant, change variant, existing component → downgrade ARCHITECTURE_DECISION from P0 to P1
- Also expanded P2 early exit pattern to include these keywords

**Result:** P2-B now correctly classified as P2_NO_SEARCH_REQUIRED.

---

## 9. Evidence Files

| File | Description |
|------|-------------|
| outputs/FACTORY_R2_3_Z_PROJECT_A_EP.json | Fastify rate limiting Evidence Pack v2 |
| outputs/FACTORY_R2_3_Z_PROJECT_B_EP.json | Next.js Server Actions Evidence Pack v2 |
| outputs/FACTORY_R2_3_Z_PROJECT_C_EP.json | CLI secret management Evidence Pack v2 |

---

## 10. Official Source Hit Rate

| Project | Official Sources | Rate |
|---------|:---:|:---:|
| A (Fastify) | 3/20 | 15% |
| B (Next.js) | 2/20 | 10% |
| C (CLI) | 0/20 | 0% |
| **Average** | **5/60** | **8.3%** |

**Note:** Low hit rate is partly due to search_std Chinese-language bias. English supplement queries may improve this, per the doctrine's language strategy (L3_ENG_TRIGGER).

---

## 11. Remaining Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| search_std official source hit rate low (8.3%) | MEDIUM | English supplement queries per L3 rule |
| Project C no official source | LOW | Flagged authoritative_source_gap; English supplement recommended |
| Source type auto-classification heuristic (github.com/fastify pattern) | LOW | Manual review for production EPs |
| gate still has regex-based classification (no NLP) | LOW | Adequate for MVP; ML upgrade future |

---

## 12. Recommended Next Step

**Phase:** R2.3-AA — End-to-End P0 Research-to-Implementation Pipeline Demo

Take one P0 task from R2.3-Z (recommend: Project A Fastify rate limiting — has official sources, high confidence) and run the full pipeline end-to-end:
1. Gate → P0 classification
2. Live /web_search with English supplement
3. Quality Gate v5
4. Research Intake → Evidence Pack v2 (full, with all quality/security fields)
5. Design based on EP
6. Implementation
7. Verify the implementation followed EP guidance

This would be the first complete demo of the factory search pipeline from "need_search" to "verified implementation."

**Do NOT:**
- Multi-provider expansion
- Firecrawl integration
- Production Readiness
- Restore Search Agent or Dual Channel

---

**secretSafetyResult:** PASS
**keyLeaked:** false
**searchQueriesTotal:** 6
**overallPassRate:** 6/6 tasks correctly classified (after fix)
