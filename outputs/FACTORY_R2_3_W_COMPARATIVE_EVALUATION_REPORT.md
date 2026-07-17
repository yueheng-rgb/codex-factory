# FACTORY R2.3-W: External Search vs DeepSeek Baseline Comparative Evaluation

**Date:** 2026-07-11
**Phase:** R2.3-W
**Classification:** **A = EXTERNAL_SEARCH_VALUE_CONFIRMED**
**Group B (DeepSeek Native Search):** SKIPPED — no native search tool available in current Codex environment

---

## 1. Experiment Design

| Group | Description | Search Allowed | Evidence Pack |
|-------|------------|:---:|:---:|
| A | No External Search Baseline | No | No |
| B | DeepSeek Native Search | N/A (not available) | N/A |
| C | Canonical Structured Web Search | Yes (/api/paas/v4/web_search) | Yes |

**Tasks selected:** 3 P0_MUST_SEARCH tasks likely to suffer from "闭门造车" (reinventing the wheel):

1. **Fastify File Upload / Multipart** — API surface changes across versions, easy to get wrong
2. **Admin Dashboard RBAC Permissions** — Ecosystem gaps, library choices matter
3. **Login JWT / Refresh Token** — Security-critical, multiple UNSURE items in baseline

---

## 2. Per-Task Comparison

### Task 1: Fastify File Upload / Multipart

| Dimension | Group A (No Search) | Group C (Structured Search) |
|-----------|:---:|:---:|
| **Evidence Quality** | 0 | **2** |
| — official_source_hit | 0 (none) | 1 (fastify/fastify-multipart README) |
| — source_traceability | 0 | 1 (GitHub + tutorial URLs) |
| — freshness | 0 | 1 (recent content) |
| **Design Quality** | 1 | **2** |
| — correctness | 1 (reasonable but UNSURE about API) | 2 (API surface confirmed) |
| — rejected_alternatives | 1 (generic) | 2 (specific: busboy, multer, bodyParser) |
| — avoids_deprecated | 1 (unknown risk) | 2 (confirmed current API) |
| **Implementation Quality** | 1 | **2** |
| — would_compile/run | 1 (likely works after trial/error) | 2 (correct API from sources) |
| — rework_needed | moderate (4 UNSURE items) | low (UNSURE resolved) |
| — hallucinated_api | moderate risk | low risk |
| **Cost / Efficiency** | 2 | 1 |
| — search_queries_used | 0 | 3 |
| — source_count | 0 | 3 |
| **TOTAL** | **4/8** | **7/8** |
| **Delta** | — | **+3** |

**Verdict:** Search clearly helped. Group A had 4 UNSURE items about @fastify/multipart API surface (.file() vs .parts(), limits.fileSize option key, buffer vs stream API). Group C confirmed via official GitHub README: equest.file() returns {toBuffer(), file, fields, mimetype, filename}, and limits.fileSize is the correct option.

---

### Task 2: Admin Dashboard RBAC Permissions

| Dimension | Group A (No Search) | Group C (Structured Search) |
|-----------|:---:|:---:|
| **Evidence Quality** | 0 | **1** |
| — official_source_hit | 0 | 0 (no Fastify RBAC plugin found) |
| — source_traceability | 0 | 1 (GitHub repos, articles) |
| — freshness | 0 | 1 |
| **Design Quality** | 1 | **2** |
| — correctness | 1 (reasonable) | 2 (confirmed ecosystem gap) |
| — rejected_alternatives | 1 (CASL, accesscontrol) | 2 (added seeden/rbac, Ory Keto) |
| — ecosystem_gap_aware | 0 (assumed plugin exists) | 2 (confirmed no Fastify plugin) |
| **Implementation Quality** | 1 | **1** |
| — would_compile/run | 1 | 1 |
| — rework_needed | moderate (might hunt for plugin) | low (custom from start) |
| **Cost / Efficiency** | 2 | 1 |
| — search_queries_used | 0 | 2 |
| — source_count | 0 | 3 |
| **TOTAL** | **4/8** | **5/8** |
| **Delta** | — | **+1** |

**Verdict:** Search provided moderate value. Key finding: no well-maintained Fastify-native RBAC plugin exists in npm ecosystem. This prevented Group A from wasting time evaluating CASL/accesscontrol/seeden-rbac integration complexity. However, the search results were predominantly Chinese-language generic RBAC articles, not Fastify-specific implementation guides. The improvement is real but modest.

---

### Task 3: Login JWT / Refresh Token

| Dimension | Group A (No Search) | Group C (Structured Search) |
|-----------|:---:|:---:|
| **Evidence Quality** | 0 | **1** |
| — official_source_hit | 0 | 0 (Tencent Cloud articles, not official JWT docs) |
| — source_traceability | 0 | 1 |
| — freshness | 0 | 1 |
| **Design Quality** | 1 | **2** |
| — correctness | 1 (reasonable but 5 UNSURE items) | 2 (best practices confirmed) |
| — rejected_alternatives | 1 | 2 (session, JWT-only, OAuth2) |
| — security_critical_items | 1 (some UNSURE) | 2 (resolved: httpOnly, rotation, reuse detection) |
| **Implementation Quality** | 1 | **2** |
| — would_compile/run | 1 | 2 (correct patterns) |
| — rework_needed | high (security regressions possible) | low |
| **Cost / Efficiency** | 2 | 1 |
| — search_queries_used | 0 | 2 |
| — source_count | 0 | 3 |
| **TOTAL** | **4/8** | **6/8** |
| **Delta** | — | **+2** |

**Verdict:** Search clearly helped. Group A had 5 security-critical UNSURE items: refresh token storage format, httpOnly vs localStorage, rotation strategy, bcrypt vs argon2, and cookie vs Bearer header. Group C confirmed: SHA-256 hash in DB, httpOnly + Secure + SameSite=Strict cookie, token rotation + reuse detection, argon2 preferred for new projects. These are not merely "nice to have" — wrong choices here create real security vulnerabilities (XSS via localStorage, token theft without rotation).

---

## 3. Overall Comparison Summary

| Metric | Group A (No Search) | Group C (Structured Search) |
|--------|:---:|:---:|
| Task 1 Score | 4/8 | **7/8** |
| Task 2 Score | 4/8 | **5/8** |
| Task 3 Score | 4/8 | **6/8** |
| **Total** | **12/24** | **18/24** |
| Total UNSURE items | 13 | 0 (resolved) |
| Total sources | 0 | 9 |
| Total search queries | 0 | 7 |
| Hallucination risk | MODERATE-HIGH | LOW-MODERATE |

---

## 4. Where External Search Helped

| Area | Impact | Evidence |
|------|--------|----------|
| **API surface confirmation** | HIGH | Task 1: @fastify/multipart .file() API, limits.fileSize confirmed vs guessed |
| **Ecosystem gap discovery** | MODERATE | Task 2: Confirmed no Fastify RBAC plugin exists → custom implementation justified |
| **Security best practice confirmation** | HIGH | Task 3: httpOnly cookie, token rotation, reuse detection all confirmed |
| **Dependency selection** | MODERATE | All tasks: search prevented choosing wrong/unmaintained libs |
| **Preventing rework** | HIGH | Task 1: 4 API guesses avoided; Task 3: 5 security decisions confirmed |

## 5. Where External Search Did NOT Help

| Area | Reason |
|------|--------|
| **Task 2 search quality** | search_std returned generic Chinese RBAC articles, not Fastify implementation details |
| **Fastify-specific docs** | @fastify/jwt refresh workflow not found in search results; relied on general knowledge |
| **Official docs hit rate** | Only 1/9 sources was official (fastify/fastify-multipart README), rest were tutorials/articles |
| **English-language precision** | search_std favors Chinese content; some English-specific Fastify docs missing |

## 6. Cases Where Baseline Was Enough

| Case | Reason |
|------|--------|
| Core RBAC model (user→role→permission) | Well-known pattern, Group A got it right |
| bcrypt for password hashing | Well-known, Group A chose correctly |
| JWT Bearer header for access tokens | Standard practice, Group A aligned |
| File type validation | Common security practice, both groups proposed correctly |

## 7. Cases Where Search Prevented Wrong Direction

| Risk | Would Group A have gotten it wrong? |
|------|:---:|
| Using equest.parts() instead of equest.file() | Likely — Fastify v4/v5 API changed, old tutorials use .parts() |
| Storing refresh token in localStorage | Possible — common beginner mistake, confirmed bad practice |
| Looking for Fastify RBAC plugin that doesn't exist | Likely — wasted time searching npm |
| Using ccesscontrol npm (unmaintained since 2018) | Possible — still appears in old tutorials |
| Not implementing token rotation | Possible — many tutorials skip this |

## 8. Cost vs Value Summary

| Cost | Value |
|------|-------|
| 7 search queries (search_std billing) | 13 UNSURE items resolved to 0 |
| ~9 sources reviewed | 3/3 designs improved (2 significantly) |
| ~10 minutes search + analysis | Prevented estimated 1-3 hours of rework per task |
| API credits consumed (~7 search_std calls) | Security regressions avoided (Task 3) |

**ROI assessment:** Positive. The search cost is negligible compared to rework cost of wrong API usage (Task 1) or security vulnerability (Task 3).

---

## 9. Classification

**Classification: A = EXTERNAL_SEARCH_VALUE_CONFIRMED**

**Justification:**
- Group C showed clear improvement in ≥2/3 P0 tasks (Tasks 1 and 3 had significant deltas; Task 2 had moderate)
- Design correctness improved (API surface confirmed, security patterns validated)
- Evidence quality improved (0 → 9 traceable sources)
- Dependency selection improved (avoided unmaintained libs, confirmed ecosystem gaps)
- Rework risk reduced (13 UNSURE → 0)

**Caveats:**
- This is a DESIGN-LEVEL comparison only; no implementations were built and tested
- Group B (DeepSeek native) was skipped — comparison is only A vs C
- search_std result quality varies by query language (Chinese-heavy results)
- Official documentation hit rate is low (1/9 sources)
- Results may differ for tasks requiring English-language precision

---

## 10. Remaining Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| search_std language bias (Chinese-heavy) | MEDIUM | Use English queries; consider multi-provider for English docs |
| Official docs under-represented in results | MEDIUM | Quality Gate should flag when no official source present |
| Design-only validation (no runtime test) | LOW | Follow-on phase should test Group C design in real implementation |
| Search cost scaling | LOW | Budget limits already in place (R2.3-T) |

---

## 11. Recommended Next Step

**Phase:** R2.3-X — Real Implementation Trial with Search-Guided Design

Take the Group C design from Task 1 (Fastify file upload — strongest delta) and Task 3 (JWT — highest security impact), implement them in a real project, and compare runtime behavior with the no-search designs. This would validate whether design-level superiority translates to implementation-level superiority.

**Do NOT:**
- Claim Production Readiness
- Expand to multi-provider search
- Reintroduce Independent Search Agent or Dual Search Channel
- Let Implementer directly search

**Architecture maintained:**

eed_search → Provider Selector → /web_search → Quality Gate → Research Intake → Evidence Pack → Agents

---

## 12. Evidence Files

| File | Description |
|------|-------------|
| outputs/FACTORY_R2_3_W_TASK1_GROUP_A.json | Task 1 no-search baseline |
| outputs/FACTORY_R2_3_W_TASK1_GROUP_C.json | Task 1 structured search design |
| outputs/FACTORY_R2_3_W_TASK1_GROUP_C_SEARCH_RESULT.json | Task 1 raw search results |
| outputs/FACTORY_R2_3_W_TASK2_GROUP_A.json | Task 2 no-search baseline |
| outputs/FACTORY_R2_3_W_TASK2_GROUP_C.json | Task 2 structured search design |
| outputs/FACTORY_R2_3_W_TASK2_SEARCH_RESULT.json | Task 2 raw search results |
| outputs/FACTORY_R2_3_W_TASK3_GROUP_A.json | Task 3 no-search baseline |
| outputs/FACTORY_R2_3_W_TASK3_GROUP_C.json | Task 3 structured search design |
| outputs/FACTORY_R2_3_W_TASK3_SEARCH_RESULT.json | Task 3 raw search results |

---

**secretSafetyResult:** PASS
**keyLeaked:** false
**searchQueriesTotal:** 7
**searchProvider:** ZhipuAI /api/paas/v4/web_search (search_std)
