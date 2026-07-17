# R5.0 — Known Risks & Non-Claims
# Codex Factory Foundation RC v1.0.0
# Generated: 2026-07-11

## EXPLICIT NON-CLAIMS

The Codex Factory Foundation RC makes no claims about the following:

### 1. Production Concurrency
- **NON-CLAIM**: Codex Factory is NOT certified for production-scale concurrency.
- Load smoke tests (autocannon: 338K requests on localhost) are LOCAL ONLY.
- These tests prove the broker pipeline works, NOT production capacity.
- Do NOT cite autocannon results as "supports X concurrent users."

### 2. Absolute Security
- **NON-CLAIM**: Semgrep CLEAN does NOT mean "zero vulnerabilities."
- Semgrep runs a limited ruleset (~227 rules) and cannot detect all vulnerability classes.
- The 3 XSS WARNING findings on products-api are triaged as false positives in testbed context — this is acceptable for a testbed, NOT for production.
- CodeQL is not live and would provide deeper static analysis.
- No penetration testing has been performed.

### 3. Playwright Reliability
- **NON-CLAIM**: Playwright is TOOL_FAILED (browser version mismatch).
- npm playwright@1.61.1 expects chromium_headless_shell-1200.
- Installed browser is chromium-1228.
- UI testing capability is NOT verified.
- All benchmarks requiring UI checks (B3, B5, B6, B8) use build/typecheck as verification, which is accepted for Foundation RC but NOT equivalent to UI testing.

### 4. CodeQL / k6 / Firecrawl
- **NON-CLAIM**: These engines are NOT live.
- CodeQL: Requires ~500MB+ download, not installed.
- k6: Not installed.
- Firecrawl: Requires external API key, not integrated.
- All were correctly SKIPPED_WITH_REASON. No fake PASS.

### 5. Expert Packs / Domain Packs
- **NON-CLAIM**: No domain-specific expertise has been built.
- No ecommerce rules, SaaS rules, miniapp rules, game rules.
- Business invariants are generic (price, inventory, status), not domain-specific.
- Expert Packs are deferred to R5.x or later.

### 6. Production Database
- **NON-CLAIM**: All testbeds and pilots use in-memory stores.
- No Postgres/MySQL/MongoDB integration verified.
- No migration scripts exist.
- No connection pooling, replication, or backup systems are configured.

### 7. Complete Admin UI
- **NON-CLAIM**: The pilot admin surface is MINIMAL (vanilla HTML/JS).
- Not production-grade UI.
- No authentication, no role-based access control in UI.
- Starter next-fullstack-admin exists but has no test suite.

### 8. Surface Detection Completeness
- **NON-CLAIM**: Surface detection may miss implicit surfaces.
- Accuracy is 67-100% depending on description clarity.
- "gallery + save" may not detect "database" surface.
- Detection uses keyword matching, not semantic understanding.

### 9. Risk Classifier Completeness
- **NON-CLAIM**: Risk classifier accuracy is 75%, not 100%.
- Compound admin+api descriptions may trigger L_CLASS instead of CRITICAL.
- Threejs+save may be downgraded to LOW instead of HIGH.
- Classification is keyword-based, not context-aware at semantic level.

### 10. Multi-Agent Readiness
- **NON-CLAIM**: Multi-agent mode is NOT the default.
- Infrastructure exists (capsules, contracts, handoff, schemas).
- No end-to-end multi-agent project has been executed in live mode.
- MULTI_AGENT_DEFAULT_REJECTED flag is set.

---

## KNOWN RISKS (RANKED)

### RISK-001: Risk Classifier Accuracy (75%)
- **Impact**: 2/8 benchmarks misclassified, may cause wrong gate decisions.
- **Mitigation**: R4.1 improved from 50% to 75%. Remaining gaps are documented.
- **Classification**: MEDIUM risk to overall Factory reliability.

### RISK-002: Playwright Browser Mismatch
- **Impact**: No UI testing capability. All UI benchmarks use build/typecheck only.
- **Mitigation**: Correctly reported as TOOL_FAILED. Fix requires `npx playwright install chromium` (not working on current environment).
- **Classification**: LOW risk to Foundation RC (UI testing is deferred).

### RISK-003: Keyword-Based Classification
- **Impact**: Risk and surface detection may misinterpret task descriptions.
- **Mitigation**: R4.1 added explicit/implicit surface detection and context-aware rules. Semantic understanding is future work.
- **Classification**: MEDIUM risk for complex project descriptions.

### RISK-004: In-Memory Stores
- **Impact**: All testbeds lose data on restart. Not representative of production.
- **Mitigation**: Acceptable for Foundation RC. Production DB integration is deferred.
- **Classification**: LOW risk to Foundation RC (testbed/pilot scope only).

### RISK-005: Starter Test Gaps
- **Impact**: 3/5 starters have no test suites (rely on typecheck/build).
- **Mitigation**: Gate policy calibrated to accept build/typecheck for content/threejs starters. API starters have full tests.
- **Classification**: LOW risk.

### RISK-006: Limited Engine Coverage
- **Impact**: Only semgrep and autocannon produce real results. 3 engines unavailable.
- **Mitigation**: All unavailable engines correctly SKIPPED_WITH_REASON. Broker infrastructure is ready for activation.
- **Classification**: LOW risk (broker architecture proven, activation is operational).

### RISK-007: No Production Hardening
- **Impact**: No CI/CD, no deployment configs, no monitoring, no alerting.
- **Mitigation**: Deferred to R6.0 Production Hardening phase.
- **Classification**: OUT OF SCOPE for Foundation RC.

### RISK-008: Admin UI Minimal
- **Impact**: Pilot admin is vanilla HTML. Next-fullstack-admin has no test suite.
- **Mitigation**: Admin surface modeled, starter exists. Production admin UI is deferred.
- **Classification**: LOW risk.

---

## VERIFIED SAFETY ASSERTIONS

The following assertions have been VERIFIED during R5.0 readiness checks:

- [VERIFIED] No API key in any committed file (secret-presence-check)
- [VERIFIED] No Independent Search Agent restored
- [VERIFIED] No Dual Search Channel configured
- [VERIFIED] Implementer cannot directly search
- [VERIFIED] Chat URL extraction is not canonical evidence
- [VERIFIED] No mock/dry_run mislabeled as live
- [VERIFIED] All 22 pilot tests pass
- [VERIFIED] All 23 products-api tests pass
- [VERIFIED] Starter consistency: 6/6 PASS
- [VERIFIED] Engine broker correctly reports TOOL_FAILED for playwright
- [VERIFIED] Engine broker correctly SKIPS codeql/k6/firecrawl
- [VERIFIED] Load smoke is labeled as local only, not production capacity

---

*Known Risks & Non-Claims — frozen 2026-07-11*
