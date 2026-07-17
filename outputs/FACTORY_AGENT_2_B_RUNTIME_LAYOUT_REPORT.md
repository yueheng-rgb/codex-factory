# FACTORY-AGENT-2 Runtime Layout Report

**Generated**: 2026-06-26T03:00:00+08:00  
**Phase**: FACTORY-AGENT-2 / Worker Capsule + Reporting Runtime Hardening  
**Step**: B — Runtime Directory and Script Layout

---

## Directory Structure

```
factory-agent-company-protocol-pack/
├── runtime/
│   ├── scripts/
│   │   ├── validate-worker-capsule.ps1        (upgraded from AGENT-1)
│   │   ├── validate-progress-report.ps1        (new)
│   │   ├── validate-worker-status-report.ps1   (new)
│   │   ├── validate-worker-handoff.ps1         (new)
│   │   ├── validate-agent-close-receipt.ps1    (new)
│   │   ├── check-scope-isolation.ps1           (new)
│   │   ├── check-evidence-integrity.ps1        (new)
│   │   ├── check-agent-protocol-integrity.ps1  (new — resolves AGENT-1 gap)
│   │   └── run-agent-runtime-suite.ps1         (new — combined suite)
│   ├── fixtures/
│   │   ├── valid-worker-capsule.json
│   │   ├── invalid-worker-capsule-missing-scope.json
│   │   ├── invalid-worker-capsule-broad-scope.json
│   │   ├── valid-progress-report.json
│   │   ├── invalid-progress-report-markdown-only.json
│   │   ├── valid-status-report.json
│   │   ├── invalid-status-report-claims-pass.json
│   │   ├── valid-handoff.json
│   │   ├── invalid-handoff-no-evidence.json
│   │   ├── valid-close-receipt.json
│   │   ├── invalid-close-receipt-no-handoff.json
│   │   ├── scope-valid-case.json
│   │   ├── scope-invalid-cross-write.json
│   │   ├── evidence-valid-case.json
│   │   └── evidence-invalid-sha.json
│   └── results/
│       └── (runtime execution outputs)
```

## Script Design Principles

| Principle | Enforcement |
|---|---|
| Accept protocol pack root parameter | `-ProtocolPackRoot` param on all scripts |
| Accept input artifact path parameter | `-InputPath` param on validators |
| Output machine-readable JSON | All scripts output JSON to stdout |
| No hardcoded absolute paths | Relative to `-ProtocolPackRoot` or `$PSScriptRoot` |
| Do not modify product code | Read-only operations only |
| Do not create ZIP | No `Compress-Archive` calls |
| Do not mark product correctness PASS | Verdicts scoped to protocol/runtime validity |
| Non-zero exit on blocking invalid input | `exit 1` on any FAIL detection |
| Support -WhatIf | Read-only behavior with preview |
| Support -Verbose | Detailed diagnostic output |

## Verdict Taxonomy

All runtime scripts use consistent verdicts:
- `PASS` — All checks passed, artifact is valid
- `FAIL` — One or more blocking issues found
- `WARNING` — Non-blocking concerns (requires waiver to treat as PASS)
- `ERROR` — Script-level error (bad input, parse failure)

## Dependencies

All scripts are standalone PowerShell 5.1+ scripts with no external module dependencies.
