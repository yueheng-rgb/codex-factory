# FACTORY-AGENT-9 / Independent Large Project Comparison Report

**Date:** 2026-06-26T18:31:36.2497217+08:00  
**Evaluator:** READONLY Independent  
**Runs Compared:** RUN-LP-A (Vanilla), RUN-LP-B (v0.4 Factory Lite), RUN-LP-C (v0.5 Agent Company)  

---

## 1. PRODUCT METRICS COMPARISON

| Metric | Vanilla (A) | v0.4 Lite (B) | v0.5 Agent Co (C) |
|--------|-------------|---------------|---------------------|
| TS/TSX files | 78 | 78 | 71 |
| Exports | 168 | 128 | 185 |
| API endpoints | 40 | 31 | 35 |
| DB tables | 15 | 15 | 15 |
| Services | 5 | 3 | 5 |
| Test files | 27 | 27 | 22 |
| Tests passed | 66/66 (100%) | 76/76 (100%) | 207/207 (100%) |
| Verifier | 38/38 PASS | 35/35 PASS | 25/25 PASS |
| Agents spawned | 0 | 0 | 7 |
| Process overhead | 1x (baseline) | ~1.1x (v0.4 overhead) | ~3-4x (agent orchestration) |

## 2. COMPLEXITY FLOOR COMPARISON

| Floor | Target | Vanilla | v0.4 | v0.5 |
|-------|--------|---------|------|------|
| Source files | 80 | 78 (MISS) | 78 (MISS) | 71 (MISS) |
| Exports | 300 | 168 (MISS) | 128 (MISS) | 185 (MISS) |
| Endpoints | 40 | 40 (PASS) | 31 (MISS) | 35 (MISS) |
| DB tables | 15 | 15 (PASS) | 15 (PASS) | 15 (PASS) |
| Test files | 20 | 27 (PASS) | 27 (PASS) | 22 (PASS) |

**Finding:** No run meets all AGENT-5 complexity floors. Vanilla closest (misses source files + exports). v0.5 has lowest source files and misses export/endpoint floors.

## 3. RUBRIC SCORING (Weighted, 0-100 scale)

### 3.1 Feature Completeness (weight: 25)

| Module | Vanilla | v0.4 | v0.5 |
|--------|---------|------|------|
| Auth | Full | Full | Full |
| Workspace | Full | Full | Full |
| Request (CRUD) | Full | Full | Full |
| Workflow | Full | Full | Full |
| Notification | Full | Route only (no service) | Full (service + route) |
| Audit | Full | Full | Full |
| SLA | Full | Full | Full |
| Report | Route only | Route only | Route only |
| User admin | Minimal | Minimal | Auth-only |
| Search | Workspace filter | Workspace filter | Workspace filter |
| Dashboard | Full | Full | Full |
| Export | Full | None | Full |
| Settings | Full | Full | Full |

**Score:** Vanilla 22/25 | v0.4 17/25 | v0.5 21/25

### 3.2 Architecture Integrity (weight: 20)

| Criterion | Vanilla | v0.4 | v0.5 |
|-----------|---------|------|------|
| Module separation | Clean | Clean | Clean |
| Shared types centralized | Yes (types/index.ts) | Yes (types.ts flat) | Yes (types.ts flat) |
| Cross-module contracts | Consistent | Consistent | Consistent |
| Circular deps | None detected | None detected | None detected |
| .js extension imports | 1 file | 14 files (!) | 0 |
| Code style consistency | Consistent | Compressed/minified | Consistent |

**Score:** Vanilla 18/20 | v0.4 14/20 | v0.5 18/20

### 3.3 Defect Count (weight: 20)

| Criterion | Vanilla | v0.4 | v0.5 |
|-----------|---------|------|------|
| Test pass rate | 66/66 (100%) | 76/76 (100%) | 207/207 (100%) |
| Test quality | DB-per-file tests | Module-numbered tests | Behavior-focused tests |
| ESM/CJS issues | None | .js imports (14 files) | Fixed 2 issues (BOM, __dirname, require.main) |
| Missing features | 0 P0 | Export + Notifications services missing | 4 endpoints, 2 modules partial |

**Score:** Vanilla 18/20 | v0.4 14/20 | v0.5 16/20

### 3.4 Code Quality (weight: 15)

| Criterion | Vanilla | v0.4 | v0.5 |
|-----------|---------|------|------|
| Error handling | Structured try/catch | Structured try/catch | Structured try/catch |
| Validation | Zod schemas | Zod schemas | Zod schemas |
| UI state handling | 4-state (loading/empty/error/success) | 4-state | 4-state |
| Code readability | Good | Compressed/minified (poor) | Good |
| Config structure | Standard | Standard | Standard |

**Score:** Vanilla 13/15 | v0.4 9/15 | v0.5 13/15

### 3.5 Process Overhead (weight: 10)

| Criterion | Vanilla | v0.4 | v0.5 |
|-----------|---------|------|------|
| Spawned agents | 0 | 0 | 7 (4 builders + 3 gatekeepers) |
| Agent orchestration time | 0 | 0 | Significant |
| Human intervention | Minimal | Minimal | Minimal |
| Context resets | 1 | 1-2 | 3+ (multi-agent spawns) |
| Close receipts/handoffs | 0 | 3 PoR receipts | 4 handoffs + 4 close receipts |
| Gatekeeper overhead | 0 | 0 | 3 gatekeeper agents |

**Score (lower overhead = higher):** Vanilla 10/10 | v0.4 8/10 | v0.5 4/10

### 3.6 Evidence Quality (weight: 10)

| Criterion | Vanilla | v0.4 | v0.5 |
|-----------|---------|------|------|
| Verifier result | 38/38 PASS | 35/35 PASS | 25/25 PASS |
| SHA256 manifests | No | No | No |
| Transcripts | Run log | Run log + PoR | Registry + lifecycle + gates |
| Anti-deception | N/A | N/A | PASS (3 caveats) |
| Phase closure gate | N/A | N/A | PASS |
| Contamination check | CLEAN | CLEAN | CLEAN |
| Agent registry | N/A | N/A | Complete (7 agents) |

**Score:** Vanilla 6/10 | v0.4 7/10 | v0.5 9/10

### 3.7 Weighted Totals

| Dimension | Weight | Vanilla | v0.4 | v0.5 |
|-----------|--------|---------|------|------|
| Feature Completeness | 25% | 22 | 17 | 21 |
| Architecture Integrity | 20% | 18 | 14 | 18 |
| Defect Count | 20% | 18 | 14 | 16 |
| Code Quality | 15% | 13 | 9 | 13 |
| Process Overhead | 10% | 10 | 8 | 4 |
| Evidence Quality | 10% | 6 | 7 | 9 |
| **WEIGHTED TOTAL** | **100%** | **17.1** | **13.2** | **16.0** |

**Normalized (0-100):** Vanilla 85.5 | v0.4 66.0 | v0.5 80.0

## 4. MULTI-AGENT SUCCESS THRESHOLD CHECK

Per AGENT-5 success-failure-thresholds:

| Condition | Status | Evidence |
|-----------|--------|----------|
| v0.5 product score > v0.4 product score | **TRUE** (80 > 66) | Rubric scoring above |
| v0.5 product score > Vanilla product score | **FALSE** (80 < 85.5) | Vanilla wins on product quality |
| Hidden fallback count = 0 | **TRUE** | Integrity checker PASS |
| Anti-deception gate = PASS | **TRUE** | PASS_WITH_CAVEAT |
| Phase closure gate = PASS | **TRUE** | All agents closed with receipts |
| All agents closed with receipts | **TRUE** | 7/7 agents completed |
| Process overhead < 2x Vanilla time | **NOT CONFIRMED** | Agent orchestration adds significant overhead |

**CRITICAL:** v0.5 score (80.0) < Vanilla score (85.5). Threshold #2 FAILS.
**"v0.5 product score > Vanilla product score" = FALSE**

Per AGENT-5 falsification threshold: if any single success condition is false, multi-agent is NOT proven.

## 5. STOP CONDITION CHECK

| Stop Condition | Triggered? |
|----------------|------------|
| S04: One run contaminates another | No (all CLEAN) |
| S09: Product cannot run | No (all verified running) |
| S10: Evaluator lacks evidence | No (sufficient evidence) |
| S11: Old packages modified | No |
| S12: New release ZIP created | No |

## 6. CONCLUSION

**Verdict: MULTI_AGENT_NO_BENEFIT (for this benchmark)**

v0.5 Agent Company Mode (80.0) scores below Vanilla Codex (85.5) on product quality after controlling for process overhead and evidence quality.

### What v0.5 does better:
- Architecture integrity (18 vs 14 for v0.4)
- Code quality (13, matching Vanilla)
- Evidence quality (9, highest of all 3)
- Defect count (16, better than v0.4's 14)

### What v0.5 does worse:
- Product features (21 vs Vanilla's 22): fewer endpoints, partial search/user
- Process overhead (4 vs Vanilla's 10): 7-agent orchestration is costly
- Complexity floors: misses export (185 vs 300) and endpoint (35 vs 40) floors

### What Vanilla wins on:
- Highest feature completeness (22/25)
- Highest architecture integrity (18/20)
- Best defect count (18/20)
- Zero process overhead (10/10)
- Meets 2/5 complexity floors (endpoints + DB + tests)

### Caveats:
- This is ONE benchmark. Multi-agent could win on different benchmarks
- v0.5's 207 tests vs Vanilla's 66 tests suggests better test coverage (but different test methodology)
- v0.5 has superior evidence quality and anti-deception gates - valuable for audit
- Process overhead is inherent to multi-agent orchestration; this must be justified by quality gains

## 7. RECOMMENDATION

**FACTORY-AGENT-9: PASS (comparison completed)**

Multi-agent not proven beneficial for OpsFlow Enterprise Lite. Vanilla Codex produced the highest-quality product with least overhead. v0.4 Factory Lite scored lowest due to missing services, compressed code style, and fewer endpoints.

**Recommended next phase:** FACTORY-AGENT-10 (or equivalent) to determine whether:
1. Different benchmark types favor multi-agent
2. Agent Company runtime should be reserved for larger-scale projects
3. v0.5 overhead can be reduced through optimization