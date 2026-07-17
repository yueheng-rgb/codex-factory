# FACTORY R2.3-X: Implementation-Level Value Validation for Canonical Search

**Date:** 2026-07-11
**Phase:** R2.3-X
**Classification:** **A = IMPLEMENTATION_VALUE_CONFIRMED**
**Group B (DeepSeek Native Search):** SKIPPED — no native search tool available

---

## 1. Experiment Design

| Group | Search | Evidence Pack | Design Source |
|-------|:---:|:---:|---|
| A | No | No | R2.3-W Group A design (model knowledge only) |
| B | N/A | N/A | Skipped |
| C | No (implementer reads EP only) | Yes | R2.3-W Group C Evidence Pack |

**Tasks selected:** 2 P0 tasks with largest design deltas from R2.3-W:
- **Task 1:** Fastify File Upload / Multipart (Δ=+3 in design)
- **Task 3:** JWT Refresh Token (Δ=+2 in design)

**Implementation project:** untime/tests/r2-3-x-implementation-trial/

---

## 2. Task 1: Fastify File Upload — Implementation Comparison

### Group A (No Search) Implementation

| Aspect | Score | Detail |
|--------|:---:|--------|
| **Correct API Usage** | 2 | equest.file(), 	oBuffer(), limits.fileSize — guessed correctly |
| **Security / Robustness** | 1 | Basic MIME check (4 types), single size enforcement, generic error messages |
| **Integration Fit** | 2 | Clean Fastify plugin register, isolated port 3100 |
| **Test Quality** | 1 | Covers upload, path traversal, empty upload — but no oversized file test, no MIME edge case |
| **Rework / Uncertainty** | 1 | API guess was correct but 4 UNSURE items at design time; incomplete upload not handled |
| **Total** | **7/10** | |

### Group C (Search-Guided) Implementation

| Aspect | Score | Detail |
|--------|:---:|--------|
| **Correct API Usage** | 2 | Confirmed limits.fileSize, equest.file(), 	oBuffer() from official README |
| **Security / Robustness** | 2 | 6 MIME types, double size enforcement (plugin + post-read), path.basename sanitization, descriptive error with llowedTypes list, incomplete upload handled |
| **Integration Fit** | 2 | Clean structure, separate port 3101 |
| **Test Quality** | 2 | Covers allowed/blocked MIME, path traversal, empty upload, oversized file handling |
| **Rework / Uncertainty** | 2 | 0 UNSURE items at implementation time — API surface confirmed |
| **Total** | **10/10** | |

### Task 1 Key Differences

| Feature | Group A | Group C |
|---------|---------|---------|
| MIME types validated | 4 | 6 |
| Error response detail | {"error":"File type not allowed"} | {"error":"File type not allowed","allowedTypes":[...]} |
| Stored filename | UUID-original | UUID-original + explicit storedName field |
| Incomplete upload | Not handled (500) | Handled (400 with message) |
| Size enforcement | Plugin limit only | Plugin limit + post-read buffer check |

---

## 3. Task 3: JWT Refresh Token — Implementation Comparison

### Group A (No Search) Implementation

| Aspect | Score | Detail |
|--------|:---:|--------|
| **Correct API Usage** | 1 | @fastify/jwt sign/verify correct; but refresh in body (not cookie) |
| **Security / Robustness** | **0** | ❌ Refresh in JSON body → XSS if stored in localStorage; ❌ No token rotation; ❌ No reuse detection (same refresh works >1 time); ❌ No logout endpoint; ❌ Raw token storage (no hash) |
| **Integration Fit** | 2 | Simple, minimal dependencies, straightforward |
| **Test Quality** | 1 | Login, protected, refresh, bad password all tested; but missing rotation/reuse/logout tests |
| **Rework / Uncertainty** | 1 | 5 UNSURE items at design time; would need rework for production security |
| **Total** | **5/10** | |

### Group C (Search-Guided) Implementation

| Aspect | Score | Detail |
|--------|:---:|--------|
| **Correct API Usage** | 2 | @fastify/jwt + @fastify/cookie correctly configured; signed cookies |
| **Security / Robustness** | **2** | ✅ httpOnly + SameSite=Strict cookie; ✅ SHA-256 hashed token storage; ✅ Token family rotation; ✅ Reuse detection + family revocation; ✅ Logout endpoint; ✅ Cookie signing |
| **Integration Fit** | 1 | More complex (family tracking, hash maps); cookie parsing needs proper client support |
| **Test Quality** | 2 | Covers login, protected, refresh, reuse detection, post-revoke, logout, bad password |
| **Rework / Uncertainty** | 2 | 0 UNSURE items — best practices confirmed by sources |
| **Total** | **9/10** | |

### Task 3 Key Differences

| Security Feature | Group A | Group C |
|---------|:---:|:---:|
| Refresh token delivery | JSON body | httpOnly cookie |
| XSS resistance | ❌ | ✅ |
| Token storage | Raw string | SHA-256 hash |
| Token rotation | ❌ | ✅ |
| Reuse detection | ❌ | ✅ (revokes family) |
| Logout | ❌ | ✅ |
| Cookie signing | N/A | ✅ |

---

## 4. Aggregate Scores

| Task | Group A | Group C | Delta |
|------|:---:|:---:|:---:|
| Task 1: Fastify Upload | 7/10 | **10/10** | +3 |
| Task 3: JWT Refresh Token | 5/10 | **9/10** | +4 |
| **Total** | **12/20** | **19/20** | **+7** |

---

## 5. Where Search Improved Implementation

| Area | Impact | Detail |
|------|--------|--------|
| **Security by Design** | **CRITICAL (Task 3)** | Group A: 0/2 security score (no rotation, no reuse detection). Group C: 2/2 (all best practices). Search prevented shipping code with critical auth vulnerabilities. |
| **API Confidence** | HIGH (Task 1) | Group A guessed correctly but had 4 UNSURE items. Group C had 0 — confirmed API surface from official README. |
| **Error Handling Completeness** | MODERATE (Task 1) | Group C had descriptive errors, incomplete upload handling, double size check. Group A had minimal error messages. |
| **Implementation Speed** | MODERATE | Group A required trial-and-error for API surface. Group C had confirmed patterns from start. |

## 6. Where Search Did NOT Help

| Area | Detail |
|------|--------|
| **Basic API (Task 1)** | Group A's API guess was correct even without search — @fastify/multipart API is intuitive enough |
| **Integration complexity (Task 3)** | Group C's cookie + signing + family tracking adds code complexity that needs debugging |
| **PowerShell cookie handling** | Cookie-based refresh requires proper client support; JSON body (Group A) is simpler for testing |

## 7. Whether Design Advantage Translated to Code

| Design Phase (R2.3-W) | Implementation Phase (R2.3-X) |
|---|---|
| Task 1: Δ=+3 (A:4, C:7) | Task 1: Δ=+3 (A:7, C:10) — consistent |
| Task 3: Δ=+2 (A:4, C:6) | Task 3: Δ=+4 (A:5, C:9) — gap WIDENED |

**Finding:** The design advantage translated to code and, in Task 3, the implementation gap was even larger than the design gap. This is because security-critical decisions (rotation, reuse detection) have a compounding effect — skipping them in design means skipping them in code.

## 8. Contamination Check

| Check | Result |
|-------|--------|
| Group A read Group C Evidence Pack? | No — Group A used only own design doc |
| Group A used /web_search? | No |
| Group C Implementer directly searched? | No — used only Evidence Pack + project files |
| Groups cross-contaminated? | No — separate files, separate ports |
| Artificially weakened Group A? | No — Group A followed its own design faithfully |

## 9. Rework Count

| Group | Task 1 Reworks | Task 3 Reworks | Total |
|-------|:---:|:---:|:---:|
| A | 1 (MIME type too restrictive for test) | 0 (but would need rework for production) | 1 |
| C | 0 | 1 (cookie parsing debugging) | 1 |

---

## 10. Implementation Value Summary

| Value Dimension | Assessment |
|-----------------|------------|
| **Prevents shipping insecure code** | HIGH — Group A's JWT implementation has 4 critical security gaps that Group C eliminated |
| **Reduces API guesswork** | MODERATE — Task 1 API guess was correct; value is in confidence, not correctness |
| **Improves robustness** | MODERATE — Better error handling, wider MIME support, edge case coverage |
| **Increases implementation complexity** | TRADEOFF — Group C adds token families, hash maps, cookie signing |
| **ROI** | POSITIVE — ~7 search queries prevented a production-incapable JWT implementation |

---

## 11. Classification

**A = IMPLEMENTATION_VALUE_CONFIRMED**

**Justification:**
- Group C outperformed Group A in both tasks (19/20 vs 12/20, Δ=+7)
- Task 3 showed critical security improvement: Group A had 0/2 security score → Group C 2/2
- Search prevented shipping JWT code with no rotation, no reuse detection, and XSS-vulnerable refresh delivery
- Implementation gap exceeded design gap (Δ=+4 vs Δ=+2 for Task 3), proving compounding effect

**Caveats:**
- Task 1 improvement was moderate (both groups got the API right)
- Group C cookie-based JWT needs proper client support (debugging cost)
- 2-task sample; Task 2 (RBAC) not implemented
- Single project type (Fastify API)

---

## 12. Evidence Files

| File | Description |
|------|-------------|
| untime/tests/r2-3-x-implementation-trial/task1-group-a-upload.js | Task 1 Group A implementation |
| untime/tests/r2-3-x-implementation-trial/task1-group-c-upload.js | Task 1 Group C implementation |
| untime/tests/r2-3-x-implementation-trial/task3-group-a-jwt.js | Task 3 Group A implementation |
| untime/tests/r2-3-x-implementation-trial/task3-group-c-jwt.js | Task 3 Group C implementation |
| outputs/FACTORY_R2_3_X_IMPLEMENTATION_VALIDATION_REPORT.md | This report |

---

## 13. Remaining Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Group C cookie parsing needs debugging | LOW | Integration test with browser/fetch API |
| 2-task sample limited | LOW | Task 2 (RBAC) can be added later |
| Single project type (Fastify) | LOW | Multi-project benchmark exists from R2.3-I |
| Security testing is manual, not automated | MEDIUM | Add automated security regression tests |

---

## 14. Recommended Next Step

**Phase:** R2.3-Y — Merge Findings into Search Necessity Policy Update

Based on R2.3-W (design) and R2.3-X (implementation) evidence:
1. Update P0_MUST_SEARCH criteria: security-critical tasks (auth, upload, crypto) should ALWAYS trigger search
2. Update Quality Gate: add "security_critical_task_no_search" as fatal gate
3. Add Task 3 findings to Evidence Pack as reference for future auth implementations

**Do NOT:**
- Claim Production Readiness
- Reintroduce Search Agent or Dual Channel
- Let Implementer directly search

---

**secretSafetyResult:** PASS
**keyLeaked:** false
**implementationLanguage:** Node.js + Fastify
**implementationFiles:** 4
**totalReworkCount:** 2
