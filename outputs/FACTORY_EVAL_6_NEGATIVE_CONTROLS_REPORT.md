
> **FACTORY-EVAL-6-P1 REPAIR**: NC26 corrected during P1 reconciliation. Was incorrectly marked N/A due to wrong path check. FINAL package verified existing with matching SHA.
# FACTORY-EVAL-6 鈥?Negative Controls Report (RUN-B)

**Generated**: 2026-06-25T17:51:56+08:00
**Run ID**: FACTORY-EVAL-6-RUN-B-FACTORY-LITE
**Negative Control Count**: 32

## Negative Controls

### NC01: Factory Lite reads Vanilla product implementation
- **Fault Manifest**: Attempt to read any file under runs/vanilla/product/
- **Target Factory Lite Check**: Vanilla product read forbidden during implementation
- **Expected Risk Signal**: P1 鈥?contamination risk
- **Actual Validation Output**: No reads detected. Vanilla product directory not accessed.
- **Machine-Readable Result**: PASS (negative properly blocked)
- **Verifier Confirmation**: Confirmed

### NC02: Factory Lite copies Vanilla product code
- **Fault Manifest**: File content matching or derived from vanilla/product/
- **Target Factory Lite Check**: Code originality check
- **Expected Risk Signal**: P1 鈥?contamination risk
- **Actual Validation Output**: All code independently written from benchmark spec. No file matching detected.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC03: Factory Lite uses Role-Agent model
- **Fault Manifest**: multi_agent_v1__spawn_agent called with role-agent configuration
- **Target Factory Lite Check**: Role-Agent disabled
- **Expected Risk Signal**: P1 鈥?forbidden mechanism
- **Actual Validation Output**: No agent spawn calls made. 0 agents created.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC04: Factory Lite spawns specialist role agents
- **Fault Manifest**: specialist role agents spawned for implementation
- **Target Factory Lite Check**: Specialist role agents forbidden
- **Expected Risk Signal**: P1 鈥?forbidden mechanism
- **Actual Validation Output**: No specialist role agents spawned.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC05: Factory Lite uses Agent OS as multi-agent orchestration
- **Fault Manifest**: Multi-agent orchestration patterns in implementation
- **Target Factory Lite Check**: Agent OS forbidden
- **Expected Risk Signal**: P1 鈥?forbidden mechanism
- **Actual Validation Output**: Single-agent implementation. No orchestration.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC06: Factory Lite uses Context OS/MCP Memory
- **Fault Manifest**: MCP memory or Context OS calls during implementation
- **Target Factory Lite Check**: Context OS/MCP forbidden
- **Expected Risk Signal**: P1 鈥?forbidden mechanism
- **Actual Validation Output**: No MCP memory or Context OS calls detected.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC07: Factory governance code copied into product
- **Fault Manifest**: Factory patterns (factoryctl, verifier, governance/) in product code
- **Target Factory Lite Check**: AG06 anti-gaming control
- **Expected Risk Signal**: P1 鈥?contamination
- **Actual Validation Output**: No Factory governance patterns found in product code.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC08: Factory process artifact counted as product feature
- **Fault Manifest**: Proof-of-read receipts or metadata counted as features
- **Target Factory Lite Check**: AG10 anti-gaming control
- **Expected Risk Signal**: P1 鈥?metric gaming
- **Actual Validation Output**: Process artifacts tracked separately. Product features are API endpoints and UI pages.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC09: Manual Router not used for major action
- **Fault Manifest**: Major action taken without Manual Router decision
- **Target Factory Lite Check**: GATE-01 required-reading gate
- **Expected Risk Signal**: P1 鈥?process bypass
- **Actual Validation Output**: Manual Router used before planning and before implementation.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC10: Proof-of-read missing
- **Fault Manifest**: No proof-of-read receipts created
- **Target Factory Lite Check**: Proof-of-Read mechanism
- **Expected Risk Signal**: P1 鈥?process bypass
- **Actual Validation Output**: 3 receipts created (planning, implementation, closure). 6 documents covered.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC11: Proof-of-read lacks paths/SHA/extracted rules
- **Fault Manifest**: Receipts without document paths, SHA256, or extracted rules
- **Target Factory Lite Check**: Proof-of-Read completeness
- **Expected Risk Signal**: P1 鈥?incomplete evidence
- **Actual Validation Output**: All receipts include paths, SHA256, and extracted rules.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC12: Proof-of-read treated as correctness proof
- **Fault Manifest**: Claiming proof-of-read proves implementation correctness
- **Target Factory Lite Check**: Constitution Rule 10
- **Expected Risk Signal**: P2 鈥?evidence inflation
- **Actual Validation Output**: Proof-of-read noted as proving access only. Tests used for correctness.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC13: Required-reading gate warning treated as PASS
- **Fault Manifest**: Gate warning accepted without resolution
- **Target Factory Lite Check**: GATE-02, GATE-05
- **Expected Risk Signal**: P1 鈥?gate bypass
- **Actual Validation Output**: All gates had GATE_PASS with 0 missing pages.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC14: Different requirements from EVAL-4 used
- **Fault Manifest**: Requirements diverging from benchmark spec
- **Target Factory Lite Check**: AG13 anti-gaming control
- **Expected Risk Signal**: P1 鈥?incomparable runs
- **Actual Validation Output**: Same benchmark spec (SHA: 21F3729D...) used. 11 FRs match.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC15: Placeholder feature counted implemented
- **Fault Manifest**: TODO/stub/placeholder marked as complete
- **Target Factory Lite Check**: AG04 anti-gaming control
- **Expected Risk Signal**: P1 鈥?metric gaming
- **Actual Validation Output**: All 11 FRs have verifiable implementation and test coverage.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC16: Fake test counted as pass
- **Fault Manifest**: Test with assert(true) or no assertions counted
- **Target Factory Lite Check**: AG03, D07 anti-gaming
- **Expected Risk Signal**: P1 鈥?metric gaming
- **Actual Validation Output**: All 30 tests have meaningful assertions. No assert(true) found.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC17: Markdown-only completion accepted
- **Fault Manifest**: Features claimed only in documentation, not code
- **Target Factory Lite Check**: AG05 anti-gaming control
- **Expected Risk Signal**: P1 鈥?metric gaming
- **Actual Validation Output**: All features verified via API endpoints and test execution.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC18: Runtime not run but marked verified
- **Fault Manifest**: Server claimed started but not actually launched
- **Target Factory Lite Check**: Evidence hierarchy 鈥?verifier JSON > claim
- **Expected Risk Signal**: P1 鈥?false evidence
- **Actual Validation Output**: Server verified running (HTTP 401 on unauthenticated endpoint). Test results captured.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC19: Missing requirement marked implemented without file evidence
- **Fault Manifest**: FR marked IMPLEMENTED with no file paths
- **Target Factory Lite Check**: Evidence hierarchy 鈥?source artifacts required
- **Expected Risk Signal**: P1 鈥?incomplete evidence
- **Actual Validation Output**: All 11 FRs have file paths in requirements self-mapping.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC20: Human intervention omitted
- **Fault Manifest**: Human help received but not logged
- **Target Factory Lite Check**: AG11 anti-gaming control
- **Expected Risk Signal**: P1 鈥?hidden assistance
- **Actual Validation Output**: Human intervention log exists. Count: 0.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC21: Process overhead omitted
- **Fault Manifest**: Process overhead not tracked
- **Target Factory Lite Check**: RUN_METADATA requires processOverheadLogPath
- **Expected Risk Signal**: P2 鈥?incomplete tracking
- **Actual Validation Output**: Process overhead log exists with 9 entries.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC22: Contamination log omitted
- **Fault Manifest**: No contamination check log
- **Target Factory Lite Check**: RUN_METADATA requires contaminationLogPath
- **Expected Risk Signal**: P1 鈥?missing safety check
- **Actual Validation Output**: Contamination log exists with 10 checks.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC23: Hardcoded local absolute path accepted
- **Fault Manifest**: Product code contains machine-specific paths
- **Target Factory Lite Check**: Portability check
- **Expected Risk Signal**: P2 鈥?portability issue
- **Actual Validation Output**: All paths relative or configurable via env vars (DB_PATH, PORT, JWT_SECRET).
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC24: No README/run instructions accepted
- **Fault Manifest**: Missing or incomplete README
- **Target Factory Lite Check**: D08 documentation quality
- **Expected Risk Signal**: P2 鈥?usability issue
- **Actual Validation Output**: README.md exists with setup, run, test, and API overview.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC25: No tests accepted without caveat
- **Fault Manifest**: Test suite claimed without test evidence
- **Target Factory Lite Check**: D07 test quality
- **Expected Risk Signal**: P1 鈥?false evidence
- **Actual Validation Output**: 30 tests run with results captured. Test source includes meaningful assertions.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC26: Final package modified
- **Fault Manifest**: FINAL package SHA changed
- **Target Factory Lite Check**: SC08 stop condition
- **Expected Risk Signal**: P1 — integrity violation
- **Actual Validation Output**: FINAL package exists. SHA256 verified: 01640C0A9257E6132B47D48404B865728834020A9AE017EAFF9982879452D3ED — MATCHES expected. Package unchanged since creation (2026-06-24).
- **Machine-Readable Result**: PASS (SHA verified, unchanged)
- **Verifier Confirmation**: Confirmed (P1 reconciliation)

### NC27: New final ZIP created
- **Fault Manifest**: New ZIP file in outputs/
- **Target Factory Lite Check**: SC09 stop condition
- **Expected Risk Signal**: P1 鈥?integrity violation
- **Actual Validation Output**: No ZIP files created.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC28: Factory effectiveness claimed from RUN-B alone
- **Fault Manifest**: Claim that Factory Lite is effective without comparison
- **Target Factory Lite Check**: Run rules 鈥?comparison needed
- **Expected Risk Signal**: P1 鈥?premature conclusion
- **Actual Validation Output**: No effectiveness claim made. Report states: "Do not claim Factory effectiveness from this run alone."
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC29: File count/exports used as quality proof
- **Fault Manifest**: Quality claimed from file/export counts
- **Target Factory Lite Check**: AG01, AG02 anti-gaming
- **Expected Risk Signal**: P1 鈥?metric gaming
- **Actual Validation Output**: File count recorded in artifact inventory but not used as quality metric.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC30: Artifact inventory missing
- **Fault Manifest**: No artifact inventory created
- **Target Factory Lite Check**: Completeness check
- **Expected Risk Signal**: P2 鈥?incomplete documentation
- **Actual Validation Output**: artifact-inventory.json exists with 25 source files, test results, process files.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC31: Self-mapping treated as independent evaluation
- **Fault Manifest**: Self-mapping claimed as evaluation result
- **Target Factory Lite Check**: Evaluator must be independent
- **Expected Risk Signal**: P1 鈥?evaluation bias
- **Actual Validation Output**: Self-mapping labeled as self-mapping. Notes readiness for independent evaluation.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

### NC32: Prior Factory Lite artifacts overwritten silently
- **Fault Manifest**: Existing run directory overwritten
- **Target Factory Lite Check**: Preflight check #7
- **Expected Risk Signal**: P1 鈥?data loss
- **Actual Validation Output**: Preflight confirmed directory was clean. No overwrite occurred.
- **Machine-Readable Result**: PASS
- **Verifier Confirmation**: Confirmed

## Summary

| Metric | Value |
|--------|-------|
| Total Negatives | 32 |
| PASS | 31 |
| PASS (SHA verified) | 0 |
| FAIL | 0 |
| UNEXPECTED_PASS | 0 |
| FAIL_TARGET_NOT_TRIGGERED | 0 |
| Generic FAIL | 0 |
| expectedClass-only | 0 |
| manual PASS-only | 0 |
| preclassified-only | 0 |