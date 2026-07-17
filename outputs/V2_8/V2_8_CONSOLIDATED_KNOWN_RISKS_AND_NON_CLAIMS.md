# V2.8 — Consolidated Known Risks & Non-Claims

**Date**: 2026-07-17
**Scope**: Codex Factory v1.0 through v2.7

---

## Production / Deployment Risks

| # | Risk | Status |
|---|------|--------|
| R1 | No real production deployment exists | GAP — Factory has never been deployed to production |
| R2 | No real WeChat / platform review | GAP — miniapp pack assumes review, not conducted |
| R3 | No real payment gateway integration | GAP — payments are mocked in all testbeds |
| R4 | In-memory / mock stores remain in some testbeds | GAP — CPM-001, CPM-004, miniapp validation use Map stores |
| R5 | No migration / rollback scripts | GAP — documented in V2.7 readiness checker |
| R6 | No structured logging in testbeds | GAP — Fastify logger=false pattern |

## Review / Approval Risks

| # | Risk | Status |
|---|------|--------|
| R7 | Human review receipts are self_declared_automated | LIMITATION — 8 receipts use self_declared_automated, not real human sign-off |
| R8 | READY_FOR_PRODUCTION_REVIEW ≠ production-ready | LIMITATION — documented in all V2.7 outputs |
| R9 | No external security audit / penetration test | GAP — semgrep is static analysis only |

## Tool / Engine Risks

| # | Risk | Status |
|---|------|--------|
| R10 | C++ sanitizer (ASan/UBSan/TSan) unavailable | TOOL_UNAVAILABLE — winget install LLVM.LLVM documented |
| R11 | CodeQL not installed | TOOL_UNAVAILABLE |
| R12 | k6 not installed | TOOL_UNAVAILABLE |
| R13 | Firecrawl reader only, not canonical search | BY DESIGN — deprecated lock active |
| R14 | Local smoke not production capacity | LIMITATION — all load tests are local smoke only |

## Capability Limitations

| # | Limitation |
|---|-----------|
| L1 | Multi-agent validated by 2 smoke missions, not unlimited autonomous project guarantee |
| L2 | semgrep clean ≠ absolute security — static analysis is one layer |
| L3 | C++ memory safety is concept-level only on this host |
| L4 | Playwright smoke is canvas-existence check, not full interaction testing |
| L5 | Cross-pack missions are design-level matrix + 2 runnable smoke tests |
| L6 | Regression 235/235 covers testbeds, not full end-to-end project builds |

---

## Non-Claims (Cumulative)

1. **Codex Factory is NOT a production-deployed system.** It is a governance, validation, and pipeline framework.

2. **No real WeChat / Alipay / platform review has been conducted.** Miniapp pack assumes but does not replace platform review.

3. **No real payment gateway is integrated.** All payment callbacks are mock implementations.

4. **Human review receipts are self_declared_automated.** They have NOT been reviewed by external human engineering leads.

5. **READY_FOR_PRODUCTION_REVIEW is NOT READY_FOR_PRODUCTION.** This is the highest classification achievable given documented gaps.

6. **Local load smoke does NOT prove production capacity.** No claims about concurrent users, throughput, or SLA are made.

7. **semgrep clean does NOT guarantee security.** It is one static analysis layer among many needed.

8. **C++ sanitizer results are NOT available.** The testbed validates invariants at concept level only.

9. **Firecrawl is NOT canonical search.** It is a reader/extractor candidate only.

10. **The Factory does NOT replace senior engineer judgment.** It provides evidence, gates, and governance — human leads own final decisions.

11. **No compliance audit (GDPR, PCI-DSS, SOC2) has been performed.**

12. **No third-party dependency audit (npm audit, supply chain) has been performed.**

---

## Deprecated Directions (Preserved)

| # | Direction | Lock Status |
|---|-----------|------------|
| 1 | Independent Search Agent | ACTIVE — never restored |
| 2 | Dual Search Channel | ACTIVE — never restored |
| 3 | Search Agent as Future Default | ACTIVE — never restored |
| 4 | Implementer direct search | ACTIVE — never restored |
| 5 | chat URL extraction as canonical evidence | ACTIVE — never restored |
| 6 | mock/dry_run mislabeled as live | ACTIVE — never restored |
| 7 | Firecrawl as canonical search replacement | ACTIVE — RGS-003 BLOCKED |
| 8 | Compression summary as trusted memory | ACTIVE — resume gate validates |
| 9 | Fake sanitizer PASS | ACTIVE — honest TOOL_UNAVAILABLE |
| 10 | Fake human review approval | ACTIVE — self_declared_automated documented |
| 11 | Local smoke as production capacity | ACTIVE — non-claim documented |
| 12 | Missing artifact counted as PASS | ACTIVE — artifact binding enforced |
| 13 | Expert Pack bypassing Risk Gate | ACTIVE — gate integration maintained |
| 14 | External tools bypassing Evidence Binding | ACTIVE — evidence binder enforced |
| 15 | multi-agent as default mode | ACTIVE — not default |
