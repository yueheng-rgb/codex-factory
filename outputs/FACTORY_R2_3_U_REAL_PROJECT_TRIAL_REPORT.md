# R2.3-U Real Project Pre-Build Research Trial — Final Report

**Phase:** FACTORY-R2.3-U  
**Date:** 2026-07-11  
**Classification:** **A = REAL_PROJECT_RESEARCH_GATE_TRIAL_PASS**

---

## 1. Summary

| Field | Value |
|-------|-------|
| phase | R2.3-U |
| classification | **A** |
| selected_task | Add secure file upload endpoint to factory-skill-live-trial Fastify API |
| gate_result | P0_MUST_SEARCH |
| evidence_pack_file | outputs/FACTORY_R2_3_U_EVIDENCE_PACK.json (13 sources, 3 queries) |
| design_file | outputs/FACTORY_R2_3_U_DESIGN.md |
| implementer_direct_search_detected | **false** |
| evidence_pack_used_by_implementer | **true** |
| quality_improvement_observed | **true** |

---

## 2. End-to-End Pipeline Flow

```
Task: "Add secure file upload endpoint..."
  ↓
Pre-Build Research Gate → P0_MUST_SEARCH
  ↓
3 live queries via Single WebSearch Tool (ZhipuAI GLM-4)
  ↓
13 sources → Quality Gate → Evidence Pack
  ↓
Design: @fastify/multipart + type whitelist + size limits + UUID naming
  ↓
IMPL-BE-001: installed @fastify/multipart@7, added /api/upload route
  ↓
4/4 tests PASS
  ↓
Verification: no direct search, no key leak, architecture preserved
```

---

## 3. What the Gate Prevented

| Without Gate | With Gate |
|---|---|
| Would have guessed multipart approach (busboy, multer, express patterns) | Used official `@fastify/multipart` with Fastify-native integration |
| Might have used base64 JSON upload (bad for files) | Used proper multipart/form-data |
| Might have missed type validation | Whitelist + size limits + sanitization from EP |
| Might have stored files in web root | UUID-prefixed names in separate uploads/ directory |

---

## 4. Trial Finding: EP_VERSION_GAP

| Finding | Detail |
|---------|--------|
| Issue | IMPL installed `@fastify/multipart@latest` (v8, Fastify 5.x) but project uses Fastify 4.29.1 |
| Root cause | Evidence Pack sources were URLs/descriptions, not version-pinned install commands |
| Resolution | Downgraded to `@fastify/multipart@7` (Fastify 4.x compatible) |
| Recommendation | P0 Evidence Packs should include version constraints for critical dependencies |

---

## 5. Changed Files

| File | Role | Change |
|------|------|--------|
| `factory-skill-live-trial/src/server.js` | IMPL | Added /api/upload endpoint with @fastify/multipart |
| `factory-skill-live-trial/tests/upload.test.js` | IMPL | 4 tests: valid upload, invalid type, no file, health |
| `factory-skill-live-trial/package.json` | IMPL | Added @fastify/multipart@7, form-data, test script |
| `outputs/FACTORY_R2_3_U_EVIDENCE_PACK.json` | RSRC | Evidence Pack (13 sources across 3 queries) |
| `outputs/FACTORY_R2_3_U_DESIGN.md` | ARCH | Design document from EP |

---

## 6. Verification (10/10)

| # | Check | Result |
|---|-------|:---:|
| V1 | Tests pass | 4/4 PASS |
| V2 | Evidence Pack exists | true |
| V3 | Design references EP | true |
| V4 | Implementation matches EP design | 5/5 matches |
| V5 | No direct search bypass | true |
| V6 | No Search Agent / Dual Channel | true |
| V7 | No key leak in project files | true |
| V8 | Gate result confirmed | P0_MUST_SEARCH |
| V9 | Architecture preserved | true |
| V10 | Quality improvement observed | true |

---

## 7. Remaining Risks

- EP_VERSION_GAP: future P0 Evidence Packs should pin dependency versions
- Only 1 task type tested (API endpoint); UX/database/architecture tasks not yet trialed
- Server not long-running tested

---

## 8. R2.3 Series Completion Status

| Phase | Classification | What Was Achieved |
|-------|:---:|---|
| R2.3-Q | A_PROVIDER | Provider API connected, search NOT verified |
| R2.3-R | A | Search tool invoked, 10 external URLs, EP verified |
| R2.3-S | A | Pipeline consolidated, 10 fatal gates, 4 regression tests |
| R2.3-T | A | Pre-Build Research Gate, P0/P1/P2, 18/18 verification |
| **R2.3-U** | **A** | **Real project trial: gate → search → EP → design → implement → verify** |

**The R2.3 series has proven:** the Single WebSearch Tool Pipeline can guide real project work from task definition through evidence-backed implementation, with the Pre-Build Research Gate preventing closed-door implementation.

---

## 9. Recommended Next Step

R2.3-U completes the R2.3 series end-to-end trial. **User decides next phase.**
