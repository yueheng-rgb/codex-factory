# FACTORY-MEMORY-QUALITY-0-P1 — Section I: Negative Controls Report

**Phase**: FACTORY-MEMORY-QUALITY-0-P1 | **Date**: 2026-06-27

| Metric | Value |
|--------|-------|
| Total | 36 |
| Detected | 36 |
| Undetected | 0 |
| UNEXPECTED_PASS | 0 |
| FAIL_TARGET_NOT_TRIGGERED | 0 |
| Generic FAIL | 0 |
| ExpectedClass-only | 0 |
| Manual PASS-only | 0 |

## Category Breakdown

| # | ID | Fault | Result |
|---|-----|-------|--------|
| 1 | NC01 | context-packet.schema.json missing | DETECTED |
| 2 | NC02 | Generator script missing | DETECTED |
| 3 | NC03 | Validator script missing | DETECTED |
| 4 | NC04 | Generator cannot run | DETECTED |
| 5 | NC05 | Validator cannot run | DETECTED |
| 6 | NC06 | Compressed summary as evidence | DETECTED |
| 7 | NC07 | Unsupported PASS claim | DETECTED |
| 8 | NC08 | Summary claim without evidence | DETECTED |
| 9 | NC09 | Active risks omitted | DETECTED |
| 10 | NC10 | Rejected claims omitted | DETECTED |
| 11 | NC11 | Forbidden assumptions omitted | DETECTED |
| 12 | NC12 | Evidence paths omitted | DETECTED |
| 13 | NC13 | Stale packet accepted | DETECTED |
| 14 | NC14 | Result JSON missing | DETECTED |
| 15 | NC15 | Negative controls report missing | DETECTED |
| 16 | NC16 | Original verifier blind spot ignored | DETECTED |
| 17 | NC17 | Archive scope gap ignored | DETECTED |
| 18 | NC18 | PRO-2 started prematurely | DETECTED |
| 19 | NC19 | Product code modified | DETECTED |
| 20 | NC20 | v0.5 package created | DETECTED |
| 21 | NC21 | Release ZIP created | DETECTED |
| 22 | NC22 | Old v0.4 release modified | DETECTED |
| 23 | NC23 | Old FINAL modified | DETECTED |
| 24 | NC24 | Diagnostic Pack treated as mainline | DETECTED |
| 25 | NC25 | External memory = model expansion | DETECTED |
| 26 | NC26 | Compressed summary trusted | DETECTED |
| 27 | NC27 | No smoke test | DETECTED |
| 28 | NC28 | No dedicated bundle | DETECTED |
| 29 | NC29 | Bundle excludes memory-quality/ | DETECTED |
| 30 | NC30 | Bundle includes product source | DETECTED |
| 31 | NC31 | Bundle includes release ZIP | DETECTED |
| 32 | NC32 | No MANIFEST.json | DETECTED |
| 33 | NC33 | No SHA manifest | DETECTED |
| 34 | NC34 | Verifier allows missing runtime artifacts | DETECTED |
| 35 | NC35 | Microphase split recommended | DETECTED |
| 36 | NC36 | No next phase update | DETECTED |

All 36 negative controls DETECTED with fault manifest, target check, risk signal, actual validation output, machine-readable result, and verifier confirmation.
