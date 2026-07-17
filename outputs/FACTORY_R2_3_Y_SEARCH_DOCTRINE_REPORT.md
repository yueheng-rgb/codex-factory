# FACTORY R2.3-Y: Search Operating Doctrine & Capability Optimization

**Date:** 2026-07-11
**Phase:** R2.3-Y
**Classification:** **A = SEARCH_DOCTRINE_AND_CAPABILITY_OPTIMIZED**

---

## 1. Summary

Consolidated evidence from R2.3-W (design comparison: 18/24 vs 12/24) and R2.3-X (implementation comparison: 19/20 vs 12/20) into an executable Search Operating Doctrine. Optimized search priority rules, query strategy, source ranking, Evidence Pack quality, and regression guardrails.

---

## 2. What Changed

### 2.1 Search Priority Rules (Updated)

| Level | R2.3-T (old) | R2.3-Y (new) |
|-------|-------------|-------------|
| **P0_MUST_SEARCH** | 10 trigger patterns | **34 trigger patterns across 4 categories** |
| — Security | Generic "auth/security" | 13 specific security patterns + security_critical flag |
| — External Deps | Basic package/SDK | 6 patterns including plugin/api/config uncertainty |
| — Architecture | Project start | 9 patterns including caching, concurrency, deployment, AI |
| — High Rework | UNSURE/uncertain | 6 patterns including multiple approaches, mainstream inquiry |
| **P1_SHOULD_SEARCH** | 4 patterns | 5 patterns (UI/UX, community, simpler alternatives) |
| **P2_NO_SEARCH** | 6 patterns | 9 patterns (added follow-existing-pattern, explicit instructions) |
| **P2 Early Exit** | None | CSS/style/text tasks excluded even if they mention security keywords |

### 2.2 W/X Evidence Incorporated

| Evidence Source | Policy Impact |
|----------------|---------------|
| R2.3-W Task 3: JWT Δ=+2 | Security-critical tasks elevated to P0 with 13 specific patterns |
| R2.3-X Task 3: Security 0→2 | P0 security must include security_controls, rejected_insecure_patterns, test_plan |
| R2.3-W Task 1: API confirmation | External dependency uncertainty triggers P0 |
| R2.3-X Task 1: error handling | P0 evidence must include version/dependency constraints |

### 2.3 Query Strategy (New)

| Rule | Description |
|------|-------------|
| R1 | Include framework name + version context |
| R2 | Append "official documentation" for P0 queries |
| R3 | English fallback when search_std returns Chinese-dominated + no official source |
| R4 | Multi-angle: P0 queries from ≥2 angles (official + community + tutorial) |
| R5 | Every query must have query_intent field |

### 2.4 Source Ranking (New)

| Tier | Weight | Types | Constraint |
|------|:---:|-------|------------|
| **Tier 1 Gold** | 3 | official_documentation, SDK repo, official example, RFC | P0: min 1 required |
| **Tier 2 Silver** | 2 | mainstream OSS, well-maintained lib, authoritative article | — |
| **Tier 3 Bronze** | 1 | community tutorial, SO accepted, issue resolution | — |
| **Tier 4 Supplement** | 0 | personal blog, low-quality article, AI summary | CANNOT be sole basis |

### 2.5 Evidence Pack Schema v2

**Per-source additions:**
source_type, source_tier, source_language, reshness_note, maturity_signal, isk_signal, ersion_or_dependency_note, selected_reason, limitations

**Top-level additions:**
source_type_counts, official_sources_count, community_sources_count, uthoritative_source_gap, english_source_gap, esearch_coverage_summary, ejected_sources_summary, open_questions, confidence_level, implementation_checklist, 	est_checklist

### 2.6 Quality Gate v5

**New fatal checks (R2.3-Y):**
- source_origin_not_model_text_extraction: rejects /chat/completions URL extraction as canonical evidence
- canonical_source_present: at least 1 provider_search_result source required

**New warnings:**
- uthoritative_source_gap: no official/tier-1 source
- english_source_gap: 0 English sources → may need supplement query
- query_intent_missing
- source_type_counts_missing

### 2.7 Firecrawl Boundary

| Allowed (future) | Forbidden |
|------------------|-----------|
| reader_provider | independent_search_agent |
| extractor_provider | canonical_search_replacement |
| crawler_provider | direct_implementer_tool |
| source_enrichment_provider | evidence_pack_bypass |

### 2.8 Search Stop Conditions

P0 search stops when: official source confirms core approach, ≥2 independent sources support main route, alternatives identified, common pitfalls recorded, version constraints noted, EP sufficient for design — OR 6 queries exceeded (requires justification).

### 2.9 Regression Tests

**17/17 PASS** (18 cases, 1 informational)

| ID | Test | Result |
|----|------|:---:|
| A | JWT Refresh Token → P0 | PASS |
| B | File Upload → P0 | PASS |
| C | RBAC → P0 | PASS |
| D | SDK Integration → P0 | PASS |
| E | Dependency Upgrade → P0 | PASS |
| F | UI Pattern → P1 | PASS |
| G | CSS Fix → P2 (no false positive) | PASS |
| H | Local Bug → P2 | PASS |
| I | Bug + Dep Uncertainty → P0 | PASS |
| J | P0 requires Evidence Pack | PASS |
| K | Implementer blocked | PASS |
| L | Chat URL → rejected (informational) | — |
| M | model_text_extraction → reject | PASS |
| N | P2 not forced to search | PASS |
| O | Security design completeness check | PASS |
| P | Official source gap detection | PASS |
| Q | Missing query_intent → warning | PASS |
| R | Missing source_type_counts → warning | PASS |

---

## 3. Example Task Classifications

| Task | Level | Reason |
|------|:---:|--------|
| Implement JWT refresh token rotation | P0 | SECURITY_CRITICAL |
| Add Fastify multipart file upload | P0 | SECURITY_CRITICAL |
| Design RBAC for admin dashboard | P0 | SECURITY_CRITICAL |
| Integrate payment SDK | P0 | SECURITY_CRITICAL + EXTERNAL_DEPENDENCY |
| Upgrade @fastify/multipart v7→v8 | P0 | HIGH_REWORK_RISK |
| Choose admin table UI component | P1 | COMMUNITY_REFERENCE |
| Fix login button padding | P2 | Style task, no implementation action |
| Fix known calculateTotal bug | P2 | Local bug, well-understood |
| Fix typo in README | P2 | Documentation only |
| Follow existing pattern for new endpoint | P2 | Copy existing implementation |

---

## 4. Changed Files

| File | Change | Description |
|------|:---:|---|
| untime/search-operating-doctrine.ps1 | NEW | Consolidated doctrine with P0/P1/P2, query strategy, source ranking, invariants |
| untime/pre-build-research-gate.ps1 | UPDATE v2.0.1 | Security-critical detection, P2 early exit, W/X evidence triggers |
| untime/search-result-quality-gate.ps1 | UPDATE v5 | 20 checkpoints, source_origin enforcement, English gap, security completeness |
| schemas/evidence-pack-v2.schema.json | NEW | Quality fields, security fields, source tier/language/freshness |
| untime/search-doctrine-regression-tests.ps1 | NEW | 18 regression test cases |

---

## 5. Invariants Enforced

1. IMPLEMENTER_NEVER_SEARCHES — confirmed by test K
2. EVIDENCE_PACK_IS_ONLY_FACT_CARRIER
3. /chat/completions URL EXTRACTION != CANONICAL — confirmed by test M
4. PLAIN_LLM_ANSWER != SEARCH_EVIDENCE
5. API_ENDPOINT_URL != EXTERNAL_SOURCE
6. MOCK/DRY_RUN != LIVE_SEARCH
7. CANNOT_SKIP_P0_WITHOUT_EVIDENCE
8. P2_CANNOT_BE_FORCED_TO_SEARCH — confirmed by test N
9. NO_INDEPENDENT_SEARCH_AGENT
10. NO_DUAL_SEARCH_CHANNEL

---

## 6. Remaining Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| CSS/style exclusion regex may have edge cases | LOW | Broadened to catch common patterns; can add more |
| English supplement strategy not yet tested live | LOW | Strategy documented; needs live trial with English query |
| Source ranking is heuristic, not ML-based | LOW | Manual tier classification sufficient for MVP |
| Firecrawl boundary is declarative only | LOW | Not yet integrated; separate spike needed |

---

## 7. Recommended Next Step

**Phase:** R2.3-Z — Multi-Project Search Doctrine Validation

Apply the updated Search Operating Doctrine to 3 real P0 tasks across different project types (Fastify, Next.js, CLI tool) and verify:
1. P0 classification is correct (no false positives/negatives)
2. P0 tasks get adequate Evidence Packs with source ranking applied
3. Security-critical tasks receive mandatory security fields
4. P2 tasks are not forced to search
5. English supplement queries trigger when authoritative_source_gap detected

**Do NOT:**
- Firecrawl integration (needs separate spike)
- Multi-provider expansion
- Production Readiness
- Restore Search Agent or Dual Channel

---

## 8. Classification

**A = SEARCH_DOCTRINE_AND_CAPABILITY_OPTIMIZED**

All criteria met:
- P0/P1/P2 search priority updated with W/X evidence
- Security-critical tasks explicitly mandatory P0
- Query strategy optimized (intent, multi-angle, English supplement)
- Source ranking established (4 tiers with constraints)
- Evidence Pack quality fields strengthened (v2 schema)
- Firecrawl boundary correctly limited to future Reader/Extractor only
- 17/17 regression tests pass
- P2 not forced to search (test G, H, N)
- Implementer still blocked (test K)
- keyLeaked=false

---

**secretSafetyResult:** PASS
**keyLeaked:** false
**regressionPassRate:** 100% (17/17)
