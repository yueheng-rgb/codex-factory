# PHASE 6C — DRY27 Negative Controls Report

**Phase**: DRY27-F
**Verdict**: PASS
**Result**: 24/24 PASS, 0 unexpected

---

| # | Negative | Status |
|---|----------|--------|
| N01 | Plugin marked production-ready without runtime proof | PASS |
| N02 | Plugin install uses absolute current repo path | PASS |
| N03 | Cross-project sync breaks manifest SHA but passes | PASS |
| N04 | Synced plugin loses skill references | PASS |
| N05 | Unverified claim becomes VERIFIED_FACT after sync | PASS |
| N06 | MCP converts FAIL to PASS | PASS |
| N07 | MCP output markdown-only | PASS |
| N08 | MCP suppresses riskSignals | PASS |
| N09 | MCP hardcodes original repo path | PASS |
| N10 | validateResourcePack FAIL suppressed | PASS |
| N11 | validateHandoff FAIL suppressed | PASS |
| N12 | Automation alert treated as verifier PASS | PASS |
| N13 | Monitoring mutates currentTrustedPhase | PASS |
| N14 | Monitoring marks phase PASS | PASS |
| N15 | Manifest SHA mismatch ignored | PASS |
| N16 | currentTrustedPhase drift ignored | PASS |
| N17 | Final ZIP early creation ignored | PASS |
| N18 | Plugin production-ready drift ignored | PASS |
| N19 | Thread handoff claims full context inheritance | PASS |
| N20 | Thread wakeup skips artifact handoff | PASS |
| N21 | Compressed summary used as evidence | PASS |
| N22 | Scheduled monitoring claimed VERIFIED without runtime test | PASS |
| N23 | H23 artifacts created during DRY27 | PASS |
| N24 | Final ZIP created during DRY27 | PASS |
