# FACTORY-DIAGNOSTIC-SMOKE-0 — SkillMarket Diagnostic Trial Summary

**Phase**: FACTORY-DIAGNOSTIC-SMOKE-0  
**Date**: 2026-06-26  
**Verdict**: PASS (Diagnostic Trial Complete)  
**Project**: SkillMarket — 数字服务交易平台 (大学期末作业)

---

## What Was Inspected

- **217 files** across 4 apps (server, client-v2, admin, merchant)
- **3 frontend apps**: Vue 3 + Vite (customer, admin, merchant)
- **2 backend implementations**: Root-level (running) vs server/src/ (MVC, unused)
- **10 database tables**: Well-designed schema with FK constraints, indexes, seed data
- **1 course report**: docx with project claims
- **0 automated tests**

---

## Top Findings (14 total)

### CRITICAL (2)

| ID | Finding |
|----|---------|
| F01 | **Two competing server implementations** — Root-level `index.js` (5 routes) vs `server/src/index.js` (14 routes MVC). Only one can run on port 3000. |
| F02 | **API-client/server route mismatch** — Frontend calls `/api/auth`, `/api/reviews`, `/api/favorites`, `/api/messages`. NONE exist on the running server. These features are broken. |

### HIGH (3)

| ID | Finding |
|----|---------|
| F03 | **package.json start script wrong** — `"start": "node src/index.js"` but actual index.js is at root |
| F04 | **JWT_SECRET mismatch** — `.env` has different value than hardcoded in `middleware/auth.js` |
| F05 | **Zero automated tests** — No test framework, no test files, no test script in any package.json |

### MEDIUM (5) + LOW (4)

Documentation gaps, credential exposure, missing merchant middleware, no resource ownership checks, writer scripts in runtime, no single startup command.

---

## Diagnostic Pack Verdicts

| Category | Verdict |
|----------|---------|
| Report/Source Consistency | **50% DISCREPANCY** (12 of 24 claims have issues) |
| Test Quality | **MISSING** (zero automated tests) |
| Security/RBAC | **BASIC_WITH_GAPS** (JWT+bcrypt correct, credential exposure) |
| Architecture Clarity | **CONFUSING** (two servers, unclear entry point) |
| DB/API/UI Alignment | **MISMATCH** (~50% of intended API surface on running server) |
| Overall Diagnostic | **MAJOR_GAPS_ESCALATE** (17 gaps found) |

---

## Diagnostic Pack Value Assessment

**Was the Diagnostic Pack helpful? YES.**

The pack systematically exposed issues that casual inspection would miss:
- Two competing server implementations (obvious once pointed out, easy to miss in quick review)
- API-client mismatch that means favorites/reviews/auth features are non-functional
- Security features (rate limiting, audit, SQL injection guard) exist but only in the UNUSED server
- Writer/generator scripts mixed with runtime code

**Overhead**: ~45 minutes for thorough 217-file inspection. Acceptable.

---

## Recommended Next Action

**REPAIR_PROJECT** — Fix F01 and F02 (critical) before grading submission:
1. Consolidate to ONE server implementation
2. Add missing routes (auth, favorites, reviews)
3. Fix package.json start script
4. Unify JWT_SECRET
5. Add at minimum auth flow tests

Then run a second diagnostic to verify fixes.

---

## Strategy Boundary Preserved

| Constraint | Status |
|------------|--------|
| Product code not modified | ✅ |
| No repairs performed | ✅ |
| No new ZIP created | ✅ |
| No v0.5 package | ✅ |
| Multi-agent not used | ✅ |
| No spawn_agent | ✅ |
| No product superiority claim | ✅ |
| Readonly boundary preserved | ✅ |
