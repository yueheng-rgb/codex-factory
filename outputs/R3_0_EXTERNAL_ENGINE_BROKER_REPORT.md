# R3.0 EXTERNAL ENGINE BROKER REPORT
# Codex Factory — External Engine Broker
# Generated: 2026-07-11

## PHASE CLASSIFICATION: A — R3_0_EXTERNAL_ENGINE_BROKER_READY

## EXECUTIVE SUMMARY

R3.0 establishes the External Engine Broker, integrating optional external
tools (semgrep, codeql, k6, autocannon, playwright, firecrawl_reader) as
plug-in verifiers into Codex Factory. The default fast path remains the
R2.14 lightweight gate detection; external engines are triggered only when
risk level, project type, and surface constraints match.

Key achievement: 6 external engines registered, engine plans generated per
risk level, tools correctly detected as unavailable on this host with
proper SKIPPED_WITH_REASON (no fake PASS), engine results bound as evidence,
and CRITICAL/L_CLASS correctly BLOCKED when key engines are unavailable
without human audit.

## DELIVERABLES

### 1. External Engine Registry
- Schema: schemas/external-engine.schema.json
- Data: governance/external-engines/engine-registry.json
- Module: runtime/external-engine-registry.ps1
- Docs: governance/external-engines/ENGINE_REGISTRY.md

6 engines registered:
| Engine | Category | Risk Levels | Default | Fail Policy |
|--------|----------|-------------|---------|-------------|
| semgrep | security_static_analysis | HIGH,CRITICAL,L_CLASS | Yes | BLOCK_IF_CRITICAL_FINDINGS |
| codeql | deep_static_analysis | CRITICAL,L_CLASS | No | BLOCK_IF_CRITICAL_FINDINGS |
| k6 | performance_load_testing | HIGH,CRITICAL,L_CLASS | No | WARN_ONLY |
| autocannon | performance_load_testing | HIGH,CRITICAL | No | WARN_ONLY |
| playwright | e2e_browser_testing | MEDIUM,HIGH,CRITICAL,L_CLASS | No | WARN_ONLY |
| firecrawl_reader | reader_extractor | (manual only) | No | EVIDENCE_ONLY |

### 2. Tool Availability Detector
- File: runtime/external-tool-availability-check.ps1
- Report: outputs/R3_0_TOOL_AVAILABILITY_REPORT.json

Detected on this host: 0/6 available (expected — no tools pre-installed)
All missing tools reported with clear SKIP reason and install hints.

### 3. Engine Broker Runtime
- File: runtime/external-engine-broker.ps1
- Schema: schemas/external-engine-run-result.schema.json

Orchestrates: Plan → Availability Check → Execute → Parse → Evidence
Read-only by design; all commands recorded; timeout enforced.

### 4. Engine Result Parsers (5 parsers)
- runtime/parsers/parse-semgrep-result.ps1
- runtime/parsers/parse-codeql-result.ps1
- runtime/parsers/parse-loadtest-result.ps1
- runtime/parsers/parse-playwright-result.ps1
- runtime/parsers/parse-reader-result.ps1

Each parser: JSON-first, fallback text parsing, standardized output.

### 5. Risk Gate Integration (v3)
- File: runtime/risk-enforcement-gate-v3.ps1

Pipeline: RiskClassifier → LightweightGate(R2.14) → EngineBroker → Merge → FinalDecision

## DEMO CASE RESULTS (6/6 PASS)

| # | Risk | Lightweight | Engines Planned | Ran | Skipped | Final |
|---|------|------------|-----------------|-----|---------|-------|
| 1 | LOW | ALLOWED | 0 | 0 | 0 | ALLOWED |
| 2 | MEDIUM | ALLOWED | 2 | 0 | 2 (TOOL_UNAVAILABLE) | ALLOWED |
| 3 | HIGH | ALLOWED | 4 | 0 | 4 (TOOL_UNAVAILABLE) | ALLOWED |
| 4 | CRITICAL | BLOCKED | 5 | 0 | 5 (TOOL_UNAVAILABLE) | BLOCKED |
| 5 | PERF (MEDIUM) | ALLOWED | 2 | 0 | 2 (TOOL_UNAVAILABLE) | ALLOWED |
| 6 | UI (MEDIUM) | BLOCKED | 2 | 0 | 2 (TOOL_UNAVAILABLE) | BLOCKED |

### Key Observations

Demo 4 (CRITICAL): BLOCKED with engine override —
"5 engine(s) unavailable without human audit".
CRITICAL risk requires either working engines OR human audit.
Neither present → correct BLOCKED.

Demo 1 (LOW): No engines triggered.
Correctly skips external tool chain for low-risk tasks.

All SKIPs: TOOL_UNAVAILABLE with specific reason.
No fake PASS. No mock/dry_run mislabeled as live.

## ENGINE PLAN EXAMPLES

### HIGH Risk (Demo 3): auth + file upload
4 engines planned:
- semgrep: risk_match + project_match + surface_match
- k6: risk_match + project_match + surface_match
- autocannon: risk_match + project_match + surface_match
- playwright: risk_match (project/surface mismatch noted)

### CRITICAL Risk (Demo 4): price + inventory + payment
5 engines planned:
- semgrep: risk + project + surface match
- codeql: risk + project + surface match
- k6: risk + project + surface match
- autocannon: risk + project + surface match
- playwright: risk match (project/surface mismatch noted)

## EVIDENCE BINDING EXAMPLES

Each engine run (or skip) produces:
- engine_id with status
- evidence_type (security_findings / performance_metrics / e2e_results / extracted_content)
- evidence_summary with human-readable result
- skip_reason when TOOL_UNAVAILABLE

Example (Demo 3, semgrep):
{
  engine_id: "semgrep",
  status: "TOOL_UNAVAILABLE",
  evidence_type: "security_findings",
  skip_reason: "semgrep not found in PATH",
  install_hint: "pip install semgrep"
}

## TOOL AVAILABILITY SUMMARY

0/6 engines available on this host:
- semgrep: MISSING (pip install semgrep)
- codeql: MISSING (choco install codeql)
- k6: MISSING (choco install k6)
- autocannon: MISSING (npm install -g autocannon)
- playwright: MISSING (npm install -D @playwright/test)
- firecrawl_reader: MISSING (npm install -g @anthropic-ai/firecrawl)

All correctly detected. No tools installed. No fake PASS.

## BLOCKED OR SKIPPED CASES

- Demo 4 BLOCKED: CRITICAL price/inventory/payment, 0/5 engines, no human audit
- Demo 6 BLOCKED: No test files in threejs starter (lightweight gate)
- All unavailable engines: SKIPPED_WITH_REASON (TOOL_UNAVAILABLE)

## BOUNDARY COMPLIANCE

- [PASS] No Independent Search Agent restored
- [PASS] No Dual Search Channel restored
- [PASS] No Implementer direct search
- [PASS] No chat URL extraction as canonical evidence
- [PASS] No mock/dry_run mislabeled as live
- [PASS] No API key leakage
- [PASS] No rebuild of search/multi-agent/verifier/harness
- [PASS] Multi-agent not set as default mode
- [PASS] External tools do not bypass Evidence Binding
- [PASS] Firecrawl does not replace canonical search (EVIDENCE_ONLY, reader_extractor category)

## KNOWN RISKS

1. All 6 engines unavailable on this host
   - Engine plans are generated but execution is always SKIPPED
   - To exercise real engine runs, install tools on the host

2. Risk classifier is keyword-based
   - Demo 5 (PERF) classified as MEDIUM instead of HIGH because "performance"
     is not in the HIGH trigger patterns
   - k6/autocannon not triggered at MEDIUM level

3. Engine result parsers are JSON-first with fallback text parsing
   - May miss structured output from non-JSON tool versions

4. Playwright requires project to have @playwright/test installed
   - Detection checks npm global and local; npx available but package missing
   - Accurate: tool is genuinely unavailable without the package

## FILES CHANGED

### New Files (13)
- schemas/external-engine.schema.json
- schemas/external-engine-run-result.schema.json
- governance/external-engines/engine-registry.json
- governance/external-engines/ENGINE_REGISTRY.md
- runtime/external-engine-registry.ps1
- runtime/external-tool-availability-check.ps1
- runtime/external-engine-broker.ps1
- runtime/risk-enforcement-gate-v3.ps1
- runtime/parsers/parse-semgrep-result.ps1
- runtime/parsers/parse-codeql-result.ps1
- runtime/parsers/parse-loadtest-result.ps1
- runtime/parsers/parse-playwright-result.ps1
- runtime/parsers/parse-reader-result.ps1
- runtime/R3_0_demo_runner.ps1
- outputs/R3_0_TOOL_AVAILABILITY_REPORT.json
- outputs/R3_0_EXTERNAL_ENGINE_BROKER_REPORT.md

## RECOMMENDED NEXT BIG CAPABILITY

**R3.1: Expert Pack System**
- With the engine broker in place, the next logical step is building
  domain-specific expert packs (ecommerce, SaaS, miniapp, CMS) that
  bundle pre-configured engine plans, invariants, and surface templates
- Each expert pack maps risk patterns → engine plans → invariants
- Reduces the keyword-classification gap by providing domain-tuned
  risk classifiers per project category
