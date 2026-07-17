# Codex Factory v1.0 — Known Risks and Non-Claims

**Generated:** 2026-07-11
**Applies to:** Codex Factory v1.0 and all v1.x unless explicitly updated

---

## Non-Claims

The following capabilities are explicitly NOT claimed by Codex Factory v1.0:

### Performance & Scale
1. **NOT claimed: support for production-level million-concurrency**
   - autocannon is used for local smoke testing only (typically 10-30 second runs, single endpoint)
   - Results are NOT capacity proofs or production performance guarantees
   - Any load numbers in reports are local dev-machine measurements, not production benchmarks

### Security
2. **NOT claimed: absolute security from Semgrep CLEAN**
   - Semgrep CLEAN means no static analysis rule matches, NOT "bug-free" or "secure"
   - False negatives exist in all static analysis tools
   - Security review still requires human audit for CRITICAL and L_CLASS projects

### Browser Testing
3. **NOT claimed: Playwright as fully integrated E2E framework**
   - Playwright 1.61.1 is available but requires per-project devDependency setup
   - Not all starters have Playwright configured
   - UI smoke tests are minimal (page open, canvas existence, no fatal console errors)

### External Tools
4. **NOT claimed: CodeQL / k6 / Firecrawl as live v1.0 core**
   - CodeQL: NOT_INSTALLED — deferred to v1.2 External Engine Expansion
   - k6: NOT_INSTALLED — deferred to v1.2 External Engine Expansion
   - Firecrawl: NOT live — Reader/Extractor candidate only; must not replace canonical search

### Expert Packs
5. **NOT claimed: comprehensive domain coverage**
   - Only 2 expert packs exist: ecommerce and saas-tool
   - No miniapp, admin-system, game/threejs, or C/C++ memory safety packs
   - Ecommerce pack is testbed validation, NOT production ecommerce platform

### Production Readiness
6. **NOT claimed: production database migration for all projects**
   - Migration path is foundation examples only (saas-runtime-validation has Postgres schema)
   - Most testbeds use in-memory stores
   - Production migration requires per-project engineering

7. **NOT claimed: READY_FOR_PRODUCTION for any testbed or pilot**
   - Readiness checker maximum level is READY_FOR_PRODUCTION_REVIEW
   - No project has achieved READY_FOR_PRODUCTION
   - READY_FOR_STAGING (84/100 on SaaS testbed) is the highest measured level
   - READY_FOR_STAGING != READY_FOR_PRODUCTION

### Benchmark Authority
8. **NOT claimed: Benchmark Suite v3 as external authority**
   - Benchmarks are internal Factory capability measurements
   - Not equivalent to external security audit, performance test, or compliance certification
   - Design-only benchmarks (BV3-09) verify planning, not runtime behavior

### Engineering Responsibility
9. **NOT claimed: Codex Factory replaces senior engineering judgment**
   - Factory automates workflow governance, NOT architectural decisions
   - Complex projects still require human audit
   - L_CLASS projects MUST have human review
   - CRITICAL risk projects MUST have reviewer + invariants + explicit test coverage

---

## Known Risks

### R1: Testbed In-Memory Stores
- **Risk:** Testbeds use in-memory data stores; not representative of production database behavior
- **Impact:** Production-specific issues (connection pooling, migration conflicts, replication) not tested
- **Mitigation:** Production readiness checker flags this; saas-runtime-validation has Postgres schema example
- **Severity:** MEDIUM

### R2: Playwright Browser Version Drift
- **Risk:** npm playwright version may drift from browser binaries
- **Impact:** Playwright smoke tests may break on npm updates
- **Mitigation:** Chromium pinned; re-check on playwright version changes
- **Severity:** LOW

### R3: autocannon Local-Only
- **Risk:** autocannon runs on local dev machine; network/CPU variance not controlled
- **Impact:** Load numbers not reproducible across machines
- **Mitigation:** Documented as local smoke only; not claimed as capacity proof
- **Severity:** LOW

### R4: Risk Classifier Keyword-Based
- **Risk:** Classification uses keyword matching; may misclassify edge cases
- **Impact:** Rare false positives/negatives on unusual task descriptions
- **Mitigation:** Risk enforcement gate v3 allows human override with reason; CRITICAL/L_CLASS gates provide safety net
- **Severity:** LOW

### R5: Expert Pack Coverage Gaps
- **Risk:** Only ecommerce and saas-tool packs exist; other domains uncovered
- **Impact:** Projects in uncovered domains get generic (non-expert) treatment
- **Mitigation:** Expert pack system designed for extensibility; v1.1 roadmap includes expansion
- **Severity:** MEDIUM

### R6: CodeQL/k6 Not Installed
- **Risk:** Security (CodeQL) and performance (k6) engines not available
- **Impact:** Deeper security/performance analysis not automated
- **Mitigation:** Semgrep provides static analysis baseline; autocannon provides load smoke baseline; both engines on v1.2 roadmap
- **Severity:** MEDIUM

### R7: Starter Ecosystem Immaturity
- **Risk:** 6 starters exist but not all have comprehensive test coverage
- **Impact:** Some project types have less validation than others
- **Mitigation:** Core starters (node-api-postgres, vite-threejs-interactive) have typecheck+build+tests; others on expansion roadmap
- **Severity:** LOW

### R8: Single-Machine Validation
- **Risk:** All testing done on single Windows dev machine
- **Impact:** Cross-platform, Docker, and CI/CD behavior not validated
- **Mitigation:** CI/CD template provided; Docker on v1.3 roadmap
- **Severity:** MEDIUM

---

## Boundary Statement

Codex Factory v1.0 is a **software engineering governance platform foundation**.
It is not a production deployment system, a security audit authority, a
performance testing lab, or a replacement for human engineering judgment.

Any claim beyond these boundaries is a misuse of this release.
